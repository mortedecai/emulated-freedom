#!/usr/bin/env bash
# Decides which documents under docs/ the Docs workflow needs to build, so a
# change rebuilds only the documents it can affect.
#
# A document (a folder with an index.adoc, see scripts/build-docs.sh) depends on:
#   * every file in its folder and subfolders, except subfolders that are
#     documents of their own; and
#   * every file reached from its .adoc files through include:: lines and
#     image or diagram macros, followed recursively through each .adoc file
#     reached, however deep and wherever it lives in the repository.
#
# Given the files a change touched, a document is rebuilt when one of them is
# among its dependencies. Every document is rebuilt when a shared build file
# changes (FULL_REBUILD_FILES), or when --all is given.
#
# A reference the scan cannot resolve (an attribute it does not know, a URL
# include, a missing file) makes that one document always rebuild and never use
# the cache, because what it depends on is unknown.
#
# Each document also gets a cache key: a hash of the contents of its
# dependencies and of the shared build files. The same key means the same
# inputs, so a build saved under it can be reused instead of rebuilt.
#
# Usage:
#   scripts/docs-affected.sh --all              plan a full rebuild
#   scripts/docs-affected.sh --changed FILE     plan for the repo-relative paths listed in FILE
#   scripts/docs-affected.sh --deps FOLDER      print one document's dependencies
#
# A plan is a JSON array with one object per document:
#   {"document": "docs/plans/product-fit", "name": "plans-product-fit",
#    "rebuild": true, "reason": "...", "cacheable": true, "key": "<sha256>"}
#
# Planning fails if a document depends on a file that the workflow's paths:
# filter does not cover, because a change to that file would not start the
# workflow at all.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKFLOW="$ROOT_DIR/.github/workflows/docs.yml"

# Files that go into every document's output.
SHARED_FILES=(scripts/build-docs.sh .github/workflows/docs.yml)
# A change to any of these rebuilds every document.
FULL_REBUILD_FILES=("${SHARED_FILES[@]}" scripts/docs-affected.sh)

# Block macros whose target is a file: image:: and the asciidoctor-diagram ones.
MACROS='image|plantuml|graphviz|ditaa|mermaid|svgbob|wavedrom|vega|vegalite|d2|structurizr|pikchr|nomnoml|erd|blockdiag|seqdiag|actdiag|nwdiag|packetdiag|rackdiag|bpmn|bytefield|dbml|gnuplot|lilypond|msc|smcat|symbolator|syntrax|tikz|umlet|a2s'
# Attributes whose value may name a file or folder the build reads.
PATH_ATTRS='pdf-theme|pdf-themesdir|pdf-fontsdir|docinfodir|stylesheet|stylesdir'

RE_ATTR='^:([A-Za-z0-9_][A-Za-z0-9_-]*):[[:space:]]*(.*)$'
RE_INCLUDE='^[[:space:]]*include::([^[]+)\['
RE_MACRO="^[[:space:]]*($MACROS)::([^[]+)\\["
RE_INLINE_IMAGE='(^|[^A-Za-z0-9_:])image:([^:[:space:][][^[]*)\['
RE_ATTR_REF='\{([A-Za-z0-9_][A-Za-z0-9_-]*)\}'

# State for the document being scanned, reset by collect_deps.
declare -A DEPS=() ATTRS=()
QUEUE=()
UNRESOLVED=()
DOC_ABS=""

# Replaces {attribute} references with the values defined in the scanned
# files. Fails if one is left that the scan does not know.
substitute() {
  local s="$1" name n=0
  while [[ $s =~ $RE_ATTR_REF ]] && ((n++ < 50)); do
    name="${BASH_REMATCH[1]}"
    [[ -v ATTRS[$name] ]] || return 1
    s="${s//"{$name}"/"${ATTRS[$name]}"}"
  done
  [[ $s != *"{"*"}"* ]] || return 1
  printf '%s' "$s"
}

# Records an existing file, or every file in an existing folder, as a
# dependency, and queues .adoc files to be scanned in turn.
add_dep() {
  local abs="$1" f
  if [[ -d $abs ]]; then
    while IFS= read -r f; do add_dep "$f"; done < <(find "$abs" -type f)
    return
  fi
  local rel="${abs#"$ROOT_DIR/"}"
  [[ -z ${DEPS[$rel]:-} ]] || return 0
  DEPS[$rel]=1
  case "$abs" in
    *.adoc | *.asciidoc | *.asc | *.ad) QUEUE+=("$abs") ;;
  esac
}

# Resolves a reference found in a file in folder $3. An include is relative to
# the including file; an image or diagram may also be relative to imagesdir or
# to the document's folder, so every candidate that exists is recorded.
resolve() {
  local raw="$1" kind="$2" dir="$3" target c n found="" imagesdir
  if ! target="$(substitute "$raw")"; then
    UNRESOLVED+=("$raw")
    return
  fi
  case "$target" in
    *://* | data:*)
      [[ $kind != include ]] || UNRESOLVED+=("$raw")
      return
      ;;
  esac
  local candidates=()
  if [[ $target == /* ]]; then
    candidates=("$target")
  elif [[ $kind == include ]]; then
    candidates=("$dir/$target")
  else
    imagesdir="$(substitute "${ATTRS[imagesdir]:-}")" || imagesdir=""
    [[ $imagesdir == /* ]] || imagesdir="$DOC_ABS/$imagesdir"
    candidates=("$dir/$target" "$imagesdir/$target" "$DOC_ABS/$target")
  fi
  for c in "${candidates[@]}"; do
    n="$(realpath -m "$c")"
    if [[ $n == "$ROOT_DIR"/* && -e $n ]]; then
      add_dep "$n"
      found=1
    fi
  done
  [[ -n $found || $kind == optional ]] || UNRESOLVED+=("$raw")
}

# Reads one .adoc file for attribute definitions and references.
scan() {
  local file="$1" dir line rest in_comment=""
  dir="$(dirname "$file")"
  while IFS= read -r line; do
    if [[ $line == '////'* ]]; then
      if [[ -n $in_comment ]]; then in_comment=""; else in_comment=1; fi
      continue
    fi
    [[ -z $in_comment && $line != //* ]] || continue

    if [[ $line =~ $RE_ATTR ]]; then
      local name="${BASH_REMATCH[1]}" value="${BASH_REMATCH[2]%"${BASH_REMATCH[2]##*[![:space:]]}"}"
      ATTRS[$name]="$value"
      if [[ $name =~ ^($PATH_ATTRS)$ && -n $value ]]; then
        resolve "$value" optional "$DOC_ABS"
      fi
      continue
    fi
    if [[ $line =~ $RE_INCLUDE ]]; then
      resolve "${BASH_REMATCH[1]}" include "$dir"
    elif [[ $line =~ $RE_MACRO ]]; then
      resolve "${BASH_REMATCH[2]}" macro "$dir"
    fi
    rest="$line"
    while [[ $rest =~ $RE_INLINE_IMAGE ]]; do
      resolve "${BASH_REMATCH[2]}" macro "$dir"
      rest="${rest#*"${BASH_REMATCH[0]}"}"
    done
  done < <(grep -E '^(//|:)|::|image:' "$file" || true)
}

# Fills DEPS and UNRESOLVED for the document in folder $1 (repo-relative).
collect_deps() {
  DOC_ABS="$ROOT_DIR/$1"
  DEPS=()
  ATTRS=([docdir]="$DOC_ABS")
  QUEUE=()
  UNRESOLVED=()
  local f i=0
  # Scan the root file first so its header attributes are known to the rest.
  add_dep "$DOC_ABS/index.adoc"
  while IFS= read -r f; do
    add_dep "$f"
  done < <(find "$DOC_ABS" -mindepth 1 -type d -exec test -f '{}/index.adoc' \; -prune -o -type f -print | sort)
  while ((i < ${#QUEUE[@]})); do
    scan "${QUEUE[i]}"
    i=$((i + 1))
  done
}

# The globs in the workflow's paths: filters. bash's * also matches "/", so
# "docs/*" is treated like "docs/**"; that only makes the check more lenient.
workflow_paths() {
  [[ -f $WORKFLOW ]] || return 0
  awk '/^[[:space:]]*paths:/ { p = 1; next }
       p && /^[[:space:]]*- / { sub(/^[[:space:]]*- */, ""); gsub(/"|\x27/, ""); print; next }
       { p = 0 }' "$WORKFLOW" | grep -v '^!' | sed 's/\*\*/*/g' | sort -u
}

# The deepest document folder holding path $1, or nothing.
owner_of() {
  local path="$1" doc best=""
  for doc in "${DOCUMENTS[@]}"; do
    if [[ $path == "$doc"/* ]] && ((${#doc} > ${#best})); then best="$doc"; fi
  done
  printf '%s' "$best"
}

plan() {
  local mode="$1" list="${2:-}" f doc full_reason="" shared_hash
  local -A changed=()
  local globs=() path_errors=() objects=()
  local listed
  listed="$("$ROOT_DIR/scripts/build-docs.sh" --list)"
  mapfile -t DOCUMENTS < <(printf '%s' "$listed" | grep . || true)
  mapfile -t globs < <(workflow_paths)

  if [[ $mode == all ]]; then
    full_reason="full rebuild requested"
  else
    while IFS= read -r f; do
      [[ -n $f ]] && changed[$f]=1
    done < "$list"
    for f in "${FULL_REBUILD_FILES[@]}"; do
      [[ -z ${changed[$f]:-} ]] || { full_reason="$f changed"; break; }
    done
  fi
  shared_hash="$(cd "$ROOT_DIR" && sha256sum -- "${SHARED_FILES[@]}" | sha256sum | cut -c1-64)"

  for doc in "${DOCUMENTS[@]}"; do
    collect_deps "$doc"
    local rebuild=false reason="unchanged" cacheable=true key name g covered
    name="${doc#docs/}"
    name="${name//\//-}"
    key="$(cd "$ROOT_DIR" && { echo "$shared_hash"; printf '%s\n' "${!DEPS[@]}" | sort | xargs -d '\n' sha256sum --; } | sha256sum | cut -c1-64)"

    if ((${#UNRESOLVED[@]})); then
      cacheable=false
      echo "::warning::$doc: cannot resolve ${UNRESOLVED[*]}; it is always rebuilt" >&2
    fi
    if [[ -n $full_reason ]]; then
      rebuild=true reason="$full_reason"
    elif [[ $cacheable == false ]]; then
      rebuild=true reason="unresolved reference: ${UNRESOLVED[0]}"
    else
      for f in "${!changed[@]}"; do
        # A deleted file is no longer found by the scan, so also match by folder.
        if [[ -n ${DEPS[$f]:-} || $(owner_of "$f") == "$doc" ]]; then
          rebuild=true reason="$f changed"
          break
        fi
      done
    fi

    if ((${#globs[@]})); then
      for f in "${!DEPS[@]}"; do
        covered=""
        for g in "${globs[@]}"; do
          # shellcheck disable=SC2053 # $g is a glob on purpose
          [[ $f == $g ]] && { covered=1; break; }
        done
        [[ -n $covered ]] || path_errors+=("$doc depends on $f")
      done
    fi

    objects+=("$(jq -nc --arg document "$doc" --arg name "$name" --argjson rebuild "$rebuild" \
      --arg reason "$reason" --argjson cacheable "$cacheable" --arg key "$key" \
      '{document: $document, name: $name, rebuild: $rebuild, reason: $reason, cacheable: $cacheable, key: $key}')")
  done
  printf '%s\n' "${objects[@]}" | jq -sc .

  for f in "${path_errors[@]}"; do
    echo "::error::$f, which the paths: filters in .github/workflows/docs.yml do not cover; add it there so changes to it rebuild the document" >&2
  done
  ((${#path_errors[@]} == 0))
}

case "${1:-}" in
  --all) plan all ;;
  --changed)
    [[ -f ${2:-} ]] || { echo "usage: $0 --changed FILE" >&2; exit 2; }
    plan changed "$2"
    ;;
  --deps)
    [[ -f $ROOT_DIR/${2%/}/index.adoc ]] || { echo "usage: $0 --deps FOLDER (a folder with an index.adoc)" >&2; exit 2; }
    collect_deps "${2%/}"
    printf '%s\n' "${!DEPS[@]}" | sort
    for f in "${UNRESOLVED[@]}"; do echo "unresolved: $f" >&2; done
    ;;
  *)
    echo "usage: $0 --all | --changed FILE | --deps FOLDER" >&2
    exit 2
    ;;
esac

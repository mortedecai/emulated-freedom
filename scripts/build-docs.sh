#!/usr/bin/env bash
# Builds every AsciiDoc document under docs/.
#
# A document is any folder under docs/ that contains a root file named
# index.adoc (lowercase only; any other casing fails the check). Each one is built to a PDF and to HTML, and the HTML is zipped with its
# diagrams. The source tree is never written to.
#
# A folder holding .adoc files must belong to a document: it, or a folder
# above it, has a root file. Otherwise the check fails, unless the folder is
# listed in docs/.build-exclude (one repo-relative folder per line, exact
# match, # starts a comment).
#
# Usage:
#   scripts/build-docs.sh --list        check, then print one document folder per line
#   scripts/build-docs.sh [folder...]   check, then build the given folders (default: all)
#
# Output goes to $OUT_DIR/<name>/ where <name> is the folder path relative to
# docs/ with "/" replaced by "-" (docs/plans/product-fit -> plans-product-fit).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCS_DIR="$ROOT_DIR/docs"
OUT_DIR="${OUT_DIR:-$ROOT_DIR/build/docs}"
EXCLUDE_FILE="$DOCS_DIR/.build-exclude"

# Every folder under docs/ that holds a root file, relative to the repo.
list_documents() {
  find "$DOCS_DIR" -type f -name index.adoc -printf '%h\n' \
    | sed "s|^$ROOT_DIR/||" \
    | sort -u
}

is_excluded() {
  [[ -f "$EXCLUDE_FILE" ]] || return 1
  sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e 's|/$||' "$EXCLUDE_FILE" | grep -qxF "$1"
}

# Fails if a root file is not spelled exactly index.adoc, or if a folder
# holding .adoc files is neither part of a document nor excluded.
check_layout() {
  local failed="" dir rel file

  while IFS= read -r file; do
    echo "::error::${file#"$ROOT_DIR/"} must be named index.adoc (lowercase)" >&2
    failed=1
  done < <(find "$DOCS_DIR" -type f -iname index.adoc ! -name index.adoc)

  while IFS= read -r dir; do
    rel="${dir#"$ROOT_DIR/"}"
    local d="$dir" covered=""
    while [[ "$d" == "$DOCS_DIR"* ]]; do
      if [[ -f "$d/index.adoc" ]]; then
        covered=1
        break
      fi
      d="$(dirname "$d")"
    done
    if [[ -n "$covered" ]]; then
      continue
    fi
    if is_excluded "$rel"; then
      echo "::warning::$rel has no index.adoc and is listed in docs/.build-exclude, so it is not built" >&2
    else
      echo "::error::$rel has AsciiDoc files but no index.adoc; add one, or list the folder in docs/.build-exclude" >&2
      failed=1
    fi
  done < <(find "$DOCS_DIR" -type f -name '*.adoc' -printf '%h\n' | sort -u)

  [[ -z "$failed" ]]
}

build_document() {
  local rel="$1"
  local src="$ROOT_DIR/$rel/index.adoc"
  local name="${rel#docs/}"
  name="${name//\//-}"
  local out="$OUT_DIR/$name"
  local cache="$OUT_DIR/.diagram-cache/$name"

  if [[ ! -f "$src" ]]; then
    echo "::error::$rel has no index.adoc"
    return 1
  fi

  echo "Building $rel -> $out"
  rm -rf "$out"
  mkdir -p "$out/html" "$cache"

  # --failure-level=WARN turns broken includes and unresolved references into
  # a non-zero exit, so the build fails instead of shipping a broken document.
  local common=(
    --failure-level=WARN
    -r asciidoctor-diagram
    -a diagram-cachedir="$cache"
  )

  asciidoctor "${common[@]}" -D "$out/html" -o index.html "$src"
  # The PDF build writes its own copy of the diagrams, so keep it out of $out.
  asciidoctor-pdf "${common[@]}" -D "$out/pdf" -o "$name.pdf" "$src"
  mv "$out/pdf/$name.pdf" "$out/"

  (cd "$out/html" && zip -qr "../$name-html.zip" .)
  rm -rf "$out/html" "$out/pdf"
}

check_layout

if [[ "${1:-}" == "--list" ]]; then
  list_documents
  exit 0
fi

if [[ $# -eq 0 ]]; then
  mapfile -t docs < <(list_documents)
else
  docs=("$@")
fi

if [[ ${#docs[@]} -eq 0 ]]; then
  echo "No folders under docs/ contain index.adoc; nothing to build."
  exit 0
fi

for doc in "${docs[@]}"; do
  build_document "${doc%/}"
done

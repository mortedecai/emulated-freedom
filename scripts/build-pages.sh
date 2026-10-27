#!/usr/bin/env bash
# Builds the public documentation site served by GitHub Pages.
#
# The whole repository is scanned for documents (any folder with an index.adoc,
# see scripts/build-docs.sh). Each one is built to a standalone HTML page and
# placed on the site under a path derived from where it lives in the tree:
#
#   <language>/<project-type>/<identifier>/docs/<doctype>[/sub...]
#     -> /<project-type>/<identifier>/<language>/<doctype>[/sub...]/
#
# The <language> segment is optional: a document whose path has only
# <project-type>/<identifier> before docs/ is published without one, e.g.
#
#   emulators/chip-8/docs/high-level-design -> /emulators/chip-8/high-level-design/
#   emulators/chip-8/docs/high-level-design/go -> /emulators/chip-8/high-level-design/go/
#
# The site root is a temporary "coming soon" page that lists every document
# built, grouped by project, and shows the version it was built from.
#
# Usage:
#   scripts/build-pages.sh          build into $SITE_DIR using $VERSION
#
# Environment:
#   SITE_DIR  output directory (default: build/pages)
#   VERSION   version string shown on the site (default: unreleased)
#   STRICT    1 to fail if any document fails to build, 0 to skip it and carry
#             on (default: 1)
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SITE_DIR="${SITE_DIR:-$ROOT_DIR/build/pages}"
VERSION="${VERSION:-unreleased}"
STRICT="${STRICT:-1}"
# Kept out of SITE_DIR so it is never published with the site.
CACHE_DIR="$ROOT_DIR/build/pages-diagram-cache"

DOCS_BUILT=()

# Maps a document folder (repo-relative, the folder holding index.adoc) to its
# path on the site, or fails if the folder is not under a
# <project-type>/<identifier>/docs/ location.
site_path_for() {
  local rel="$1"
  [[ "$rel" == */docs/* ]] || return 1
  local prefix="${rel%%/docs/*}" rest="${rel#*/docs/}"
  local -a seg
  IFS='/' read -ra seg <<< "$prefix"
  local lang="" ptype id
  case "${#seg[@]}" in
    3) lang="${seg[0]}" ptype="${seg[1]}" id="${seg[2]}" ;;
    2) ptype="${seg[0]}" id="${seg[1]}" ;;
    *) return 2 ;;
  esac
  if [[ -n "$lang" ]]; then
    printf '%s/%s/%s/%s' "$ptype" "$id" "$lang" "$rest"
  else
    printf '%s/%s/%s' "$ptype" "$id" "$rest"
  fi
}

build_document() {
  local rel="$1" sub out src
  src="$ROOT_DIR/$rel/index.adoc"
  if ! sub="$(site_path_for "$rel")"; then
    echo "::warning::$rel is not under a <project-type>/<identifier>/docs/ path; skipping"
    return 0
  fi
  out="$SITE_DIR/$sub"
  echo "Building $rel -> /$sub/"
  rm -rf "$out"
  mkdir -p "$out"

  # --failure-level=WARN turns broken includes and unresolved references into a
  # non-zero exit, matching scripts/build-docs.sh.
  if asciidoctor \
    --failure-level=WARN \
    -r asciidoctor-diagram \
    -a "diagram-cachedir=$CACHE_DIR/$sub" \
    -D "$out" -o index.html "$src"; then
    DOCS_BUILT+=("$sub")
  else
    rm -rf "$out"
    if [[ "$STRICT" == "1" ]]; then
      echo "::error::$rel failed to build"
      return 1
    fi
    echo "::warning::$rel failed to build; it is omitted from the site"
  fi
}

# Writes the "coming soon" landing page, listing every document built grouped
# by "<project-type>/<identifier>".
generate_landing() {
  local links="" sub group label gk
  if ((${#DOCS_BUILT[@]})); then
    declare -A groups=()
    for sub in "${DOCS_BUILT[@]}"; do
      group="${sub%%/*}/$(cut -d/ -f2 <<< "$sub")"
      label="${sub#*/*/}"
      label="${label//\// &middot; }"
      groups["$group"]+="<li><a href=\"$sub/\">$label</a></li>"
    done
    links='      <section class="docs">
        <h2>Documentation</h2>'
    while IFS= read -r gk; do
      links+="
        <h3>${gk//\// / }</h3>
        <ul>${groups[$gk]}</ul>"
    done < <(printf '%s\n' "${!groups[@]}" | sort)
    links+='
      </section>'
  fi

  mkdir -p "$SITE_DIR"
  # Serve asciidoctor's output verbatim (no Jekyll processing).
  touch "$SITE_DIR/.nojekyll"

  cat > "$SITE_DIR/index.html" <<HTML
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Emulated Freedom &mdash; Coming Soon</title>
  <style>
    :root { color-scheme: light dark; }
    body {
      margin: 0; min-height: 100vh;
      display: flex; flex-direction: column;
      font-family: system-ui, -apple-system, Segoe UI, Roboto, sans-serif;
      background: #0f1117; color: #e6e6e6;
    }
    main { flex: 1; display: flex; flex-direction: column;
      align-items: center; justify-content: center;
      text-align: center; padding: 3rem 1.5rem; }
    h1 { font-size: clamp(2rem, 6vw, 3.5rem); margin: 0 0 .5rem; }
    .tagline { color: #9aa4b2; margin: 0 0 1.25rem; }
    .version { display: inline-block; padding: .25rem .75rem;
      border: 1px solid #2a3040; border-radius: 999px;
      color: #9aa4b2; font-size: .9rem; }
    .docs { margin-top: 2.5rem; text-align: left; width: min(40rem, 100%); }
    .docs h2 { font-size: 1.25rem; border-bottom: 1px solid #2a3040; padding-bottom: .4rem; }
    .docs h3 { font-size: .95rem; color: #9aa4b2; margin: 1.2rem 0 .4rem; }
    .docs ul { margin: 0; padding-left: 1.2rem; }
    .docs a { color: #7aa2ff; text-decoration: none; }
    .docs a:hover { text-decoration: underline; }
    footer { padding: 1rem; text-align: center; color: #6b7280;
      font-size: .8rem; border-top: 1px solid #1a1f2b; }
  </style>
</head>
<body>
  <main>
    <h1>Emulated Freedom</h1>
    <p class="tagline">Documentation is on its way &mdash; coming soon.</p>
    <p class="version">Version $VERSION</p>
$links
  </main>
  <footer>Emulated Freedom &middot; Version $VERSION</footer>
</body>
</html>
HTML
  echo "Wrote $SITE_DIR/index.html (version $VERSION, ${#DOCS_BUILT[@]} document(s))"
}

main() {
  rm -rf "$SITE_DIR"
  mapfile -t docs < <(
    cd "$ROOT_DIR" && find . -type f -name index.adoc \
      -not -path './.git/*' -not -path './build/*' -printf '%h\n' \
      | sed 's|^\./||' | sort -u
  )
  for doc in "${docs[@]}"; do
    build_document "$doc"
  done
  generate_landing
}

main "$@"

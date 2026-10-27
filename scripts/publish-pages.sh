#!/usr/bin/env bash
# Publishes a built site directory to the gh-pages branch with plain git.
#
# Existing files on the branch that the site does not replace are kept, so a
# release that rebuilds the root documents leaves other published content (for
# example a /preview/ subfolder) in place.
#
# Usage:
#   scripts/publish-pages.sh SITE_DIR
#
# Environment:
#   PAGES_BRANCH  branch to publish to (default: gh-pages)
#   VERSION       included in the commit message (default: empty)
set -euo pipefail

SRC="${1:?usage: publish-pages.sh SITE_DIR}"
BRANCH="${PAGES_BRANCH:-gh-pages}"
SRC="$(cd "$SRC" && pwd)"

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"

work="$(mktemp -d)"
trap 'git worktree remove --force "$work" 2>/dev/null || true' EXIT

if git ls-remote --exit-code --heads origin "$BRANCH" >/dev/null 2>&1; then
  git fetch --depth=1 origin "$BRANCH"
  git worktree add -B "$BRANCH" "$work" "origin/$BRANCH"
else
  git worktree add --detach "$work"
  git -C "$work" checkout --orphan "$BRANCH"
  git -C "$work" rm -rf . >/dev/null 2>&1 || true
fi

# Copy the site over the branch contents without deleting anything else.
cp -R "$SRC"/. "$work"/

git -C "$work" add -A
if git -C "$work" diff --cached --quiet; then
  echo "No changes to publish."
else
  git -C "$work" commit -m "Publish site ${VERSION:-}"
  git -C "$work" push origin "$BRANCH"
fi

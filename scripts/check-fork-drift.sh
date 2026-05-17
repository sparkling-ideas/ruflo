#!/bin/bash
# scripts/check-fork-drift.sh
#
# Reads FORK-PATCHES.md and alerts when upstream has published past a patched version.
# Per ADR-0002 (in fork-restart meta-repo), each drift event triggers a re-patch / drop /
# no-action decision documented inline in FORK-PATCHES.md.
#
# Exit codes:
#   0 — all patches are at current upstream versions (no drift)
#   1 — one or more patches show drift (review needed)
#   2 — script error (couldn't read manifest, missing tools, etc.)

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
PATCHES_FILE="$REPO_ROOT/FORK-PATCHES.md"
NPMJS="${NPMJS_REGISTRY:-https://registry.npmjs.org}"

# Required tools
for tool in curl jq; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "ERROR: '$tool' is required" >&2
    exit 2
  fi
done

if [ ! -f "$PATCHES_FILE" ]; then
  echo "ERROR: FORK-PATCHES.md not found at $PATCHES_FILE" >&2
  exit 2
fi

drift_count=0
checked_count=0
declare -a drift_lines
in_code_block=0

# Parse manifest lines like: "- @scope/pkg@version — description"
# or:                        "- unscoped-pkg@version — description"
# Skip lines inside ``` code fences (those are format examples, not real entries).
while IFS= read -r line; do
  if [[ "$line" =~ ^\`\`\` ]]; then
    in_code_block=$((1 - in_code_block))
    continue
  fi
  [ "$in_code_block" -eq 1 ] && continue
  if [[ "$line" =~ ^-[[:space:]]+([@a-zA-Z0-9/._-]+)@([0-9a-zA-Z.+_-]+)[[:space:]] ]]; then
    pkg="${BASH_REMATCH[1]}"
    patched_version="${BASH_REMATCH[2]}"
    checked_count=$((checked_count + 1))

    # URL-encode scope-prefixed names: '@scope/pkg' → '@scope%2Fpkg'
    pkg_encoded=$(printf '%s' "$pkg" | sed 's|/|%2F|g')
    upstream_version=$(curl -sf "$NPMJS/${pkg_encoded}/latest" 2>/dev/null | jq -r '.version // empty')

    if [ -z "$upstream_version" ]; then
      echo "WARN: could not fetch upstream version for $pkg (npmjs returned empty or 404)" >&2
      continue
    fi

    if [ "$upstream_version" != "$patched_version" ]; then
      drift_lines+=("DRIFT: $pkg — patched at $patched_version; upstream latest is $upstream_version")
      drift_count=$((drift_count + 1))
    fi
  fi
done < "$PATCHES_FILE"

if [ "$checked_count" -eq 0 ]; then
  echo "No A0 patches recorded in FORK-PATCHES.md — nothing to check."
  exit 0
fi

if [ "$drift_count" -gt 0 ]; then
  printf '%s\n' "${drift_lines[@]}"
  echo
  echo "$drift_count of $checked_count fork patch(es) have upstream drift."
  echo "Per ADR-0002: review each entry in FORK-PATCHES.md and decide re-patch / drop / no-action."
  exit 1
fi

echo "All $checked_count fork patch(es) are at current upstream versions."
exit 0

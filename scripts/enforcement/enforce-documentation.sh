#!/usr/bin/env bash
# enforce-documentation.sh — deterministic enforcer for core/documentation-policy.md

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/evidence.sh
. "$SCRIPT_DIR/lib/evidence.sh" 2>/dev/null || { echo "BYPASS DENIED: canonical bypass library is unavailable" >&2; exit 2; }

bypass_reject_disabled_master_requests EOS_BYPASS_DOC || exit 2
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

staged="$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)"
[ -z "$staged" ] && exit 0

in_index() { git cat-file -e ":$1" 2>/dev/null; }

fail=0

dirs="$(printf '%s\n' "$staged" | grep -E '^(patterns|external-systems)/[^/]+/' | sed -E 's#^((patterns|external-systems)/[^/]+)/.*#\1#' | sort -u || true)"
if [ -n "$dirs" ]; then
  while IFS= read -r dir; do
    [ -z "$dir" ] && continue
    if ! in_index "$dir/README.md"; then
      if ! bypass_staged_tree_request EOS_BYPASS_DOCREADME; then
        echo "❌ COMMIT BLOCKED — documentation-policy.md <documentation>: '$dir/' has no README.md."
        echo "  BYPASS: EOS_BYPASS_DOCREADME=1 (or EOS_BYPASS_DOC=1)."
        fail=1
      fi
    fi
  done <<EOF
$dirs
EOF
fi

if ! in_index "README.md"; then
  if ! bypass_repository_tree_request EOS_BYPASS_ROOTREADME; then
    echo "❌ COMMIT BLOCKED — documentation-policy.md <documentation>: the repo has no root README.md."
    echo "  BYPASS: EOS_BYPASS_ROOTREADME=1 (or EOS_BYPASS_DOC=1)."
    fail=1
  fi
fi

added="$(git diff --cached --diff-filter=ACMR -U0 -- '*.md' 2>/dev/null | grep -E '^\+' | grep -vE '^\+\+\+' || true)"
if [ -n "$added" ]; then
  tbd_hits="$(printf '%s\n' "$added" | grep -nE '^\+[[:space:]]*([*-][[:space:]]+|>[[:space:]]+)?(#+[[:space:]]*)?(TBD|FIXME|XXX|\?\?\?)[[:space:]]*$|^\+[[:space:]]*[^:]+:[[:space:]]*(TBD|FIXME|XXX|\?\?\?)[[:space:]]*$' || true)"
  if [ -n "$tbd_hits" ]; then
    if ! bypass_staged_tree_request EOS_BYPASS_TBD; then
      echo "❌ COMMIT BLOCKED — documentation-policy.md <documentation>: placeholder markers in staged docs."
      printf '%s\n' "$tbd_hits" | sed 's/^/    /'
      echo "  BYPASS: EOS_BYPASS_TBD=1 (or EOS_BYPASS_DOC=1)."
      fail=1
    fi
  fi
fi

if ! bypass_staged_tree_request EOS_BYPASS_DOCHYGIENE; then
  if [ -f "$SCRIPT_DIR/check-documentation-hygiene.sh" ]; then
    if ! bash "$SCRIPT_DIR/check-documentation-hygiene.sh"; then
      echo "  BYPASS: EOS_BYPASS_DOCHYGIENE=1 (or EOS_BYPASS_DOC=1)."
      fail=1
    fi
  fi
fi

exit "$fail"

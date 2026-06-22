#!/usr/bin/env bash
# enforce-sync.sh — keeps each md in sync with its enforcer.
#
# Called from pre-commit. For every staged md listed in MANIFEST.tsv:
#   - if it maps to an enforcer → that enforcer must be staged too, else exit 1.
#   - if it maps to NONE        → allowed (the registry documents why).
#   - if it is NOT in MANIFEST  → exit 1 (forces a conscious decision).
#
# Bypass: EOS_BYPASS_MDSYNC=1
# Governing policy: core/hooks-policy.md <hooks> (md ↔ enforcer sync rule)

case "${EOS_BYPASS_MDSYNC:-}" in 1|true|TRUE|yes|YES) exit 0 ;; esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="$SCRIPT_DIR/MANIFEST.tsv"
[ -f "$MANIFEST" ] || exit 0

# Validate MANIFEST.tsv format: every non-comment, non-empty line must contain a tab.
# A space-instead-of-tab mistake breaks awk -F '\t' silently — the whole sync check
# becomes a no-op without any error, which is worse than a noisy failure.
bad_format="$(grep -v '^#' "$MANIFEST" | grep -v '^[[:space:]]*$' | grep -v $'\t' || true)"
if [ -n "$bad_format" ]; then
  echo "ERROR_FOR_AGENT: enforce-sync — MANIFEST.tsv has lines without tab separators (use TAB, not spaces):"
  printf '%s\n' "$bad_format" | head -5 | sed 's/^/    /'
  echo "  Fix: ensure each row uses a literal TAB between columns."
  exit 1
fi

STAGED="$(git diff --cached --name-only 2>/dev/null)"
[ -z "$STAGED" ] && exit 0

# Only consider staged markdown policy files (core/*.md and root CLAUDE.md).
STAGED_MD="$(printf '%s\n' "$STAGED" | grep -E '(^core/.*\.md$|^CLAUDE\.md$)' || true)"
[ -z "$STAGED_MD" ] && exit 0

RC=0
while IFS= read -r md; do
  [ -z "$md" ] && continue
  # Look up the md in the manifest (skip comments).
  row="$(grep -v '^#' "$MANIFEST" | awk -F '\t' -v m="$md" '$1==m {print; exit}')"
  if [ -z "$row" ]; then
    echo "ERROR_FOR_AGENT: md-sync — '$md' is not in scripts/enforcement/MANIFEST.tsv."
    echo "ACTION: add a row '$md<TAB><enforcer|NONE><TAB><note>' (NONE if no enforcer is appropriate)."
    RC=1
    continue
  fi
  enforcer="$(printf '%s' "$row" | awk -F '\t' '{print $2}')"
  [ "$enforcer" = "NONE" ] && continue
  # An enforcer is mapped — it must be staged alongside the md change.
  if ! printf '%s\n' "$STAGED" | grep -qxF "$enforcer"; then
    echo "ERROR_FOR_AGENT: md-sync — '$md' changed but its enforcer '$enforcer' is not staged."
    echo "ACTION: update and stage '$enforcer' to match the policy change, then commit."
    echo "BYPASS: EOS_BYPASS_MDSYNC=1"
    RC=1
  fi
done <<EOF
$STAGED_MD
EOF

exit $RC

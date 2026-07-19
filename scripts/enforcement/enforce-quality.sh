#!/usr/bin/env bash
# enforce-quality.sh — deterministic enforcer for core/quality-gates.md (<cleanup>).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib/evidence.sh" 2>/dev/null || true
if ! declare -f bypass_active >/dev/null 2>&1; then
  bypass_active() {
    local name="${1:-}"; [ -z "$name" ] && return 1
    case "${!name:-}" in 1|true|TRUE|yes|YES) return 0 ;; *) return 1 ;; esac
  }
fi

bypass_active EOS_BYPASS_QUALITY && exit 0
bypass_active EOS_BYPASS_CLEANUP && exit 0

added="$(git diff --cached --diff-filter=ACMR -U0 -- \
  '*.js' '*.jsx' '*.ts' '*.tsx' '*.py' '*.rb' \
  '*.go' '*.rs' '*.java' '*.kt' 2>/dev/null \
  | grep -E '^\+' | grep -vE '^\+\+\+' || true)"

if [ -n "$added" ]; then
  debug_hits="$(printf '%s\n' "$added" \
    | grep -nE \
      '\bdebugger\b|pdb\.set_trace\(|\bbreakpoint\(\)|import (i)?pdb|binding\.pry|\bbyebug\b|'\
'runtime\.Breakpoint\(\)|debug\.PrintStack\(\)|spew\.Dump\(|'\
'\bdbg!\(|'\
'Thread\.dumpStack\(\)|\.dumpStack\(\)' \
    || true)"
  conflict_hits="$(printf '%s\n' "$added" | grep -nE '^\+(<{7}|>{7})' || true)"
  if [ -n "$debug_hits" ] || [ -n "$conflict_hits" ]; then
    echo "❌ COMMIT BLOCKED — quality-gates.md <cleanup>: debug leftovers in the staged diff."
    [ -z "$debug_hits" ] || printf '%s\n' "$debug_hits" | sed 's/^/    /'
    [ -z "$conflict_hits" ] || printf '%s\n' "$conflict_hits" | sed 's/^/    /'
    echo "  BYPASS: EOS_BYPASS_CLEANUP=1 (or EOS_BYPASS_QUALITY=1)."
    exit 1
  fi
  warn_hits="$(printf '%s\n' "$added" \
    | grep -nE 'console\.(log|debug)\(|\bprint\(|fmt\.Printf\(|log\.Printf\(|\beprintln!\(|System\.out\.print|System\.err\.print' \
    || true)"
  if [ -n "$warn_hits" ]; then
    echo "⚠️  quality-gates.md <cleanup>: debug-style output added — confirm intentional logging:"
    printf '%s\n' "$warn_hits" | sed 's/^/    /'
  fi
fi

if ! bypass_active EOS_BYPASS_SEMANTIC_CLEANUP; then
  if [ -f "$SCRIPT_DIR/check-semantic-cleanup.sh" ]; then
    bash "$SCRIPT_DIR/check-semantic-cleanup.sh"
  fi
fi

# quality-gates.md <definition_of_done>: CI-dependent items (e.g. "PR checks
# pass", "CI green") must never be a plan `## DoD` checkbox — G9a (DoD items
# cannot be removed) and G10 (all DoD items checked before commit) make such
# an item structurally impossible to satisfy honestly before the commit that
# would trigger that CI run exists. Advisory only (not blocking): the correct
# fix is moving the item to a `## Live External Gates Before Merge` section,
# not deleting it, and only a human/agent can judge that rewrite.
plan_dod_ci_hits=""
for staged_plan in $(git diff --cached --diff-filter=ACMR --name-only -- '.claude/plans/*.md' 2>/dev/null || true); do
  [ -f "$staged_plan" ] || continue
  hit="$(awk '
    /^#{1,4}[[:space:]].*([Dd]o[Dd]|תנאי.סיום|Definition.of.Done)/ { found=1; next }
    found && /^#{1,4}[[:space:]]/ { found=0 }
    found && /^\- \[( |x)\]/ { print }
  ' "$staged_plan" | grep -iE 'CI (is |be )?green|CI passe|checks? pass(es)?|PR checks|pipeline (is |be )?green' || true)"
  [ -z "$hit" ] || plan_dod_ci_hits="${plan_dod_ci_hits}${staged_plan}:\n${hit}\n"
done
if [ -n "$plan_dod_ci_hits" ]; then
  echo "⚠️  quality-gates.md <definition_of_done>: a plan '## DoD' section names a CI-outcome item — this cannot be truthfully checked before the commit that triggers that CI run exists."
  printf '%b' "$plan_dod_ci_hits" | sed 's/^/    /'
  echo "  ACTION: move it to a '## Live External Gates Before Merge' section instead (see .claude/plans/audit-freshness-p0.md for the pattern)."
fi

exit 0

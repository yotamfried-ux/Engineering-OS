#!/usr/bin/env bash
# enforce-quality.sh — deterministic enforcer for core/quality-gates.md (<cleanup>).
#
# One enforcer per md file (Engineering OS convention). quality-gates.md is partly
# enforced already (pre-commit.sh: lint+test + physical test-file scan; commit-msg.sh:
# message format). This script adds the one deterministic gate still missing — the
# <cleanup> rule ("אם לא בוצע ניקוי מאומת — הקומיט אינו תקף"): it blocks debug
# leftovers from entering the staged diff.
#
# Scope (the honest deterministic boundary): only UNAMBIGUOUS leftovers are blocked.
# Judgment items (dead code, duplicate logic, legitimate logging) stay manual.
#
# Invoked from scripts/hooks/pre-commit.sh. Master bypass: EOS_BYPASS_QUALITY=1.
# Governing policy: core/quality-gates.md <cleanup>.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/evidence.sh
. "$SCRIPT_DIR/lib/evidence.sh" 2>/dev/null || true
if ! declare -f bypass_active >/dev/null 2>&1; then
  bypass_active() {
    local name="${1:-}"; [ -z "$name" ] && return 1
    case "${!name:-}" in 1|true|TRUE|yes|YES) return 0 ;; *) return 1 ;; esac
  }
fi

bypass_active EOS_BYPASS_QUALITY && exit 0
bypass_active EOS_BYPASS_CLEANUP && exit 0

# Added lines (only '+', never '+++') in staged code files, deletions excluded.
# Scoping to code extensions also means .sh/.md files (including this enforcer and
# its own tests) are never scanned, so the gate can't trip on its own pattern text.
added="$(git diff --cached --diff-filter=ACMR -U0 -- \
  '*.js' '*.jsx' '*.ts' '*.tsx' '*.py' '*.rb' 2>/dev/null \
  | grep -E '^\+' | grep -vE '^\+\+\+' || true)"

[ -z "$added" ] && exit 0

# ── Blocking: interactive debuggers + leftover merge-conflict markers ─────────
debug_hits="$(printf '%s\n' "$added" \
  | grep -nE '\bdebugger\b|pdb\.set_trace\(|\bbreakpoint\(\)|import (i)?pdb|binding\.pry|\bbyebug\b' || true)"
conflict_hits="$(printf '%s\n' "$added" | grep -nE '^\+(<{7}|>{7})' || true)"

if [ -n "$debug_hits" ] || [ -n "$conflict_hits" ]; then
  echo "❌ COMMIT BLOCKED — quality-gates.md <cleanup>: debug leftovers in the staged diff."
  if [ -n "$debug_hits" ]; then
    echo "  Interactive debug statements (remove before committing):"
    printf '%s\n' "$debug_hits" | sed 's/^/    /'
  fi
  if [ -n "$conflict_hits" ]; then
    echo "  Unresolved merge-conflict markers:"
    printf '%s\n' "$conflict_hits" | sed 's/^/    /'
  fi
  echo "  BYPASS: EOS_BYPASS_CLEANUP=1 (or EOS_BYPASS_QUALITY=1) — only if genuinely intentional."
  exit 1
fi

# ── Advisory (non-blocking): console.log / print may be leftover debug ────────
warn_hits="$(printf '%s\n' "$added" | grep -nE 'console\.(log|debug)\(|\bprint\(' || true)"
if [ -n "$warn_hits" ]; then
  echo "⚠️  quality-gates.md <cleanup>: console.log/print added — confirm these are intentional logging, not leftover debug:"
  printf '%s\n' "$warn_hits" | sed 's/^/    /'
fi
exit 0

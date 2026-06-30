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

exit 0

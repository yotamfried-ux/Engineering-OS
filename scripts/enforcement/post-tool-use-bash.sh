#!/usr/bin/env bash
set -o pipefail
# post-tool-use-bash.sh — PostToolUse evidence recorder for Bash tool.
#
# Records evidence for gates that depend on successful Bash commands:
#   graphify_used  — graphify query/explain/path/update exited cleanly (G7)
#   tests_run      — a test command produced passing output (validation gate)
#
# Evidence is recorded ONLY when the command is a recognised subcommand AND
# the output is non-trivial (filters echo graphify, --help, failed runs).
#
# Wired from .claude/settings.json PostToolUse["Bash"].
# Governing policy: core/workflow.md (G7, validation step).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/evidence.sh
. "$SCRIPT_DIR/lib/evidence.sh" 2>/dev/null || true

INPUT="$(cat 2>/dev/null || true)"

# Parse tool_input.command and tool_response from the PostToolUse JSON payload.
_parse_field() {
  command -v python3 >/dev/null 2>&1 || return
  printf '%s' "$INPUT" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    field = '$1'
    if field == 'cmd':
        print(d.get('tool_input', d).get('command', '') or '')
    elif field == 'out':
        r = d.get('tool_response', '') or d.get('output', '') or ''
        print(str(r)[:2000] if r else '')
except Exception:
    print('')
" 2>/dev/null || printf ''
}

CMD="$(_parse_field cmd)"
OUT="$(_parse_field out)"

[ -z "$CMD" ] && exit 0

# ── graphify evidence (G7) ────────────────────────────────────────────────────
# Require a real subcommand (not just any string containing "graphify") AND
# non-trivial output (length > 30 chars and no leading error text).
case "$CMD" in
  *"graphify query "*|*"graphify explain "*|*"graphify path "*|*"graphify update "*|*"graphify update"*)
    OUT_LEN="${#OUT}"
    if [ "${OUT_LEN:-0}" -gt 30 ]; then
      FIRST_100="${OUT:0:100}"
      if ! printf '%s' "$FIRST_100" | grep -qiE 'error|not found|command not found|no such|usage:'; then
        evidence_record graphify_used
      fi
    fi
    ;;
esac

# ── tests_run evidence (validation gate) ─────────────────────────────────────
# Require test result markers in output (not just --help or a failed run).
case "$CMD" in
  *pytest*|*"npm test"*|*"npm run test"*|*"pnpm test"*|*"pnpm run test"*|\
  *"cargo test"*|*"go test "*|*" jest "*|*"jest --"*|*vitest*|*"yarn test"*)
    if printf '%s' "$OUT" | grep -qiE 'passed|\.\.ok|[0-9]+ tests? (ok|passed)|PASS |test result:'; then
      evidence_record tests_run
    fi
    ;;
esac

exit 0

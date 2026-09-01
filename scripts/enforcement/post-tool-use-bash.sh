#!/usr/bin/env bash
set -o pipefail
# post-tool-use-bash.sh — PostToolUse evidence recorder for Bash tool.
#
# Records evidence for gates that depend on successful Bash commands:
#   graphify_used  — graphify query/explain/path/update exited cleanly (G7)
#   tests_run      — a test command produced trustworthy passing evidence
#
# Evidence is recorded ONLY when the command is a recognised subcommand AND
# the result is strong enough to avoid fabricating evidence from mentions,
# help text, masked failures, malformed hook payloads, or fixture-only runners.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib/evidence.sh" 2>/dev/null || true
INPUT="$(cat 2>/dev/null || true)"

_parse_field() {
  command -v python3 >/dev/null 2>&1 || return
  printf '%s' "$INPUT" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    field = '$1'
    if field == 'cmd':
        print(d.get('tool_input', d).get('command', '') or '')
    else:
        r = d.get('tool_response', '') or d.get('output', '') or ''
        if field == 'graph_out':
            text = str(r) if r else ''
            sys.stdout.write(text[:2000])
        elif field == 'test_out':
            if isinstance(r, dict):
                stdout = r.get('stdout', '') or ''
                stderr = r.get('stderr', '') or ''
                text = '\n'.join(part for part in (str(stdout), str(stderr)) if part)
            else:
                text = str(r) if r else ''
            sys.stdout.write(text[-20000:])
except Exception:
    pass
" 2>/dev/null || printf ''
}

CMD="$(_parse_field cmd)"
GRAPH_OUT="$(_parse_field graph_out)"
TEST_OUT="$(_parse_field test_out)"
[ -z "$CMD" ] && exit 0

case "$CMD" in
  *"graphify query "*|*"graphify explain "*|*"graphify path "*|*"graphify update "*|*"graphify update"*)
    OUT_LEN="${#GRAPH_OUT}"
    if [ "${OUT_LEN:-0}" -gt 30 ]; then
      FIRST_100="${GRAPH_OUT:0:100}"
      if ! printf '%s' "$FIRST_100" | grep -qiE 'error|not found|command not found|no such|usage:'; then
        evidence_record graphify_used
      fi
    fi
    ;;
esac

_eos_test_mode() {
  command -v python3 >/dev/null 2>&1 || return
  python3 - "$1" <<'PY'
import re
import sys

cmd = sys.argv[1]
common_prefix = r"\s*(?:[A-Za-z_][A-Za-z0-9_]*=[^;&|\s]+\s+)*(?:bash|/bin/bash)\s+"

direct_suite = re.fullmatch(
    common_prefix
    + r"(?:\./)?scripts/enforcement/tests/test-[A-Za-z0-9._-]+\.sh"
    + r"(?:\s+[^;&|\n]*)?\s*",
    cmd,
    re.S,
)
if direct_suite:
    print("direct-suite")
    raise SystemExit(0)

canonical_runner = re.fullmatch(
    common_prefix
    + r"(?:\./)?scripts/enforcement/run-enforcement-tests\.sh"
    + r"(?:\s+[^;&|\n]*)?\s*",
    cmd,
    re.S,
)
if canonical_runner and not re.search(r"(?:^|\s)--fixture(?:\s|$)", cmd):
    print("canonical-runner")
PY
}

_test_output_has_failure() {
  printf '%s' "$TEST_OUT" | grep -qiE \
    '([1-9][0-9]*[[:space:]]+(tests?[[:space:]]+)?failed|[1-9][0-9]*[[:space:]]+failures?|one or more enforcement suites failed|test result:[[:space:]]*FAILED|(^|[[:space:]])FAIL([[:space:]:]|$))'
}

EOS_TEST_MODE="$(_eos_test_mode "$CMD")"
case "$EOS_TEST_MODE" in
  direct-suite)
    if [ -n "$TEST_OUT" ] && ! _test_output_has_failure; then
      evidence_record tests_run
    fi
    ;;
  canonical-runner)
    if printf '%s' "$TEST_OUT" | grep -qiE 'all [0-9]+ enforcement suites passed' \
       && ! _test_output_has_failure; then
      evidence_record tests_run
    fi
    ;;
esac

case "$CMD" in
  *pytest*|*"npm test"*|*"npm run test"*|*"pnpm test"*|*"pnpm run test"*|\
  *"cargo test"*|*"go test "*|*" jest "*|*"jest --"*|*vitest*|*"yarn test"*)
    if ! _test_output_has_failure \
       && printf '%s' "$TEST_OUT" | grep -qiE 'passed|\.\.ok|[0-9]+ tests? (ok|passed)|PASS |test result:|(^|[[:space:]])ok[[:space:]]'; then
      evidence_record tests_run
    fi
    ;;
esac

exit 0

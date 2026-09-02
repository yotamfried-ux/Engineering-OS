#!/usr/bin/env bash
set -o pipefail
# post-tool-use-bash.sh — PostToolUse evidence recorder for Bash tool.
#
# Records evidence for gates that depend on successful Bash commands:
#   graphify_used   — graphify query/explain/path/update exited cleanly (G7)
#   tests_run       — a test command produced trustworthy passing evidence
#   bash_suite_run  — a named corpus suite executed, and how it ended
#
# Evidence is recorded ONLY when the command actually executed something AND the
# result is strong enough to avoid fabricating evidence from mentions, help text,
# masked failures, malformed hook payloads, or fixture-only runners.
#
# Suite detection is delegated to lib/bash_test_invocation.py, which classifies each
# control-operator segment of the command rather than matching the whole command
# string. The previous whole-command `re.fullmatch` recognised only a bare invocation,
# so a `cd` prefix, an `&&` chain, a pipe or a redirect made a real suite run invisible
# — and since virtually every real invocation is wrapped, that was the common case.
#
# This recorder covers *direct* suite invocations. Runs that go through
# run-enforcement-tests.sh record themselves from inside the execution via
# lib/test-run-evidence.sh, where no command wrapper can affect the outcome.

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

_eos_test_invocations() {
  command -v python3 >/dev/null 2>&1 || return
  [ -f "$SCRIPT_DIR/lib/bash_test_invocation.py" ] || return
  python3 "$SCRIPT_DIR/lib/bash_test_invocation.py" "$1" 2>/dev/null || printf ''
}

_test_output_has_failure() {
  printf '%s' "$TEST_OUT" | grep -qiE \
    '([1-9][0-9]*[[:space:]]+(tests?[[:space:]]+)?failed|[1-9][0-9]*[[:space:]]+failures?|one or more enforcement suites failed|test result:[[:space:]]*FAILED|(^|[[:space:]])FAIL([[:space:]:]|$))'
}

# A positive success signal, required whenever the observed output passed through a
# downstream filter that could have dropped the failure lines. Absence of a failure
# marker is not enough there: `| head -1` removes evidence rather than adding it.
_test_output_has_success() {
  printf '%s' "$TEST_OUT" | grep -qiE \
    '(^|[[:space:]])(✅|PASS|passed|OK)([[:space:]:.,]|$)|all [0-9]+ [a-z ]*suites passed|[0-9]+ tests? (ok|passed)|test result:[[:space:]]*ok'
}

while IFS="$(printf '\t')" read -r EOS_TEST_KIND EOS_TEST_PATH EOS_TEST_TRUST; do
  [ -n "$EOS_TEST_KIND" ] || continue
  # A masked (`||`) or backgrounded (`&`) invocation is never evidence: its status is
  # discarded, which is precisely how a failing suite is made to look successful.
  [ "$EOS_TEST_TRUST" = "untrusted" ] && continue
  [ -n "$TEST_OUT" ] || continue
  case "$EOS_TEST_KIND" in
    direct-suite)
      if _test_output_has_failure; then
        # The suite genuinely ran and genuinely failed. Record that it ran — a failed
        # run is still runtime evidence — but never as a passing one.
        evidence_record bash_suite_run "${EOS_TEST_PATH}:fail"
        continue
      fi
      if [ "$EOS_TEST_TRUST" = "filtered" ] && ! _test_output_has_success; then
        continue
      fi
      evidence_record bash_suite_run "${EOS_TEST_PATH}:pass"
      evidence_record tests_run "$EOS_TEST_PATH"
      ;;
    canonical-runner)
      # The runner records each suite from inside its own execution. This branch only
      # adds the corpus-level summary, and only on the runner's own success line.
      if printf '%s' "$TEST_OUT" | grep -qiE 'all [0-9]+ enforcement suites passed' \
         && ! _test_output_has_failure; then
        evidence_record tests_run
      fi
      ;;
  esac
done <<EOF_TEST_INVOCATIONS
$(_eos_test_invocations "$CMD")
EOF_TEST_INVOCATIONS

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

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
# help text, masked failures, or malformed hook payloads.
#
# Wired from .claude/settings.json PostToolUse["Bash"].
# Governing policy: core/workflow.md (G7, validation step).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/evidence.sh
. "$SCRIPT_DIR/lib/evidence.sh" 2>/dev/null || true

INPUT="$(cat 2>/dev/null || true)"

# Parse tool_input.command and tool_response from the PostToolUse JSON payload.
# Graphify keeps the historical leading-output behavior. Test evidence uses the
# structured Bash stdout/stderr shape when available and keeps the *tail* of long
# responses, because test summaries conventionally appear at the end.
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

# ── graphify evidence (G7) ────────────────────────────────────────────────────
# Require a real subcommand (not just any string containing "graphify") AND
# non-trivial output (length > 30 chars and no leading error text).
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

# Classify only invocation shapes whose test exit status is known to propagate to
# the Bash tool result. PostToolUse fires only after the Bash tool succeeds, but a
# shell wrapper can still hide an inner test failure (for example `test.sh || true`).
# Direct EOS suites therefore must be the whole simple command. The all-suite loop
# is accepted only when it either runs under `set -e` outside an `if`, or explicitly
# aggregates failures and exits non-zero when any suite fails.
_eos_test_mode() {
  command -v python3 >/dev/null 2>&1 || return
  python3 - "$1" <<'PY'
import re
import sys

cmd = sys.argv[1]
direct = re.fullmatch(
    r"\s*(?:[A-Za-z_][A-Za-z0-9_]*=[^;&|\s]+\s+)*(?:bash|/bin/bash)\s+"
    r"(?:\./)?scripts/enforcement/tests/test-[A-Za-z0-9._-]+\.sh"
    r"(?:\s+[^;&|\n]*)?\s*",
    cmd,
    re.S,
)
if direct:
    print("direct")
    raise SystemExit(0)

loop = re.search(
    r"\bfor\s+([A-Za-z_][A-Za-z0-9_]*)\s+in\s+"
    r"(?:\./)?scripts/enforcement/tests/test-\*\.sh\s*;\s*do\b",
    cmd,
    re.S,
)
if not loop:
    raise SystemExit(0)
var = re.escape(loop.group(1))
bash_var = rf"\bbash\s+[\"']?\$\{{?{var}\}}?[\"']?"
if not re.search(bash_var, cmd):
    raise SystemExit(0)

prefix = cmd[: loop.start()]
set_e = bool(re.search(r"(?:^|[;\n])\s*set\s+-[A-Za-z]*e[A-Za-z]*(?:\s|;|$)", prefix))
conditional_test = bool(re.search(rf"\bif\s+{bash_var}", cmd))
masked_test = bool(re.search(rf"{bash_var}\s*(?:\|\||\|(?!\|))", cmd))
set_e_safe = set_e and not conditional_test and not masked_test

aggregates = all(
    (
        re.search(r"\bfail\s*=\s*0\b", cmd),
        re.search(r"\belse\s+fail\s*=\s*1\s*;\s*fi\b", cmd, re.S),
        re.search(r"\[\s*[\"']?\$fail[\"']?\s+-ne\s+0\s*\]", cmd),
        re.search(r"\bexit\s+1\b", cmd),
    )
)
if set_e_safe or aggregates:
    print("full-suite")
PY
}

# Obvious failure summaries must never be converted into positive evidence even
# when an outer shell command returned zero. Keep this deliberately conservative:
# a false negative merely asks for another verification; a false positive weakens G11.
_test_output_has_failure() {
  printf '%s' "$TEST_OUT" | grep -qiE \
    '([1-9][0-9]*[[:space:]]+(tests?[[:space:]]+)?failed|[1-9][0-9]*[[:space:]]+failures?|one or more enforcement suites failed|test result:[[:space:]]*FAILED|(^|[[:space:]])FAIL([[:space:]:]|$))'
}

# ── tests_run evidence (validation gate) ─────────────────────────────────────
EOS_TEST_MODE="$(_eos_test_mode "$CMD")"
case "$EOS_TEST_MODE" in
  direct)
    # The command itself is the test process. Since this is PostToolUse, its exit
    # status was successful; reject only contradictory/masked failure output.
    if [ -n "$TEST_OUT" ] && ! _test_output_has_failure; then
      evidence_record tests_run
    fi
    ;;
  full-suite)
    # A multi-suite loop needs an aggregate success marker as an additional guard
    # that the loop reached its success boundary after checking every test result.
    if printf '%s' "$TEST_OUT" | grep -qiE 'all enforcement suites passed' \
       && ! _test_output_has_failure; then
      evidence_record tests_run
    fi
    ;;
esac

# Existing ecosystem runners remain supported. Use the test-output tail instead of
# the old first-2,000-character stringification so long runs keep their summaries.
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

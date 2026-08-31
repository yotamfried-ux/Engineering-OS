#!/usr/bin/env bash
# Regression coverage for Bash PostToolUse evidence recording and its consumers.
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
RECORDER="$ROOT/scripts/enforcement/post-tool-use-bash.sh"
STOP="$ROOT/scripts/enforcement/post-stop-hook.sh"
PRECOMMIT="$ROOT/scripts/hooks/pre-commit.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

PASS=0
FAIL=0
ok() { PASS=$((PASS + 1)); printf '  ✅ %s\n' "$1"; }
bad() { FAIL=$((FAIL + 1)); printf '  ❌ %s\n' "$1"; }

case_dir() { printf '%s/%s' "$WORK" "$1"; }
ledger() { printf '%s/evidence/ledger' "$(case_dir "$1")"; }

run_payload() {
  local name="$1" payload="$2" dir
  dir="$(case_dir "$name")"
  rm -rf "$dir"
  mkdir -p "$dir"
  printf '%s' "$payload" | (
    cd "$dir" || exit 1
    EOS_EVIDENCE_DIR="$dir/evidence" bash "$RECORDER"
  ) >"$dir/out" 2>"$dir/err"
}

run_generated_payload() {
  local name="$1" generator="$2" dir
  dir="$(case_dir "$name")"
  rm -rf "$dir"
  mkdir -p "$dir"
  eval "$generator" | (
    cd "$dir" || exit 1
    EOS_EVIDENCE_DIR="$dir/evidence" bash "$RECORDER"
  ) >"$dir/out" 2>"$dir/err"
}

assert_has_tests() {
  local name="$1" label="$2"
  if [ -s "$(ledger "$name")" ] && grep -q $'\ttests_run\t' "$(ledger "$name")"; then
    ok "$label"
  else
    bad "$label (ledger=$(cat "$(ledger "$name")" 2>/dev/null || printf '<empty>'))"
  fi
}

assert_no_tests() {
  local name="$1" label="$2"
  if [ ! -s "$(ledger "$name")" ] || ! grep -q $'\ttests_run\t' "$(ledger "$name")"; then
    ok "$label"
  else
    bad "$label (unexpected ledger=$(cat "$(ledger "$name")"))"
  fi
}

echo "── Engineering OS direct-suite evidence ──"
run_payload direct_success '{"tool_name":"Bash","tool_input":{"command":"bash scripts/enforcement/tests/test-hook-classification.sh"},"tool_response":{"stdout":"hook classification: 8 passed, 0 failed\n","stderr":"","interrupted":false}}'
assert_has_tests direct_success "successful direct enforcement suite records tests_run"

run_payload direct_no_summary '{"tool_name":"Bash","tool_input":{"command":"bash scripts/enforcement/tests/test-workflow-evidence.sh"},"tool_response":{"stdout":"workflow evidence checks passed\n","stderr":"","interrupted":false}}'
assert_has_tests direct_no_summary "successful direct suite does not depend on one summary format"

run_payload path_mention '{"tool_name":"Bash","tool_input":{"command":"echo bash scripts/enforcement/tests/test-hook-classification.sh"},"tool_response":{"stdout":"bash scripts/enforcement/tests/test-hook-classification.sh\n","stderr":"","interrupted":false}}'
assert_no_tests path_mention "mentioning a test path does not fabricate tests_run"

run_payload masked_direct '{"tool_name":"Bash","tool_input":{"command":"bash scripts/enforcement/tests/test-hook-classification.sh || true"},"tool_response":{"stdout":"hook classification: 7 passed, 1 failed\n","stderr":"","interrupted":false}}'
assert_no_tests masked_direct "masked direct failure does not record tests_run"

echo "── canonical all-suite loop evidence ──"
FULL_LOOP='set -u
fail=0
for t in scripts/enforcement/tests/test-*.sh; do
  if bash "$t"; then :; else fail=1; fi
done
if [ "$fail" -ne 0 ]; then
  echo "one or more enforcement suites failed"
  exit 1
fi
echo "✅ all enforcement suites passed"'
run_generated_payload full_loop_success "python3 -c 'import json; print(json.dumps({\"tool_name\":\"Bash\",\"tool_input\":{\"command\":'''$FULL_LOOP'''},\"tool_response\":{\"stdout\":\"suite output\\n✅ all enforcement suites passed\\n\",\"stderr\":\"\",\"interrupted\":False}}))'"
assert_has_tests full_loop_success "failure-aggregating full-suite loop records tests_run"

UNSAFE_LOOP='for t in scripts/enforcement/tests/test-*.sh; do bash "$t" || true; done; echo "✅ all enforcement suites passed"'
run_generated_payload unsafe_loop "python3 -c 'import json; print(json.dumps({\"tool_name\":\"Bash\",\"tool_input\":{\"command\":'''$UNSAFE_LOOP'''},\"tool_response\":{\"stdout\":\"7 passed, 1 failed\\n✅ all enforcement suites passed\\n\",\"stderr\":\"\",\"interrupted\":False}}))'"
assert_no_tests unsafe_loop "failure-masking full-suite loop is rejected"

echo "── existing ecosystem runners + long output ──"
run_generated_payload pytest_long "python3 -c 'import json; print(json.dumps({\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"pytest -q\"},\"tool_response\":{\"stdout\":\"x\"*5000+\"\\n12 passed in 0.42s\\n\",\"stderr\":\"\",\"interrupted\":False}}))'"
assert_has_tests pytest_long "pytest summary beyond the old 2,000-character cutoff records tests_run"

run_payload pytest_masked_failure '{"tool_name":"Bash","tool_input":{"command":"pytest -q || true"},"tool_response":{"stdout":"1 failed, 4 passed in 0.50s\n","stderr":"","interrupted":false}}'
assert_no_tests pytest_masked_failure "generic runner failure summary is not converted to tests_run"

run_payload npm_success '{"tool_name":"Bash","tool_input":{"command":"npm test"},"tool_response":{"stdout":"PASS src/example.test.js\nTests: 3 passed, 3 total\n","stderr":"","interrupted":false}}'
assert_has_tests npm_success "existing npm test evidence remains supported"

run_payload malformed '{bad-json'
assert_no_tests malformed "malformed PostToolUse input does not fabricate evidence"

echo "── Stop consumer ──"
STOP_DIR="$(case_dir direct_success)"
STOP_OUT="$(cd "$STOP_DIR" && EOS_EVIDENCE_DIR="$STOP_DIR/evidence" bash "$STOP" <<<'{}' 2>&1)"
if printf '%s' "$STOP_OUT" | grep -q 'tests passed'; then
  ok "Stop reports tests passed after recorder evidence"
else
  bad "Stop did not consume tests_run evidence: $STOP_OUT"
fi

echo "── G11 pre-commit consumer ──"
G11="$WORK/g11"
STUB_EOS="$WORK/stub-eos"
mkdir -p "$G11" "$STUB_EOS/scripts/enforcement/lib" "$STUB_EOS/scripts/enforcement"
cp "$ROOT/scripts/enforcement/lib/evidence.sh" "$STUB_EOS/scripts/enforcement/lib/evidence.sh"
for name in enforce-quality.sh enforce-resource.sh enforce-connector.sh enforce-learning.sh enforce-learning-capture.sh enforce-run-trace.sh enforce-tests.sh; do
  printf '#!/usr/bin/env bash\nexit 0\n' > "$STUB_EOS/scripts/enforcement/$name"
  chmod +x "$STUB_EOS/scripts/enforcement/$name"
done
(
  cd "$G11" || exit 1
  git init -q
  git config user.email test@example.com
  git config user.name test
  echo base > README.md
  git add README.md
  git commit -qm init
  mkdir -p src
  echo 'print(1)' > src/a.py
  echo 'print(2)' > src/b.py
  echo 'print(3)' > src/c.py
  git add src/a.py src/b.py src/c.py
)

G11_EVIDENCE="$WORK/g11-evidence"
mkdir -p "$G11_EVIDENCE"
: > "$G11_EVIDENCE/ledger"
set +e
(
  cd "$G11" || exit 1
  ENGINEERING_OS_HOME="$STUB_EOS" EOS_EVIDENCE_DIR="$G11_EVIDENCE" bash "$PRECOMMIT"
) >"$WORK/g11-without.out" 2>&1
G11_WITHOUT=$?
set -e
if [ "$G11_WITHOUT" -ne 0 ] && grep -q 'G11 (Verification gate)' "$WORK/g11-without.out"; then
  ok "G11 blocks the same >2-code-file diff without verification evidence"
else
  bad "G11 negative fixture did not block as expected (code=$G11_WITHOUT output=$(cat "$WORK/g11-without.out"))"
fi

printf '%s\ttests_run\t\n' "$(date +%s)" > "$G11_EVIDENCE/ledger"
set +e
(
  cd "$G11" || exit 1
  ENGINEERING_OS_HOME="$STUB_EOS" EOS_EVIDENCE_DIR="$G11_EVIDENCE" bash "$PRECOMMIT"
) >"$WORK/g11-with.out" 2>&1
G11_WITH=$?
set -e
if [ "$G11_WITH" -eq 0 ]; then
  ok "G11 accepts the same >2-code-file diff when tests_run exists"
else
  bad "G11 did not consume tests_run evidence (code=$G11_WITH output=$(cat "$WORK/g11-with.out"))"
fi

printf '\npost-tool-use Bash evidence: %d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]

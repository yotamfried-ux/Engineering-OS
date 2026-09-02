#!/usr/bin/env bash
# test-bash-runtime-evidence.sh — every executed Bash suite must be represented in
# operational runtime evidence, no matter how the command was wrapped, and a missing
# record must be DETECTED rather than silently tolerated.
#
# Three surfaces are covered:
#   1. lib/bash_test_invocation.py — segment classification of a wrapped command.
#   2. run-enforcement-tests.sh + lib/test-run-evidence.sh — the executing runner as
#      the evidence producer, exercised through a disposable corpus.
#   3. test_evidence.py runtime-reconcile + check-bash-runtime-evidence.sh — the
#      detector, including the negative fixture where a suite runs with recording
#      suppressed and reconciliation must fail.
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SCANNER="$ROOT/scripts/enforcement/lib/bash_test_invocation.py"
RECORDER="$ROOT/scripts/enforcement/post-tool-use-bash.sh"
SKILL_RECORDER="$ROOT/scripts/enforcement/post-tool-use-skill-evidence.sh"
READ_RECORDER="$ROOT/scripts/enforcement/post-tool-use-read-evidence.sh"
EVIDENCE_PY="$ROOT/scripts/enforcement/test_evidence.py"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

PASS=0
FAIL=0
ok() { PASS=$((PASS + 1)); printf '  ✅ %s\n' "$1"; }
bad() { FAIL=$((FAIL + 1)); printf '  ❌ %s\n' "$1"; }

SUITE="scripts/enforcement/tests/test-known-gaps.sh"

# ── 1. command classification ───────────────────────────────────────────────────

scan() { python3 "$SCANNER" "$1" 2>/dev/null; }

assert_trust() {
  local label="$1" command="$2" expected="$3" got
  got="$(scan "$command" | awk -F'\t' 'NR==1 {print $3}')"
  [ -z "$got" ] && got="(none)"
  if [ "$got" = "$expected" ]; then ok "$label"; else bad "$label (expected $expected, got $got)"; fi
}

echo "── wrapped invocations are recognised ──"
assert_trust "bare invocation is direct"              "bash $SUITE" direct
assert_trust "cd prefix with && is direct"            "cd $ROOT && bash $SUITE" direct
assert_trust "cd prefix on its own line is direct"    "cd $ROOT
bash $SUITE" direct
assert_trust "2>&1 is a redirect, not backgrounding"  "bash $SUITE 2>&1" direct
assert_trust "file redirect is direct"                "bash $SUITE > out.log 2>&1" direct
assert_trust "&>file redirect is direct"              "bash $SUITE &> out.log" direct
assert_trust "env assignment prefix is direct"        "EOS_X=1 bash $SUITE" direct
assert_trust "leading ./ path is direct"              "./$SUITE" direct
assert_trust "bare path with no interpreter is direct" "$SUITE" direct
assert_trust "trailing && chain is direct"            "bash $SUITE && echo done" direct

echo "── untrustworthy shapes stay untrustworthy ──"
assert_trust "|| masking is untrusted"                "bash $SUITE || true" untrusted
assert_trust "backgrounding is untrusted"             "bash $SUITE &" untrusted
assert_trust "pipe is filtered, not trusted"          "bash $SUITE | tail -5" filtered
assert_trust "echo of a path is not an execution"     "echo bash $SUITE" "(none)"
assert_trust "grep over a path is not an execution"   "grep -n foo $SUITE" "(none)"
assert_trust "quoted path is not an execution"        "echo 'bash $SUITE'" "(none)"
assert_trust "command substitution is not observable" "OUT=\$(bash $SUITE)" "(none)"
assert_trust "fixture runner is not corpus evidence"  "bash scripts/enforcement/run-enforcement-tests.sh --fixture /tmp/a.sh" "(none)"

MULTI="$(scan "bash scripts/enforcement/tests/test-a.sh && bash scripts/enforcement/tests/test-b.sh" | wc -l | tr -d ' ')"
if [ "$MULTI" = "2" ]; then ok "each suite in a chain is classified separately"; else bad "chain produced $MULTI records, expected 2"; fi

# ── 2. the recorder consumes the classification ─────────────────────────────────

record_payload() {
  local name="$1" command="$2" stdout="$3" dir
  dir="$WORK/rec-$name"
  rm -rf "$dir"; mkdir -p "$dir"
  CMD_VALUE="$command" STDOUT_VALUE="$stdout" python3 - <<'PY' | (
import json, os
print(json.dumps({"tool_name": "Bash",
                  "tool_input": {"command": os.environ["CMD_VALUE"]},
                  "tool_response": {"stdout": os.environ["STDOUT_VALUE"], "stderr": "", "interrupted": False}}))
PY
    cd "$dir" || exit 1
    EOS_EVIDENCE_DIR="$dir/evidence" bash "$RECORDER"
  ) >"$dir/out" 2>"$dir/err"
  printf '%s/evidence/ledger' "$dir"
}

assert_ledger() {
  local label="$1" ledger="$2" pattern="$3" want="$4"
  if grep -q "$pattern" "$ledger" 2>/dev/null; then
    if [ "$want" = "yes" ]; then ok "$label"; else bad "$label (unexpected match: $(cat "$ledger" 2>/dev/null))"; fi
  else
    if [ "$want" = "no" ]; then ok "$label"; else bad "$label (ledger=$(cat "$ledger" 2>/dev/null || printf '<empty>'))"; fi
  fi
}

echo "── recorder writes suite-named runtime evidence ──"
L="$(record_payload wrapped "cd $ROOT && bash $SUITE 2>&1" $'known gaps checks passed (50 gaps)\n')"
assert_ledger "wrapped run records tests_run" "$L" $'\ttests_run\t' yes
assert_ledger "wrapped run names the suite" "$L" "bash_suite_run	${SUITE}:pass" yes

L="$(record_payload failing "bash $SUITE" $'known gaps: 3 failed\n')"
assert_ledger "failing run records the run" "$L" "bash_suite_run	${SUITE}:fail" yes
assert_ledger "failing run records no tests_run" "$L" $'\ttests_run\t' no

L="$(record_payload masked "bash $SUITE || true" $'checks passed\n')"
assert_ledger "masked run records nothing" "$L" 'bash_suite_run' no

L="$(record_payload filtered_nosignal "bash $SUITE | tail -1" $'...\n')"
assert_ledger "filtered output without a success signal records nothing" "$L" 'bash_suite_run' no

L="$(record_payload filtered_signal "bash $SUITE | tail -1" $'known gaps checks passed\n')"
assert_ledger "filtered output with a success signal records" "$L" "bash_suite_run	${SUITE}:pass" yes

L="$(record_payload mention "echo bash $SUITE" "bash $SUITE"$'\n')"
assert_ledger "a mention records nothing" "$L" 'bash_suite_run' no

L="$(record_payload empty_out "bash $SUITE" "")"
assert_ledger "empty tool output records nothing" "$L" 'bash_suite_run' no

# ── 3. the executing runner is the producer ─────────────────────────────────────

# A disposable corpus: the runner and the evidence module are copied so the fixture
# exercises the real code, while discovery sees only the two synthetic suites.
FAKE="$WORK/fake-root"
mkdir -p "$FAKE/scripts/enforcement/tests"
cp "$ROOT/scripts/enforcement/run-enforcement-tests.sh" "$FAKE/scripts/enforcement/"
cp "$EVIDENCE_PY" "$FAKE/scripts/enforcement/"
cp -r "$ROOT/scripts/enforcement/lib" "$FAKE/scripts/enforcement/lib"
printf '#!/usr/bin/env bash\necho alpha passed\nexit 0\n' > "$FAKE/scripts/enforcement/tests/test-alpha.sh"
printf '#!/usr/bin/env bash\necho beta passed\nexit 0\n' > "$FAKE/scripts/enforcement/tests/test-beta.sh"
chmod +x "$FAKE/scripts/enforcement/tests/"*.sh
git -C "$FAKE" init -q 2>/dev/null || true

# The disposable corpus is its own root with its own ledger, so it is not a nested run
# of the outer corpus. EOS_SUITE_RUN_ACTIVE is cleared explicitly: when this suite runs
# under the real runner it inherits that marker, and leaving it set would make the
# fixture assert against the nesting guard rather than against the recording path.
run_fake_corpus() {
  local evidence_dir="$1"; shift
  (
    cd "$FAKE" || exit 1
    EOS_EVIDENCE_DIR="$evidence_dir" EOS_TEST_HEAD_SHA=fakehead EOS_SUITE_RUN_ACTIVE=0 "$@" \
      bash scripts/enforcement/run-enforcement-tests.sh
  ) >"$WORK/fake-run.out" 2>&1
}

reconcile() {
  local ledger="$1"; shift
  python3 "$EVIDENCE_PY" runtime-reconcile --root "$FAKE" --ledger "$ledger" "$@" \
    >"$WORK/reconcile.out" 2>"$WORK/reconcile.err"
}

echo "── the executing runner records what it ran ──"
E1="$WORK/ev-plain"
run_fake_corpus "$E1" env
RC=$?
if [ "$RC" -eq 0 ]; then ok "disposable corpus runs green"; else bad "disposable corpus failed: $(cat "$WORK/fake-run.out")"; fi
assert_ledger "runner records the first suite" "$E1/ledger" 'bash_suite_run	scripts/enforcement/tests/test-alpha.sh:pass' yes
assert_ledger "runner records the second suite" "$E1/ledger" 'bash_suite_run	scripts/enforcement/tests/test-beta.sh:pass' yes

# The point of the fix: the wrapper is not part of the decision, so a cd prefix, a
# redirect and a pipe all produce the same records as a bare invocation.
E2="$WORK/ev-wrapped"
mkdir -p "$E2"
( cd "$FAKE" && EOS_EVIDENCE_DIR="$E2" EOS_TEST_HEAD_SHA=fakehead EOS_SUITE_RUN_ACTIVE=0 \
    bash scripts/enforcement/run-enforcement-tests.sh 2>&1 | tail -3 ) >/dev/null 2>&1
assert_ledger "a piped runner invocation still records suites" "$E2/ledger" 'bash_suite_run	scripts/enforcement/tests/test-alpha.sh:pass' yes

E3="$WORK/ev-redirected"
mkdir -p "$E3"
( cd "$FAKE" && EOS_EVIDENCE_DIR="$E3" EOS_TEST_HEAD_SHA=fakehead EOS_SUITE_RUN_ACTIVE=0 \
    bash scripts/enforcement/run-enforcement-tests.sh > "$WORK/redir.log" 2>&1 ) || true
assert_ledger "a redirected runner invocation still records suites" "$E3/ledger" 'bash_suite_run	scripts/enforcement/tests/test-beta.sh:pass' yes

echo "── reconciliation against the discovered corpus ──"
if reconcile "$E1/ledger" --require-complete; then
  ok "a complete run reconciles against the discovered corpus"
else
  bad "complete run failed reconciliation: $(cat "$WORK/reconcile.err")"
fi
if grep -q '2/2 Bash suites represented' "$WORK/reconcile.out"; then
  ok "reconciliation reports represented-vs-discovered counts"
else
  bad "reconciliation summary missing counts: $(cat "$WORK/reconcile.out")"
fi

# NEGATIVE FIXTURE — the requirement that makes this gap closable. A suite that
# genuinely executes while its runtime record is suppressed must FAIL reconciliation.
# Without this, "no record" and "suite never ran" are indistinguishable, which is the
# exact blindness being removed.
echo "── a suppressed record is detected, not tolerated ──"
E4="$WORK/ev-suppressed"
mkdir -p "$E4"
run_fake_corpus "$E4" env EOS_SUITE_EVIDENCE_DISABLED=1
if [ -s "$WORK/fake-run.out" ] && grep -q 'enforcement suites passed' "$WORK/fake-run.out"; then
  ok "the suites still executed and passed with recording suppressed"
else
  bad "suppressed run did not execute the suites: $(cat "$WORK/fake-run.out")"
fi
if reconcile "$E4/ledger" --require-complete; then
  bad "reconciliation PASSED with no runtime evidence — a missing record is being tolerated"
else
  ok "reconciliation fails when executed suites left no runtime evidence"
fi
if grep -q 'no runtime' "$WORK/reconcile.err"; then
  ok "the failure names the missing-evidence cause"
else
  bad "failure message did not name the cause: $(cat "$WORK/reconcile.err")"
fi

# Partial coverage must fail too: one recorded suite is not a green light for the other.
E5="$WORK/ev-partial"
mkdir -p "$E5"
printf '1\tbash_suite_run\tscripts/enforcement/tests/test-alpha.sh:pass\n' > "$E5/ledger"
if reconcile "$E5/ledger" --require-complete; then
  bad "partial coverage passed reconciliation"
else
  ok "partial coverage fails reconciliation"
fi

# A recorded failure is evidence that something is wrong, not evidence of success.
E6="$WORK/ev-failed"
mkdir -p "$E6"
printf '1\tbash_suite_run\tscripts/enforcement/tests/test-alpha.sh:pass\n2\tbash_suite_run\tscripts/enforcement/tests/test-beta.sh:fail\n' > "$E6/ledger"
if reconcile "$E6/ledger"; then
  bad "a suite recorded as failing passed reconciliation"
else
  ok "a suite recorded as failing fails reconciliation even without --require-complete"
fi

# A record naming a suite outside the corpus means ledger and corpus disagree.
E7="$WORK/ev-unknown"
mkdir -p "$E7"
printf '1\tbash_suite_run\tscripts/enforcement/tests/test-alpha.sh:pass\n2\tbash_suite_run\tscripts/enforcement/tests/test-beta.sh:pass\n3\tbash_suite_run\tscripts/enforcement/tests/test-ghost.sh:pass\n' > "$E7/ledger"
if reconcile "$E7/ledger" --require-complete; then
  bad "a record naming a non-corpus suite passed reconciliation"
else
  ok "a record naming a non-corpus suite fails reconciliation"
fi

# The ledger accumulates across runs in one session, so a suite's result is its LATEST
# record. A suite that failed, was fixed and then passed is passing; a suite whose most
# recent run failed is still failing. Anything else reports the wrong state.
E6b="$WORK/ev-fixed"
mkdir -p "$E6b"
printf '1\tbash_suite_run\tscripts/enforcement/tests/test-alpha.sh:fail\n2\tbash_suite_run\tscripts/enforcement/tests/test-alpha.sh:pass\n3\tbash_suite_run\tscripts/enforcement/tests/test-beta.sh:pass\n' > "$E6b/ledger"
if reconcile "$E6b/ledger" --require-complete; then
  ok "a suite that failed and was then fixed reconciles as passing"
else
  bad "a fixed suite still reported as failing: $(cat "$WORK/reconcile.err")"
fi

E6c="$WORK/ev-regressed"
mkdir -p "$E6c"
printf '1\tbash_suite_run\tscripts/enforcement/tests/test-alpha.sh:pass\n2\tbash_suite_run\tscripts/enforcement/tests/test-alpha.sh:fail\n3\tbash_suite_run\tscripts/enforcement/tests/test-beta.sh:pass\n' > "$E6c/ledger"
if reconcile "$E6c/ledger" --require-complete; then
  bad "a suite that regressed to failing passed reconciliation"
else
  ok "a suite whose latest run failed still fails reconciliation"
fi

# A malformed ledger line must never be read as a suite record.
E8="$WORK/ev-malformed"
mkdir -p "$E8"
printf 'garbage\n1\tbash_suite_run\tno-result-suffix\n2\tbash_suite_run\tscripts/enforcement/tests/test-alpha.sh:maybe\n' > "$E8/ledger"
if reconcile "$E8/ledger" --require-complete; then
  bad "a malformed ledger satisfied reconciliation"
else
  ok "malformed ledger lines are not read as suite records"
fi

# A corpus suite that invokes the runner itself must not write corpus evidence on the
# outer session's behalf. This is the guard that makes the suite above safe to run
# under the real runner, so it is pinned rather than left implicit.
echo "── a nested runner does not record for the outer session ──"
E10="$WORK/ev-nested"
mkdir -p "$E10"
( cd "$FAKE" && EOS_EVIDENCE_DIR="$E10" EOS_TEST_HEAD_SHA=fakehead EOS_SUITE_RUN_ACTIVE=1 \
    bash scripts/enforcement/run-enforcement-tests.sh ) >"$WORK/nested.out" 2>&1
if grep -q 'enforcement suites passed' "$WORK/nested.out"; then
  ok "a nested runner still executes its suites"
else
  bad "nested runner did not execute: $(cat "$WORK/nested.out")"
fi
if [ ! -s "$E10/ledger" ]; then
  ok "a nested runner records no corpus evidence"
else
  bad "nested runner wrote corpus evidence: $(cat "$E10/ledger")"
fi

echo "── the fixture runner never writes corpus evidence ──"
E9="$WORK/ev-fixture"
mkdir -p "$E9"
printf '#!/usr/bin/env bash\necho fixture ok\nexit 0\n' > "$WORK/fixture.sh"
( cd "$FAKE" && EOS_EVIDENCE_DIR="$E9" EOS_SUITE_RUN_ACTIVE=0 \
    bash scripts/enforcement/run-enforcement-tests.sh --fixture "$WORK/fixture.sh" ) >/dev/null 2>&1
if [ ! -s "$E9/ledger" ]; then
  ok "a fixture run records no corpus evidence"
else
  bad "fixture run wrote corpus evidence: $(cat "$E9/ledger")"
fi

echo "── suite id normalisation refuses non-corpus paths ──"
# shellcheck source=../lib/test-run-evidence.sh
. "$ROOT/scripts/enforcement/lib/test-run-evidence.sh"
check_id() {
  local label="$1" path="$2" want="$3" got
  got="$(eos_suite_id "$path" "$ROOT" 2>/dev/null || printf '(rejected)')"
  if [ "$got" = "$want" ]; then ok "$label"; else bad "$label (expected '$want', got '$got')"; fi
}
check_id "absolute corpus path normalises"    "$ROOT/$SUITE" "$SUITE"
check_id "relative corpus path normalises"    "./$SUITE" "$SUITE"
check_id "a temp-dir script is rejected"      "/tmp/test-fake.sh" "(rejected)"
check_id "a traversal path is rejected"       "scripts/enforcement/tests/../../../test-x.sh" "(rejected)"
check_id "a non-test script is rejected"      "scripts/enforcement/check-known-gaps.sh" "(rejected)"

if eos_record_suite_run "$SUITE" "maybe" "$ROOT" 2>/dev/null; then
  bad "an unknown result was recorded"
else
  ok "an unknown result is refused rather than recorded"
fi

# ── 4. verification evidence keys on the work ───────────────────────────────────

skill_payload() {
  local name="$1" json="$2" dir
  dir="$WORK/skill-$name"
  rm -rf "$dir"; mkdir -p "$dir"
  printf '%s' "$json" | ( cd "$dir" || exit 1; EOS_EVIDENCE_DIR="$dir/evidence" bash "$SKILL_RECORDER" ) >/dev/null 2>&1
  printf '%s/evidence/ledger' "$dir"
}

echo "── the verification gate records on the work ──"
L="$(skill_payload verify '{"tool_name":"Skill","tool_input":{"skill":"superpowers-verify"},"tool_response":{"content":"ok"}}')"
assert_ledger "invoking the verification skill records superpowers_verify_run" "$L" $'\tsuperpowers_verify_run\t' yes
assert_ledger "invoking the verification skill records skill_used" "$L" 'skill_used	superpowers-verify' yes

L="$(skill_payload plugin '{"tool_name":"Skill","tool_input":{"skill":"superpowers:superpowers-verify"},"tool_response":{"content":"ok"}}')"
assert_ledger "a plugin-qualified skill name is canonicalised" "$L" $'\tsuperpowers_verify_run\t' yes

L="$(skill_payload other '{"tool_name":"Skill","tool_input":{"skill":"engineering-route"},"tool_response":{"content":"ok"}}')"
assert_ledger "another skill records its own evidence" "$L" 'skill_used	engineering-route' yes
assert_ledger "another skill does not record verification evidence" "$L" 'superpowers_verify_run' no

L="$(skill_payload errored '{"tool_name":"Skill","tool_input":{"skill":"superpowers-verify"},"tool_response":{"is_error":true,"content":"boom"}}')"
assert_ledger "a failed skill invocation records nothing" "$L" 'skill_used' no

L="$(skill_payload malformed 'not json at all')"
assert_ledger "malformed skill payload records nothing" "$L" 'skill_used' no

L="$(skill_payload wrongtool '{"tool_name":"Bash","tool_input":{"skill":"superpowers-verify"}}')"
assert_ledger "a non-Skill payload records nothing" "$L" 'skill_used' no

read_payload() {
  local name="$1" path="$2" dir
  dir="$WORK/read-$name"
  rm -rf "$dir"; mkdir -p "$dir"
  printf '{"tool_name":"Read","tool_input":{"file_path":"%s"}}' "$path" \
    | ( cd "$dir" || exit 1; EOS_EVIDENCE_DIR="$dir/evidence" bash "$READ_RECORDER" ) >/dev/null 2>&1
  printf '%s/evidence/ledger' "$dir"
}

L="$(read_payload command .claude/commands/superpowers-verify.md)"
assert_ledger "reading the command file still records verification" "$L" $'\tsuperpowers_verify_run\t' yes

L="$(read_payload skillfile .claude/skills/superpowers-verify/SKILL.md)"
assert_ledger "reading the skill definition records verification" "$L" $'\tsuperpowers_verify_run\t' yes

L="$(read_payload unrelated core/git-policy.md)"
assert_ledger "an unrelated read records no verification" "$L" 'superpowers_verify_run' no

# ── 5. the checker wrapper ──────────────────────────────────────────────────────

echo "── check-bash-runtime-evidence.sh ──"
CHECKER="$ROOT/scripts/enforcement/check-bash-runtime-evidence.sh"
if bash "$CHECKER" --ledger "$WORK/does-not-exist" >"$WORK/checker.out" 2>&1; then
  ok "the checker reports coverage without --require-complete"
else
  bad "the checker failed on a coverage-only run: $(cat "$WORK/checker.out")"
fi
if bash "$CHECKER" --ledger "$WORK/does-not-exist" --require-complete >"$WORK/checker2.out" 2>&1; then
  bad "the checker passed --require-complete against an empty ledger"
else
  ok "the checker fails --require-complete against an empty ledger"
fi
if bash "$CHECKER" --bogus-flag >"$WORK/checker3.out" 2>&1; then
  bad "the checker accepted an unknown flag"
else
  ok "the checker rejects an unknown flag"
fi

echo
echo "bash runtime evidence: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]

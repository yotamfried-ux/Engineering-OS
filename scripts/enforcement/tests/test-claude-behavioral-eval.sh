#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
EVAL="$ROOT/experiments/claude-behavioral-eval/evaluate.py"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/oracle.tsv" <<'TSV'
# task_id	check	artifact	value	description
t1	required	route-plan.md	alpha	must include alpha
t1	required_any	route-plan.md	beta||gamma	must include one option
TSV

mkdir -p "$TMP/pass/t1"
cat > "$TMP/pass/t1/route-plan.md" <<'PLAN'
alpha
beta
PLAN
python3 "$EVAL" --oracle "$TMP/oracle.tsv" --run-dir "$TMP/pass" >"$TMP/behavioral-pass.out"
grep -q 'Summary: 2/2 checks passed' "$TMP/behavioral-pass.out"

# Regression: required/forbidden variants must accept table or inline field separators.
cat > "$TMP/sep-oracle.tsv" <<'TSV'
# task_id	check	artifact	value	description
t2	required_any	route-plan.md	plan scope | project||plan scope: project	must accept either separator form
t2	forbidden_any	route-plan.md	user decisions required | none||user decisions required: none	must reject either separator form
TSV

mkdir -p "$TMP/sep-pass/t2" "$TMP/sep-fail/t2"
cat > "$TMP/sep-pass/t2/route-plan.md" <<'PLAN'
Plan Scope: project
User decisions required: pending owner choice
PLAN
python3 "$EVAL" --oracle "$TMP/sep-oracle.tsv" --run-dir "$TMP/sep-pass" >"$TMP/behavioral-sep-pass.out"
grep -q 'Summary: 2/2 checks passed' "$TMP/behavioral-sep-pass.out"

cat > "$TMP/sep-fail/t2/route-plan.md" <<'PLAN'
Plan Scope: project
User decisions required: none
PLAN
if python3 "$EVAL" --oracle "$TMP/sep-oracle.tsv" --run-dir "$TMP/sep-fail" >"$TMP/behavioral-sep-fail.out"; then exit 1; fi
grep -q 'FAIL t2: forbidden any' "$TMP/behavioral-sep-fail.out"

# Regression: occurrence checks score an operator-observed interaction artifact.
cat > "$TMP/count-oracle.tsv" <<'TSV'
# task_id	check	artifact	value	description
t3	required	interaction-log.md	source: operator-observed-trace	trace must be external to the evaluated model
t3	max_occurrences	interaction-log.md	1||ask_user_question:execution-context	task may ask the decision at most once
t3	exact_occurrences	interaction-log.md	1||decision_state:execution-context:deferred	closed state must be recorded once
TSV

mkdir -p "$TMP/count-pass/t3" "$TMP/count-fail/t3"
cat > "$TMP/count-pass/t3/interaction-log.md" <<'LOG'
source: operator-observed-trace
ask_user_question:execution-context
decision_state:execution-context:deferred
LOG
python3 "$EVAL" --oracle "$TMP/count-oracle.tsv" --run-dir "$TMP/count-pass" >"$TMP/behavioral-count-pass.out"
grep -q 'Summary: 3/3 checks passed' "$TMP/behavioral-count-pass.out"

cat > "$TMP/count-fail/t3/interaction-log.md" <<'LOG'
source: operator-observed-trace
ask_user_question:execution-context
decision_state:execution-context:deferred
ask_user_question:execution-context
LOG
if python3 "$EVAL" --oracle "$TMP/count-oracle.tsv" --run-dir "$TMP/count-fail" >"$TMP/behavioral-count-fail.out"; then exit 1; fi
grep -q 'found 2' "$TMP/behavioral-count-fail.out"

cat > "$TMP/bad-count-oracle.tsv" <<'TSV'
# task_id	check	artifact	value	description
t3	max_occurrences	interaction-log.md	not-a-count||ask_user_question:execution-context	malformed count must fail closed
TSV
if python3 "$EVAL" --oracle "$TMP/bad-count-oracle.tsv" --run-dir "$TMP/count-pass" >"$TMP/behavioral-bad-count.out"; then exit 1; fi
grep -q 'count must be an integer' "$TMP/behavioral-bad-count.out"

# Regression: one complete approved alternative must pass; mixed partial evidence must fail.
cat > "$TMP/group-oracle.tsv" <<'TSV'
# task_id	check	artifact	value	description
t4	required_all_any	route-plan.md	status: deferred&&handoff_persistence: ready&&handoff_type: destination_pr&&handoff_ref:||status: blocked&&handoff_persistence: blocked&&handoff_block:	must satisfy one complete handoff path
TSV

mkdir -p "$TMP/group-ready/t4" "$TMP/group-blocked/t4" "$TMP/group-fail/t4"
cat > "$TMP/group-ready/t4/route-plan.md" <<'PLAN'
status: deferred
handoff_persistence: ready
handoff_type: destination_pr
handoff_ref: https://example.test/project/pull/7
PLAN
python3 "$EVAL" --oracle "$TMP/group-oracle.tsv" --run-dir "$TMP/group-ready" >"$TMP/behavioral-group-ready.out"
grep -q 'Summary: 1/1 checks passed' "$TMP/behavioral-group-ready.out"

cat > "$TMP/group-blocked/t4/route-plan.md" <<'PLAN'
status: blocked
handoff_persistence: blocked
handoff_block: copyable safe metadata
PLAN
python3 "$EVAL" --oracle "$TMP/group-oracle.tsv" --run-dir "$TMP/group-blocked" >"$TMP/behavioral-group-blocked.out"
grep -q 'Summary: 1/1 checks passed' "$TMP/behavioral-group-blocked.out"

cat > "$TMP/group-fail/t4/route-plan.md" <<'PLAN'
status: deferred
handoff_persistence: blocked
handoff_ref: invented
PLAN
if python3 "$EVAL" --oracle "$TMP/group-oracle.tsv" --run-dir "$TMP/group-fail" >"$TMP/behavioral-group-fail.out"; then exit 1; fi
grep -q 'required one complete alternative' "$TMP/behavioral-group-fail.out"

cat > "$TMP/bad-group-oracle.tsv" <<'TSV'
# task_id	check	artifact	value	description
t4	required_all_any	route-plan.md	status: deferred&&||status: blocked	malformed group must fail closed
TSV
if python3 "$EVAL" --oracle "$TMP/bad-group-oracle.tsv" --run-dir "$TMP/group-ready" >"$TMP/behavioral-bad-group.out"; then exit 1; fi
grep -q 'empty required term' "$TMP/behavioral-bad-group.out"

echo "claude behavioral evaluator mechanics passed"

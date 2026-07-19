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
python3 "$EVAL" --oracle "$TMP/oracle.tsv" --run-dir "$TMP/pass" >/tmp/behavioral-pass.out

grep -q 'Summary: 2/2 checks passed' /tmp/behavioral-pass.out

# Regression: a real live-review finding showed that a single-variant
# required/forbidden string only matches one Route Plan field separator
# (table "| Label | value |" vs inline "Label: value"), so a compliant
# plan in the other form incorrectly failed, and a noncompliant plan in
# the other form incorrectly passed. required_any/forbidden_any with
# both variants (as used by experiments/claude-behavioral-eval/oracle.tsv)
# must catch both forms.
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
python3 "$EVAL" --oracle "$TMP/sep-oracle.tsv" --run-dir "$TMP/sep-pass" >/tmp/behavioral-sep-pass.out
grep -q 'Summary: 2/2 checks passed' /tmp/behavioral-sep-pass.out

cat > "$TMP/sep-fail/t2/route-plan.md" <<'PLAN'
Plan Scope: project
User decisions required: none
PLAN
if python3 "$EVAL" --oracle "$TMP/sep-oracle.tsv" --run-dir "$TMP/sep-fail" >/tmp/behavioral-sep-fail.out; then exit 1; fi
grep -q 'FAIL t2: forbidden any' /tmp/behavioral-sep-fail.out

# Regression: final self-report cannot prove that a decision prompt was not
# repeated. Occurrence checks score a normalized interaction artifact.
cat > "$TMP/count-oracle.tsv" <<'TSV'
# task_id	check	artifact	value	description
t3	max_occurrences	interaction-log.md	1||ask_user_question:execution-context	ask may ask the decision at most once
t3	exact_occurrences	interaction-log.md	1||decision_state:execution-context:deferred	closed state must be recorded once
TSV

mkdir -p "$TMP/count-pass/t3" "$TMP/count-fail/t3"
cat > "$TMP/count-pass/t3/interaction-log.md" <<'LOG'
ask_user_question:execution-context
decision_state:execution-context:deferred
LOG
python3 "$EVAL" --oracle "$TMP/count-oracle.tsv" --run-dir "$TMP/count-pass" >/tmp/behavioral-count-pass.out
grep -q 'Summary: 2/2 checks passed' /tmp/behavioral-count-pass.out

cat > "$TMP/count-fail/t3/interaction-log.md" <<'LOG'
ask_user_question:execution-context
decision_state:execution-context:deferred
ask_user_question:execution-context
LOG
if python3 "$EVAL" --oracle "$TMP/count-oracle.tsv" --run-dir "$TMP/count-fail" >/tmp/behavioral-count-fail.out; then exit 1; fi
grep -q 'found 2' /tmp/behavioral-count-fail.out

cat > "$TMP/bad-count-oracle.tsv" <<'TSV'
# task_id	check	artifact	value	description
t3	max_occurrences	interaction-log.md	not-a-count||ask_user_question:execution-context	malformed count must fail closed
TSV
if python3 "$EVAL" --oracle "$TMP/bad-count-oracle.tsv" --run-dir "$TMP/count-pass" >/tmp/behavioral-bad-count.out; then exit 1; fi
grep -q 'count must be an integer' /tmp/behavioral-bad-count.out

echo "claude behavioral evaluator mechanics passed"

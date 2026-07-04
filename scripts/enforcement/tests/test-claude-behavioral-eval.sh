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

echo "claude behavioral evaluator mechanics passed"

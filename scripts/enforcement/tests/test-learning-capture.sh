#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
GATE="$ROOT/scripts/enforcement/enforce-learning-capture.sh"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
LOG="$TMP/out.log"
pass(){ local n="$1"; shift; "$@" >"$LOG" 2>&1 || { echo "fail: $n"; cat "$LOG"; exit 1; }; echo "ok: $n"; }
failcase(){ local n="$1"; shift; if "$@" >"$LOG" 2>&1; then echo "unexpected pass: $n"; cat "$LOG"; exit 1; else echo "ok: $n"; fi; }
setup_repo(){ rm -rf "$TMP/repo"; mkdir -p "$TMP/repo/.claude/plans" "$TMP/repo/src" "$TMP/repo/lessons-learned/bugs" "$TMP/repo/failed-solutions" "$TMP/repo/scripts/enforcement/tests"; cd "$TMP/repo"; git init >/dev/null; git config user.email test@example.com; git config user.name test; echo base>README.md; echo test>scripts/enforcement/tests/regression.sh; git add .; git commit -m base >/dev/null; }
plan(){ cat > .claude/plans/active.md <<EOF
| Field | Decision |
|---|---|
| Task class | $1 |
| Domain tags | $2 |
| Task-router evidence | read |
| Workflow evidence | read |
| Templates | not required |
| Patterns | none |
| External systems/connectors | none |
| Skills | superpowers |
EOF
[ "${3:-}" = waiver ] && printf '\n## Learning Capture Waiver\n\nwaiver text\n' >> .claude/plans/active.md; }
code(){ echo "export const x=$1;" > src/app.ts; git add src/app.ts; }
doc(){ echo docs>NOTE.md; git add NOTE.md; }
lesson(){ local mode="${1:-good}"; cat > lessons-learned/bugs/regression.md <<'EOF'
# Lesson

## מה קרה
A regression changed the payment flow.

## שורש הבעיה
The verified cause was missing guard logic in src/app.ts during regression handling, proven by the stored regression check.

## השערות שנבדקו
- timeout hypothesis was rejected.
- regression guard hypothesis was verified.

## ראיה
scripts/enforcement/tests/regression.sh failed before the guard and passed after the corrected guard was added.

## רמת ביטחון
Medium

## איך מזהים מוקדם
Run scripts/enforcement/tests/regression.sh before related code changes.

## איך מונעים בעתיד
Keep scripts/enforcement/tests/regression.sh and read this lesson before changing the same area.

## טסט רגרסיה
scripts/enforcement/tests/regression.sh

## סטטוס הבשלה
Verified Lesson

## Prevented Future Issues: 0

## Prevention/Enforcement Update
scripts/enforcement/tests/regression.sh covers this regression class.
EOF
case "$mode" in
placeholder) python3 - <<'PY'
from pathlib import Path
p=Path('lessons-learned/bugs/regression.md'); s=p.read_text(); a=s.index('## שורש הבעיה'); b=s.index('## השערות שנבדקו'); p.write_text(s[:a]+'## שורש הבעיה\nTODO\n\n'+s[b:])
PY
;;
badpath) perl -0pi -e 's#scripts/enforcement/tests/regression.sh#scripts/enforcement/tests/missing.sh#g' lessons-learned/bugs/regression.md ;;
esac
git add lessons-learned/bugs/regression.md; }
attempt(){ local name="${1:-regression-timeout}"; mkdir -p failed-solutions; cat > "failed-solutions/$name.md" <<EOF
# Attempt

## מה ניסיתי
Tried $name.

## למה לא עבד
It did not address the regression guard.

## מה לבדוק במקום
Check the regression guard.
EOF
git add "failed-solutions/$name.md"; }
run_gate(){ (cd "$TMP/repo" && bash "$GATE"); }
pass gate_file_present test -f "$GATE"
setup_repo; plan bug_fix regression; code 1; failcase bug_fix_requires_full_lesson run_gate
setup_repo; plan bug_fix regression; code 2; echo TODO > lessons-learned/bugs/empty.md; git add lessons-learned/bugs/empty.md; failcase placeholder_lesson_does_not_satisfy_capture run_gate
setup_repo; plan debugging regression; code 3; lesson good; pass debugging_allows_staged_lesson run_gate
setup_repo; plan incident regression; code 4; attempt regression-timeout; failcase failed_solution_alone_does_not_satisfy_bug_capture run_gate
setup_repo; plan incident regression; code 5; attempt regression-timeout; lesson good; pass incident_allows_failed_solution_plus_lesson run_gate
setup_repo; plan bug_fix regression; code 6; lesson placeholder; failcase root_cause_placeholder_fails run_gate
setup_repo; plan bug_fix regression; code 7; lesson badpath; failcase regression_path_must_exist run_gate
setup_repo; plan incident regression; code 8; attempt cache-retry; lesson good; failcase failed_solution_must_be_referenced run_gate
setup_repo; plan bug_fix regression waiver; code 9; failcase waiver_does_not_replace_bug_lesson run_gate
setup_repo; plan feature regression; code 10; pass non_learning_task_not_blocked run_gate
setup_repo; plan bug_fix regression; doc; pass docs_only_change_not_blocked run_gate
setup_repo; plan feature regression; printf '| Task class | bug_fix |\n| Domain tags | regression |\n' > .claude/plans/old.md; code 11; pass active_plan_preferred_over_other_plans run_gate
echo "learning capture simulations passed"

#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECKER="$ROOT/scripts/enforcement/check-workflow-evidence.sh"
chmod +x "$CHECKER"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cd "$TMP"
git init -q
git config user.email test@example.com
git config user.name test
echo initial > README.md
git add README.md
git commit -qm initial
BASE="$(git rev-parse HEAD)"

reset_workspace() { mkdir -p .claude/plans src; }
expect_pass() { local name="$1" head="$2"; if ! "$CHECKER" "$BASE" "$head"; then echo "expected $name to pass"; exit 1; fi; }
expect_fail() { local name="$1" head="$2"; if "$CHECKER" "$BASE" "$head"; then echo "expected $name to fail"; exit 1; fi; }

write_good_plan() {
  local path="$1"
  local progress_body="${2:-full}"
  local inherited_sha="${3:-}"
  local inherited_reason="${4:-}"
  cat > "$path" <<PLAN
# Route Plan

| Field | Value |
|---|---|
| Task type | Feature implementation |
| Domain tags | api, testing |
| Templates | templates/api-service/README.md checked and reused |
| Patterns | patterns/api/README.md, patterns/testing/README.md |
| External systems/connectors | none |
| Skills | superpowers-verify |
| Validation gates | npm test, PR CI |
| Task-router evidence | core/task-router.md routing matrix consulted |
| Workflow evidence | core/workflow.md steps consulted before coding |

$(if [ -n "$inherited_sha" ]; then
  echo "Inherited base commit: $inherited_sha"
  echo "Inherited base reason: $inherited_reason"
fi)

## DoD

- [x] fixture verified by this suite checker run.

## Source of Truth Checks

| Source | Status |
|---|---|
| patterns/api/README.md | checked |
| patterns/testing/README.md | checked |

## Skill Evidence

- superpowers-verify

## Template/Pattern Rating Evidence

- asset: patterns/api/README.md and patterns/testing/README.md
- rating: 4 medium confidence for this workflow fixture.
- outcome: workflow evidence fixture reused the patterns successfully.
- decision: keep these patterns preferred for API/testing workflow fixtures.

$(case "$progress_body" in
  start) cat <<'PROGRESS'
## Progress Lifecycle Evidence

- start: plan committed before code.
PROGRESS
  ;;
  mid) cat <<'PROGRESS'
## Progress Lifecycle Evidence

- start: plan committed before code.
- mid: fixture implementation update recorded after code began.
PROGRESS
  ;;
  full|*) cat <<'PROGRESS'
## Progress Lifecycle Evidence

- start: plan committed before code.
- mid: fixture implementation update recorded after code began.
- pre-merge: fixture final validation recorded after code changes.
PROGRESS
  ;;
esac)

## Claude Run Trace

- goal: test workflow evidence gate.
- hypothesis: plan before code with required evidence passes.
PLAN
}

# Code without plan fails.
git checkout -q -b code-without-plan "$BASE"
reset_workspace
echo 'console.log("hello")' > src/app.js
git add src/app.js
git commit -qm code-without-plan
expect_fail code-without-plan "$(git rev-parse HEAD)"

# Plan and code in same commit fails because order is not proven.
git checkout -q -b plan-and-code-same-commit "$BASE"
reset_workspace
write_good_plan .claude/plans/task.md
echo 'console.log("hello")' > src/app.js
git add .claude/plans/task.md src/app.js
git commit -qm plan-and-code-same-commit
expect_fail plan-and-code-same-commit "$(git rev-parse HEAD)"

# Ordered plan lifecycle passes: start before code, mid after work starts, pre-merge after code.
git checkout -q -b plan-before-code "$BASE"
reset_workspace
write_good_plan .claude/plans/task.md start
git add .claude/plans/task.md
git commit -qm plan-first
reset_workspace
echo 'console.log("hello")' > src/app.js
git add src/app.js
git commit -qm code-second
write_good_plan .claude/plans/task.md mid
git add .claude/plans/task.md
git commit -qm plan-mid
write_good_plan .claude/plans/task.md full
git add .claude/plans/task.md
git commit -qm plan-pre-merge
expect_pass plan-before-code "$(git rev-parse HEAD)"

# Regression: a branch that fast-forwards/inherits another branch's pre-existing
# commits (touching a non-doc/non-plan file, e.g. root guidance docs) before its own
# Route Plan commit must not be falsely flagged, provided it declares a valid,
# git-verified "Inherited base commit" marker with a concrete reason. Without the
# marker, the same commit shape must still fail (safe default, no silent bypass).
git checkout -q -b inherited-without-marker-fails "$BASE"
reset_workspace
echo "guidance v1" > GUIDE.md
git add GUIDE.md
git commit -qm "inherited: add guidance v1"
echo "guidance v2" > GUIDE.md
git add GUIDE.md
git commit -qm "inherited: add guidance v2"
reset_workspace
write_good_plan .claude/plans/task.md start
git add .claude/plans/task.md
git commit -qm plan-first
reset_workspace
echo 'console.log("hello")' > src/app.js
git add src/app.js
git commit -qm code-second
write_good_plan .claude/plans/task.md mid
git add .claude/plans/task.md
git commit -qm plan-mid
write_good_plan .claude/plans/task.md full
git add .claude/plans/task.md
git commit -qm plan-pre-merge
expect_fail inherited-without-marker-fails "$(git rev-parse HEAD)"

git checkout -q -b inherited-with-valid-marker-passes "$BASE"
reset_workspace
echo "guidance v1" > GUIDE.md
git add GUIDE.md
git commit -qm "inherited: add guidance v1"
echo "guidance v2" > GUIDE.md
git add GUIDE.md
git commit -qm "inherited: add guidance v2"
INHERITED_SHA="$(git rev-parse HEAD)"
reset_workspace
write_good_plan .claude/plans/task.md start "$INHERITED_SHA" "reused an already-open guidance branch's commits (fast-forwarded in) that predate this branch's own plan; those commits are not this PR's own work."
git add .claude/plans/task.md
git commit -qm plan-first
reset_workspace
echo 'console.log("hello")' > src/app.js
git add src/app.js
git commit -qm code-second
write_good_plan .claude/plans/task.md mid "$INHERITED_SHA" "reused an already-open guidance branch's commits (fast-forwarded in) that predate this branch's own plan; those commits are not this PR's own work."
git add .claude/plans/task.md
git commit -qm plan-mid
write_good_plan .claude/plans/task.md full "$INHERITED_SHA" "reused an already-open guidance branch's commits (fast-forwarded in) that predate this branch's own plan; those commits are not this PR's own work."
git add .claude/plans/task.md
git commit -qm plan-pre-merge
expect_pass inherited-with-valid-marker-passes "$(git rev-parse HEAD)"

# Marker referencing a SHA that is not in this diff range at all must fail loudly,
# not silently fall back to unexempted (which would just look like the no-marker case
# and could mask a copy-paste error), and must not grant any exemption.
git checkout -q -b inherited-marker-invalid-sha-fails "$BASE"
reset_workspace
echo "guidance v1" > GUIDE.md
git add GUIDE.md
git commit -qm "inherited: add guidance v1"
reset_workspace
write_good_plan .claude/plans/task.md start "0000000deadbeef0000000000000000deadbeef" "reused an already-open guidance branch's commits that predate this branch's own plan."
git add .claude/plans/task.md
git commit -qm plan-first
reset_workspace
echo 'console.log("hello")' > src/app.js
git add src/app.js
git commit -qm code-second
write_good_plan .claude/plans/task.md full "0000000deadbeef0000000000000000deadbeef" "reused an already-open guidance branch's commits that predate this branch's own plan."
git add .claude/plans/task.md
git commit -qm plan-pre-merge
expect_fail inherited-marker-invalid-sha-fails "$(git rev-parse HEAD)"

# A marker cannot point at (or past) this branch's own plan commit or later — that
# would let a branch relabel its own code as "inherited" to dodge the ordering rule.
git checkout -q -b inherited-marker-after-plan-fails "$BASE"
reset_workspace
write_good_plan .claude/plans/task.md start
git add .claude/plans/task.md
git commit -qm plan-first
PLAN_SHA="$(git rev-parse HEAD)"
reset_workspace
echo 'console.log("hello")' > src/app.js
git add src/app.js
git commit -qm code-second
write_good_plan .claude/plans/task.md full "$PLAN_SHA" "claims its own plan commit as the inherited boundary, which must be rejected."
git add .claude/plans/task.md
git commit -qm plan-pre-merge
expect_fail inherited-marker-after-plan-fails "$(git rev-parse HEAD)"

# A valid marker for genuinely inherited commits must not exempt this branch's own
# code from still needing to come after this branch's own plan commit.
git checkout -q -b inherited-marker-own-code-before-own-plan-fails "$BASE"
reset_workspace
echo "guidance v1" > GUIDE.md
git add GUIDE.md
git commit -qm "inherited: add guidance v1"
INHERITED_SHA="$(git rev-parse HEAD)"
reset_workspace
echo 'console.log("own sneaky code before own plan")' > src/app.js
git add src/app.js
git commit -qm "own code committed before own plan"
reset_workspace
write_good_plan .claude/plans/task.md full "$INHERITED_SHA" "reused an already-open guidance branch's single commit that predates this branch's own plan."
git add .claude/plans/task.md
git commit -qm plan-after-own-code
expect_fail inherited-marker-own-code-before-own-plan-fails "$(git rev-parse HEAD)"

# A marker without a concrete reason of at least 20 characters must fail — the marker
# alone is not "explicit evidence"; a documented reason is required.
git checkout -q -b inherited-marker-short-reason-fails "$BASE"
reset_workspace
echo "guidance v1" > GUIDE.md
git add GUIDE.md
git commit -qm "inherited: add guidance v1"
INHERITED_SHA="$(git rev-parse HEAD)"
reset_workspace
write_good_plan .claude/plans/task.md start "$INHERITED_SHA" "n/a"
git add .claude/plans/task.md
git commit -qm plan-first
reset_workspace
echo 'console.log("hello")' > src/app.js
git add src/app.js
git commit -qm code-second
write_good_plan .claude/plans/task.md full "$INHERITED_SHA" "n/a"
git add .claude/plans/task.md
git commit -qm plan-pre-merge
expect_fail inherited-marker-short-reason-fails "$(git rev-parse HEAD)"

# Missing task-router evidence fails.
git checkout -q -b missing-router-evidence "$BASE"
reset_workspace
write_good_plan .claude/plans/task.md
python3 - <<'PY'
from pathlib import Path
p=Path('.claude/plans/task.md')
s=p.read_text().replace('| Task-router evidence | core/task-router.md routing matrix consulted |\n','')
p.write_text(s)
PY
git add .claude/plans/task.md
git commit -qm missing-router-evidence
expect_fail missing-router-evidence "$(git rev-parse HEAD)"

# Missing source-of-truth checks fails.
git checkout -q -b missing-source-checks "$BASE"
reset_workspace
write_good_plan .claude/plans/task.md
python3 - <<'PY'
from pathlib import Path
p=Path('.claude/plans/task.md')
s=p.read_text()
s=s.split('## Source of Truth Checks')[0] + '## Skill Evidence\n\n- superpowers-verify\n\n## Progress Lifecycle Evidence\n\n- start: plan.\n- mid: validation.\n- pre-merge: final checks.\n\n## Claude Run Trace\n\n- goal: test.\n'
p.write_text(s)
PY
git add .claude/plans/task.md
git commit -qm missing-source-checks
expect_fail missing-source-checks "$(git rev-parse HEAD)"

# Declared skill without evidence fails.
git checkout -q -b missing-skill-evidence "$BASE"
reset_workspace
write_good_plan .claude/plans/task.md
python3 - <<'PY'
from pathlib import Path
p=Path('.claude/plans/task.md')
s=p.read_text().split('## Skill Evidence')[0]
p.write_text(s)
PY
git add .claude/plans/task.md
git commit -qm missing-skill-evidence
expect_fail missing-skill-evidence "$(git rev-parse HEAD)"

# Template gap without waiver or learning/template artifact fails.
git checkout -q -b template-gap-no-waiver "$BASE"
reset_workspace
write_good_plan .claude/plans/task.md
python3 - <<'PY'
from pathlib import Path
p=Path('.claude/plans/task.md')
s=p.read_text().replace('templates/api-service/README.md checked and reused','none — no matching template exists')
p.write_text(s)
PY
git add .claude/plans/task.md
git commit -qm template-gap-no-waiver
expect_fail template-gap-no-waiver "$(git rev-parse HEAD)"

# Template gap with waiver passes.
git checkout -q -b template-gap-with-waiver "$BASE"
reset_workspace
write_good_plan .claude/plans/task.md
python3 - <<'PY'
from pathlib import Path
p=Path('.claude/plans/task.md')
s=p.read_text().replace('templates/api-service/README.md checked and reused','none — no matching template exists')
s += '\n## Template Gap Waiver\n\nThe task is an internal test fixture; no reusable template should be added.\n'
p.write_text(s)
PY
git add .claude/plans/task.md
git commit -qm template-gap-with-waiver
expect_pass template-gap-with-waiver "$(git rev-parse HEAD)"

echo "workflow evidence checker tests passed"

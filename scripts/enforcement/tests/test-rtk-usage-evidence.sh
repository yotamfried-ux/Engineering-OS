#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECKER="$ROOT/scripts/enforcement/check-workflow-evidence.sh"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cd "$TMP"
git init -q
git config user.email test@example.com
git config user.name test
echo initial > README.md
git add README.md
git commit -qm initial
BASE="$(git rev-parse HEAD)"
reset_workspace(){ mkdir -p .claude/plans src; }
expect_pass(){ local n="$1" h="$2"; bash "$CHECKER" "$BASE" "$h" >/dev/null || { echo "expected $n to pass"; exit 1; }; echo "ok: $n"; }
expect_fail(){ local n="$1" h="$2"; if bash "$CHECKER" "$BASE" "$h" >/dev/null 2>&1; then echo "expected $n to fail"; exit 1; else echo "ok: $n"; fi; }
progress(){ case "$1" in start) echo '- start: plan first.';; mid) echo '- start: plan first.'; echo '- mid: fixture executed after code began.';; *) echo '- start: plan first.'; echo '- mid: fixture executed after code began.'; echo '- pre-merge: final fixture check recorded after code.';; esac; }
write_plan(){ local mode="$1" step="$2"; cat > .claude/plans/rtk.md <<PLAN
# Route Plan
| Field | Value |
|---|---|
| Task class | code_change |
| Domain tags | context-heavy |
| Target paths | src/app.js |
| Templates | not required |
| Patterns | not required |
| External systems/connectors | github |
| Skills | superpowers, rtk |
| Validation gates | workflow-evidence-policy, enforcement-tests |
| Task-router evidence | read |
| Workflow evidence | read |

## DoD

- [x] fixture verified by this suite checker run.

## Source of Truth Checks
| Source | Status |
|---|---|
| core/workflow.md | checked |
| src/app.js | checked |

## Skill Evidence
- superpowers
- rtk

PLAN
if [ "$mode" = waiver ]; then cat >> .claude/plans/rtk.md <<'PLAN'
## RTK Usage Waiver

RTK impact evidence is waived in this isolated fixture because the test case validates the explicit waiver path rather than a real RTK run.

PLAN
elif [ "$mode" != missing ]; then cat >> .claude/plans/rtk.md <<'PLAN'
## RTK Usage Evidence
- source: RTK context summary was checked.
- action: RTK was used before editing the fixture.
- result: RTK confirmed src/app.js is in scope.
- decision: limit the fixture change to src/app.js.
- prior assumption: src/app.js might require broader context.
- finding: RTK indicated the fixture scope is limited to src/app.js.
- impact: RTK confirmed and narrowed the decision to only update src/app.js.
- target: src/app.js
- confidence: medium because this fixture has direct target evidence.
- limitation: fixture evidence proves an auditable RTK impact record, not hidden reasoning.

PLAN
fi
case "$mode" in
  invalid) python3 - <<'PY'
from pathlib import Path
p=Path('.claude/plans/rtk.md')
p.write_text(p.read_text().replace('- decision: limit the fixture change to src/app.js.\n',''))
PY
  ;;
  noimpact) python3 - <<'PY'
from pathlib import Path
p=Path('.claude/plans/rtk.md')
p.write_text(p.read_text().replace('- impact: RTK confirmed and narrowed the decision to only update src/app.js.\n',''))
PY
  ;;
  badimpact) python3 - <<'PY'
from pathlib import Path
p=Path('.claude/plans/rtk.md')
p.write_text(p.read_text().replace('- impact: RTK confirmed and narrowed the decision to only update src/app.js.\n','- impact: RTK was present.\n'))
PY
  ;;
  notarget) python3 - <<'PY'
from pathlib import Path
p=Path('.claude/plans/rtk.md')
p.write_text(p.read_text().replace('- target: src/app.js\n',''))
PY
  ;;
  wrongtarget) python3 - <<'PY'
from pathlib import Path
p=Path('.claude/plans/rtk.md')
p.write_text(p.read_text().replace('- target: src/app.js\n','- target: src/other.js\n'))
PY
  ;;
  noconfidence) python3 - <<'PY'
from pathlib import Path
p=Path('.claude/plans/rtk.md')
p.write_text(p.read_text().replace('- confidence: medium because this fixture has direct target evidence.\n',''))
PY
  ;;
esac
printf '%s
' '## Progress Lifecycle Evidence' '' >> .claude/plans/rtk.md
progress "$step" >> .claude/plans/rtk.md
printf '%s
' '' '## Claude Run Trace' '- goal: rtk fixture.' >> .claude/plans/rtk.md
}
change(){ echo 'console.log("rtk")' > src/app.js; }
case_run(){ local b="$1" m="$2"; git checkout -q -B "$b" "$BASE"; reset_workspace; write_plan "$m" start; git add .claude/plans/rtk.md; git commit -qm plan-start; change; git add src/app.js; git commit -qm code; write_plan "$m" mid; git add .claude/plans/rtk.md; git commit -qm plan-mid; write_plan "$m" full; git add .claude/plans/rtk.md; git commit -qm plan-pre-merge; }
case_run good good; expect_pass rtk_usage_evidence_passes "$(git rev-parse HEAD)"
case_run missing missing; expect_fail rtk_usage_evidence_missing_fails "$(git rev-parse HEAD)"
case_run invalid invalid; expect_fail rtk_usage_evidence_invalid_fails "$(git rev-parse HEAD)"
case_run noimpact noimpact; expect_fail rtk_usage_evidence_missing_impact_fails "$(git rev-parse HEAD)"
case_run badimpact badimpact; expect_fail rtk_usage_evidence_weak_impact_fails "$(git rev-parse HEAD)"
case_run notarget notarget; expect_fail rtk_usage_evidence_missing_target_fails "$(git rev-parse HEAD)"
case_run wrongtarget wrongtarget; expect_fail rtk_usage_evidence_wrong_target_fails "$(git rev-parse HEAD)"
case_run noconfidence noconfidence; expect_fail rtk_usage_evidence_missing_confidence_fails "$(git rev-parse HEAD)"
case_run waiver waiver; expect_pass rtk_usage_waiver_passes "$(git rev-parse HEAD)"

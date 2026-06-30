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
write_plan(){ cat > .claude/plans/rtk.md <<'PLAN'
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

## Source of Truth Checks
| Source | Status |
|---|---|
| core/workflow.md | checked |
| src/app.js | checked |

## Skill Evidence
- superpowers
- rtk

## RTK Usage Evidence
- source: RTK context summary was checked.
- action: RTK was used before editing the fixture.
- result: RTK confirmed src/app.js is in scope.
- decision: limit the fixture change to src/app.js.

## Progress Lifecycle Evidence
- start: plan first.
- mid: fixture executed.
- pre-merge: CI final.

## Claude Run Trace
- goal: rtk_usage_evidence_passes fixture.
PLAN
}
change(){ echo 'console.log("rtk")' > src/app.js; }
case_run(){ local b="$1" m="$2"; git checkout -q -B "$b" "$BASE"; reset_workspace; write_plan; if [ "$m" = missing ]; then python3 - <<'PY'
from pathlib import Path
p=Path('.claude/plans/rtk.md'); s=p.read_text(); p.write_text(s.split('## RTK Usage Evidence')[0]+'## Progress Lifecycle Evidence\n- start: plan.\n- mid: fixture.\n- pre-merge: final.\n\n## Claude Run Trace\n- goal: rtk_usage_evidence_missing_fails fixture.\n')
PY
elif [ "$m" = invalid ]; then python3 - <<'PY'
from pathlib import Path
p=Path('.claude/plans/rtk.md'); s=p.read_text().replace('- decision: limit the fixture change to src/app.js.\n',''); p.write_text(s)
PY
elif [ "$m" = waiver ]; then python3 - <<'PY'
from pathlib import Path
p=Path('.claude/plans/rtk.md'); s=p.read_text(); a=s.index('## RTK Usage Evidence'); b=s.index('## Progress Lifecycle Evidence'); p.write_text(s[:a]+'## RTK Usage Waiver\n\nRTK decision-impact evidence is waived for this isolated fixture because no repository context is available.\n\n'+s[b:])
PY
fi; git add .claude/plans/rtk.md; git commit -qm plan; change; git add src/app.js; git commit -qm code; }
case_run good good; expect_pass rtk_usage_evidence_passes "$(git rev-parse HEAD)"
case_run missing missing; expect_fail rtk_usage_evidence_missing_fails "$(git rev-parse HEAD)"
case_run invalid invalid; expect_fail rtk_usage_evidence_invalid_fails "$(git rev-parse HEAD)"
case_run waiver waiver; expect_pass rtk_usage_waiver_passes "$(git rev-parse HEAD)"

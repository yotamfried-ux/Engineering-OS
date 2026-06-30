#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECKER="$ROOT/scripts/enforcement/check-workflow-evidence.sh"
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
expect_pass() { local name="$1" head="$2"; if ! bash "$CHECKER" "$BASE" "$head"; then echo "expected $name to pass"; exit 1; fi; echo "ok: $name"; }
expect_fail() { local name="$1" head="$2"; if bash "$CHECKER" "$BASE" "$head"; then echo "expected $name to fail"; exit 1; fi; echo "ok: $name"; }

write_rtk_plan() {
  local path="$1"
  cat > "$path" <<'PLAN'
# Route Plan

| Field | Value |
|---|---|
| Task class | code_change |
| Domain tags | context-heavy, long-running |
| Target paths | src/app.js |
| Templates | not required |
| Patterns | patterns/api/README.md |
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

- source: RTK context summary was checked before selecting the target file.
- action: RTK was used to reduce context before editing the fixture.
- result: RTK confirmed only src/app.js is in scope for this change.
- decision: limited the change to src/app.js instead of expanding the fixture.

## Progress Lifecycle Evidence

- start: plan committed before code.
- mid: RTK usage fixture added.
- pre-merge: final CI checks represented by this test.

## Claude Run Trace

- goal: rtk_usage_evidence_passes fixture.
- hypothesis: RTK usage evidence with decision impact passes.
PLAN
}

# Positive: RTK usage evidence with decision impact passes.
git checkout -q -b rtk-usage-good "$BASE"
reset_workspace
write_rtk_plan .claude/plans/rtk.md
git add .claude/plans/rtk.md
git commit -qm plan-first
reset_workspace
echo 'console.log("rtk")' > src/app.js
git add src/app.js
git commit -qm code-second
expect_pass rtk_usage_evidence_passes "$(git rev-parse HEAD)"

# Negative: declaring rtk without RTK Usage Evidence fails.
git checkout -q -b rtk-usage-missing "$BASE"
reset_workspace
write_rtk_plan .claude/plans/rtk.md
python3 - <<'PY'
from pathlib import Path
p=Path('.claude/plans/rtk.md')
s=p.read_text()
s=s.split('## RTK Usage Evidence')[0] + '## Progress Lifecycle Evidence\n\n- start: plan.\n- mid: fixture.\n- pre-merge: final.\n\n## Claude Run Trace\n\n- goal: rtk_usage_evidence_missing_fails fixture.\n'
p.write_text(s)
PY
git add .claude/plans/rtk.md
git commit -qm plan-first
reset_workspace
echo 'console.log("rtk")' > src/app.js
git add src/app.js
git commit -qm code-second
expect_fail rtk_usage_evidence_missing_fails "$(git rev-parse HEAD)"

# Invalid: evidence without decision impact fails.
git checkout -q -b rtk-usage-invalid "$BASE"
reset_workspace
write_rtk_plan .claude/plans/rtk.md
python3 - <<'PY'
from pathlib import Path
p=Path('.claude/plans/rtk.md')
s=p.read_text().replace('- decision: limited the change to src/app.js instead of expanding the fixture.\n', '')
s=s.replace('rtk_usage_evidence_passes fixture', 'rtk_usage_evidence_invalid_fails fixture')
p.write_text(s)
PY
git add .claude/plans/rtk.md
git commit -qm plan-first
reset_workspace
echo 'console.log("rtk")' > src/app.js
git add src/app.js
git commit -qm code-second
expect_fail rtk_usage_evidence_invalid_fails "$(git rev-parse HEAD)"

# Waiver: explicit RTK usage waiver passes when decision-impact evidence is unavailable.
git checkout -q -b rtk-usage-waiver "$BASE"
reset_workspace
write_rtk_plan .claude/plans/rtk.md
python3 - <<'PY'
from pathlib import Path
p=Path('.claude/plans/rtk.md')
s=p.read_text()
start=s.index('## RTK Usage Evidence')
end=s.index('## Progress Lifecycle Evidence')
s=s[:start] + '## RTK Usage Waiver\n\nRTK decision-impact evidence is waived for this isolated test fixture because no real repository context is available.\n\n' + s[end:]
s=s.replace('rtk_usage_evidence_passes fixture', 'rtk_usage_waiver_passes fixture')
p.write_text(s)
PY
git add .claude/plans/rtk.md
git commit -qm plan-first
reset_workspace
echo 'console.log("rtk")' > src/app.js
git add src/app.js
git commit -qm code-second
expect_pass rtk_usage_waiver_passes "$(git rev-parse HEAD)"

echo "RTK usage evidence simulations passed"

#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
VALIDATOR="$ROOT/scripts/enforcement/validate-capability-evidence.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/.claude/plans"
cd "$TMP"

cat > .claude/plans/pass.md <<'PLAN'
# Route Plan

| Field | Decision |
|---|---|
| Task type | governance |
| Task class | engineering_os_governance |
| Domain tags | governance |
| Plan Scope | standard |
| Planning Mode | approved |
| Templates | not required because this is validator maintenance, not a scaffold |
| Architecture guides | docs/operations/ checked |
| Patterns | not required because no implementation pattern is involved |
| External systems/connectors | GitHub |
| Skills | superpowers |
| Validation gates | validate-capability-evidence.sh |
| Evidence to check | validator output |
| User decisions required | none |

## Capability Evidence

- `routing.task-router-read` — checked.
- `workflow.workflow-read` — checked.
- `plan.route-plan-before-write` — checked.
- `source.github-repo-read` — checked.
- `validation.policy-change-has-validator` — checked.
- `validation.coderabbit-policy` — checked.
PLAN
bash "$VALIDATOR" .claude/plans/pass.md >/tmp/pass.out

cp .claude/plans/pass.md .claude/plans/missing-field.md
sed -i '/| Skills |/d' .claude/plans/missing-field.md
if bash "$VALIDATOR" .claude/plans/missing-field.md >/tmp/missing.out 2>&1; then exit 1; fi
grep -q 'missing required Route Plan field' /tmp/missing.out

cp .claude/plans/pass.md .claude/plans/missing-user-decisions.md
sed -i '/| User decisions required |/d' .claude/plans/missing-user-decisions.md
if bash "$VALIDATOR" .claude/plans/missing-user-decisions.md >/tmp/missing-user-decisions.out 2>&1; then exit 1; fi
grep -q 'User decisions required' /tmp/missing-user-decisions.out

cp .claude/plans/pass.md .claude/plans/placeholder.md
sed -i 's/not required because this is validator maintenance, not a scaffold/none/' .claude/plans/placeholder.md
if bash "$VALIDATOR" .claude/plans/placeholder.md >/tmp/placeholder.out 2>&1; then exit 1; fi
grep -q 'placeholder Route Plan field' /tmp/placeholder.out

cp .claude/plans/pass.md .claude/plans/missing-cap.md
sed -i '/source.github-repo-read/d' .claude/plans/missing-cap.md
sed -i 's/engineering_os_governance/code_change/' .claude/plans/missing-cap.md
if bash "$VALIDATOR" .claude/plans/missing-cap.md >/tmp/missing-cap.out 2>&1; then exit 1; fi
grep -q 'missing required capability evidence' /tmp/missing-cap.out

echo "✅ capability evidence validator tests passed"

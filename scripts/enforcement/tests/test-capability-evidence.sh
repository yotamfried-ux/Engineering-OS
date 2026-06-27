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
| Task class | engineering_os_governance |
| Domain tags | governance, enforcement |

## Capability Evidence

- `routing.task-router-read` — task router policy read.
- `workflow.workflow-read` — workflow policy checked.
- `plan.route-plan-before-write` — plan exists before implementation.
- `source.github-repo-read` — repository files inspected through GitHub.
- `validation.policy-change-has-validator` — validator and tests updated.
- `validation.coderabbit-policy` — manual review fallback recorded.
PLAN

bash "$VALIDATOR" .claude/plans/pass.md >/tmp/capability-pass.out

cat > .claude/plans/waiver.md <<'PLAN'
# Route Plan

Task class: engineering_os_governance

## Capability Evidence

- `routing.task-router-read` — task router policy read.
- `workflow.workflow-read` — workflow policy checked.
- `plan.route-plan-before-write` — plan exists before implementation.
- `source.github-repo-read` — repository files inspected.
- `validation.policy-change-has-validator` — validator and tests updated.

## Capability Waiver

- `validation.coderabbit-policy` — reason: CodeRabbit is unavailable/rate-limited, so manual review fallback is used.
PLAN

bash "$VALIDATOR" .claude/plans/waiver.md >/tmp/capability-waiver.out

cat > .claude/plans/unclassified-waiver.md <<'PLAN'
# Route Plan

Task class: unclassified

## Capability Waiver

Reason: no registry task class matches this tiny local documentation note.
PLAN

bash "$VALIDATOR" .claude/plans/unclassified-waiver.md >/tmp/capability-unclassified.out

cat > .claude/plans/missing-task-class.md <<'PLAN'
# Route Plan

## Capability Evidence

- `source.github-repo-read` — connector evidence.
PLAN

if bash "$VALIDATOR" .claude/plans/missing-task-class.md >/tmp/capability-missing-task.out 2>&1; then
  echo "expected missing task class to fail" >&2
  exit 1
fi
grep -q 'missing Task class evidence' /tmp/capability-missing-task.out

cat > .claude/plans/missing-evidence.md <<'PLAN'
# Route Plan

Task class: code_change
PLAN

if bash "$VALIDATOR" .claude/plans/missing-evidence.md >/tmp/capability-missing-evidence.out 2>&1; then
  echo "expected missing capability evidence to fail" >&2
  exit 1
fi
grep -q 'missing Capability Evidence' /tmp/capability-missing-evidence.out

cat > .claude/plans/evidence-no-ids.md <<'PLAN'
# Route Plan

Task class: code_change

## Capability Evidence

- GitHub was used.
PLAN

if bash "$VALIDATOR" .claude/plans/evidence-no-ids.md >/tmp/capability-no-ids.out 2>&1; then
  echo "expected evidence without IDs to fail" >&2
  exit 1
fi
grep -q 'no backticked capability IDs' /tmp/capability-no-ids.out

cat > .claude/plans/missing-required-capability.md <<'PLAN'
# Route Plan

Task class: code_change

## Capability Evidence

- `routing.task-router-read` — task router policy read.
- `workflow.workflow-read` — workflow policy checked.
- `plan.route-plan-before-write` — plan exists.
PLAN

if bash "$VALIDATOR" .claude/plans/missing-required-capability.md >/tmp/capability-missing-required.out 2>&1; then
  echo "expected missing required capability to fail" >&2
  exit 1
fi
grep -q 'missing required capability evidence/waiver' /tmp/capability-missing-required.out
grep -q '`source.github-repo-read`' /tmp/capability-missing-required.out

cat > .claude/plans/waiver-no-reason.md <<'PLAN'
# Route Plan

Task class: engineering_os_governance

## Capability Evidence

- `routing.task-router-read` — task router policy read.
- `workflow.workflow-read` — workflow policy checked.
- `plan.route-plan-before-write` — plan exists.
- `source.github-repo-read` — repository files inspected.
- `validation.policy-change-has-validator` — validator updated.

## Capability Waiver

- `validation.coderabbit-policy`
PLAN

if bash "$VALIDATOR" .claude/plans/waiver-no-reason.md >/tmp/capability-waiver-no-reason.out 2>&1; then
  echo "expected waiver without reason to fail" >&2
  exit 1
fi
grep -q 'no explicit reason' /tmp/capability-waiver-no-reason.out

cat > .claude/plans/unknown-no-waiver.md <<'PLAN'
# Route Plan

Task class: docs_governance

## Capability Evidence

- `source.github-repo-read` — connector evidence.
PLAN

if bash "$VALIDATOR" .claude/plans/unknown-no-waiver.md >/tmp/capability-unknown-no-waiver.out 2>&1; then
  echo "expected unknown task class without waiver to fail" >&2
  exit 1
fi
grep -q 'unknown/unclassified task class' /tmp/capability-unknown-no-waiver.out

echo "✅ capability evidence validator tests passed"

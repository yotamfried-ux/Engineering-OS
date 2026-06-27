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
| Task class | engineering_os_maintenance |
| Domain tags | governance, enforcement |

## Capability Evidence

- `superpowers` — required planning/review capability; portable slash commands installed.
- `github` — connector used for repository evidence.
- `claude-template` — not applicable to this task, checked as template inventory.
PLAN

bash "$VALIDATOR" .claude/plans/pass.md >/tmp/capability-pass.out

cat > .claude/plans/waiver.md <<'PLAN'
# Route Plan

Task class: docs_governance

## Capability Waiver

Reason: no external connector capability is required because this is a local documentation-only update.
PLAN

bash "$VALIDATOR" .claude/plans/waiver.md >/tmp/capability-waiver.out

cat > .claude/plans/missing-task-class.md <<'PLAN'
# Route Plan

## Capability Evidence

- `github` — connector evidence.
PLAN

if bash "$VALIDATOR" .claude/plans/missing-task-class.md >/tmp/capability-missing-task.out 2>&1; then
  echo "expected missing task class to fail" >&2
  exit 1
fi
grep -q 'missing Task class evidence' /tmp/capability-missing-task.out

cat > .claude/plans/missing-evidence.md <<'PLAN'
# Route Plan

Task class: feature_implementation
PLAN

if bash "$VALIDATOR" .claude/plans/missing-evidence.md >/tmp/capability-missing-evidence.out 2>&1; then
  echo "expected missing capability evidence to fail" >&2
  exit 1
fi
grep -q 'missing Capability Evidence' /tmp/capability-missing-evidence.out

cat > .claude/plans/evidence-no-ids.md <<'PLAN'
# Route Plan

Task class: feature_implementation

## Capability Evidence

- GitHub was used.
PLAN

if bash "$VALIDATOR" .claude/plans/evidence-no-ids.md >/tmp/capability-no-ids.out 2>&1; then
  echo "expected evidence without IDs to fail" >&2
  exit 1
fi
grep -q 'no backticked capability IDs' /tmp/capability-no-ids.out

cat > .claude/plans/waiver-no-reason.md <<'PLAN'
# Route Plan

Task class: docs_governance

## Capability Waiver

- skipped
PLAN

if bash "$VALIDATOR" .claude/plans/waiver-no-reason.md >/tmp/capability-waiver-no-reason.out 2>&1; then
  echo "expected waiver without reason to fail" >&2
  exit 1
fi
grep -q 'no explicit reason' /tmp/capability-waiver-no-reason.out

echo "✅ capability evidence validator tests passed"

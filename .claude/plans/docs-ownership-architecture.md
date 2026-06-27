# Docs Ownership Architecture Cleanup Plan

Created: 2026-06-26
Branch: `docs-ownership-architecture`
Status: PR review

## Route Plan

| Field | Value |
|---|---|
| Task-router evidence | Read `core/task-router.md`; task type is Engineering OS maintenance / governance. |
| Workflow evidence | Read `core/workflow.md`; plan fallback is `.claude/plans/`. |
| Templates | N/A for documentation ownership cleanup. |
| Patterns | Existing core policy and README inventory structure. |
| External systems/connectors | GitHub. |
| Skills | Not required. |
| Validation gates | enforcement tests, plan policy, connector evidence policy, workflow evidence policy, review. |

## Source of Truth Checks

- `CLAUDE.md` is the entry point.
- `core/documentation-policy.md` owns documentation placement and lifecycle.
- `core/task-router.md` owns task routing.
- `core/workflow.md` owns planning workflow.
- `core/skill-orchestration-policy.md` owns SIP rules.
- `core/connector-policy.md` owns connector policy.
- `core/capability-registry.yaml` owns capability vocabulary.

## Connector Evidence

Repository reads and writes were done through GitHub on branch `docs-ownership-architecture`.

## Template Gap Waiver

No scaffold template applies. The reusable structure is the existing `core/` policy pattern and inventory README pattern.

## Scope

1. Add canonical documentation ownership to `core/documentation-policy.md`.
2. Keep `external-systems/README.md` as an index-only inventory.
3. Keep `external-skills/README.md` as an index-only inventory.
4. Separate active skills, replaced wrappers, and adjacent accelerators.
5. Add an ownership regression test under `scripts/enforcement/tests/`.

## Out of Scope

- Large documentation deletions.
- Runtime capability-registry enforcement.
- Vendor documentation rewrite.
- Direct `CLAUDE.md` edit.

## Validation Plan

- PR policy workflows.
- `scripts/enforcement/tests/test-documentation-ownership.sh` through the existing enforcement test loop.
- Review before merge.

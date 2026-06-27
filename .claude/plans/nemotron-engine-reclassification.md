# Route Plan: Nemotron Engine Reclassification

Branch: `claude/docs-architecture-duplicates-r4vycx`
PR: #96

## Route Plan

| Field | Value |
|---|---|
| Task type | Engineering OS maintenance / documentation governance |
| Domain tags | engines, skills, runtime-adapters, security-gate, docs |
| Task-router evidence | `core/task-router.md` routes Engineering OS governance changes through plan-first docs/governance workflow. |
| Workflow evidence | `core/workflow.md` requires plan before changing OS policy/docs/runtime wiring. |
| Templates | Not required; this is not a project scaffold. |
| Patterns | Not required; no reusable app code pattern is added. |
| Skills | None; this change clarifies that Nemotron is an engine, not a skill. |
| External systems/connectors | GitHub connector only. |
| Validation gates | GitHub Actions, CodeRabbit review, explicit user approval before merge. |

## Source of Truth Checks

- `CLAUDE.md` ownership model: one canonical owner per concept.
- `core/skill-orchestration-policy.md`: skills are workflow capabilities.
- `external-skills/README.md`: active skill registry.
- `external-systems/nvidia-nemotron/README.md`: provider/system reference.
- `.claude/agents/nemotron-*`: runtime adapters to the engine.
- `.claude/commands/superpowers-verify.md`: completion/security verification gate wording.

## Connector Evidence

- GitHub: read PR #96 state, PR #93 merge result, changed files, workflow failures, and repository files before rewriting this PR branch.

## Skill Evidence

- None. This task changes skill/engine classification docs and does not require running a runtime skill.

## Template Gap Waiver

No template is required because this is a documentation/governance correction, not a new application or repository scaffold.

## Scope

- Reclassify Nemotron from active skill to LLM engine/backend.
- Keep `.claude/agents/nemotron-*` as runtime adapters only.
- Clarify that raw `nemotron_review_code` is first-pass review and does not satisfy `/security-review`.
- Add engine orchestration docs under `external-systems/nvidia-nemotron/`.
- Keep legacy `external-skills/nemotron/*` only as redirects/compatibility pointers, not as skill policy.
- Remove the stale PR #95 route plan file.

## Completed Work

- [x] Route Plan committed before implementation changes.
- [x] Nemotron skill registry entry removed or redirected.
- [x] Engine documentation added/updated.
- [x] Runtime adapters clarified.
- [x] `/superpowers-verify` security gate wording fixed.
- [x] Stale PR #95 plan removed.

## Remaining Validation Outside This Plan

- GitHub Actions pass.
- CodeRabbit review is checked.
- Merge requires explicit user approval.

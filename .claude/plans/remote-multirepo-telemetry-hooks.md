# Route Plan — Remote multi-repository telemetry hooks

## Route Plan

| Field | Decision |
|---|---|
| Task type | infrastructure / telemetry runtime repair |
| Task class | `engineering_os_governance` |
| Domain tags | governance, observability, privacy, cross-repository, Claude Code hooks |
| Plan Scope | project |
| Planning Mode | approved — the owner authorized implementation and conditional squash merge after exact-head validation |
| Target paths | `scripts/monitoring/`; `scripts/enforcement/tests/`; `.github/workflows/telemetry-handoff-tests.yml`; operational documentation |
| Task-router evidence | `core/task-router.md` read before implementation; task classified as Engineering OS governance |
| Workflow evidence | `core/workflow.md` read before implementation; plan-first and experiment-fix-experiment rules selected |
| Templates | waiver — no registered template owns a Claude Code user-level dispatcher |
| Architecture guides | `architecture-decisions/ADR-2026-002-managed-settings-rollout.md`; `docs/operations/managed-settings-deployment-proof.md`; `docs/operations/project8-telemetry-preflight.md` |
| Patterns | waiver — no registered pattern covers cross-repository hook attribution; existing per-repository telemetry entry points will be reused |
| External systems/connectors | GitHub; Claude Code runtime |
| Skills | security-review; verification-before-completion |
| Validation gates | telemetry-handoff-tests; enforcement-tests; pr-policy; plan/workflow/connector/capability/documentation policies |
| Evidence to check | PR #250 review and Actions evidence; official Claude Code settings/hooks documentation; existing telemetry scripts and fixtures |
| User decisions required | none outstanding |

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| `core/task-router.md` | read | The change is Engineering OS governance and requires a Route Plan before implementation writes. |
| `core/workflow.md` | read | The task requires evidence checkpoints, experiment-fix loops, exact-head validation, and review correction. |
| `scripts/monitoring/require-telemetry-session.sh` | read | The repository guard is intentionally fail-closed and must only run after safe attribution. |
| `scripts/monitoring/eos-telemetry-session-start.sh` | read | Repository-local SessionStart remains the owner of run initialization. |
| `scripts/monitoring/eos-telemetry-event.sh` | read | Repository-local event recording retains the metadata-only contract. |
| Official Claude Code settings/hooks documentation | consulted | User-level and project-level settings scopes can both contribute hooks to a session. |

## Architecture Decision

Use a user-level dispatcher only as a bootstrap. It discovers explicitly opted-in repositories, reconciles authoritative path/repository targets, changes into the proven repository root, and delegates to the existing per-repository SessionStart, recorder, guard, and boundary scripts. Unmanaged or ambiguous activity remains outside enforcement scope.

## Privacy and Security Contract

- No recursive home-directory monitoring.
- Only repositories with a valid non-escaping telemetry policy marker opt in.
- Raw prompts, responses, commands, paths, file contents, environment values, and secrets are excluded from diagnostics.
- Explicit outside or conflicting targets cannot inherit a managed repository's fail-closed guard.
- Required handoff failures remain observable after lifecycle fan-out.

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.actions-checked`
- `validation.coderabbit-policy`

## Documentation Asset Evidence

- internal: `docs/operations/project8-telemetry-preflight.md`, `docs/operations/managed-settings-deployment-proof.md`, and `architecture-decisions/ADR-2026-002-managed-settings-rollout.md`.
- context7: not required because no external library, framework, SDK, or API is integrated; official Claude Code documentation is the direct source.
- decision: use a narrowly scoped user-level bootstrap and retain the existing repository-local telemetry pipeline.

## Connector Evidence

- GitHub: required for repository state, PR review, Actions evidence, and final branch/merge validation.
- Claude Code runtime: not a connector; its behavior is validated from official documentation and a controlled Remote experiment.

## Connector Usage Evidence

- source: GitHub connector for `yotamfried-ux/Engineering-OS`.
- action: inspect PR #250, the existing telemetry runtime, CI failures, and review findings before implementation.
- result: PR #250 and concrete paths under `scripts/monitoring/` define the implementation and evidence scope.
- decision: selected reuse of the hard repository guard and existing handoff pipeline rather than weakening or bypassing them.
- target: `scripts/monitoring/`, `scripts/enforcement/tests/`, and `.github/workflows/telemetry-handoff-tests.yml`.

## Skill Evidence

- `security-review` — required for repository boundaries, privacy, malformed inputs, and guard scope.
- `verification-before-completion` — completion remains blocked until exact-head CI, review, and merge verification are clean.

## Progress Lifecycle Evidence

- start: this Route Plan records the approved scope, source checks, privacy constraints, and validation gates before any implementation, configuration, workflow, or test write.

## Definition of Done

- [ ] Managed repositories are discovered without recursive scanning or unmanaged writes.
- [ ] Repository attribution rejects malformed, outside, ambiguous, and conflicting signals.
- [ ] The fail-closed guard runs only for a safely attributed managed repository.
- [ ] Per-repository run state, policy, handoff, and PR matching remain isolated.
- [ ] Lifecycle boundaries propagate required failures after full fan-out.
- [ ] CI tests and focused positive/negative fixtures validate every changed runtime contract.
- [ ] Exact-head review and required workflows are clean before merge.

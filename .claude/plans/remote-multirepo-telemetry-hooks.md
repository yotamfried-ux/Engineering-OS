# Route Plan — Remote multi-repository telemetry hooks

## Route Plan

| Field | Decision |
|---|---|
| Task type | infrastructure / telemetry runtime repair |
| Task class | `engineering_os_governance` |
| Domain tags | governance, observability, privacy, cross-repository, Claude Code hooks |
| Plan Scope | project |
| Planning Mode | approved — the owner authorized implementation and conditional squash merge after exact-head validation |
| Target paths | `scripts/monitoring/`; `scripts/enforcement/tests/`; `.github/workflows/telemetry-handoff-tests.yml`; `docs/operations/remote-multirepo-telemetry-hooks.md` |
| Task-router evidence | `core/task-router.md` was read before implementation and classified this as Engineering OS governance |
| Workflow evidence | `core/workflow.md` was followed through plan-first, experiment-fix loops, exact-head validation, and review correction |
| Templates | waiver — no registered template owns a Claude Code user-level dispatcher |
| Architecture guides | `architecture-decisions/ADR-2026-002-managed-settings-rollout.md`; `docs/operations/managed-settings-deployment-proof.md`; `docs/operations/project8-telemetry-preflight.md` |
| Patterns | waiver — no registered pattern covers cross-repository hook attribution; the repository-local telemetry pipeline is reused |
| External systems/connectors | GitHub; Claude Code runtime |
| Skills | security-review; verification-before-completion |
| Validation gates | telemetry-handoff-tests; enforcement-tests; pr-policy; plan/workflow/connector/capability/documentation/cleanup policies |
| Evidence to check | PR #250 exact-head Actions and reviews; official Claude Code documentation; focused positive and negative fixtures |
| User decisions required | none outstanding |

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| `core/task-router.md` | read | The change is Engineering OS governance and requires a Route Plan before implementation. |
| `core/workflow.md` | read | Experiment → fix → experiment, exact-head evidence, and review correction are mandatory. |
| `scripts/monitoring/require-telemetry-session.sh` | validated | The guard is fail-closed only after current attribution and catch-all PreToolUse coverage. |
| `scripts/monitoring/eos-telemetry-session-start.sh` | read | Repository-local SessionStart remains the run initializer. |
| `scripts/monitoring/eos-telemetry-event.sh` | read | Event recording retains the metadata-only schema. |
| `scripts/monitoring/record-and-sync-telemetry.sh` | validated | Boundary fan-out and durable handoff remain repository-local. |
| `scripts/monitoring/select-pr-telemetry.py` | validated | Repository, branch, head, run, and PR identities remain exact downstream gates. |
| Official Claude Code settings/hooks documentation | consulted | User and project settings contribute event- and matcher-scoped hooks. |

## Root Cause and Architecture

A Remote session may begin above managed repositories, where project-local settings are not active. The user-level dispatcher is therefore only a bootstrap: it discovers currently opted-in Git roots, reconciles every explicit filesystem and repository signal, changes into the proven root, and delegates to the existing repository-local runtime.

The repair independently validates current opt-in, typed path values, exact repository identity, complete project-hook coverage, catch-all guard scope, cache freshness, settings inode permissions, hook ownership, exact installed-hook sets, lifecycle failure propagation, and metadata-only diagnostics. Unmanaged, malformed, revoked, or conflicting activity remains unattributed.

## Privacy and Security

- No recursive home-directory monitoring.
- A current, valid, non-escaping policy marker is required on every cache use.
- Path signals must be non-empty strings; malformed types are negative evidence.
- All repository identity forms must be exact and mutually consistent.
- Partial project settings cannot suppress dispatcher enforcement.
- Guard and recorder coverage must be catch-all for PreToolUse.
- New settings are `0600`; existing permissions are established on the temporary inode before content is written and preserved across replacement.
- Ownership requires an Engineering OS runtime marker; similarly named user hooks remain untouched.
- Verification rejects missing, stale, duplicate, misplaced, and additional owned hooks.
- Raw prompts, responses, commands, paths, tool payloads, contents, environment values, and secrets are excluded from diagnostics.

## Validation Matrix

Focused tests cover managed-only discovery, partial versus complete direct hooks, cache revocation, typed path and repository attribution, Grep paths, exact/conflicting identities, catch-all matchers, marker-only guards, complete boundaries, required failure propagation, settings migration, pre-write modes, exact hook-set verification, unrelated hooks, malformed JSON, retention, product-head advancement, bundle privacy, and PR matching.

## Live Claude Code Remote Evidence

The real pre-merge attempt proved installation, verification, and dynamic loading, and reproduced inactive-sibling suppression plus a global false block. This is valid failure evidence, not successful closure. `multirepo-remote-telemetry-validation`, `project-8-real-run-evidence`, and `monitoring-metrics-sufficiency` remain open until a fresh post-merge session succeeds.

## Documentation Asset Evidence

- internal: `docs/operations/remote-multirepo-telemetry-hooks.md`, `docs/operations/project8-telemetry-preflight.md`, `docs/operations/managed-settings-deployment-proof.md`, `architecture-decisions/ADR-2026-002-managed-settings-rollout.md`, `docs/operations/known-gaps.tsv`, and `docs/operations/operational-readiness-audit.md`.
- context7: not required because no external library, framework, SDK, or API is integrated; official Claude Code documentation was checked directly.
- decision: use a narrow user-level bootstrap restricted by current opt-in, strict attribution, and event/matcher-aware enforcement.

## Capability Evidence

- `routing.task-router-read` — governance classification completed.
- `workflow.workflow-read` — plan-first and exact-head review loops followed.
- `plan.route-plan-before-write` — start commit `4fe393c786cdc76fa05215524733191bf6b3b772` preceded implementation.
- `source.docs-read` — official settings/hooks behavior informed event and matcher validation.
- `source.github-repo-read` — PR, Actions, and all review threads were inspected through GitHub.
- `validation.policy-change-has-validator` — every runtime and security contract has positive and negative coverage.
- `validation.actions-checked` — `.github/workflows/telemetry-handoff-tests.yml` runs focused dispatcher and handoff fixtures.
- `validation.coderabbit-policy` — valid automated findings are fixed before resolution and merge.
- security-sensitive change waiver: none; identity, opt-in, routing types, permissions, ownership, privacy, and failure propagation are tested.

## Skill Evidence

- `security-review` — applied to typed routing, identity, cache state, realpath boundaries, settings modes, hook ownership, and privacy.
- `verification-before-completion` — completion remains blocked on exact-head CI, review, thread resolution, and merge verification.

## Connector Evidence

- GitHub: required to inspect and update `yotamfried-ux/Engineering-OS`, PR #250, Actions, and review threads.
- Claude Code runtime: not used as a connector; official documentation and the controlled Remote attempt supplied runtime evidence.

## Connector Usage Evidence

- source: GitHub connector for `yotamfried-ux/Engineering-OS`.
- action: inspected PR #250, exact-head Actions, and all review threads; updated runtime, tests, runbook, and checkpoints.
- result: final code and tests through `a9ac60ef2194e3e80b819bc5335ccbe3997aedc8` plus checkpoint `960732b96747f64bfeab7465047d77d6cc030fb8` implement typed path rejection, secure pre-write modes, and exact complete hook verification.
- decision: kept the hard guard and implemented root-cause fixes rather than weakening enforcement.
- target: `scripts/monitoring/patch-settings-telemetry.py`, `scripts/monitoring/telemetry_repo_discovery.py`, and focused installer/attribution tests.

## Claude Run Trace

- goal: reliable per-repository telemetry from parent-started Remote sessions without unmanaged monitoring or global blocking.
- hypothesis: current opt-in plus authoritative typed target reconciliation can safely reuse the repository-local pipeline.
- connectors: GitHub; Claude Code runtime was observed but not used as a connector.
- steps: plan-first; implement bootstrap/discovery/attribution; run a real attempt; diagnose failures; repeat CI/review-fix loops for hook completeness, guard scope, identity, cache, lifecycle, permissions, ownership, typed paths, atomic modes, exact verification, diagnostics, retention, and fixtures.
- evidence: PR #250, start `4fe393c786cdc76fa05215524733191bf6b3b772`, implementation history, live report, Actions, reviews, fixtures, and last code/test commit `a9ac60ef2194e3e80b819bc5335ccbe3997aedc8`.
- rejected: disabling the guard, recursive scanning, trusting partial settings or stale cache, stringifying malformed targets, transiently broad settings modes, or accepting additional owned hooks.
- result: deterministic implementation and regression evidence are present; fresh successful Remote validation remains post-merge.

## Progress Lifecycle Evidence

- start: `4fe393c786cdc76fa05215524733191bf6b3b772` recorded scope and validation before implementation.
- mid: `ff974707978c0cfac72850233e1923f06ae20018` and `855d1277c1e6f310cca18ec77ed60a1953f4e9c8` recorded implementation and the mid checkpoint.
- pre-merge: final code/tests through `a9ac60ef2194e3e80b819bc5335ccbe3997aedc8` precede checkpoints `960732b96747f64bfeab7465047d77d6cc030fb8` and this evidence-only correction.

## Definition of Done

- [x] Installation is exact, reversible, mode-safe, permission-safe, and preserves unrelated hooks.
- [x] Temporary settings content is written only after the final inode mode is established.
- [x] Discovery is bounded, symlink-safe, and revalidates current opt-in.
- [x] Explicit signals are typed, strict, complete, and mutually consistent.
- [x] The guard requires current attribution and catch-all coverage.
- [x] Verification rejects stale, missing, duplicate, misplaced, or additional owned hooks.
- [x] Repository state, lifecycle failures, privacy, and downstream matching remain isolated and validated.
- [x] Every available review finding has focused regression coverage.
- [x] The failed live attempt is documented honestly and successful closure gaps remain open.

## Merge Gates

Merge remains blocked until every required workflow succeeds on one exact final head, current-head review has no remaining valid finding, verified threads are resolved, and the PR body references that exact evidence.

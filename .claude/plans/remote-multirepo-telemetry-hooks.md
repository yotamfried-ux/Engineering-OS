# Route Plan — Remote multi-repository telemetry hooks

## Route Plan

| Field | Decision |
|---|---|
| Task type | infrastructure / telemetry runtime repair |
| Task class | `engineering_os_governance` |
| Domain tags | governance, observability, privacy, cross-repository, Claude Code hooks |
| Plan Scope | project |
| Planning Mode | approved — the owner authorized implementation and squash merge after exact-head validation and clean review |
| Target paths | `scripts/monitoring/`; `scripts/enforcement/tests/`; `.github/workflows/telemetry-handoff-tests.yml`; operational runbook; known-gaps and readiness audit |
| Task-router evidence | `core/task-router.md` was read before implementation; the task was classified as Engineering OS governance with plan-first execution |
| Workflow evidence | `core/workflow.md` was followed through plan-first commits, experiment-fix loops, exact-head validation, review correction, and conditional merge |
| Templates | waiver — no registered template owns a Claude Code user-level dispatcher |
| Architecture guides | `architecture-decisions/ADR-2026-002-managed-settings-rollout.md`; `docs/operations/managed-settings-deployment-proof.md`; `docs/operations/project8-telemetry-preflight.md` |
| Patterns | waiver — no registered pattern covers cross-repository hook attribution; the existing per-repository telemetry pipeline is reused |
| External systems/connectors | GitHub; Claude Code runtime |
| Skills | security-review; verification-before-completion |
| Validation gates | telemetry-handoff-tests; enforcement-tests; pr-policy; plan-policy; workflow-evidence-policy; connector-evidence-policy; capability-evidence-policy; documentation-asset-policy; cleanup policies |
| Evidence to check | PR #250 exact-head Actions and review threads; official Claude Code documentation; live Remote failure evidence; executable fixtures |
| User decisions required | none outstanding |

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| `core/task-router.md` | read | The change is Engineering OS governance and requires a Route Plan before implementation writes. |
| `core/workflow.md` | read | Experiment → fix → experiment, exact-head evidence, review correction, and conditional merge are mandatory. |
| Official Claude Code settings/hooks documentation | checked | User-level settings load across sessions; project settings depend on project/session scope; hooks from applicable scopes merge. |
| `scripts/monitoring/require-telemetry-session.sh` | read | The guard remains fail-closed for an attributed managed repository but validates direct or dispatcher settings under the correct hook events. |
| `scripts/monitoring/eos-telemetry-session-start.sh` | read | It remains the owner of repository-local run initialization and rotation. |
| `scripts/monitoring/eos-telemetry-event.sh` | read | It retains the metadata-only event schema. |
| `scripts/monitoring/record-and-sync-telemetry.sh` | validated | Repository, branch, head, bundle, push, and PR matching remain downstream and per repository. |
| PR #250 live Remote attempt | validated | Installation, verification, and dynamic hook loading worked; two runtime defects were reproduced. The attempt ended with a required restart, so fresh successful validation remains open. |

## Root Cause

A Remote session can start from a parent directory where repository-local hook settings are not active. A user-level bootstrap solves hook loading, but it has no repository identity of its own. The original implementation also confused project settings present on disk with hooks active in the current session and allowed a sole-repository fallback to override explicit outside-repository evidence.

The result was first zero telemetry for `project-8`, then a session-wide false block when an unrelated operation inherited `project-8`'s correct missing-SessionStart guard.

## Architecture

### User-level installation

`install-user-level-telemetry-hooks.sh` manages `$HOME/.claude/settings.json` without sudo. It preserves unrelated entries, backs up and writes atomically, rejects malformed JSON, verifies exact commands and runtime paths, supports dry-run/uninstall, and removes stale direct-mode entries before installing dispatcher mode.

### Discovery and project-hook coexistence

- Cwd is checked first.
- Otherwise only immediate children are inspected; no recursive home scan exists.
- A repository must be its own Git root with a valid, regular, non-escaping telemetry policy marker.
- Direct project hooks are suppressed only for the native repository of an actual in-repository `SessionStart`.
- Parent siblings and non-SessionStart cache misses remain dispatchable even when project settings exist on disk.

### Event attribution

All explicit targets are authoritative and must agree:

1. Actual path fields such as `file_path` and `path`, after realpath normalization. Search expressions such as `Grep.pattern` are not treated as paths.
2. Explicit GitHub/MCP repository identity matched to a discovered repository's real `origin` slug.
3. Payload cwd only when no explicit target exists.
4. Sole-repository fallback only when the payload contains no routing signal.

An invalid, unmanaged, malformed, or conflicting explicit target makes the event unattributed. Cwd and fallback cannot override that result.

### Repository-scoped guard

User-level PreToolUse uses `eos-telemetry-dispatch.sh guard`. The dispatcher resolves the repository first and invokes the existing guard only for that repository. It passes dispatcher mode and the active user settings path, so a marker-only managed repository can validate SessionStart, guard, recorder, and boundary commands under their actual hook events.

Unmanaged or unattributed activity does not inherit another repository's enforcement.

### Isolation and boundaries

Each repository keeps its own run ID, events, policy, branch/head, bundle, and handoff state. A shared host correlation ID is additive only.

Lifecycle fan-out visits every repository. For Stop, StopFailure, and SessionEnd, any required durable-handoff failure is returned after all siblings have been visited rather than swallowed.

### Failure diagnostics and retention

Resolver failures are separate from normal unattributed events and produce metadata-only hashed diagnostics. Session-cache files are pruned on SessionStart after a bounded retention period.

## Privacy and Security

- Only explicit policy markers opt repositories in.
- No recursive monitoring is introduced.
- Raw prompts, responses, commands, full tool inputs, file contents, paths, environment values, and secrets are excluded from diagnostics and repository telemetry.
- Realpath and repository-boundary checks reject traversal and escaping symlinks.
- Explicit outside targets cannot be overridden by cwd.
- A user-level guard cannot become a global host-session blocker.

## Validation Matrix

Executable coverage includes:

- managed-only parent discovery and unmanaged exclusion;
- native active hooks versus inactive parent siblings and mid-session cache misses;
- file, cwd, Grep path, and GitHub/MCP attribution;
- agreement and conflict across filesystem and repository targets;
- malformed repository targets as negative evidence;
- marker-only dispatcher guard behavior and event-placement validation;
- required/best-effort/disabled policy isolation;
- boundary fan-out with required failure propagation;
- complete direct and dispatcher Stop/StopFailure/SessionEnd hook registration;
- separate repository run IDs/events with shared host correlation;
- installer creation, migration, exact verification, idempotency, backup, malformed JSON refusal, dry-run, and uninstall;
- resolver errors, cache retention, traversal, malformed inputs, and privacy-safe diagnostics;
- downstream repository/branch/head/PR matching compatibility.

## Live Claude Code Remote Evidence

The real pre-merge attempt proved installation, `--verify`, and dynamic hook loading. It reproduced and informed fixes for:

1. inactive project settings being treated as active;
2. unrelated explicit activity inheriting the sole managed repository and its guard.

This is valid failure evidence, not successful closure. `multirepo-remote-telemetry-validation`, `project-8-real-run-evidence`, and `monitoring-metrics-sufficiency` remain open until a fresh post-merge session produces the required successful evidence.

## Documentation Asset Evidence

- internal: `docs/operations/remote-multirepo-telemetry-hooks.md`, `docs/operations/project8-telemetry-preflight.md`, `docs/operations/managed-settings-deployment-proof.md`, `architecture-decisions/ADR-2026-002-managed-settings-rollout.md`, `docs/operations/known-gaps.tsv`, and `docs/operations/operational-readiness-audit.md`.
- context7: not required because this change does not integrate an external library, framework, SDK, or API; official Claude Code settings/hooks documentation was checked directly.
- decision: the documentation confirmed a user-level bootstrap restricted to explicitly managed repositories while retaining the repository-local downstream pipeline.

## Capability Evidence

- `routing.task-router-read` — classified as Engineering OS governance and telemetry runtime work.
- `workflow.workflow-read` — plan-first, evidence checkpoints, exact-head validation, and conditional merge authorization were followed.
- `plan.route-plan-before-write` — Route Plan commit `9c10bae` preceded implementation writes.
- `source.docs-read` — official Claude Code settings/hooks behavior informed the design.
- `source.github-repo-read` — PR #250, Actions diagnostics, and all review threads were inspected through GitHub.
- `validation.policy-change-has-validator` — every changed runtime contract has positive and negative executable coverage.
- `validation.actions-checked` — `.github/workflows/telemetry-handoff-tests.yml` runs the focused attribution and dispatcher guard fixtures.
- `validation.coderabbit-policy` — valid Codex and CodeRabbit findings are fixed before thread resolution and merge.
- security-sensitive change waiver: no waiver is used; repository boundaries, privacy, guard scope, traversal, malformed targets, and failure propagation are tested explicitly.

## Skill Evidence

- `security-review` — applied to repository opt-in, realpath boundaries, privacy-safe diagnostics, malformed inputs, and fail-closed enforcement scope.
- `verification-before-completion` — completion is withheld until exact-head CI, current-head review, thread resolution, and merge verification are all complete.

## Connector Evidence

- GitHub: required to inspect and update `yotamfried-ux/Engineering-OS`, read PR #250 reviews and Actions diagnostics, and validate the final head.
- Claude Code runtime: not used as a connector; its settings and hook behavior were checked through official documentation and the real Remote experiment.

## Connector Usage Evidence

- source: GitHub connector for `yotamfried-ux/Engineering-OS`.
- action: inspected original head `aaa498b7587cefc6653c49320877c4d1ed9ec87c`, run `29705789876`, subsequent exact-head runs, and every Codex/CodeRabbit thread; then updated runtime, tests, workflow, plan, runbook, gap registry, and audit.
- result: commits through boundary-fixture commit `b93d11619fddec58208000f9e6559b02fdf2359c` implement managed discovery, evidence-safe attribution, dispatcher-aware guard validation, boundary failure propagation, complete lifecycle hook fixtures, diagnostics, retention, and regressions.
- decision: kept the hard repository guard and durable-handoff contract while fixing attribution, settings scope, and test fixtures at the root.
- target: `scripts/monitoring/`, `scripts/enforcement/tests/test-remote-telemetry-handoff.sh`, `.github/workflows/telemetry-handoff-tests.yml`, and operational documentation.

## Claude Run Trace

- goal: obtain reliable per-repository telemetry from parent-started Remote sessions without monitoring unmanaged work or globally blocking the host.
- hypothesis: a narrow user-level bootstrap plus authoritative explicit-target reconciliation can safely reuse the existing per-repository pipeline.
- connectors: GitHub; Claude Code runtime was observed directly but was not used as a connector.
- steps: verify settings scope; create plan-first commit; implement bootstrap/discovery/attribution/isolation; open PR; run real Remote attempt; diagnose two live failures; correct project-hook activation, guard routing, user-settings validation, explicit-target precedence, malformed targets, Grep path handling, lifecycle failure propagation, mode migration, diagnostics, retention, and tests; align the legacy handoff fixture with complete lifecycle hooks; rerun exact-head gates and review.
- evidence: PR #250, plan-first commit `9c10bae`, boundary-fixture commit `b93d11619fddec58208000f9e6559b02fdf2359c`, live Remote report, Actions runs, review threads, and focused fixtures.
- rejected: disabling the guard, recursively scanning home, trusting on-disk project settings as active, or assigning explicit outside activity to a default repository.
- result: deterministic implementation and regression evidence are present; fresh successful Remote evidence remains a separate post-merge gate.

## Progress Lifecycle Evidence

- start: Route Plan commit `9c10bae` preceded implementation.
- mid: the initial implementation reached a real Remote attempt, which exposed two concrete failures rather than producing a false success claim.
- pre-merge: boundary-fixture correction `b93d11619fddec58208000f9e6559b02fdf2359c` follows the last code/test finding; this Route Plan update records the exact implementation and evidence contract before final CI.

## Definition of Done

- [x] User-level installation is idempotent, exact-verifiable, reversible, and safely migrates modes.
- [x] Discovery is managed-only, bounded, deterministic, and symlink-safe.
- [x] Active native project hooks are deduplicated without suppressing inactive siblings.
- [x] All explicit path and repository targets are reconciled and malformed/conflicting targets fail unattributed.
- [x] Search patterns are not misclassified as filesystem paths.
- [x] The hard guard runs only after attribution and validates dispatcher commands under their actual hook events.
- [x] Repository state, policy, run IDs, events, and downstream matching remain isolated.
- [x] Required lifecycle handoff failures remain observable after full fan-out.
- [x] Complete Stop, StopFailure, and SessionEnd hooks are validated under their actual events.
- [x] Diagnostics and cache retention preserve the privacy and lifecycle contracts.
- [x] Automated coverage includes the live defects and every valid review finding.
- [x] The failed real Remote attempt is recorded honestly and successful closure gaps remain open.
- [x] PR evidence sections and conditional owner approval are recorded.

## Merge Gates

Merge remains blocked until every required workflow succeeds on one exact final head, the current-head review has no remaining valid finding, all fixed threads are resolved, and the PR body references that exact head and its evidence.

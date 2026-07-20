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
| Evidence to check | PR #250 exact-head Actions and review threads; official Claude Code documentation; live Remote failure evidence; focused positive and negative fixtures |
| User decisions required | none outstanding |

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| `core/task-router.md` | read | The change is Engineering OS governance and requires a Route Plan before implementation writes. |
| `core/workflow.md` | read | Experiment → fix → experiment, exact-head evidence, review correction, and conditional merge are mandatory. |
| Official Claude Code settings/hooks documentation | consulted | User-level settings load across sessions; project settings depend on project/session scope; hook blocks retain event and matcher scope. |
| `scripts/monitoring/require-telemetry-session.sh` | validated | The guard is fail-closed only for an attributed managed repository and requires catch-all PreToolUse guard/recorder coverage. |
| `scripts/monitoring/eos-telemetry-session-start.sh` | read | It remains the owner of repository-local run initialization and rotation. |
| `scripts/monitoring/eos-telemetry-event.sh` | read | It retains the metadata-only event schema. |
| `scripts/monitoring/record-and-sync-telemetry.sh` | validated | Repository, branch, head, bundle, push, and PR matching remain downstream and per repository. |
| PR #250 live Remote attempt | observed | Installation, verification, and dynamic hook loading worked; two runtime defects were reproduced. The attempt ended with a required restart, so fresh successful validation remains open. |

## Root Cause

A Remote session can start from a parent directory where repository-local hook settings are not active. A user-level bootstrap solves hook loading, but has no repository identity of its own. The initial implementation also treated partial settings and stale cache entries as sufficient evidence, allowed ambiguous repository identities, and did not preserve every user-settings security boundary.

The repair therefore treats repository identity, current policy opt-in, hook completeness, matcher scope, file permissions, and hook ownership as independently validated contracts.

## Architecture

### User-level installation

`install-user-level-telemetry-hooks.sh` manages `$HOME/.claude/settings.json` without sudo. It preserves unrelated entries, backs up and writes atomically, rejects malformed JSON, verifies exact commands and runtime paths, supports dry-run/uninstall, and removes stale direct-mode entries before installing dispatcher mode.

New settings are created with mode `0600`; existing file permissions are preserved. An entry is considered owned only when it contains an Engineering OS runtime marker and the expected action, so similarly named user hooks are not replaced.

### Discovery and project-hook coexistence

- Cwd is checked first; otherwise only immediate children are inspected.
- A repository must be its own Git root with a valid, regular, non-escaping policy marker.
- Direct project hooks suppress the dispatcher only for an actual native SessionStart and only when SessionStart, catch-all PreToolUse guard/recorder, and all lifecycle boundaries form a complete direct installation.
- Parent siblings, partial settings, and non-SessionStart cache misses remain dispatchable.
- Cached paths are revalidated against current Git-root and policy-marker state before every later event and fan-out; invalid entries are removed from the cache.

### Event attribution

All explicit targets are authoritative and must agree:

1. Actual path fields such as `file_path` and `path`, after realpath normalization. Search expressions such as `Grep.pattern` are not paths.
2. Every explicit GitHub/MCP repository identity form, normalized only when it has an exact `owner/repo` shape or a supported two-component Git URL.
3. Payload cwd only when no explicit target exists.
4. Sole-repository fallback only when the payload contains no routing signal.

Extra components are rejected rather than truncated. Multiple repository fields, multiple paths, and filesystem/repository targets must all agree. Malformed, incomplete, unmanaged, or conflicting evidence remains unattributed.

### Repository-scoped guard

User-level PreToolUse uses `eos-telemetry-dispatch.sh guard`. The dispatcher resolves and revalidates the repository before invoking the existing guard. The guard accepts commands only under the expected events and requires the guard plus recorder in a catch-all PreToolUse block (`matcher` absent or `.*`); a narrow matcher cannot satisfy required coverage.

Unmanaged or unattributed activity does not inherit another repository's enforcement.

### Isolation and boundaries

Each repository keeps its own run ID, events, policy, branch/head, bundle, and handoff state. Host correlation is additive only. Stop, StopFailure, and SessionEnd visit every currently valid repository and return a required handoff failure after sibling fan-out rather than swallowing it.

## Privacy and Security

- Only a currently valid explicit policy marker opts a repository in.
- No recursive monitoring is introduced.
- Raw prompts, responses, commands, full tool inputs, file contents, paths, environment values, and secrets are excluded from diagnostics and repository telemetry.
- Realpath and repository-boundary checks reject traversal and escaping symlinks.
- Explicit outside, malformed, extra-component, and conflicting targets cannot be overridden by cwd.
- Partial project settings cannot disable missing dispatcher enforcement.
- User settings permissions cannot be weakened by atomic replacement.
- Unrelated action-named user hooks remain untouched.

## Validation Matrix

Executable coverage includes:

- managed-only parent discovery and unmanaged exclusion;
- complete active direct hooks versus partial native hooks, inactive siblings, and mid-session cache misses;
- cached-marker revocation before later attribution, guard execution, recording, and fan-out;
- file, cwd, Grep path, and GitHub/MCP attribution;
- exact, malformed, incomplete, extra-component, agreeing, and conflicting repository identities;
- catch-all versus narrow PreToolUse matcher validation;
- marker-only dispatcher guard behavior and correct hook-event placement;
- settings mode `0600`, preservation of existing modes, and preservation of similarly named user hooks;
- required/best-effort/disabled policy isolation and boundary failure propagation;
- complete Stop/StopFailure/SessionEnd registration, product-head advancement, downstream handoff, and PR matching;
- resolver errors, cache retention, traversal, malformed inputs, and privacy-safe diagnostics.

## Live Claude Code Remote Evidence

The real pre-merge attempt proved installation, `--verify`, and dynamic hook loading. It reproduced inactive sibling suppression and a global false block from sole-repository fallback. This is valid failure evidence, not successful closure. `multirepo-remote-telemetry-validation`, `project-8-real-run-evidence`, and `monitoring-metrics-sufficiency` remain open until a fresh post-merge session succeeds.

## Documentation Asset Evidence

- internal: `docs/operations/remote-multirepo-telemetry-hooks.md`, `docs/operations/project8-telemetry-preflight.md`, `docs/operations/managed-settings-deployment-proof.md`, `architecture-decisions/ADR-2026-002-managed-settings-rollout.md`, `docs/operations/known-gaps.tsv`, and `docs/operations/operational-readiness-audit.md`.
- context7: not required because this change does not integrate an external library, framework, SDK, or API; official Claude Code settings/hooks documentation was checked directly.
- decision: the documentation supports a narrow user-level bootstrap restricted by current repository opt-in, exact attribution, and matcher-aware fail-closed enforcement.

## Capability Evidence

- `routing.task-router-read` — classified as Engineering OS governance and telemetry runtime work.
- `workflow.workflow-read` — plan-first, evidence checkpoints, exact-head validation, and conditional merge authorization were followed.
- `plan.route-plan-before-write` — Route Plan commit `4fe393c786cdc76fa05215524733191bf6b3b772` preceded implementation writes.
- `source.docs-read` — official Claude Code settings/hooks behavior informed event and matcher validation.
- `source.github-repo-read` — PR #250, Actions diagnostics, and all review threads were inspected through GitHub.
- `validation.policy-change-has-validator` — every changed runtime and security contract has positive and negative executable coverage.
- `validation.actions-checked` — `.github/workflows/telemetry-handoff-tests.yml` runs attribution, guard, coexistence, installer, failure-mode, and downstream fixtures.
- `validation.coderabbit-policy` — valid Codex and CodeRabbit findings are fixed before thread resolution and merge.
- security-sensitive change waiver: no waiver is used; repository identity, opt-in revocation, hook scope, permissions, ownership, traversal, privacy, and failure propagation are tested explicitly.

## Skill Evidence

- `security-review` — applied to repository opt-in, cached state, identity parsing, realpath boundaries, settings permissions, hook ownership, privacy-safe diagnostics, and fail-closed scope.
- `verification-before-completion` — completion is withheld until exact-head CI, current-head review, thread resolution, and merge verification are complete.

## Connector Evidence

- GitHub: required to inspect and update `yotamfried-ux/Engineering-OS`, read PR #250 reviews and Actions diagnostics, and validate the final head.
- Claude Code runtime: not used as a connector; its settings and hook behavior were checked through official documentation and the real Remote experiment.

## Connector Usage Evidence

- source: GitHub connector for `yotamfried-ux/Engineering-OS`.
- action: inspected PR #250, exact-head Actions, and every Codex/CodeRabbit thread; then updated runtime, focused tests, workflow evidence, runbook, gap registry, and audit.
- result: implementation commits through `e168a1eba9e286eeb4050dee8811ce6b186b7ce4` enforce complete direct-hook suppression, strict agreeing identities, cache revalidation, catch-all guards, secure settings modes, strict hook ownership, and permanent regressions.
- decision: kept the hard repository guard and durable-handoff pipeline while repairing every attribution and settings boundary at the root.
- target: `scripts/monitoring/`, focused telemetry tests, `.github/workflows/telemetry-handoff-tests.yml`, and `docs/operations/remote-multirepo-telemetry-hooks.md`.

## Claude Run Trace

- goal: obtain reliable per-repository telemetry from parent-started Remote sessions without monitoring unmanaged work or globally blocking the host.
- hypothesis: a narrow user-level bootstrap plus current opt-in validation and authoritative target reconciliation can safely reuse the repository-local pipeline.
- connectors: GitHub; Claude Code runtime was observed directly but was not used as a connector.
- steps: verify settings scope; create plan-first history; implement discovery/attribution/isolation; run a real Remote attempt; diagnose live failures; complete repeated review-fix loops covering project-hook completeness, guard routing and matchers, identities, cache validation, lifecycle propagation, mode migration, permissions, ownership, diagnostics, retention, and fixtures; checkpoint before exact-head validation.
- evidence: PR #250, plan-first commit `4fe393c786cdc76fa05215524733191bf6b3b772`, implementation history, live Remote report, Actions runs, review threads, focused fixtures, and runbook commit `e168a1eba9e286eeb4050dee8811ce6b186b7ce4`.
- rejected: disabling the guard, recursively scanning home, trusting partial settings or stale cache, truncating repository identities, weakening settings permissions, claiming similarly named user hooks, or assigning explicit outside activity to a default repository.
- result: deterministic implementation and regression evidence are present; fresh successful Remote evidence remains a separate post-merge gate.

## Progress Lifecycle Evidence

- start: Route Plan commit `4fe393c786cdc76fa05215524733191bf6b3b772` recorded approved scope and validation contracts before implementation.
- mid: implementation commit `ff974707978c0cfac72850233e1923f06ae20018` and checkpoint `855d1277c1e6f310cca18ec77ed60a1953f4e9c8` recorded the initial dispatcher implementation and real review outcome.
- pre-merge: security-review fixes through runbook commit `e168a1eba9e286eeb4050dee8811ce6b186b7ce4` follow all runtime and test changes; this separate checkpoint records the final contracts before exact-head CI and review.

## Definition of Done

- [x] User-level installation is exact, reversible, mode-safe, permission-safe, and preserves unrelated hooks.
- [x] Discovery is managed-only, bounded, deterministic, symlink-safe, and revalidates cached opt-in.
- [x] Only complete active native direct hooks suppress dispatcher coverage.
- [x] All explicit path and repository signals are strict, complete, and mutually consistent.
- [x] Search patterns are not misclassified as paths.
- [x] The hard guard runs only after current attribution and requires catch-all PreToolUse coverage.
- [x] Repository state, policy, run IDs, events, and downstream matching remain isolated.
- [x] Required lifecycle handoff failures remain observable after full fan-out.
- [x] Product-head advancement and complete lifecycle hooks are validated.
- [x] Diagnostics, retention, permissions, and ownership preserve the privacy contract.
- [x] Automated CI tests and focused positive/negative fixtures cover every valid review finding.
- [x] The failed real Remote attempt is recorded honestly and successful closure gaps remain open.
- [x] PR evidence sections and conditional owner approval are recorded.

## Merge Gates

Merge remains blocked until every required workflow succeeds on one exact final head, the current-head review has no remaining valid finding, all verified threads are resolved, and the PR body references that exact head and evidence.

# Remote Claude Telemetry Handoff

Date: 2026-07-13
Status: implementation and application-head validation complete; merge externally gated

## Route Plan

| Field | Value |
|---|---|
| Task type | bug / observability / CI |
| Task class | engineering_os_governance |
| Domain tags | observability, governance, testing, security |
| Plan Scope | standard |
| Planning Mode | approved |
| Templates | Not required |
| Architecture guides | `docs/operations/runtime-telemetry-archive-plan.md`; `docs/operations/operational-work-history.md` |
| Patterns | Not required |
| External systems/connectors | GitHub |
| Skills | Not required |
| Validation gates | enforcement-tests; telemetry-handoff-tests; pr-policy; plan-policy; workflow-evidence-policy; connector-evidence-policy; capability-evidence-policy; documentation-asset-policy; semantic-cleanup-policy; import-cleanup-policy |
| Evidence to check | `scripts/monitoring/sync-telemetry-run.py`; `scripts/monitoring/select-pr-telemetry.py`; `.github/workflows/pr-policy.yml`; `.github/workflows/telemetry-handoff-tests.yml`; `scripts/enforcement/check-live-review-threads.py`; `scripts/enforcement/tests/test-telemetry-policy-and-path-overrides.sh`; `scripts/enforcement/tests/test-telemetry-head-advancement.sh`; `lessons-learned/bugs/remote-workspace-telemetry-requires-durable-handoff.md` |
| User decisions required | explicit owner merge approval |
| Task-router evidence | `core/task-router.md` read; Engineering OS governance selected |
| Workflow evidence | `core/workflow.md` read; plan commit `e530ecc3dcea93458ba38b865ab617a9e185e19c` preceded implementation |
| Target paths | `scripts/monitoring/`; `.github/workflows/`; `scripts/enforcement/`; `docs/operations/`; `lessons-learned/bugs/remote-workspace-telemetry-requires-durable-handoff.md` |

## Template Gap Waiver

No template applies to repair of the existing telemetry runtime and policy workflows.

## Skill Evidence

No external skill is required; repository-native regression suites validate the change.

## Capability Evidence

- `routing.task-router-read` — routing source read.
- `workflow.workflow-read` — workflow source read.
- `plan.route-plan-before-write` — plan preceded implementation.
- `source.github-repo-read` — Project 8 PR #6, CI, OWH, and review threads inspected through GitHub.
- `validation.policy-change-has-validator` — positive and negative fixtures cover delivery, matching, privacy, concurrency, source paths, policy modes, product-head ancestry, OWH, CI history, and live threads.
- `validation.actions-checked` — modified workflows validated in live Actions.
- `validation.coderabbit-policy` — valid CodeRabbit and Codex findings were verified against current code, fixed when applicable, and covered by regression tests.

## Connector Evidence

- GitHub — source of truth for PR #6, OWH, workflow state, review threads, transport, and CI selection.

## Connector Usage Evidence

- source: GitHub repositories `yotamfried-ux/Engineering-OS` and `yotamfried-ux/project-8`.
- action: inspected merge `b6dd9a662a31e7ef1bad8c7e420450ab80c9ef26`, artifact `operational-work-history-6-29245891365`, runtime workflows, current Actions results, official GitHub workflow-run query limits, and live review threads.
- result: `scripts/monitoring/sync-telemetry-run.py`, `scripts/monitoring/select-pr-telemetry.py`, `.github/workflows/pr-policy.yml`, and `scripts/enforcement/check-live-review-threads.py` implement durable delivery, strict remote validation, canonical identity, safe product-head advancement, monotonic exact binding, bounded CI history, and live-state validation.
- decision: selected an isolated same-repository telemetry branch with trusted-base policy resolution and exact repository, PR, branch-hash, and CI-head matching; sync separately validates product-head ancestry before replacement; historical run retrieval is bounded from PR creation before local PR filtering.
- target: `scripts/monitoring/`; `.github/workflows/pr-policy.yml`; `.github/workflows/telemetry-handoff-tests.yml`; `scripts/enforcement/check-live-review-threads.py`.

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| `scripts/monitoring/eos-telemetry-event.sh` | read | previous events stayed in the remote Claude workspace |
| `scripts/monitoring/sync-telemetry-run.py` | validated | fetched bundles are fully validated before use; same or ancestor product heads can advance safely; descendant or unrelated heads, stale progress, and conflicting PR rebinds fail closed |
| `scripts/monitoring/require-telemetry-session.sh` | validated | `required` checks durable delivery while `best_effort` remains nonblocking after transport failure |
| `scripts/monitoring/export-telemetry-run.py` | validated | explicit and environment-selected telemetry event/run-id paths are exported consistently |
| `.github/workflows/pr-policy.yml` | validated | CI reads policy from the exact base SHA, retrieves an isolated telemetry branch, selects an exact matching bundle, bounds CI history from PR creation, and checks live review threads |
| `.github/workflows/telemetry-handoff-tests.yml` | validated | remote handoff, policy/path overrides, product-head advancement, and live-thread behavior run as named timeout-bounded stages |
| `lessons-learned/bugs/remote-workspace-telemetry-requires-durable-handoff.md` | validated | records the complete transport, identity, privacy, policy, source-path, ancestry, state, CI-history, and review-state prevention contract |

## Validation Evidence

- application/content head `8bc8682aa5719dcba8e4cd89df881fecc7b24aab` passed every stage in `enforcement-tests` run `29498660859`, including all grouped suites, the aggregate all-suites pass, and all eight repository contract checks;
- the same application/content head passed `telemetry-handoff-tests` run `29498660824`;
- named focused stages passed for remote workspace handoff, telemetry policy modes and source overrides, product-head advancement, and live review threads;
- the product-head regression proved that a validated ancestor-head bundle advances to the current descendant head, stale local durable state is rejected after a commit, and an older workspace cannot downgrade a newer remote head;
- negative coverage rejected wrong repository, selector PR, conflicting sync PR, branch hash, stale descendant head, unrelated history, stale local progress, checksum, empty bundle, raw field, array-nested secret, untrusted policy, and missing durable state;
- `best_effort` remained nonblocking without durable state while `required` remained fail-closed;
- custom event and run-id source paths were exported and synced without creating or reading silent default telemetry files;
- `pr-policy` run `29464405759` accepted the server-side `created` bound, generated OWH with 737 PR-associated runs across 76 head SHAs, and then failed at the deliberately unresolved live thread;
- every known review thread was resolved only after its finding was fixed or verified against exact focused evidence;
- verified lesson commit `c3afb8dc7c5893f13f6b5481fc5096d752514235` captured the complete failure variants and prevention rules after application validation.

## Definition of Done

- [x] Separate-workspace simulation produces non-empty telemetry.
- [x] Exact selector rejects wrong repository, PR, branch, stale head, empty, tampered, and privacy-invalid bundles.
- [x] OWH consumes non-zero events from a clean checkout.
- [x] Required preflight rejects missing durable state.
- [x] Best-effort preflight remains nonblocking after a transport failure.
- [x] Custom telemetry event and run-id paths are used consistently by validation and export.
- [x] Trusted base policy prevents a PR checkout from disabling required handoff.
- [x] Live unresolved current and outdated threads fail.
- [x] Stale provisional rebind persists exact local state and rejects a conflicting PR.
- [x] Product-head advancement permits only validated ancestor-to-descendant replacement and rejects stale downgrade or unrelated history.
- [x] PR CI history is bounded server-side from PR creation and remains locally PR-scoped.
- [x] Application/content head passed complete enforcement and all named telemetry handoff stages.
- [x] Verified lesson captures prevention and tests.

## Claude Run Trace

1. Inspected PR #6 and its zero-event OWH.
2. Reproduced the remote-workspace/clean-CI boundary.
3. Implemented isolated-branch delivery, exact selection, sequential hooks, and live-thread blocking.
4. Added positive and negative regression tests.
5. Used CI artifacts to correct repository identity and lifecycle evidence.
6. Applied Codex findings for provisional PR association and monotonic concurrent sync.
7. Replaced PR-controlled policy resolution with an exact-base trusted policy checkout.
8. Added array-scalar privacy scanning, a real missing-metadata fixture, repository mismatch coverage, named CI steps, and job timeouts.
9. Isolated the simulation registry mismatch from its named failing step and updated only the stale coverage token.
10. Reproduced and fixed the stale-provisional remote/local state race, including conflicting-PR rejection.
11. Applied the Codex CI-history finding with a server-side PR-created-at bound and wiring enforcement.
12. Added consistent custom telemetry source-path propagation and distinct `best_effort`/`required` preflight behavior.
13. Reproduced strict-head rejection after a normal commit and replaced it with fully validated same/ancestor/descendant/unrelated product-head handling.
14. Isolated product-head advancement as a named telemetry CI stage.
15. Verified the application/content head through complete enforcement and focused telemetry workflows.
16. Expanded the Verified Lesson after every runtime and workflow correction.

## Progress Lifecycle Evidence

- start: PR #6 evidence, telemetry runtime, CI workflow, installer, and live thread state were inspected before implementation; both false-green paths were reproduced.
- mid: exact selection, durable state, provisional/exact PR binding, monotonic sync, local-state convergence, explicit artifact availability, trusted-base policy resolution, array privacy validation, canonical identity, source-path consistency, policy-mode semantics, bounded CI history, and named CI isolation were implemented with focused regressions.
- pre-merge: application/content head `8bc8682aa5719dcba8e4cd89df881fecc7b24aab` passed complete `enforcement-tests` run `29498660859` and focused `telemetry-handoff-tests` run `29498660824`; the named product-head advancement regression proved safe ancestor replacement and stale downgrade rejection; all known review threads were resolved after evidence; verified lesson commit `c3afb8dc7c5893f13f6b5481fc5096d752514235` recorded the complete prevention contract after the last runtime and workflow changes.

## Merge Gate

Merge is blocked unless every required workflow passes on the exact evidence head, final live review state has no unresolved thread, and the owner gives separate explicit approval.

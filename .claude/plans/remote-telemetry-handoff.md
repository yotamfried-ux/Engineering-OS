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
| Patterns | metadata-only observability; fail-closed required delivery; independently monotonic progress; positive export schema |
| External systems/connectors | GitHub |
| Skills | Not required |
| Validation gates | enforcement-tests; telemetry-handoff-tests; pr-policy; plan-policy; workflow-evidence-policy; connector-evidence-policy; capability-evidence-policy; documentation-asset-policy; semantic-cleanup-policy; import-cleanup-policy |
| Evidence to check | `scripts/monitoring/sync-telemetry-run.py`; `scripts/monitoring/export-telemetry-run.py`; `scripts/monitoring/select-pr-telemetry.py`; `.github/workflows/pr-policy.yml`; `.github/workflows/telemetry-handoff-tests.yml`; `scripts/enforcement/check-live-review-threads.py`; `scripts/enforcement/tests/test-telemetry-policy-and-path-overrides.sh`; `scripts/enforcement/tests/test-telemetry-head-advancement.sh`; `scripts/enforcement/tests/test-telemetry-progress-ordering.sh`; `scripts/enforcement/tests/test-telemetry-export-allowlist.sh`; `lessons-learned/bugs/remote-workspace-telemetry-requires-durable-handoff.md` |
| User decisions required | explicit owner merge approval |
| Task-router evidence | `core/task-router.md` read; Engineering OS governance selected |
| Workflow evidence | `core/workflow.md` read; plan commit `e530ecc3dcea93458ba38b865ab617a9e185e19c` preceded implementation |
| Target paths | `scripts/monitoring/`; `.github/workflows/`; `scripts/enforcement/`; `docs/operations/`; `lessons-learned/bugs/remote-workspace-telemetry-requires-durable-handoff.md` |

## Template Gap Waiver

No template applies to repair of the existing telemetry runtime and policy workflows.

## Skill Evidence

No external skill was required; repository-native regression suites and live GitHub evidence validated the change.

## Capability Evidence

- `routing.task-router-read` — routing source read.
- `workflow.workflow-read` — workflow source read.
- `plan.route-plan-before-write` — plan preceded implementation.
- `source.github-repo-read` — Project 8 PR #6, CI, OWH, reviews, and live threads were inspected through GitHub.
- `validation.policy-change-has-validator` — positive and negative fixtures cover delivery, matching, privacy, custom paths, policy modes, product-head ancestry, independently monotonic event/boundary progress, export-schema allowlisting, OWH, CI history, and live threads.
- `validation.actions-checked` — modified workflows passed focused and complete live Actions runs.
- `validation.coderabbit-policy` — CodeRabbit and Codex findings were verified against current code; every valid finding was reproduced, fixed, and regression-tested.

## Connector Evidence

- GitHub — source of truth for PR #6, OWH, workflow state, review findings, thread resolution, transport, and CI selection.

## Connector Usage Evidence

- source: GitHub repositories `yotamfried-ux/Engineering-OS` and `yotamfried-ux/project-8`.
- action: inspected merge `b6dd9a662a31e7ef1bad8c7e420450ab80c9ef26`, artifact `operational-work-history-6-29245891365`, runtime workflows, Actions results, official workflow-run query constraints, reviews, and live review threads.
- result: `scripts/monitoring/sync-telemetry-run.py`, `scripts/monitoring/export-telemetry-run.py`, `scripts/monitoring/select-pr-telemetry.py`, `.github/workflows/pr-policy.yml`, and `scripts/enforcement/check-live-review-threads.py` implement durable delivery, complete remote validation, canonical identity, safe product-head advancement, independently monotonic progress, positive export allowlisting, bounded CI history, and live-state validation.
- decision: selected an isolated same-repository telemetry branch with trusted-base policy resolution and exact repository, PR, branch-hash, and CI-head matching; sync validates product-head ancestry before replacement, rejects incomparable event/boundary states, and export reconstructs events only from the approved metadata schema.
- target: `scripts/monitoring/`; `.github/workflows/pr-policy.yml`; `.github/workflows/telemetry-handoff-tests.yml`; `scripts/enforcement/check-live-review-threads.py`.

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| `scripts/monitoring/eos-telemetry-event.sh` | read | previous events stayed in the remote Claude workspace |
| `scripts/monitoring/sync-telemetry-run.py` | validated | fetched bundles are fully validated; product-head ancestry is checked; event count and lifecycle boundary are compared independently; incomparable or regressing progress fails closed |
| `scripts/monitoring/export-telemetry-run.py` | validated | explicit and environment-selected sources are honored and every exported event is reconstructed from an approved top-level and nested allowlist |
| `scripts/monitoring/require-telemetry-session.sh` | validated | `required` checks durable delivery while `best_effort` remains nonblocking after transport failure |
| `.github/workflows/pr-policy.yml` | validated | CI reads policy from the exact base SHA, retrieves an isolated telemetry branch, selects an exact matching bundle, bounds CI history from PR creation, and checks live review threads |
| `.github/workflows/telemetry-handoff-tests.yml` | validated | remote handoff, policy/path overrides, product-head advancement, progress ordering, export allowlisting, and live-thread behavior run as named timeout-bounded stages |
| `lessons-learned/bugs/remote-workspace-telemetry-requires-durable-handoff.md` | validated | records the transport, identity, privacy, policy, source-path, ancestry, partial-order progress, export-schema, state, CI-history, and review-state prevention contract |

## Validation Evidence

- application/content head `b8f974a35b780b960afbbe7db8aa8f0dae18216f` passed every stage in `enforcement-tests` run `29501895512`, including grouped A-Z suites, the aggregate all-suites pass, and all repository contract checks;
- the same application/content head passed `telemetry-handoff-tests` run `29501895601`;
- named focused stages passed for remote workspace handoff, telemetry policy modes and source overrides, product-head advancement, telemetry progress ordering, telemetry export allowlisting, and live review threads;
- progress-ordering failure was reproduced before repair in run `29500646182`; the corrected check rejects a local bundle that leads in event count while lagging in lifecycle-boundary position;
- export leakage was reproduced before repair in run `29500578566`; the corrected exporter strips unknown top-level, resource, status, attribute, nested-path, and span-event fields from caller-selected sources;
- negative coverage rejects wrong repository, selector PR, conflicting sync PR, branch hash, stale descendant head, unrelated history, stale or incomparable progress, checksum mismatch, empty bundle, raw field, array-nested secret, unknown export fields, untrusted policy, and missing durable state;
- `best_effort` remained nonblocking without durable state while `required` remained fail-closed;
- custom event and run-id paths were exported and synced without creating or reading silent default telemetry files;
- live `pr-policy` run `29464405759` accepted the server-side `created` bound, generated OWH with 737 PR-associated runs across 76 head SHAs, and then failed at the deliberately unresolved live thread;
- both final Codex threads were resolved only after the failing reproductions and exact passing evidence were recorded;
- verified lesson commit `5c8d73e1e8fa454f1d24b9dd4675a635b5d05136` captured the final progress-ordering and export-privacy failure variants after application validation.

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
- [x] Event-count and lifecycle-boundary progress are monotonic independently; incomparable progress fails closed.
- [x] Caller-selected telemetry sources are reconstructed through a positive export schema allowlist.
- [x] PR CI history is bounded server-side from PR creation and remains locally PR-scoped.
- [x] Application/content head passed complete enforcement and every named telemetry handoff stage.
- [x] Verified Lesson captures the complete prevention and regression contract.

## Claude Run Trace

1. Inspected PR #6 and its zero-event OWH.
2. Reproduced the remote-workspace/clean-CI boundary.
3. Implemented isolated-branch delivery, exact selection, sequential hooks, and live-thread blocking.
4. Added positive and negative regression tests.
5. Used CI artifacts to correct repository identity and lifecycle evidence.
6. Applied review findings for provisional PR association and monotonic concurrent sync.
7. Replaced PR-controlled policy resolution with an exact-base trusted policy checkout.
8. Added array-scalar privacy scanning, a real missing-metadata fixture, repository mismatch coverage, named CI steps, and job timeouts.
9. Reproduced and fixed stale remote/local state divergence, conflicting PR binding, bounded CI-history retrieval, custom-path propagation, policy-mode behavior, and descendant-head advancement.
10. Reproduced the final progress partial-order defect in run `29500646182` and the export allowlist defect in run `29500578566` before modifying runtime.
11. Implemented independent event/boundary comparison and explicit telemetry export reconstruction.
12. Passed focused run `29501895601` and complete enforcement run `29501895512` on application head `b8f974a35b780b960afbbe7db8aa8f0dae18216f`.
13. Expanded the Verified Lesson and resolved both final Codex threads only after evidence.

## Progress Lifecycle Evidence

- start: PR #6 evidence, telemetry runtime, CI workflow, installer, and live thread state were inspected before implementation; the remote-workspace/clean-CI false green was reproduced.
- mid: exact selection, durable state, provisional/exact PR binding, trusted-base policy, privacy validation, canonical identity, source-path consistency, policy-mode semantics, bounded CI history, product-head ancestry, named CI isolation, independently monotonic progress, and positive export allowlisting were implemented through repeated focused result loops.
- pre-merge: application/content head `b8f974a35b780b960afbbe7db8aa8f0dae18216f` passed complete `enforcement-tests` run `29501895512` and focused `telemetry-handoff-tests` run `29501895601`; failing reproductions `29500646182` and `29500578566` proved both final defects before repair; all known review threads were resolved after passing evidence; verified lesson commit `5c8d73e1e8fa454f1d24b9dd4675a635b5d05136` recorded the complete prevention contract after the last runtime and workflow changes.

## Final Pre-Merge Checkpoint — 2026-07-16

- pre-merge: final application head `4e7f9d1faa0d6018e8d22ead60d0e42bf23230fe` passed seven focused regressions in helper run `29508718994`; Verified Lesson commit `3c6e7cb22e8a4ec25867f22ecdc1c4227841611e` recorded bounded shallow-history recovery, strict UTF-8 privacy input, event-derived boundary validation, and unique atomic state writes after the last runtime correction; focused run `29508908367` passed every telemetry job and complete run `29508908285` passed every enforcement stage, grouped A-Z suites, aggregate execution, and repository contract check after that lesson without another runtime change.

## Merge Gate

Merge is blocked unless every required workflow passes on the exact evidence head, final live review state has no unresolved thread, and the owner gives separate explicit approval.

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
| Evidence to check | `scripts/monitoring/sync-telemetry-run.py`; `scripts/monitoring/select-pr-telemetry.py`; `.github/workflows/pr-policy.yml`; `scripts/enforcement/check-live-review-threads.py`; `lessons-learned/bugs/remote-workspace-telemetry-requires-durable-handoff.md` |
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
- `validation.policy-change-has-validator` — positive and negative fixtures cover delivery, matching, privacy, concurrency, OWH, CI history, and live threads.
- `validation.actions-checked` — modified workflows validated in live Actions.
- `validation.coderabbit-policy` — valid CodeRabbit and Codex findings were verified against current code, fixed when applicable, and covered by regression tests.

## Connector Evidence

- GitHub — source of truth for PR #6, OWH, workflow state, review threads, transport, and CI selection.

## Connector Usage Evidence

- source: GitHub repositories `yotamfried-ux/Engineering-OS` and `yotamfried-ux/project-8`.
- action: inspected merge `b6dd9a662a31e7ef1bad8c7e420450ab80c9ef26`, artifact `operational-work-history-6-29245891365`, runtime workflows, current Actions results, official GitHub workflow-run query limits, and live review threads.
- result: `scripts/monitoring/sync-telemetry-run.py`, `scripts/monitoring/select-pr-telemetry.py`, `.github/workflows/pr-policy.yml`, and `scripts/enforcement/check-live-review-threads.py` implement durable delivery, monotonic exact binding, bounded CI history, and live-state validation.
- decision: selected an isolated same-repository telemetry branch with trusted-base policy resolution and exact repository, PR, branch-hash, and head matching; bounded historical run retrieval from PR creation before local PR filtering.
- target: `scripts/monitoring/`; `.github/workflows/pr-policy.yml`; `scripts/enforcement/check-live-review-threads.py`.

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| `scripts/monitoring/eos-telemetry-event.sh` | read | previous events stayed in the remote Claude workspace |
| `scripts/monitoring/sync-telemetry-run.py` | validated | stale syncs preserve newer remote progress, persist the effective exact PR binding locally, and reject conflicting PR rebinds |
| `.github/workflows/pr-policy.yml` | validated | CI reads policy from the exact base SHA, retrieves an isolated telemetry branch, selects an exact matching bundle, bounds CI history from PR creation, and checks live review threads |
| `scripts/monitoring/require-telemetry-session.sh` | validated | required mode checks durable handoff state rather than treating local recording as delivery |
| `lessons-learned/bugs/remote-workspace-telemetry-requires-durable-handoff.md` | validated | records the root cause, concurrency/state prevention rules, CI history bound, and regression evidence |

## Validation Evidence

- application/content head `c74d62bc85afe69929329f813bbd5bb001ba5bcb` passed all 26 steps in `enforcement-tests` run `29464405770`;
- the same head passed both jobs in `telemetry-handoff-tests` run `29464405805`;
- the named remote handoff test produced non-empty separate-workspace syncs and ended with `remote telemetry handoff tests passed`;
- negative coverage rejected repository, selector PR, conflicting sync PR, branch-hash, exact-head, checksum, empty-bundle, raw-field, array-nested-secret, untrusted-policy, stale-overwrite, and missing-durable-state cases;
- the stale provisional rebind simulation proved that a newer remote bundle can become exact without leaving local durable state provisional;
- the live review-thread suite rejected unresolved current, unresolved outdated, and missing-metadata fixtures;
- `pr-policy` run `29464405759` accepted the server-side `created` bound, generated OWH with 737 PR-associated runs across 76 head SHAs, and then failed at the deliberately unresolved live thread;
- installer coverage, Project 8 telemetry readiness, telemetry archive export/import/analyze, simulation coverage, result-loop, scaling, and generated-target installation tests passed in the full enforcement run;
- every review thread found before this evidence commit was resolved only after its finding was fixed or verified against live evidence.

## Definition of Done

- [x] Separate-workspace simulation produces non-empty telemetry.
- [x] Exact selector rejects wrong repository, PR, branch, stale head, empty, tampered, and privacy-invalid bundles.
- [x] OWH consumes non-zero events from a clean checkout.
- [x] Required preflight rejects missing durable state.
- [x] Trusted base policy prevents a PR checkout from disabling required handoff.
- [x] Live unresolved current and outdated threads fail.
- [x] Stale provisional rebind persists exact local state and rejects a conflicting PR.
- [x] PR CI history is bounded server-side from PR creation and remains locally PR-scoped.
- [x] Application/content head passed all 26 enforcement steps and both named handoff jobs.
- [x] Provisional PR binding and stale concurrent overwrite findings have regression coverage.
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
11. Applied the final Codex CI-history finding with a server-side PR-created-at bound and wiring enforcement.
12. Verified the application/content head through the complete enforcement and telemetry workflows.

## Progress Lifecycle Evidence

- start: PR #6 evidence, telemetry runtime, CI workflow, installer, and live thread state were inspected before implementation; both false-green paths were reproduced.
- mid: exact selection, durable state, provisional/exact PR binding, monotonic sync, local-state convergence, explicit artifact availability, trusted-base policy resolution, array privacy validation, bounded CI history, and named CI isolation were implemented with focused regressions.
- pre-merge: application/content head `c74d62bc85afe69929329f813bbd5bb001ba5bcb` passed all 26 enforcement steps and both named telemetry-handoff jobs; the focused artifact recorded non-empty remote sync and a passing handoff suite, the live query generated complete PR-scoped OWH inside the documented API bound, and all known review threads were resolved. Final evidence-head policy execution and separate owner approval remain outside the application commit.

## Merge Gate

Merge is blocked unless every required workflow passes on the exact evidence head, final live review state has no unresolved thread, and the owner gives separate explicit approval.

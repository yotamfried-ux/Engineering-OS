# PR and Telemetry-Gap Remediation

Plan Scope: standard

| Field | Value |
|---|---|
| Task type | governance remediation — PR review, audit follow-up, and enforcement/doc fixes |
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | audit, operational-readiness, telemetry, pr-policy, quality-gates, known-gaps |
| Plan Scope | standard |
| Planning Mode | approved — user explicitly approved proceeding with this plan's scope in the current conversation |
| Target paths | docs/operations, core/quality-gates.md, scripts/monitoring, scripts/enforcement, .github/workflows/pr-policy.yml, .claude/plans/pr-and-telemetry-remediation.md |
| Templates | not required |
| Architecture guides | not required — no new architecture/scaffold introduced, only governance-script and documentation edits |
| Patterns | governance validator pattern |
| External systems/connectors | github, notion |
| Skills | superpowers, security-review |
| Validation gates | enforcement-tests, workflow-evidence-policy, capability-evidence-policy, connector-evidence-policy, documentation-asset-policy, plan-policy, pr-policy |
| Evidence to check | patterns/ governance validator pattern; docs/operations/operational-readiness-audit.md; docs/operations/known-gaps.tsv; graphify graph.json |
| User decisions required | none — the branch/PR strategy and the plan-first history rewrite were both explicitly confirmed with the user in the current conversation |

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`

## Connector Evidence

- github: read open PRs (#247, and closed #199/#200/#201 for history), `docs/operations/operational-readiness-audit.md`, `docs/operations/known-gaps.tsv`, `docs/operations/runtime-telemetry-archive-audit-checklist.md`, `docs/operations/project8-telemetry-preflight.md` before implementation. Read the `yotamfried-ux/project-8` repo (read-only) to check its current `pr-policy.yml`/`.engineering-os/telemetry-policy.json` state without running the real experiment.
- notion: unavailable; fallback plan file used for progress tracking.

## Connector Usage Evidence

- source: github `pull_request_read` on #199, #200, #201, #247.
- action: compared each PR's body claims against its live, current state (merged/closed/draft) and real check-run history rather than trusting PR-body prose.
- result: #199 and #200 are merged; #201 is closed unmerged (its Route Plan was genuinely written after the code, by the PR's own admission, and rebasing to fake plan-first order was rejected as dishonest); #247 is an open draft that already recreated the telemetry work referenced by #201 (B2) on `main` via merged PRs #244/#245/#246, and left a remediation checklist with Phase B (telemetry gap) and Phase C (process gap) items unchecked.
- decision: reuse the existing checklist and audit findings instead of re-deriving them from scratch; scope this session's real work to the concrete open items that are achievable inside this repo (B1, B4, C1, C2) and correct the checklist's B2 status to reflect that it already shipped on `main`. Leave B3 (the real Project 8 experiment) explicitly gated and unchecked, per the user's instruction not to run another data-collection experiment until every item is resolved with real evidence.
- target: docs/operations/pr-and-telemetry-remediation-2026-07.md, docs/operations/project8-telemetry-preflight.md, scripts/enforcement/check-pr-review-evidence.sh, core/quality-gates.md, scripts/monitoring/eos-telemetry-event.sh.

## Progress Lifecycle Evidence

- start: this plan is committed before any code/doc changes for B1/B4/C1/C2.
- mid: the checklist, `project8-telemetry-preflight.md` wording fix, `check-pr-review-evidence.sh` stale-CI check, `quality-gates.md` DoD-paradox policy text, `enforce-quality.sh` advisory check, and `eos-telemetry-event.sh` gen_ai.* attributes all landed in the code/doc commit that followed this plan; each item's own test suite ran green locally before that commit.
- pre-merge: CI, review threads, mergeability, and expected head SHA must be checked live in GitHub before merge.

## Skill Evidence

- superpowers
- security-review

## Template/Pattern Rating Evidence

- asset: governance validator pattern (same pattern used by `check-known-gaps.sh`, `check-pr-review-evidence.sh`).
- rating: 4 medium confidence.
- outcome: reused the shell/Python semantic validator plus positive/negative fixture pattern for the new stale-Merge-Readiness check (C1), and reused the existing "Live External Gates Before Merge" plan-file convention (already used ad hoc in `.claude/plans/audit-freshness-p0.md`) as the documented fix for the DoD checkbox-ordering paradox (C2) instead of inventing a new mechanism.
- decision: keep preferred for governance/enforcement changes because it gives deterministic failure modes and avoids inventing new conventions where a proven one already exists in this repo.

## Graphify Usage Evidence

- source: graphify `graph.json` (1088 nodes), query `graphify explain "check-pr-review-evidence"`.
- action: queried the context graph for `check-pr-review-evidence.sh` before reading/editing it, to find its callers/dependents ahead of adding the C1 stale-SHA check.
- result: the node is a single-file, low-degree community (`check-pr-review-evidence.sh`) with no cross-file callee edges captured in the graph, confirming the script's stale-check logic can be extended in place without a hidden caller contract elsewhere in the graph.
- decision: extend `check-pr-review-evidence.sh` directly for C1 rather than adding a new indirection layer, since the graph shows no other module depends on its current internal structure.
- target: scripts/enforcement, docs/operations, core/quality-gates.md, scripts/monitoring, .claude/plans, .github/workflows

## Documentation Asset Evidence

- asset: `docs/operations/operational-readiness-audit.md`, `docs/operations/known-gaps.tsv`, `docs/operations/runtime-telemetry-archive-audit-checklist.md`, `docs/operations/project8-telemetry-preflight.md`.
- reason: these are the canonical source-of-truth documents for readiness status and the telemetry data-collection gap; the task explicitly requires reading them before proposing a remediation plan.

## Source of Truth Checks

| Source | Status |
|---|---|
| docs/operations/operational-readiness-audit.md | checked |
| docs/operations/known-gaps.tsv | checked |
| docs/operations/runtime-telemetry-archive-audit-checklist.md | checked |
| docs/operations/project8-telemetry-preflight.md | checked |
| docs/research/official-patterns-adoption-audit.md | checked |
| github.com/yotamfried-ux/Engineering-OS/pull/199 | checked |
| github.com/yotamfried-ux/Engineering-OS/pull/200 | checked |
| github.com/yotamfried-ux/Engineering-OS/pull/201 | checked |
| github.com/yotamfried-ux/Engineering-OS/pull/247 | checked |
| scripts/monitoring/eos-telemetry-event.sh | checked |
| scripts/monitoring/eos-telemetry-summary.py | checked |
| scripts/enforcement/check-pr-review-evidence.sh | checked |
| core/quality-gates.md | checked |
| opentelemetry.io/docs/specs/semconv/registry/attributes/gen-ai | checked |
| docs.github.com/en/rest/checks/runs | checked |

## Template Gap Waiver

reason: internal governance/documentation/enforcement change; no project template applies.

## Claude Run Trace

- goal: turn the open PR review + audit + telemetry-gap review into a concrete, trackable remediation plan, and close as many of its real open items as are safely achievable in this repo without running the gated Project 8 experiment.
- hypothesis: a prior session (PR #247, same day) already did the PR review and audit review and left a checklist; the highest-value move is to continue that checklist rather than re-derive a competing plan, since B2 (telemetry recreation) turned out to already be merged to `main` and only needed the checklist corrected.
- experiment: (1) diffed PR #247's checklist against the real state of `main` (scripts/monitoring/*, `.claude/settings.json`) to find B2 was actually done; (2) grepped for the literal claims in B1 (hook-reload wording), B4 (`gen_ai.*` fields), C1 (stale-check script) and C2 (DoD paradox fix) to confirm none of the four had landed yet; (3) fetched official OpenTelemetry GenAI semantic-convention and GitHub Checks API documentation to validate the proposed field names and stale-check approach against real official sources rather than assumption.
- steps: (1) read the audit/known-gaps/checklist docs; (2) inspected PRs #199/#200/#201/#247 via `pull_request_read`; (3) diffed the prior checklist's claims against real `main` state; (4) researched official connectors/documentation (OpenTelemetry, GitHub REST API) before writing B4/C1; (5) implemented B1/B4/C1/C2 with fixtures; (6) read-only inspected the `project-8` connector repo for B3's real blockers; (7) updated the checklist and this plan's DoD from real, verified outcomes only.
- connectors: github (PR/check-run inspection on Engineering OS and read-only inspection of the `project-8` repo, added via `add_repo`); no Notion access in this session, so this plan file is the fallback progress-tracking artifact.
- evidence: direct `main`-state inspection (`ls scripts/monitoring/`, `grep telemetry .claude/settings.json`) superseded the prior checklist's own claim; local test runs (`test-pr-review-evidence.sh`, `test-eos-telemetry.sh`, `test-quality.sh`) are the acceptance evidence for C1/B4/C2, not assumption.
- rejected: rejected re-deriving a competing plan from scratch instead of reusing PR #247's checklist (see Alternatives Considered); rejected attempting B3 now, since the user explicitly gated the next experiment on every other item first.
- result: B2 is done (evidence: `scripts/monitoring/eos-telemetry-event.sh` and its sibling scripts exist on `main`, wired into `.claude/settings.json`, via merged PRs #244/#245/#246). B1, B4, C1, C2 are genuinely open, now implemented, and fixture-verified. B3 (the real Project 8 run) is correctly still gated open and is out of scope for this plan by design.
- follow-up: after B1/B4/C1/C2 land and CI is green on the real head SHA, re-read `docs/operations/operational-readiness-audit.md` — note that closing `monitoring-metrics-sufficiency`/`project-8-real-run-evidence` still requires the real B3 run, not this PR.

## Alternatives Considered

- Start a brand-new competing plan/PR instead of reusing PR #247's checklist: rejected — it already did the real PR/audit review correctly and duplicating it wastes effort and risks contradicting its findings.
- Rebase closed PR #201 to look plan-first: rejected by explicit prior user decision as dishonest; superseded by the already-merged fresh recreation (B2).
- Attempt the real Project 8 experiment (B3) now: rejected — the user explicitly asked for the plan/tracker first and to gate the next experiment on every other item being resolved with real evidence.
- Make CI-dependent DoD items "CI-computed" via new automation instead of a doc-only policy fix (C2): rejected for this PR as higher-risk/larger scope than needed; the existing "Live External Gates Before Merge" convention already solves it and only needed to be documented as the required pattern.

## Affected Surfaces

- `docs/operations/` (checklist, preflight doc).
- `scripts/enforcement/check-pr-review-evidence.sh` and its test fixtures (C1).
- `core/quality-gates.md` (C2 policy text).
- `scripts/monitoring/eos-telemetry-event.sh` and its test fixtures (B4).
- No production runtime, no target-project code, is touched.

## Data/State Impact

- No data migrations. Telemetry attribute additions in B4 are additive-only (existing `eos.claude.*` fields are unchanged) so existing consumers (`eos-telemetry-summary.py`, export/import/sync scripts, archive fixtures) keep working unmodified.

## Integration Impact

- C1 changes `check-pr-review-evidence.sh`'s behavior only when a caller passes `--head-sha` (the `pr-policy.yml` CI workflow already does); no change when the flag is absent, so existing fixture calls without it are unaffected.
- No connector/config changes to GitHub Actions workflows in this PR.

## Validation Plan

- Run `scripts/enforcement/tests/test-pr-review-evidence.sh` after the C1 change (add a stale-SHA negative fixture and a matching-SHA positive fixture).
- Run `scripts/enforcement/tests/test-eos-telemetry.sh` after the B4 change (assert the new `gen_ai.*` attributes are present and existing `eos.claude.*` attributes are unchanged).
- Manually diff `project8-telemetry-preflight.md` before/after to confirm the operational instruction (open a fresh session) is unchanged, only the justification text.
- Re-read the updated checklist end to end to confirm every checkbox state matches real, cited evidence (no aspirational checks).

## Open Questions

- None blocking. B3 (the real Project 8 experiment) is deliberately left as a separate future step, not an open question in this plan.

## DoD

- [x] Checklist `docs/operations/pr-and-telemetry-remediation-2026-07.md` created on this branch, with B2 corrected to reflect it already shipped on `main`.
- [x] B1: `project8-telemetry-preflight.md` hook-reload claim corrected to the precise, officially accurate reason.
- [x] C1: stale Merge-Readiness-vs-live-CI check added to `check-pr-review-evidence.sh` (or a dedicated script it calls), with a passing positive fixture and a failing negative (stale-claim) fixture.
- [x] C2: DoD checkbox-ordering paradox fix documented in `core/quality-gates.md`, codifying the existing "Live External Gates Before Merge" convention as the required pattern for CI-dependent items, plus a non-blocking advisory check in `enforce-quality.sh` (its md-sync enforcer) with passing fixtures.
- [x] B4: `gen_ai.*` OpenTelemetry GenAI semantic-convention attributes added additively, alongside (not replacing) the existing `eos.claude.model` and related fields, to `eos-telemetry-event.sh`, with a passing test.
- [x] Project 8 repo state inspected read-only (no writes, no experiment run) to confirm B3's real current blockers for the tracker.
- [x] `docs/operations/pr-and-telemetry-remediation-2026-07.md` updated to reflect the true final state of every item touched by this PR.
- [x] Tests for touched scripts pass locally.

## Live External Gates Before Merge

These gates are intentionally not represented as unchecked plan checklist items because `plan-policy` treats every unchecked plan checkbox as a blocker. They must be verified directly against the PR head before merge:

- GitHub Actions passed on the final PR head.
- Review threads are resolved or outdated after the final PR head.
- Mergeability and expected head SHA are checked immediately before merge.
- B3 (the actual Project 8 telemetry-gap-closing experiment) is explicitly NOT a merge gate for this PR — it is deliberately left open in the checklist and must not be run until every other Phase B/C item is checked with real evidence, per the user's instruction.

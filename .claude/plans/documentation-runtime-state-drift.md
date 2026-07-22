# Route Plan — Documentation Runtime State Reconciliation

## Route Plan

| Field | Decision |
|---|---|
| Task type | governance documentation reconciliation / deterministic stale-claim prevention / audit lifecycle update |
| Task class | `engineering_os_governance` |
| Domain tags | documentation-as-code, runtime truth, capabilities, review governance, testing, operational readiness |
| Plan Scope | standard |
| Planning Mode | user-authorized continuation after merged PR #255; implementation PR remains owner-gated |
| Target paths | `.claude/plans/documentation-runtime-state-drift.md`; `CLAUDE.md`; `README.md`; `core/coderabbit-policy.md`; `scripts/enforcement/check-documentation-hygiene.sh`; `scripts/enforcement/tests/test-documentation-hygiene.sh`; `docs/operations/live-state-claims.json`; `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md` |
| Task-router evidence | `core/task-router.md` routes entrypoint, policy, validator, and readiness changes as `engineering_os_governance`. |
| Workflow evidence | `core/workflow.md`, `core/quality-gates.md`, `core/git-policy.md`, `core/documentation-policy.md`, and `core/coderabbit-policy.md` require plan-first work, fixtures, exact-head review, owner approval, and post-merge proof. |
| Templates | waiver — this extends existing canonical documentation and enforcement paths |
| Architecture guides | `core/documentation-policy.md`; `docs/operations/documentation-ownership.tsv`; `docs/operations/operational-readiness-audit.md` |
| Patterns | none — no application pattern owns documentation-state reconciliation |
| External systems/connectors | GitHub |
| Skills | `verification-before-completion`; `writing-plans` |
| Validation gates | documentation-hygiene fixtures; known-gaps; readiness; enforcement-tests; documentation, plan, workflow, connector, capability, cleanup, telemetry, pr-policy, live-state, review-thread, and post-merge gates |
| Evidence to check | `CLAUDE.md`; `README.md`; `core/capability-registry.yaml`; `core/coderabbit-policy.md`; checker/fixtures; PR #255 head `97d56e2f5743b019145da600cf0914f6d092cd0f`; merge `0ee2dbee7a9ab58e86a11726021c30baca0faa22`; official Anthropic, GitHub Docs, and CodeRabbit sources |
| User decisions required | keep Project 8 and its prompt blocked; do not merge PR #256 without new explicit approval |

## Goal

Align active documentation with executable runtime truth. The capability registry remains authoritative, README stops duplicating volatile counts, CodeRabbit uses current PR evidence with structured fallback, and the existing documentation-hygiene gate blocks recurrence. PR #255 is registered as the live closure claim; the current documentation gap remains open through its own merge and post-merge proof.

## Non-negotiable behavior

1. Capability runtime status comes from `core/capability-registry.yaml`.
2. Maintained README inventory rows contain no numeric snapshots.
3. Observed or pending CodeRabbit feedback blocks; proven absence uses structured fallback; fabricated success is forbidden.
4. Checks cover active canonical surfaces, not historical plans.
5. No Project 8 or provider-state change.
6. Current-gap closure requires tests, exact-head CI, review, owner-approved merge, and post-merge evidence.

## Plan

1. Align CLAUDE runtime wording.
2. Remove README count snapshots.
3. Align CodeRabbit availability/fallback policy.
4. Extend the existing checker and fixtures.
5. Register and live-validate PR #255 closure.
6. Synchronize registry/audit while retaining the current gap as open.
7. Run exact-head result loops and reconcile review.

## Alternatives

- Refresh the counts — rejected because drift recurs.
- Generate counts — rejected because low-value numbers create churn.
- Assume permanent reviewer availability/unavailability — rejected because it is live state.
- Add another registry — rejected because canonical owners exist.
- Rewrite historical plans — rejected because they are dated evidence.

## Source of Truth Checks

| Source | Status | Finding / decision |
|---|---|---|
| `core/task-router.md` | read | Engineering OS governance route. |
| `core/workflow.md` | read | Plan-first result loops apply. |
| `core/documentation-policy.md` | read | One owner plus deterministic fixtures. |
| `core/capability-registry.yaml` | checked | Active `plan_level_write_gate`; old planned wording was stale. |
| `CLAUDE.md` | checked | Runtime and live-review/fallback wording reconciled. |
| `README.md` | checked | Count snapshots replaced by live inventory links. |
| `core/coderabbit-policy.md` | checked | Observed review and fallback are explicit branches. |
| `scripts/enforcement/check-documentation-hygiene.sh` | checked | Three invariants enforced on active surfaces. |
| `scripts/enforcement/tests/test-documentation-hygiene.sh` | checked | Positive and negative drift fixtures added. |
| `github/docs/src/content-linter/lib/linting-rules/index.ts` | read | Executable custom documentation rules. |
| `https://code.claude.com/docs/en/memory` | read | Shared project memory must remain current. |
| `https://docs.coderabbit.ai/guides/code-review-overview` | read | Review depends on live integration and PR state. |

## Official Documentation Evidence

- `https://code.claude.com/docs/en/memory`
- `https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-readmes`
- `https://docs.coderabbit.ai/guides/code-review-overview`
- `https://docs.coderabbit.ai/configuration/auto-review`
- `https://docs.coderabbit.ai/guides/configuration-overview`

## Official Repository Evidence

- `github/docs/src/content-linter/lib/linting-rules/index.ts`
- `github/docs/src/content-linter/lib/linting-rules/hardcoded-data-variable.ts`
- `anthropics/claude-code`

## Documentation Asset Evidence

- internal: all target paths plus the capability registry and ownership manifest.
- context7: official URLs and repository paths above were read directly; no SDK is introduced.
- decision: use executable owners, remove snapshots, and enforce live reviewer-or-fallback semantics.

## Template Gap Waiver

reason: this is a focused extension of canonical governance files and the existing documentation checker.

## Capability Evidence

- `routing.task-router-read` — `engineering_os_governance`.
- `workflow.workflow-read` — plan-first and post-merge proof applied.
- `plan.route-plan-before-write` — `13d6e8456b6c75db03eb31a8393a505adc3e8ac7` preceded implementation.
- `source.github-repo-read` — canonical and official repositories inspected.
- `validation.policy-change-has-validator` — every rule has fixtures.
- `validation.actions-checked` — exact-head/live-state gates remain required.
- `validation.coderabbit-policy` — live review and fallback both represented.

## Skill Evidence

- `verification-before-completion` — implementation, CI, review, merge, and closure are distinct.
- `writing-plans` — scope, alternatives, sources, validation, and lifecycle recorded.

## Connector Evidence

| Connector | Evidence |
|---|---|
| GitHub | Verified PR #255/main, read canonical and official repos, created branch/commits/PR #256, and supplies Actions/review state. |

## Connector Usage Evidence

- source: GitHub connector for `yotamfried-ux/Engineering-OS`, `github/docs`, and `anthropics/claude-code`.
- action: merged PR #255; inspected owners; researched examples; implemented nine paths; opened PR #256; inspected run 1118 diagnostics.
- result: PR #256 head advanced from `971cb8aec150d45aee4e1341d4eea879978552d0`; workflow-evidence artifact `8530827195` identified only source-label and lifecycle-order defects.
- decision: kept strict enforcement and corrected evidence instead of weakening the checker.
- target: the nine Route Plan paths.

## Data / State Impact

Documentation, validator code, fixtures, and metadata-only claims only; no application/provider state.

## Integration Impact

CLAUDE, README, CodeRabbit policy, documentation hygiene, live claims, and audit state agree; Project 8 stays blocked.

## Validation Plan

- focused documentation-hygiene checker/fixtures;
- live-state, known-gaps, readiness, and full enforcement suites;
- exact-head policies, artifact inspection, thread reconciliation, self-review, and post-merge validation.

## Claude Run Trace

- goal: prevent active documentation from contradicting runtime/reviewer state.
- hypothesis: narrow owner-based assertions plus negative fixtures prevent recurrence.
- connectors: GitHub and official Anthropic, GitHub Docs, and CodeRabbit sources.
- steps: merge PR #255; inspect main; research; plan first; implement; synchronize audit; open PR #256; inspect CI diagnostics.
- evidence: PR #255 head/merge; plan commit `13d6e8456b6c75db03eb31a8393a505adc3e8ac7`; workflow-evidence run 1118 artifact `8530827195`; commit `836f1538a9873cc109d159adc790891debc35c60`.
- rejected: refreshed counts, static reviewer assumptions, generated churn, historical rewrites, parallel owners.
- result: implementation is complete; evidence chronology is being corrected through ordered plan-only commits.

## Definition of Done

- [x] CLAUDE runtime wording agrees with registry.
- [x] README inventory rows contain no numeric snapshots.
- [x] CodeRabbit policy requires current review or structured fallback.
- [x] Checker covers all three active-surface invariants.
- [x] Fixtures cover runtime, inventory, and reviewer drift.
- [ ] PR #255 live claim passes on PR #256.
- [x] Registry/audit synchronized while current gap stays open.
- [ ] Focused/full exact-head suites pass.
- [ ] Review findings/threads reconciled.
- [ ] Owner-approved merge and post-merge validation complete.

## Progress Lifecycle Evidence

- start: commit `13d6e8456b6c75db03eb31a8393a505adc3e8ac7` recorded scope, sources, alternatives, and validation before implementation.
- mid: commit `836f1538a9873cc109d159adc790891debc35c60` materially updated the implementation checkpoint after all nine target paths and the first CI diagnostic existed.
- pre-merge: commit `1e4657050e308d2fab905424354e43b923012f47` completed the scoped branch cleanup and preserved canonical navigation; no green-CI, review-clean, or merge-readiness claim is made before the external gates run.

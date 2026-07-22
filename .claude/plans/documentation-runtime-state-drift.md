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

- internal: `CLAUDE.md`, `README.md`, `core/capability-registry.yaml`, `core/coderabbit-policy.md`, `scripts/enforcement/check-documentation-hygiene.sh`, `scripts/enforcement/tests/test-documentation-hygiene.sh`, `docs/operations/known-gaps.tsv`, and `docs/operations/operational-readiness-audit.md`.
- context7: `https://code.claude.com/docs/en/memory`, `https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-readmes`, `https://docs.coderabbit.ai/guides/code-review-overview`, and `https://github.com/github/docs` were read directly; no SDK is introduced.
- decision: executable owners define active state, count snapshots are removed, and live reviewer-or-fallback semantics are enforced.

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
| GitHub | Verified PR #255/main, read canonical and official repos, created branch/commits/PR #256, and supplied Actions/review state. |

## Connector Usage Evidence

- source: GitHub connector for `yotamfried-ux/Engineering-OS`, `github/docs`, and `anthropics/claude-code`.
- action: merged PR #255; inspected owners; researched examples; implemented nine paths; opened PR #256; inspected workflow and live-state result loops.
- result: `known-gaps-live-state` runs 11 and 14 accepted both live closure claims; workflow-evidence run 1121 succeeded on head `06d410eddb2d19c94e2eeab08edbf23298bd96a3`.
- decision: kept strict enforcement and corrected evidence structure instead of weakening any checker.
- target: `.claude/plans/documentation-runtime-state-drift.md`; `scripts/enforcement/check-documentation-hygiene.sh`; `scripts/enforcement/tests/test-documentation-hygiene.sh`; `docs/operations/live-state-claims.json`.

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
- steps: merge PR #255; inspect main; research; plan first; implement; synchronize audit; open PR #256; run evidence result loops; fix six valid review findings with isolated regressions.
- evidence: PR #255 head/merge; plan commit `13d6e8456b6c75db03eb31a8393a505adc3e8ac7`; live-state runs 11/14; workflow-evidence run 1121; checker commit `f302f0e8e28c7a8dc8982fcf33de0b8cc03964d8`; fixture commit `890e535da3c5a69951986ad92d436113f6fc0c08`.
- rejected: refreshed counts, static reviewer assumptions, generated churn, historical rewrites, parallel owners.
- result: implementation and review fixes are complete; exact-head CI and thread reconciliation are running.

## Definition of Done

- [x] CLAUDE runtime wording agrees with registry.
- [x] README inventory rows contain no numeric snapshots.
- [x] CodeRabbit policy requires current review or structured fallback.
- [x] Checker covers all three active-surface invariants.
- [x] Fixtures cover runtime, inventory, and reviewer drift.
- [x] PR #255 live claim passes on PR #256 through `known-gaps-live-state` runs 11 and 14.
- [x] Registry/audit synchronized while current gap stays open.

## Live External Gates Before Merge

PR #256 remains unmerged until the final exact head passes focused and full suites, all named non-self workflows, live artifact inspection, external review or structured fallback, thread reconciliation, exact-head self-review, updated Merge Readiness evidence, and a new explicit owner approval. After an authorized merge, post-merge validation on `main` is required before `documentation-runtime-state-drift` can close.

## Progress Lifecycle Evidence

- start: commit `13d6e8456b6c75db03eb31a8393a505adc3e8ac7` recorded scope, sources, alternatives, and validation before implementation.
- mid: commit `836f1538a9873cc109d159adc790891debc35c60` materially updated the implementation checkpoint after all nine target paths and the first CI diagnostic existed.
- pre-merge: commit `890e535da3c5a69951986ad92d436113f6fc0c08` completed the six review-driven checker and fixture corrections after the last code/config/test change; PR #256 remained unmerged and owner approval remained absent.

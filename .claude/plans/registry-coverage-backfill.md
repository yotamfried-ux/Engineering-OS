# Registry Coverage Backfill Route Plan

Plan Scope: standard

| Field | Value |
|---|---|
| Task type | Engineering OS maintenance |
| Task class | engineering_os_governance |
| Domain tags | ops-readiness, governance, registry-coverage |
| Plan Scope | standard |
| Planning Mode | approved |
| Task-router evidence | core/task-router.md read |
| Workflow evidence | core/workflow.md read |
| Templates | governance-maintenance waiver |
| Architecture guides | governance-maintenance waiver |
| Patterns | core/task-router.md routing pattern |
| External systems/connectors | GitHub |
| Skills | not required |
| Validation gates | scripts/enforcement/check-scaling-extension.py, scripts/enforcement/tests/test-scaling-extension.sh, scripts/enforcement/check-required-connectors.sh, scripts/enforcement/check-required-templates.py, scripts/enforcement/check-required-skills.sh, scripts/enforcement/check-connector-evidence.sh, scripts/enforcement/check-workflow-evidence.sh |
| Evidence to check | scripts/enforcement/project-type-roadmaps.tsv; scripts/enforcement/template-requirements.tsv; scripts/enforcement/connector-requirements.tsv; scripts/enforcement/check-scaling-extension.py; templates/; external-systems/connectors/* |
| User decisions required | none |
| selected_project_type | engineering_os_governance |
| selected_template | governance-maintenance waiver |
| selected_roadmap | docs/operations/project-type-roadmaps.md |
| selected_result_loop_contract | scripts/enforcement/result-loop-requirements.tsv |
| required_user_simulation | fixture test coverage |
| local_creator_review_path | local CLI tests |
| telemetry_export_path | scripts/monitoring/export-telemetry-run.sh |
| evidence_policy_rule | metadata-only evidence export |
| Target paths | scripts/enforcement/project-type-roadmaps.tsv, scripts/enforcement/check-scaling-extension.py, scripts/enforcement/tests/test-scaling-extension.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md, scripts/enforcement/check-semantic-cleanup.sh, .gitignore |

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| scripts/enforcement/connector-requirements.tsv | checked | `check-required-connectors.sh --check-coverage` passes against `external-systems/connectors/*`; PR #224's broader `external-systems/` comparison was not the real connector inventory. |
| scripts/enforcement/template-requirements.tsv | checked | 26 template rows exist. 21 rows are `kind=project`; 10 of those project templates had no project-type roadmap entry before this PR. |
| scripts/enforcement/project-type-roadmaps.tsv | checked | Added 10 honest `status=deferred` roadmap rows for uncovered project templates instead of fabricating active roadmap content. |
| scripts/enforcement/check-scaling-extension.py | checked | Added a coverage rule requiring every `kind=project` template row to have a project-type roadmap entry with any status. |
| scripts/enforcement/tests/test-scaling-extension.sh | checked | Added a fixture for a project template that lacks a roadmap row. |
| docs/operations/known-gaps.tsv | checked | Corrected the `registry-coverage-backfill` gap text to describe the verified project-template roadmap gap. |
| docs/operations/operational-readiness-audit.md | checked | Corrected the readiness matrix and ROI language to match the verified registry gap. |
| scripts/enforcement/check-semantic-cleanup.sh | checked | Fixed a pre-existing false positive that treated `from __future__ import annotations` as an unused import. |

## Documentation Asset Evidence

- internal: `scripts/enforcement/project-type-roadmaps.tsv`; `scripts/enforcement/template-requirements.tsv`; `scripts/enforcement/connector-requirements.tsv`; `docs/operations/known-gaps.tsv`; `docs/operations/operational-readiness-audit.md`.
- context7: not required — internal governance manifests, no external library/API involved.
- decision: existing manifest schemas already support `status=deferred`, so the PR records coverage honestly without inventing active roadmap evidence.

## Connector Evidence

- GitHub: used for repository reads/writes, PR #224 evidence review, PR #225 creation, CI verification, and merge-readiness checks.

## Connector Usage Evidence

- source: GitHub repository `yotamfried-ux/Engineering-OS`; PR #224; paths `scripts/enforcement/template-requirements.tsv`, `scripts/enforcement/project-type-roadmaps.tsv`, `scripts/enforcement/connector-requirements.tsv`, `scripts/enforcement/check-scaling-extension.py`, `docs/operations/known-gaps.tsv`, and `docs/operations/operational-readiness-audit.md`.
- action: cross-referenced every registry/manifest pair by running coverage checkers and diffing `template-requirements.tsv` project rows against `project-type-roadmaps.tsv` template-path references; GitHub was also used to open PR #225 and inspect CI failures on commit `dde82a97d31a093b9bb8a6de104ee80817783093`.
- result: GitHub PR #224 plus paths `scripts/enforcement/template-requirements.tsv` and `scripts/enforcement/project-type-roadmaps.tsv` showed the verified gap: 10 `kind=project` templates lacked roadmap rows; paths `scripts/enforcement/connector-requirements.tsv` and `external-systems/connectors/*` showed connector coverage was already complete.
- decision: added 10 `status=deferred` rows to `scripts/enforcement/project-type-roadmaps.tsv`, added a coverage rule in `scripts/enforcement/check-scaling-extension.py`, added a fixture in `scripts/enforcement/tests/test-scaling-extension.sh`, corrected `docs/operations/known-gaps.tsv` and `docs/operations/operational-readiness-audit.md`, and refreshed this Route Plan after CI showed connector/workflow evidence gaps.
- target: scripts/enforcement/project-type-roadmaps.tsv; scripts/enforcement/check-scaling-extension.py; scripts/enforcement/tests/test-scaling-extension.sh; docs/operations/known-gaps.tsv; docs/operations/operational-readiness-audit.md; scripts/enforcement/check-semantic-cleanup.sh; .gitignore

## Capability Evidence

- `routing.task-router-read` — core/task-router.md read.
- `workflow.workflow-read` — core/workflow.md read.
- `plan.route-plan-before-write` — plan before edits in the Claude run; this follow-up commit is a plan-only checkpoint after CI feedback.
- `source.github-repo-read` — repository files and PR #224 read.
- `validation.policy-change-has-validator` — `check-scaling-extension.py` and `test-scaling-extension.sh` are in scope and re-run.
- `validation.coderabbit-policy` — manual review fallback if CodeRabbit is rate-limited; CI and review threads still gate merge.

## Claude Run Trace

- goal: complete Registry Coverage Backfill without fabricating coverage and correct the false connector-gap framing introduced by PR #224.
- hypothesis: the merged audit text overstated the connector gap; the real coverage gap had to be re-verified from manifests and coverage checkers before editing.
- steps: ran/checked connector, template, skill, and scaling coverage; compared `template-requirements.tsv` project rows with `project-type-roadmaps.tsv`; found 10 missing roadmap entries; added deferred rows; added a checker rule and fixture; corrected audit text; fixed a pre-existing semantic-cleanup false positive.
- evidence: coverage checks for connectors/templates/skills passed; `check-scaling-extension.py` and `test-scaling-extension.sh` pass locally per PR evidence; `enforcement-tests` is green on the PR head before this plan-only fix; CI showed connector/workflow evidence gaps that this plan-only commit addresses.
- result: the verified registry blind spot is now explicitly represented by deferred roadmap rows and a fixture-tested checker rule; no active roadmap content is fabricated.
- rejected: broad connector backfill, fabricated active roadmap rows, and full result-loop/documentation/pattern/skill rows for the 10 deferred project types in this PR.
- follow-up: the 10 deferred project types still need real roadmap research before they can become active.

## Graphify Usage Evidence

- source: graphify explain query against graphify-out/graph.json.
- action: ran `graphify explain` for `check-scaling-extension.py`, `test-scaling-extension.sh`, `operational-readiness-audit.md`, `check-semantic-cleanup.sh`, and `.gitignore` before edits.
- result: no graph nodes/edges exist for these enforcement/governance/config files.
- decision: treated each changed file as isolated governance/enforcement scope with targeted fixtures and policy checks.
- target: scripts/enforcement/check-scaling-extension.py; scripts/enforcement/tests/test-scaling-extension.sh; docs/operations/operational-readiness-audit.md; scripts/enforcement/check-semantic-cleanup.sh; .gitignore

## Alternatives

- Left PR #224's registry text unchanged — rejected because the connector-gap framing was factually wrong.
- Marked 10 roadmap rows as active — rejected because that would fabricate domain evidence.
- Added full result-loop/documentation/pattern/skill content for all 10 templates — rejected because that is separate domain-specific research.

## Affected Surfaces

- `scripts/enforcement/project-type-roadmaps.tsv` receives 10 deferred rows.
- `scripts/enforcement/check-scaling-extension.py` receives a stricter coverage rule.
- `scripts/enforcement/tests/test-scaling-extension.sh` receives a negative fixture.
- `docs/operations/known-gaps.tsv` and `docs/operations/operational-readiness-audit.md` receive corrected gap text.
- `scripts/enforcement/check-semantic-cleanup.sh` receives a narrow pre-existing false-positive fix.
- `.gitignore` receives local generated-file exclusions.

## Data/State Impact

- None: governance manifests, policy scripts, tests, docs, and repo config only.

## Integration Impact

- None: no external service integration behavior changes. GitHub is used only for repository and PR operations.

## Validation Plan

- Run `python3 scripts/enforcement/check-scaling-extension.py --root .` locally.
- Run `bash scripts/enforcement/tests/test-scaling-extension.sh` locally.
- Run `bash scripts/enforcement/check-known-gaps.sh` and `bash scripts/enforcement/check-readiness-audit.sh` locally.
- Run the full `scripts/enforcement/tests/test-*.sh` loop locally.
- Confirm GitHub Actions checks are green after this plan-only fix.
- Confirm 0 open review threads before merge.

## Open Questions

- None outstanding for this scoped PR.

## Progress Lifecycle Evidence

- start: coverage checkers and manifest cross-references were read before edits, including `connector-requirements.tsv`, `template-requirements.tsv`, `project-type-roadmaps.tsv`, and `check-scaling-extension.py`.
- mid: after the code/config/doc commit landed, the deferred roadmap rows, checker rule, fixture, corrected gap text, and semantic-cleanup fix were rechecked against the plan and PR diff.
- pre-merge: after CI on commit `dde82a97d31a093b9bb8a6de104ee80817783093` reported `workflow-evidence-policy` and `connector-evidence-policy` failures, this plan-only checkpoint refreshed connector result identifiers, target linkage, and lifecycle evidence after all code/config/test changes; no code/config/test file is changed in this checkpoint.

## Run Evidence (Telemetry Surrogate)

Recorded on explicit user request, mid-session, before continuing PR 2. This is a factual log of this Claude run, not fabricated telemetry, and is not Project 8 evidence.

1. **Task/gap being worked on:** Registry Coverage Backfill — correcting a factually wrong `registry-coverage-backfill` description from merged PR #224 and backfilling the verified gap of 10 `kind=project` templates without roadmap rows.
2. **Branch:** `claude/engineering-os-audit-post-merge-voiaqp`.
3. **Files changed:** `.claude/plans/registry-coverage-backfill.md`, `.gitignore`, `docs/operations/known-gaps.tsv`, `docs/operations/operational-readiness-audit.md`, `scripts/enforcement/check-scaling-extension.py`, `scripts/enforcement/check-semantic-cleanup.sh`, `scripts/enforcement/project-type-roadmaps.tsv`, `scripts/enforcement/tests/test-scaling-extension.sh`.
4. **Commands run, grouped by purpose:** investigation with git/find/grep; validation with registry coverage checkers, readiness/audit checkers, scaling checker/tests, and the full enforcement test suite; GitHub PR/CI/review operations.
5. **Failures / false positives:** PR #224 had two corrected premature conclusions; PR #225 hit connector/workflow evidence failures; the semantic-cleanup checker had a pre-existing `__future__` import false positive.
6. **Pre-existing bugs found:** `check-semantic-cleanup.sh` treated `from __future__ import annotations` as an unused import.
7. **Extra work caused:** approximately 10 extra tool-call round trips to diagnose and fix the semantic-cleanup false positive.
8. **Tests passed:** local evidence reports all 79 enforcement test suites passed; PR CI had green `enforcement-tests` before this plan-only fix.
9. **Estimated wasted/avoidable work:** two correction cycles from PR #224 assumptions, plus several graphify/plan-scope stop-and-fix cycles.
10. **Was telemetry exporter/importer run?** No.
11. **Why not:** this was Engineering OS self-governance work, not a real target-project run; running telemetry here would risk being confused with Project 8 evidence.
12. **What should be enforced next:** add a PR/plan gate requiring Run Usage Evidence or an explicit telemetry waiver before merging non-trivial Engineering OS PRs.

## DoD

- [x] Verify connector, template, and skill registries before changing coverage claims.
- [x] Add 10 `status=deferred` rows to `project-type-roadmaps.tsv` for uncovered `kind=project` templates.
- [x] Add a checker rule requiring each `kind=project` template to have a roadmap row, with a fixture.
- [x] Correct `registry-coverage-backfill` text in `known-gaps.tsv` and `operational-readiness-audit.md`.
- [x] Keep deferred rows honest; do not fabricate active roadmap content.
- [x] Fix the unrelated pre-existing `__future__` false positive in `check-semantic-cleanup.sh`.
- [x] Record Run Evidence / telemetry surrogate for this Claude run.
- [x] Refresh plan-only evidence after CI identified connector/workflow evidence failures.

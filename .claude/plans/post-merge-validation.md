# Post-merge Validation Repair Loop

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | governance, merge, post-merge, CI, repair-loop, operational-readiness |
| Target paths | .github/workflows/post-merge-validation.yml, scripts/enforcement/check-post-merge-validation-contract.sh, scripts/enforcement/tests/test-post-merge-validation-contract.sh, scripts/enforcement/simulation-coverage.tsv, docs/operations/operational-readiness-audit.md |
| Templates | not required |
| Patterns | shell test pattern, github-actions workflow pattern |
| External systems/connectors | github, notion |
| Skills | superpowers, security-review |
| Validation gates | enforcement-tests, pr-policy, workflow-evidence-policy, connector-evidence-policy, capability-evidence-policy, plan-policy |

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.post-merge-validation`
- `validation.coderabbit-policy`

## Connector Evidence

- github: repository workflows, previous PR merge status, and existing enforcement contract files were read before selecting the implementation.
- notion: unavailable in this session; this Route Plan is the fallback progress tracker.

## Connector Usage Evidence

- github: post-merge validation gap was confirmed by checking the merged PR SHA `d36eb732d51551a5e0f0ba98cf160c719b419a6d`; commit workflow lookup returned no usable post-merge evidence, so this plan targets a dedicated push-to-main workflow and repair-loop contract.
- github: read `.github/workflows/enforcement-tests.yml` and `scripts/enforcement/check-merge-readiness.sh` to reuse existing required workflow names and CI conventions.
- notion: unavailable; progress lifecycle is tracked in this plan.

## Notion Progress Validation

- start: plan created before adding workflow/script/test files.
- mid: CI failures and review findings will be recorded in PR comments and commit messages.
- pre-merge: final head SHA, workflows, review threads, and mergeability will be checked before merging.

## Skill Evidence

- superpowers
- security-review

## Source of Truth Checks

| Source | Status |
|---|---|
| CLAUDE.md | checked |
| core/task-router.md | checked |
| core/workflow.md | checked |
| core/git-policy.md | checked |
| core/hooks-policy.md | checked |
| docs/operations/operational-readiness-audit.md | checked |
| .github/workflows/enforcement-tests.yml | checked |
| scripts/enforcement/check-merge-readiness.sh | checked |

## Template Gap Waiver

reason: this is an internal governance/CI repair-loop change, not a project scaffold, so no project template applies.

## Progress Lifecycle Evidence

- start: plan created before any post-merge validation workflow or script changes.
- mid: validator and fixture tests will be added before PR creation and iterated against CI evidence.
- pre-merge: all required PR workflows, review threads, and expected head SHA will be verified before merge.

## Claude Run Trace

- goal: enforce post-merge validation so `main` failures after merge trigger a deterministic repair loop instead of silently remaining broken.
- hypothesis: a dedicated push-to-main workflow with a repair issue step plus a static contract validator gives immediate operational coverage and is testable in PR without forcing an actual failing main run.
- connectors: github, notion fallback.
- steps: create plan; add post-merge workflow; add contract validator; add positive/negative/invalid/waiver simulations; update simulation coverage manifest; update audit if tool safety permits; open PR; validate CI/reviews; merge with expected head SHA; verify post-merge evidence.
- evidence: GitHub CI, review threads, and merge result.
- rejected attempts: relying only on PR-triggered `fetch_commit_workflow_runs` is insufficient because it returned no post-merge evidence for the merged SHA.
- result: pending.
- follow-up enforcement: future changes to post-merge repair behavior must keep the contract validator and simulation coverage updated.

## DoD

- [x] Route Plan created before enforcement changes.
- [x] GitHub connector evidence used to confirm the gap.
- [x] Required validation gates selected.
- [ ] Post-merge validation workflow added.
- [ ] Contract validator added.
- [ ] Positive/negative/invalid/waiver simulations added.
- [ ] Simulation coverage manifest updated.
- [ ] CI green on PR head.
- [ ] Review threads resolved.
- [ ] PR merged to main.
- [ ] Post-merge evidence checked.

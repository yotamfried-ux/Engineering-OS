# RTK Runtime Hardening

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | rtk, context-heavy, runtime-evidence, semantic-use |
| Target paths | scripts/enforcement/check-workflow-evidence.sh, scripts/enforcement/tests/test-rtk-usage-evidence.sh, scripts/enforcement/simulation-coverage.d/rtk-usage-evidence.tsv, docs/operations/operational-readiness-audit.md, docs/operations/known-gaps.tsv |
| Templates | not required |
| Patterns | workflow evidence validator pattern, simulation coverage manifest pattern |
| External systems/connectors | github, notion |
| Skills | superpowers, security-review, rtk |
| Validation gates | enforcement-tests, pr-policy, workflow-evidence-policy, connector-evidence-policy, capability-evidence-policy, plan-policy |

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`

## Connector Evidence

- github: read existing RTK contract checker, RTK session blocking test, workflow evidence checker, simulation coverage, known-gaps manifest, and audit before implementation.
- notion: unavailable in this session; this plan is the fallback tracker.

## Connector Usage Evidence

- github: checked `check-rtk-contract.sh` and used the result to identify that current enforcement proves policy/hook/session setup only.
- github: checked `test-context-optimizer-contract.sh` and `test-rtk-session-blocking.sh` and used the result to avoid duplicating availability checks.
- github: checked `check-workflow-evidence.sh` and used it as the right enforcement point for Route Plan RTK usage evidence.
- github: checked `known-gaps.tsv` and used the `rtk-semantic-use` row to scope this PR to decision-impact evidence, not full semantic reasoning proof.

## Progress Lifecycle Evidence

- start: this Route Plan is committed before RTK usage evidence enforcement changes.
- mid: workflow validator, tests, coverage row, known-gaps, and audit updates will be committed after this plan.
- pre-merge: final PR workflows, review threads, mergeability, and head SHA will be checked before merge.

## Skill Evidence

- superpowers
- security-review
- rtk

## RTK Usage Evidence

- source: existing RTK contract and known-gaps evidence show availability/hook checks are already enforced.
- action: use workflow evidence enforcement to require an RTK Usage Evidence section when a plan declares `rtk` for code/config/test changes.
- result: plans must state RTK source/action/result/decision impact or provide an explicit RTK usage waiver.
- decision: implement a structural decision-impact gate as the next reliable step before deeper semantic verification.

## Source of Truth Checks

| Source | Status |
|---|---|
| scripts/enforcement/check-rtk-contract.sh | checked |
| scripts/enforcement/tests/test-context-optimizer-contract.sh | checked |
| scripts/enforcement/tests/test-rtk-session-blocking.sh | checked |
| scripts/enforcement/check-workflow-evidence.sh | checked |
| docs/operations/known-gaps.tsv | checked |
| docs/operations/operational-readiness-audit.md | checked |

## Template Gap Waiver

reason: internal governance/enforcement change; no project template applies.

## Claude Run Trace

- goal: strengthen RTK from availability evidence to Route Plan decision-impact evidence.
- hypothesis: requiring RTK source/action/result/decision fields when `rtk` is declared for code changes catches silent RTK non-use while remaining deterministic.
- connectors: github, notion fallback.
- result: pending CI/review/merge.

## DoD

- [x] Route Plan created before enforcement changes.
- [x] Existing RTK contract/session tests read.
- [x] Audit and known-gaps RTK row read.
- [ ] Workflow evidence checker requires RTK Usage Evidence for RTK-declared code/config/test changes.
- [ ] Positive/negative/invalid/waiver simulations added.
- [ ] Simulation coverage row added.
- [ ] Audit and known-gaps refreshed without overclaiming full semantic readiness.
- [ ] CI green on PR head.
- [ ] Review threads resolved/outdated with evidence.
- [ ] PR merged to main.

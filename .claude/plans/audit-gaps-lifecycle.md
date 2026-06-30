# Audit Freshness and Known Gaps Lifecycle

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | operational-readiness, audit, known-gaps, lifecycle |
| Target paths | docs/operations/operational-readiness-audit.md, docs/operations/known-gaps.tsv, scripts/enforcement/check-known-gaps.sh, scripts/enforcement/tests/test-known-gaps.sh, scripts/enforcement/coverage-required-gates.tsv, scripts/enforcement/simulation-coverage.d/known-gaps-lifecycle.tsv |
| Templates | not required |
| Patterns | TSV manifest validator pattern |
| External systems/connectors | github, notion |
| Skills | superpowers, security-review |
| Validation gates | enforcement-tests, pr-policy, workflow-evidence-policy, connector-evidence-policy, capability-evidence-policy, plan-policy |

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`

## Connector Evidence

- github: read operational readiness audit, hooks policy, and required-gates manifest before implementation.
- notion: unavailable in this session; this plan is the fallback tracker.

## Connector Usage Evidence

- github: checked the audit and used the result to identify stale status rows for semantic cleanup, coverage map hardening, and documentation hygiene scope.
- github: read hooks policy and used it to keep this change in deterministic enforcement scripts instead of only editing documentation.
- github: checked coverage-required-gates and used it to add a required gate for the new known-gaps lifecycle validator.

## Progress Lifecycle Evidence

- start: this Route Plan was committed before writing the known-gaps manifest or validator.
- mid: manifest, validator, tests, simulation coverage, required gate, and audit refresh were committed after this plan.
- pre-merge: final PR workflows, review threads, mergeability, and head SHA will be checked before merge.

## Skill Evidence

- superpowers
- security-review

## Source of Truth Checks

| Source | Status |
|---|---|
| docs/operations/operational-readiness-audit.md | checked and refreshed |
| core/hooks-policy.md | checked |
| scripts/enforcement/coverage-required-gates.tsv | checked and updated |
| docs/operations/known-gaps.tsv | added |
| scripts/enforcement/check-known-gaps.sh | added |
| scripts/enforcement/tests/test-known-gaps.sh | added |

## Template Gap Waiver

reason: internal governance/audit enforcement change; no project template applies.

## Claude Run Trace

- goal: make operational-readiness gaps lifecycle-managed and refresh stale audit status after recent merges.
- hypothesis: a known-gaps TSV manifest plus validator can force owner, risk, mitigation, test, and closure fields for every open gap.
- connectors: github, notion fallback.
- result: ready for PR CI validation.

## DoD

- [x] Route Plan created before enforcement changes.
- [x] Audit, hooks policy, and required-gates manifest read.
- [x] Known-gaps manifest added.
- [x] Known-gaps validator added.
- [x] Positive/negative/invalid/waiver simulations added.
- [x] Simulation coverage row and required gate added.
- [x] Audit refreshed to reflect recent merged gates without overclaiming full semantic readiness.
- [x] Ready for PR CI validation.

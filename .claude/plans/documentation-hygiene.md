# Documentation Hygiene Gate

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | documentation, hygiene, markdown, canonical-owner |
| Target paths | core/documentation-policy.md, scripts/enforcement/check-documentation-hygiene.sh, scripts/enforcement/tests/test-documentation-hygiene.sh, docs/operations/documentation-ownership.tsv, docs/operations/operational-readiness-audit.md, scripts/enforcement/simulation-coverage.tsv |
| Templates | not required |
| Patterns | shell validator pattern, TSV manifest pattern |
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

- github: source files were read before choosing the gate shape.
- notion: unavailable in this session; this plan is the progress tracker.

## Connector Usage Evidence

- github: existing documentation enforcement checks README presence and standalone placeholders, but not canonical ownership or duplicate policy locations.
- github: `core/documentation-policy.md` defines canonical ownership, so this change adds validation for that policy.

## Notion Progress Validation

- start: plan created before adding validator files.
- mid: CI findings will be recorded in commit messages.
- pre-merge: final checks will be recorded before merge.

## Skill Evidence

- superpowers
- security-review

## Source of Truth Checks

| Source | Status |
|---|---|
| core/documentation-policy.md | checked |
| scripts/enforcement/enforce-documentation.sh | checked |
| docs/README.md | checked |
| docs/operations/operational-readiness-audit.md | checked |

## Template Gap Waiver

reason: internal governance change; no project template applies.

## Progress Lifecycle Evidence

- start: plan created before validator/test/manifest changes.
- mid: validator and fixtures will be added and repaired against CI evidence.
- pre-merge: workflows, review threads, and expected head SHA will be checked.

## Claude Run Trace

- goal: require durable documentation to have canonical ownership and block stale or duplicate policy documentation.
- hypothesis: TSV ownership manifest plus a shell validator can catch high-risk documentation hygiene failures deterministically.
- connectors: github, notion fallback.
- steps: plan, manifest, validator, simulations, CI, review, merge.
- evidence: pending GitHub CI and review evidence.
- rejected attempts: existing documentation gate alone is not enough.
- result: pending.
- follow-up enforcement: future doc governance changes must update this gate.

## DoD

- [x] Route Plan created before enforcement changes.
- [x] Existing documentation policy and enforcer read.
- [x] Required validation gates selected.
- [ ] Ownership manifest added.
- [ ] Documentation hygiene validator added.
- [ ] Positive/negative/invalid/waiver simulations added.
- [ ] Documentation enforcer wired to the hygiene validator.
- [ ] Simulation coverage manifest updated.
- [ ] Operational readiness audit updated.
- [ ] CI green on PR head.

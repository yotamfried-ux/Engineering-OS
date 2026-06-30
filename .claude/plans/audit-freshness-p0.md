# Audit Freshness P0

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | audit, operational-readiness, known-gaps, enforcement-freshness |
| Target paths | scripts/enforcement/check-known-gaps.sh, scripts/enforcement/tests/test-known-gaps.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md |
| Templates | not required |
| Patterns | governance validator pattern |
| External systems/connectors | github, notion |
| Skills | superpowers, security-review |
| Validation gates | enforcement-tests, workflow-evidence-policy, capability-evidence-policy, connector-evidence-policy, plan-policy, pr-policy |

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`

## Connector Evidence

- github: read `docs/operations/known-gaps.tsv`, `docs/operations/operational-readiness-audit.md`, `scripts/enforcement/check-known-gaps.sh`, and `scripts/enforcement/tests/test-known-gaps.sh` before implementation.
- notion: unavailable; fallback plan file used for progress tracking.

## Connector Usage Evidence

- source: github `docs/operations/known-gaps.tsv`, `docs/operations/operational-readiness-audit.md`, `scripts/enforcement/check-known-gaps.sh`, and `scripts/enforcement/tests/test-known-gaps.sh`.
- action: inspected GitHub audit/gap state and current known-gaps validator behavior.
- result: GitHub showed `audit-freshness` is open P0, the audit row still says freshness is only partially enforced, and the current validator checks row shape but not audit-to-gap consistency or closure freshness.
- decision: implemented a deterministic freshness gate that cross-checks known-gaps rows against the audit ledger and fails if open/mitigated/closed gap states drift from the audit.
- target: scripts/enforcement/check-known-gaps.sh, scripts/enforcement/tests/test-known-gaps.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md.

## Progress Lifecycle Evidence

- start: this plan was committed before enforcement changes.
- mid: validator, tests, known-gaps, and audit were updated after this plan.
- pre-merge: CI, review threads, mergeability, and expected head SHA must be checked live in GitHub before merge.

## Skill Evidence

- superpowers
- security-review

## Template/Pattern Rating Evidence

- asset: governance validator pattern.
- rating: 4 medium confidence.
- outcome: reused the pattern of a shell/Python semantic validator plus positive/negative fixtures.
- decision: keep preferred for governance freshness checks because it gives deterministic failure modes for drift.

## Source of Truth Checks

| Source | Status |
|---|---|
| docs/operations/known-gaps.tsv | checked |
| docs/operations/operational-readiness-audit.md | checked |
| scripts/enforcement/check-known-gaps.sh | checked |
| scripts/enforcement/tests/test-known-gaps.sh | checked |
| .github/workflows/enforcement-tests.yml | checked |

## Template Gap Waiver

reason: internal governance validator change; no project template applies.

## Claude Run Trace

- goal: close `audit-freshness` without leaving a future-deep drift path.
- hypothesis: known-gaps is the structured gap lifecycle ledger, while the audit matrix is the human readiness map; the strongest deterministic closure is a CI validator that cross-checks both directions.
- experiment: local temp fixtures where a gap is missing from audit, audit status mismatches known-gaps, audit has an extra unknown gap, known-gaps has a missing field, known-gaps has a duplicate gap, and a correct audit/gap pair passes.
- result: local simulation passed the positive fixtures and failed the negative fixtures in the expected direction.
- follow-up: rerun GitHub Actions, inspect CodeRabbit/Codex review threads, then merge only with expected head SHA.

## DoD

- [x] Route Plan created before enforcement changes.
- [x] Existing known-gaps row inspected.
- [x] Operational readiness audit inspected.
- [x] Current known-gaps validator inspected.
- [x] Validator fails when a gap is missing from the audit freshness ledger.
- [x] Validator fails when a gap status/priority differs between known-gaps and audit.
- [x] Validator fails when the audit includes an unknown gap not present in known-gaps.
- [x] Positive fixture passes for a consistent known-gaps/audit pair.
- [x] `audit-freshness` row updated after validator and tests proved freshness enforcement.

## Live External Gates Before Merge

These gates are intentionally not represented as unchecked plan checklist items because `plan-policy` treats every unchecked plan checkbox as a blocker. They must be verified directly against the PR head before merge:

- GitHub Actions passed on the final PR head.
- Review threads are resolved or outdated after the final PR head.
- Mergeability and expected head SHA are checked immediately before merge.

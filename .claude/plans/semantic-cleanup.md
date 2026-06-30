# Semantic Cleanup Gate

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | quality, cleanup, semantic-cleanup, dead-code, risky-todo, unused-imports |
| Target paths | scripts/enforcement/enforce-quality.sh, scripts/enforcement/check-semantic-cleanup.sh, scripts/enforcement/tests/test-semantic-cleanup.sh, scripts/enforcement/simulation-coverage.d/semantic-cleanup.tsv |
| Templates | not required |
| Patterns | shell validator pattern, staged-diff enforcement pattern |
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

- github: read `core/quality-gates.md`, `scripts/enforcement/enforce-quality.sh`, `scripts/enforcement/tests/test-quality.sh`, `scripts/enforcement/simulation-coverage.tsv`, and the readiness audit before implementation.
- notion: unavailable in this session; this plan is the fallback tracker.

## Connector Usage Evidence

- github: `quality-gates.md` says dead code, imports, duplicate logic, and debug cleanup are part of cleanup, while current enforcement only blocks unambiguous debug leftovers and merge conflict markers.
- github: `enforce-quality.sh` scoped the existing gate to staged added code lines; the new semantic-cleanup gate reuses that boundary to avoid broad repo-wide false positives.
- github: existing `test-quality.sh` already covers debug leftovers, so this plan adds a separate test file for semantic-cleanup-specific cases instead of overloading the existing gate.
- github: readiness audit still treats deep Semantic cleanup as a manual gap; this PR intentionally closes only deterministic high-confidence cases and documents the remaining deeper analyzer work here instead of overclaiming audit readiness.
- notion: unavailable; progress lifecycle is tracked in this plan.

## Notion Progress Validation

- start: plan created before adding semantic cleanup validator files.
- mid: validator, tests, quality-enforcer wiring, and simulation coverage were added before PR.
- pre-merge: final workflows, review threads, mergeability, and head SHA will be checked before merge.

## Skill Evidence

- superpowers
- security-review

## Source of Truth Checks

| Source | Status |
|---|---|
| core/quality-gates.md | checked |
| scripts/enforcement/enforce-quality.sh | checked and updated |
| scripts/enforcement/tests/test-quality.sh | checked |
| scripts/enforcement/check-semantic-cleanup.sh | added |
| scripts/enforcement/tests/test-semantic-cleanup.sh | added |
| scripts/enforcement/simulation-coverage.d/semantic-cleanup.tsv | added |
| docs/operations/operational-readiness-audit.md | checked; left as a broader manual/semantic gap |

## Template Gap Waiver

reason: internal governance/enforcement change; no project template applies.

## Progress Lifecycle Evidence

- start: plan created before validator/test/coverage changes.
- mid: semantic cleanup validator, fixtures, quality-enforcer wiring, and coverage row were added.
- pre-merge: workflows, review threads, and merge safety will be checked.

## Claude Run Trace

- goal: move Semantic cleanup from purely manual toward deterministic enforcement for high-confidence cases.
- hypothesis: a staged-diff validator can safely block risky cleanup markers, disabled false branches, and simple Python unused imports without claiming full semantic cleanup.
- connectors: github, notion fallback.
- steps: plan; add semantic cleanup validator; add tests; wire into quality enforcer; update simulation coverage; open PR; iterate CI/reviews; merge.
- evidence: pending GitHub CI and review evidence.
- rejected attempts: claiming full dead-code/duplicate-logic detection is too broad and would overclaim beyond deterministic signals.
- result: pending CI/review/merge validation.
- follow-up enforcement: deeper semantic cleanup will require language-specific linters or AST analyzers.

## DoD

- [x] Route Plan created before enforcement changes.
- [x] Existing quality policy/enforcer/test read.
- [x] Scope narrowed to deterministic high-confidence cases.
- [x] Semantic cleanup validator added.
- [x] Positive/negative/invalid/waiver simulations added.
- [x] Validator wired into quality enforcer.
- [x] Simulation coverage row added.
- [x] Audit limitation documented in this plan instead of overclaiming full semantic cleanup.
- [x] Ready for PR CI validation.

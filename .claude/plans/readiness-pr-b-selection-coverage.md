# Readiness PR B — selection coverage hardening

| Field | Value |
|---|---|
| Task class | engineering_os_governance |
| Task type | governance / enforcement hardening |
| Domain tags | governance, connectors, templates, patterns, skills, capabilities |
| Task-router evidence | core/task-router.md checked before writing; Engineering OS maintenance route selected |
| Workflow evidence | core/workflow.md checked before writing; plan-file fallback used because Notion is unavailable |
| Target paths | scripts/enforcement/check-required-connectors.sh, scripts/enforcement/check-connector-evidence.sh, scripts/enforcement/check-required-templates.py, scripts/enforcement/check-required-skills.sh, scripts/enforcement/validate-capability-evidence.sh, scripts/enforcement/tests/test-required-connectors.sh, scripts/enforcement/tests/test-connector-evidence.sh, scripts/enforcement/tests/test-required-templates.sh, scripts/enforcement/tests/test-skill-selection-gate.sh, scripts/enforcement/tests/test-capability-evidence.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md, scripts/enforcement/simulation-coverage.tsv |
| Templates | not required |
| Patterns | existing enforcement script + fixture-test pattern |
| Skills | none |
| External systems/connectors | github |
| Validation gates | enforcement-tests, workflow-evidence-policy, connector-evidence-policy, documentation-asset-policy, capability-evidence-policy, plan-policy, pr-policy, semantic-cleanup-policy, import-cleanup-policy |

## Scope

Implement readiness PR B: selection coverage hardening for the gaps re-registered by PR A:

1. `connector-selection-coverage`
2. `connector-result-identifiers`
3. `template-selection-coverage`
4. `pattern-required-manifest`
5. `skill-selection-coverage`
6. `capability-staged-guard`

The goal is to close only high-confidence structural gaps. Deep judgment such as whether the chosen connector/template/pattern/skill is semantically best remains review-based by design and must be stated honestly in the audit.

## Capability Evidence

- `routing.task-router-read` — core/task-router.md was checked before writing this plan.
- `workflow.workflow-read` — core/workflow.md was checked before writing this plan.
- `plan.route-plan-before-write` — this route plan is committed before enforcement/test/doc changes.
- `source.github-repo-read` — repository files and merged PR A state were inspected through GitHub.
- `validation.policy-change-has-validator` — every new policy claim must ship with checker and fixture updates in this PR or remain an open gap.
- `validation.coderabbit-policy` — work will ship through a PR and will not merge without owner approval.

## Connector Evidence

- github: inspected `CLAUDE.md`, `core/task-router.md`, `core/workflow.md`, `core/hooks-policy.md`, `core/capability-registry.yaml`, `docs/operations/known-gaps.tsv`, and current selection/capability checkers before writing this plan.

## Connector Selection Waiver

Notion is required for governance work, but the Notion connector is unavailable in this session; the approved `.claude/plans/` fallback is used for planning and progress evidence.

## Connector Usage Evidence

- source: github files `docs/operations/known-gaps.tsv`, `core/task-router.md`, `core/workflow.md`, `core/capability-registry.yaml`, `scripts/enforcement/check-required-connectors.sh`, `scripts/enforcement/check-connector-evidence.sh`, `scripts/enforcement/check-required-templates.py`, `scripts/enforcement/check-required-skills.sh`, and `scripts/enforcement/validate-capability-evidence.sh`.
- action: checked PR B gap definitions and current enforcement coverage before selecting implementation targets.
- result: PR A re-registered six selection/capability gaps for PR B, and current checkers use inline keyword rules rather than inventory/manifest-backed coverage for all required domains.
- decision: implement manifest-backed or fixture-backed structural selection coverage where high-confidence rules exist; leave deep best-choice judgment explicitly review-based.
- target: scripts/enforcement/check-required-connectors.sh, scripts/enforcement/check-connector-evidence.sh, scripts/enforcement/check-required-templates.py, scripts/enforcement/check-required-skills.sh, scripts/enforcement/validate-capability-evidence.sh, docs/operations/known-gaps.tsv, docs/operations/operational-readiness-audit.md

## Documentation Asset Evidence

- internal: `docs/operations/known-gaps.tsv`, `docs/operations/operational-readiness-audit.md`, `core/capability-registry.yaml`, `core/task-router.md`, and current enforcement checkers were checked.
- context7: not required because this is internal Engineering OS governance enforcement and does not integrate an external library, SDK, or API.
- decision: use existing checker + fixture-test conventions and the PR A known-gaps contract as the source of truth.

## Graphify Usage Evidence

- source: unavailable in this ChatGPT connector runtime.
- action: not run.
- result: not applicable in this environment.
- decision: use direct GitHub file inspection as fallback and keep graphify as a runtime-specific manual note, not a false claim.
- target: scripts/enforcement, docs/operations, core/capability-registry.yaml

## Template Gap Waiver

No project scaffold template applies because this is an internal Engineering OS enforcement-hardening PR.

## Source of Truth Checks

| Source | Status |
|---|---|
| CLAUDE.md | checked |
| core/task-router.md | checked |
| core/workflow.md | checked |
| core/hooks-policy.md | checked |
| core/capability-registry.yaml | checked |
| docs/operations/known-gaps.tsv | checked |
| scripts/enforcement/check-required-connectors.sh | checked |
| scripts/enforcement/check-required-skills.sh | checked |
| scripts/enforcement/check-required-templates.py | checked |
| scripts/enforcement/validate-capability-evidence.sh | checked |

## Progress Lifecycle Evidence

- start: plan committed before any PR B enforcement, test, audit, or known-gap edits.

## Claude Run Trace

- goal: implement readiness PR B selection coverage hardening.
- hypothesis: manifest/fixture-backed high-confidence selection checks can close PR B's structural gaps without pretending to prove deep semantic judgment.
- connectors: GitHub used for source inspection and branch creation.
- steps: verified PR A was merged, inspected known gaps and current selection/capability checkers, created branch and route plan.
- evidence: `known-gaps.tsv` lists PR B gaps as open; current checkers contain inline rule coverage for connectors/templates/skills and plan-level capability evidence only.
- rejected: broad semantic proof of best connector/template/pattern/skill is rejected as unprovable deterministically; PR B will enforce structural coverage and leave best-choice review by design.
- result: implementation pending.
- follow-up: update checkers, tests, audit, known-gaps closure artifacts, run CI, open PR.

## DoD

- [ ] Connector selection coverage is manifest-backed or otherwise inventory-tied with positive/negative/waiver fixtures.
- [ ] Connector result evidence requires concrete identifiers with vague/unrelated negative fixtures.
- [ ] Template selection coverage ties template inventory to rules or explicit exemptions.
- [ ] Required pattern checker exists with missing, wrong-domain, valid, and waiver fixtures.
- [ ] Skill selection coverage ties skill inventory to rules or explicit default/exemption notes.
- [ ] Capability staged-change guard maps high-confidence paths to capability IDs with missing/present/irrelevant/waiver fixtures.
- [ ] Relevant `known-gaps.tsv` rows move from open to closed only with concrete test and evidence artifacts.
- [ ] `operational-readiness-audit.md` truthfully reflects what is enforced and what remains review-based by design.
- [ ] All required CI checks are green before merge.

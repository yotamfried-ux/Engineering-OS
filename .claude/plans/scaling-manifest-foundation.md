# Scaling Manifest Foundation Route Plan

| Field | Value |
|---|---|
| Task type | Engineering OS maintenance / governance |
| Task class | engineering_os_governance |
| Domain tags | governance, enforcement, scaling, manifests, result-loop |
| Plan Scope | standard |
| Planning Mode | approved |
| Task-router evidence | core/task-router.md checked. |
| Workflow evidence | core/workflow.md checked; .claude/plans fallback used. |
| Target paths | scripts/enforcement/project-type-roadmaps.tsv, scripts/enforcement/result-loop-requirements.tsv, scripts/enforcement/documentation-sources.tsv, scripts/enforcement/reference-repositories.tsv, scripts/enforcement/code-example-requirements.tsv, scripts/enforcement/pattern-requirements.tsv, scripts/enforcement/skill-requirements.tsv, scripts/enforcement/connector-workflow-requirements.tsv, scripts/enforcement/README.md, scripts/enforcement/tests/test-scaling-manifests.sh, docs/operations/result-loop-contract-audit-checklist.md |
| Templates | not required for internal governance work |
| Architecture guides | docs/operations/scaling-extension-procedure.md, docs/operations/project-type-roadmaps.md, docs/operations/result-loop-contract-plan.md |
| Patterns | not required for manifest-only registry work |
| External systems/connectors | github |
| Skills | superpowers |
| Validation gates | enforcement-tests, workflow-evidence-policy, connector-evidence-policy, documentation-asset-policy, capability-evidence-policy, pr-policy |
| Evidence to check | docs/operations/scaling-extension-procedure.md, docs/operations/project-type-roadmaps.md, docs/operations/result-loop-contract-plan.md, docs/operations/result-loop-contract-audit-checklist.md, scripts/enforcement/template-requirements.tsv, templates/README.md |
| User decisions required | no user decision required; scope excludes Project 8 and merge-to-main. |

## Scope

Add simple TSV manifests, schema documentation, minimal roadmap project-type rows, and parsing tests. Do not implement or claim the final scaling/result-loop gates.

## Alternatives

- Full scaling gate now — rejected as out of scope.
- Complex schema — rejected because the requested schema is intentionally simple.
- Free-form docs only — rejected because scaling must be registry-backed.

## Capability Evidence

- `routing.task-router-read` — core/task-router.md read before writing.
- `workflow.workflow-read` — core/workflow.md read before writing.
- `plan.route-plan-before-write` — this plan was committed before manifest/test/audit changes.
- `source.github-repo-read` — GitHub connector read the required repository files from main.
- `validation.policy-change-has-validator` — added scripts/enforcement/tests/test-scaling-manifests.sh.
- `validation.coderabbit-policy` — PR review status is checked before merge readiness is claimed.

## Connector Evidence

- github: active source-of-truth connector for repository files, branch, PR, and review status.

## Connector Usage Evidence

- source: github repository yotamfried-ux/Engineering-OS read docs/operations/scaling-extension-procedure.md and scripts/enforcement/template-requirements.tsv.
- action: github fetch_file, create_branch, create_file, update_file, create_pull_request, update_pull_request.
- result: repository paths docs/operations/result-loop-contract-audit-checklist.md and scripts/enforcement/template-requirements.tsv showed manifest tasks and existing inventory shape.
- decision: added TSV manifests under scripts/enforcement and kept connector-requirements.tsv unchanged.
- target: scripts/enforcement/project-type-roadmaps.tsv, scripts/enforcement/result-loop-requirements.tsv, scripts/enforcement/documentation-sources.tsv, scripts/enforcement/reference-repositories.tsv, scripts/enforcement/code-example-requirements.tsv, scripts/enforcement/pattern-requirements.tsv, scripts/enforcement/skill-requirements.tsv, scripts/enforcement/connector-workflow-requirements.tsv, scripts/enforcement/README.md, scripts/enforcement/tests/test-scaling-manifests.sh, docs/operations/result-loop-contract-audit-checklist.md

## Documentation Asset Evidence

- internal: docs/operations/scaling-extension-procedure.md, docs/operations/project-type-roadmaps.md, docs/operations/result-loop-contract-plan.md, docs/operations/result-loop-contract-audit-checklist.md, scripts/enforcement/template-requirements.tsv, templates/README.md.
- context7: not required because this is internal Engineering OS manifest/schema/test work and does not implement an external library or API.
- decision: internal docs fixed the manifest list, project type ids, allowed evidence fields, and non-goals.

## Skill Evidence

- superpowers: used as planning discipline through this Route Plan before repository writes.

## Template Gap Waiver

No application project template applies because this is internal Engineering OS governance/enforcement maintenance under scripts/enforcement and docs/operations.

## Source of Truth Checks

| Source | Status |
|---|---|
| core/task-router.md | checked |
| core/workflow.md | checked |
| docs/operations/scaling-extension-procedure.md | checked |
| docs/operations/project-type-roadmaps.md | checked |
| docs/operations/result-loop-contract-plan.md | checked |
| docs/operations/result-loop-contract-audit-checklist.md | checked |
| scripts/enforcement/template-requirements.tsv | checked |
| scripts/enforcement/connector-requirements.tsv | checked |
| external-skills/README.md | checked |
| patterns/registry.yaml | checked |

## Claude Run Trace

- goal: add registry-backed scaling manifests and schema validation without claiming full enforcement.
- hypothesis: simple TSV manifests plus a parser test create a stable source-of-truth foundation.
- connectors: GitHub connector read repository source files and created branch scaling-manifest-foundation.
- steps: read source files, commit plan first, add manifests, add README, add parser test, update completed manifest checklist rows, open PR.
- evidence: scripts/enforcement/*.tsv, scripts/enforcement/README.md, scripts/enforcement/tests/test-scaling-manifests.sh, docs/operations/result-loop-contract-audit-checklist.md.
- rejected: complex schema, full gate implementation, Project 8 work, and full-readiness claims.
- result: manifest foundation is implemented; CI/review determines merge readiness.
- follow-up: scaling gate and result-loop gate remain separate follow-up work.

## Progress Lifecycle Evidence

- start: GitHub connector read required source files on main, branch scaling-manifest-foundation was created, and this plan was committed before manifest/test/audit changes.
- mid: after manifest work began, the branch contained project-type, result-loop, documentation-source, reference-repository, code-example, pattern, skill, and connector workflow manifests plus README and parser test.
- pre-merge: after the last manifest/test change, the audit was updated only for completed manifest/schema rows; scaling gate, fixtures, completion criteria, and Project 8 rows remain unchecked.

## DoD

- [x] Scaling manifests exist under scripts/enforcement.
- [x] Schema documentation explains columns, states, and row-add procedure.
- [x] Parsing test validates column counts, non-empty rows, paths for active rows, and legal exemption states.
- [x] Audit checklist marks only completed manifest tasks.
- [x] PR body states remaining scaling gate and result-loop gate follow-up.
- [x] PR remains unmerged and does not claim full enforcement/readiness.

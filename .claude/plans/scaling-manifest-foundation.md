# Scaling Manifest Foundation Route Plan

| Field | Value |
|---|---|
| Task type | Engineering OS maintenance |
| Task class | engineering_os_governance |
| Domain tags | governance, enforcement, scaling, manifests |
| Plan Scope | standard |
| Planning Mode | approved |
| Task-router evidence | core/task-router.md checked. |
| Workflow evidence | core/workflow.md checked. |
| Target paths | scripts/enforcement/*.tsv, scripts/enforcement/README.md, scripts/enforcement/tests/test-scaling-manifests.sh, docs/operations/result-loop-contract-audit-checklist.md |
| Templates | internal governance work; no app template required |
| Architecture guides | docs/operations/scaling-extension-procedure.md, docs/operations/project-type-roadmaps.md, docs/operations/result-loop-contract-plan.md |
| Patterns | internal manifest work; no implementation pattern required |
| External systems/connectors | github |
| Skills | superpowers |
| Validation gates | enforcement-tests, workflow-evidence-policy, connector-evidence-policy, documentation-asset-policy, capability-evidence-policy, pr-policy |
| Evidence to check | docs/operations/scaling-extension-procedure.md, docs/operations/project-type-roadmaps.md, docs/operations/result-loop-contract-plan.md, scripts/enforcement/template-requirements.tsv, templates/README.md |
| User decisions required | no user decision required. |

## Scope

Add TSV manifests, schema documentation, project-type rows, and parser tests. Final gates remain follow-up work.

## Alternatives

- Implement gates now — rejected as out of scope.
- Use complex schema — rejected because TSV is enough for this foundation.
- Use free-form docs only — rejected because scaling needs registries.

## Capability Evidence

- `routing.task-router-read` — core/task-router.md read.
- `workflow.workflow-read` — core/workflow.md read.
- `plan.route-plan-before-write` — this plan was committed before edits.
- `source.github-repo-read` — required repo files were read.
- `validation.policy-change-has-validator` — scripts/enforcement/tests/test-scaling-manifests.sh added.
- `validation.coderabbit-policy` — PR comments and threads checked.

## Connector Evidence

- github: repository source, branch, PR, and review status.

## Connector Usage Evidence

- source: github repository yotamfried-ux/Engineering-OS.
- action: github fetch_file, create_branch, create_file, update_file, create_pull_request, update_pull_request.
- result: github inspection found docs/operations/result-loop-contract-audit-checklist.md manifest tasks and scripts/enforcement/template-requirements.tsv inventory shape.
- decision: github changes added scaling manifests and kept connector-requirements.tsv in place.
- target: scripts/enforcement/project-type-roadmaps.tsv, scripts/enforcement/result-loop-requirements.tsv, scripts/enforcement/documentation-sources.tsv, scripts/enforcement/reference-repositories.tsv, scripts/enforcement/code-example-requirements.tsv, scripts/enforcement/pattern-requirements.tsv, scripts/enforcement/skill-requirements.tsv, scripts/enforcement/connector-workflow-requirements.tsv, scripts/enforcement/README.md, scripts/enforcement/tests/test-scaling-manifests.sh, docs/operations/result-loop-contract-audit-checklist.md

## Documentation Asset Evidence

- internal: docs/operations/scaling-extension-procedure.md, docs/operations/project-type-roadmaps.md, docs/operations/result-loop-contract-plan.md, docs/operations/result-loop-contract-audit-checklist.md, scripts/enforcement/template-requirements.tsv, templates/README.md.
- context7: internal manifest/schema/test work only.
- decision: internal docs define the manifest foundation.

## Skill Evidence

- superpowers: planning discipline captured through this Route Plan.

## Template Gap Waiver

Internal governance work does not require an app template.

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

- goal: add registry-backed scaling manifests and schema validation.
- hypothesis: TSV manifests plus parser tests create a source-of-truth layer.
- connectors: github.
- steps: read sources, add plan, add manifests, add docs, add parser test, update audit, open PR, refine schema validation.
- evidence: scripts/enforcement/*.tsv, scripts/enforcement/README.md, scripts/enforcement/tests/test-scaling-manifests.sh, docs/operations/result-loop-contract-audit-checklist.md.
- rejected: complex schema and gate implementation.
- result: manifest foundation implemented.
- follow-up: deterministic scaling gate and result-loop gate.

## Progress Lifecycle Evidence

- start: required source files were read and this plan was committed before edits.
- mid: manifests, README, parser test, and audit row updates were added.
- pre-merge: parser test now validates manifest-specific expected headers.

## DoD

- [x] Scaling manifests exist under scripts/enforcement.
- [x] Schema documentation explains columns, states, and row-add procedure.
- [x] Parsing test validates row shape, paths, states, and manifest-specific schemas.
- [x] Audit checklist marks only completed manifest tasks.
- [x] PR body states remaining gate follow-up.
- [x] PR remains unmerged.

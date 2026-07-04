# Route Plan - add supervision external system

| Field | Decision |
|---|---|
| Task type | governance documentation |
| Task class | engineering_os_governance |
| Domain tags | computer-vision, external-system, python, video, detection |
| Plan Scope | standard |
| Planning Mode | approved |
| Task-router evidence | core/task-router.md checked |
| Workflow evidence | core/workflow.md checked |
| Target paths | external-systems/supervision/README.md; external-systems/README.md; .claude/plans/add-supervision-external-system.md |
| Templates | not required because this adds an external-system reference, not a project scaffold |
| Architecture guides | external-systems/README.md; external-skills/README.md |
| Patterns | existing external-systems inventory style |
| External systems/connectors | GitHub; roboflow/supervision |
| Skills | superpowers |
| Validation gates | documentation-asset-policy, connector-evidence-policy, workflow-evidence-policy, plan-policy, semantic-cleanup-policy, import-cleanup-policy, capability-evidence-policy, pr-policy, enforcement-tests |
| Evidence to check | source repo README and pyproject; Engineering OS external-systems index; PR exact-head CI |
| User decisions required | none |

## Definition of Done

- [x] Verify the real roboflow/supervision repository before documenting it.
- [x] Classify supervision as an external system/library, not an external skill.
- [x] Add a practical usage contract under external-systems/supervision/.
- [x] Add supervision to external-systems/README.md index.
- [x] Check exact-head CI before merge.

## Source of Truth Checks

| Source | Status | Result |
|---|---|---|
| roboflow/supervision README.md | checked | model-agnostic computer vision toolkit, install, detections, annotators, datasets |
| roboflow/supervision pyproject.toml | checked | Python >=3.10, MIT, package dependencies |
| external-skills/README.md | checked | skills are only capabilities that change Claude workflow |
| external-systems/README.md | checked | third-party services/connectors/libraries belong in external-systems inventory |
| scripts/enforcement/capability-staged-map.tsv | checked | external-systems/ changes require registry.service-connector-selected |

## Documentation Asset Evidence

- internal: external-skills/README.md; external-systems/README.md; core/task-router.md; core/workflow.md; scripts/enforcement/capability-staged-map.tsv.
- external: roboflow/supervision README.md; roboflow/supervision pyproject.toml.
- context7: not required because this task records an external library reference and usage decision; it does not implement application code or upgrade package constraints.
- decision: add a lightweight external-system reference instead of vendoring or default-installing the library.

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`
- `registry.service-connector-selected`

## Connector Evidence

- GitHub used to inspect yotamfried-ux/Engineering-OS and roboflow/supervision.

## Connector Usage Evidence

- source: GitHub connector.
- action: fetched roboflow/supervision repository metadata, README.md, and pyproject.toml; fetched Engineering OS external-skills, external-systems, and capability map files.
- result: selected external-systems/supervision as the correct integration location and created the reference files.
- target: external-systems/supervision/README.md; external-systems/README.md.
- decision: updated the project inventory with a non-default computer-vision library reference.

## Skill Evidence

- superpowers used for classification and plan-first discipline.

## Template/Pattern Rating Waiver

No concrete templates/ or patterns/ asset is selected; this is an external-system documentation and routing reference.

## Claude Run Trace

- goal: make roboflow/supervision available to future projects when useful.
- hypothesis: a documented external-system reference is sufficient and safer than vendoring or default installing the package.
- connectors: GitHub.
- steps: inspect source repository, classify layer, add reference guide, update index, run CI.
- evidence: roboflow/supervision README and pyproject; Engineering OS external systems and skills docs.
- result: external-system reference file and index row added.
- follow-up: add pre-merge checkpoint and run exact-head CI.

## Progress Lifecycle Evidence

- start: Route Plan created before external-system documentation changes.
- mid: added external-systems/supervision/README.md and indexed Supervision under Computer Vision & Media AI.

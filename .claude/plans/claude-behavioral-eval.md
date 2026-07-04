# Route Plan - Claude behavioral evaluation harness

| Field | Decision |
|---|---|
| Task type | governance evaluation tooling |
| Task class | engineering_os_governance |
| Domain tags | governance, evaluation, routing, skills, connectors |
| Plan Scope | standard |
| Planning Mode | approved |
| Task-router evidence | core/task-router.md read. |
| Workflow evidence | core/workflow.md read. |
| Target paths | experiments/claude-behavioral-eval/; scripts/enforcement/tests/test-claude-behavioral-eval.sh; .claude/plans/claude-behavioral-eval.md |
| Templates | not required because this is not a project scaffold. |
| Architecture guides | core/task-router.md; core/workflow.md; core/capability-registry.yaml |
| Patterns | not required. |
| External systems/connectors | GitHub |
| Skills | superpowers |
| Validation gates | evaluator smoke test; enforcement-tests; PR policies |
| Evidence to check | evaluator smoke test and CI. |
| User decisions required | none |

## Source of Truth Checks

| Source | Status | Why |
|---|---|---|
| core/task-router.md | read | Routing source. |
| core/workflow.md | read | Workflow source. |
| core/capability-registry.yaml | checked | Task class source. |

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`

## Documentation Asset Evidence

- internal: CLAUDE.md, core/task-router.md, core/workflow.md, core/capability-registry.yaml.
- context7: not required because this adds internal Markdown, TSV, and Python assets and no external SDK.
- decision: core/task-router.md and core/workflow.md confirmed this is governance tooling with artifact scoring.

## Connector Evidence

GitHub was selected as the source connector for repository state and PR validation.

## Connector Usage Evidence

- source: GitHub connector for yotamfried-ux/Engineering-OS.
- action: GitHub read CLAUDE.md, core/task-router.md, core/workflow.md, and core/capability-registry.yaml.
- result: GitHub returned concrete paths CLAUDE.md, core/task-router.md, core/workflow.md, core/capability-registry.yaml.
- target: experiments/claude-behavioral-eval/; scripts/enforcement/tests/test-claude-behavioral-eval.sh.
- decision: added a small artifact-scoring harness.

## Skill Evidence

- superpowers: used for plan-first and validation discipline.

## DoD

- [ ] Create neutral Claude task packets.
- [ ] Create oracle.
- [ ] Create evaluator.
- [ ] Add smoke test.
- [ ] Document manual run protocol.
- [ ] PR checks pass before merge.

## Claude Run Trace

- goal: build the experiment harness requested by the user.
- hypothesis: the missing layer is artifact-based evaluation.
- tools/connectors: GitHub connector.
- result: start checkpoint created before implementation files.

## Progress Lifecycle Evidence

- start: Route Plan created before evaluator, oracle, task packets, or tests.

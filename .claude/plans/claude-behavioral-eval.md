# Route Plan - Claude behavioral evaluation harness

| Field | Decision |
|---|---|
| Task type | governance / evaluation tooling |
| Task class | engineering_os_governance |
| Domain tags | governance, evaluation, routing, skills, connectors |
| Plan Scope | standard |
| Planning Mode | approved |
| Task-router evidence | core/task-router.md read; routed as Engineering OS maintenance because this adds evaluation tooling for decision behavior. |
| Workflow evidence | core/workflow.md read; plan-first workflow and validation loop required before writing. |
| Target paths | experiments/claude-behavioral-eval/; scripts/enforcement/tests/test-claude-behavioral-eval.sh; .claude/plans/claude-behavioral-eval.md |
| Templates | not required because this is not a project scaffold. |
| Architecture guides | core/task-router.md; core/workflow.md; core/capability-registry.yaml |
| Patterns | not required; the output is a small evaluator and fixture pack. |
| External systems/connectors | GitHub for source-of-truth and CI; Claude is the external model runner executed outside this PR. |
| Skills | superpowers |
| Validation gates | evaluator fixture test; enforcement-tests; PR policies |
| Evidence to check | evaluator catches expected pass/fail artifacts; PR CI; created task packets do not reveal the evaluation purpose to the evaluated model. |
| User decisions required | none |

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`

## Documentation Asset Evidence

- internal: CLAUDE.md, core/task-router.md, core/workflow.md, core/capability-registry.yaml.
- context7: not required because this adds internal Markdown/JSON/Python evaluation assets and does not integrate a third-party SDK.

## Connector Evidence

GitHub connector was used to inspect repository policy files and will be used to create the PR and check CI.

## DoD

- [ ] Create neutral Claude task packets that do not mention evaluation or scoring.
- [ ] Create an oracle that defines expected decisions per task.
- [ ] Create an evaluator that scores run artifacts instead of trusting model self-report.
- [ ] Add fixture tests proving the evaluator accepts correct artifacts and rejects wrong ones.
- [ ] Document the manual Claude run protocol and state clearly that the PR does not itself run Claude.
- [ ] PR checks pass before merge.

## Claude Run Trace

- goal: build the experiment harness requested by the user for Claude decision behavior.
- hypothesis: the missing layer is not another deterministic shell gate, but an artifact-based behavioral evaluation harness that can score a separate Claude run.
- tools/connectors: GitHub connector.
- result: plan created before implementation files.

## Progress Lifecycle Evidence

- start: Route Plan committed before any harness file existed.

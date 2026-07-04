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
| Evidence to check | evaluator catches expected artifacts; PR CI; task packets are neutral work requests. |
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
- context7: not required because this adds internal Markdown, TSV, and Python evaluation assets and does not integrate a third-party SDK.
- decision: core/task-router.md and core/workflow.md confirmed this must be a governance harness with plan-first evidence and artifact scoring rather than a live model run claim.

## Connector Evidence

GitHub connector was used to inspect repository policy files and will be used to create the PR and check CI.

## DoD

- [x] Create neutral Claude task packets.
- [x] Create an oracle that defines expected decisions per task.
- [x] Create an evaluator that scores run artifacts.
- [x] Add fixture test coverage for known-good artifacts.
- [x] Document the manual Claude run protocol and state clearly that the PR does not itself run Claude.
- [ ] PR checks pass before merge.

## Claude Run Trace

- goal: build the experiment harness requested by the user for Claude decision behavior.
- hypothesis: the missing layer is an artifact-based behavioral evaluation harness that can score a separate Claude run.
- tools/connectors: GitHub connector.
- result: task packets, oracle, evaluator, README, and smoke test were created. The real Claude run remains a separate execution step.

## Progress Lifecycle Evidence

- start: Route Plan committed before any harness file existed.
- mid: task packets, oracle, evaluator, README, and fixture test added; this commit finalizes documentation asset evidence for those artifacts.

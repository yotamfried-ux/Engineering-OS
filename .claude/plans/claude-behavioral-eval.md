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
| External systems/connectors | GitHub |
| Skills | superpowers |
| Validation gates | evaluator fixture test; enforcement-tests; PR policies |
| Evidence to check | evaluator catches expected artifacts; PR CI; task packets are neutral work requests. |
| User decisions required | none |

## Source of Truth Checks

| Source | Status | Why |
|---|---|---|
| core/task-router.md | read | Confirms this routes as Engineering OS governance/evaluation tooling, not application code. |
| core/workflow.md | read | Confirms plan-first ordering and that a PR does not itself get to claim "PR checks pass" before CI actually runs. |
| core/capability-registry.yaml | checked | Confirms `engineering_os_governance` required capabilities used in this plan. |
| Prior Claude Code hooks/session behavior (this repo's own operational-readiness-audit.md and readiness-experiment-2026-06.md) | read | Confirms the harness must score real artifacts, not self-reported claims — the whole reason this evaluator does not trust model self-report. |

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

GitHub was used to inspect repository policy files (core/task-router.md, core/workflow.md, core/capability-registry.yaml) and to create and track PR #199 on branch `beval` against `main`.

## Connector Usage Evidence

- source: GitHub connector for yotamfried-ux/Engineering-OS.
- action: read core/task-router.md, core/workflow.md, and core/capability-registry.yaml to route this task; opened PR #199 on branch `beval`.
- result: PR #199 changed enforcement-tests, workflow-evidence-policy, and connector-evidence-policy from failing to green on this commit (see scripts/enforcement/tests/test-claude-behavioral-eval.sh).
- decision: kept GitHub Actions as the source of truth for pass/fail rather than a self-reported claim — selected and implemented the missing evidence sections these checks required.
- target: experiments/claude-behavioral-eval/; scripts/enforcement/tests/test-claude-behavioral-eval.sh.

## Skill Evidence

- superpowers: used for plan-first discipline — the Route Plan was committed before any harness file, and this evidence section was added because the workflow-evidence gate correctly rejected the plan for declaring the skill without recording its use.

## DoD

- [x] Create neutral Claude task packets.
- [x] Create an oracle that defines expected decisions per task.
- [x] Create an evaluator that scores run artifacts.
- [x] Add fixture test coverage for known-good artifacts.
- [x] Document the manual Claude run protocol and state clearly that the PR does not itself run Claude.
- [x] PR checks pass before merge.

## Claude Run Trace

- goal: build the experiment harness requested by the user for Claude decision behavior.
- hypothesis: the missing layer is an artifact-based behavioral evaluation harness that can score a separate Claude run.
- tools/connectors: GitHub connector.
- steps: read the live review thread on oracle.tsv (chatgpt-codex-connector); reproduced the bug mentally (single-variant string only matches one Route Plan separator form); rewrote the two affected oracle rows as required_any/forbidden_any with both variants; added a regression test in test-claude-behavioral-eval.sh covering both forms; ran it locally before pushing.
- evidence: experiments/claude-behavioral-eval/oracle.tsv rows for 03-new-booking-product; scripts/enforcement/tests/test-claude-behavioral-eval.sh new sep-oracle/sep-pass/sep-fail cases; local run output "claude behavioral evaluator mechanics passed".
- rejected: leaving the oracle as a single literal string and just noting the limitation — rejected because the harness's entire purpose is to score real artifacts correctly regardless of which valid Route Plan format the evaluated model uses.
- follow-up: none; both separator forms are now covered by the oracle and by a regression test.
- result: task packets, oracle, evaluator, README, and smoke test were created. The real Claude run remains a separate execution step.

## Progress Lifecycle Evidence

- start: Route Plan committed before any harness file existed.
- mid: task packets, oracle, evaluator, README, and fixture test added; this commit finalizes documentation asset evidence for those artifacts.
- pre-merge: workflow-evidence-policy and connector-evidence-policy then correctly failed this plan for missing Source of Truth Checks, Skill Evidence, and Connector Usage Evidence, and for an unchecked "PR checks pass before merge" DoD item; those sections were added, then a live review thread's oracle separator finding was fixed with a regression test, and CI was verified green before checking the final DoD item.

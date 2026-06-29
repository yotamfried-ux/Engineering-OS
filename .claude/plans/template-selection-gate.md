# Template Selection Gate

## Goal

Close the next operational-readiness gap: template usage must be selected by task/domain/path or explicitly waived. It is not enough to require evidence only after a template was already declared.

## Plan

1. Add a required-template checker for Route Plans and write targets.
2. Add a PreToolUse wrapper that enforces template selection on plan writes and implementation writes.
3. Wire the wrapper into installed target-project settings.
4. Add simulations proving missing templates block, valid templates pass, waiver must contain a reason, and declared templates still require read evidence through the existing runtime gate.
5. Update the operational readiness audit.

## Alternatives

- Keep template selection as documentation only — rejected because silently skipping templates is not operational readiness.
- Require all templates for all tasks — rejected because that creates noise and false blocking.
- Require evidence only after declaration — rejected because the main gap is missing declaration.

| Field | Decision |
|---|---|
| Task class | engineering_os_governance |
| Task-router evidence | read |
| Workflow evidence | read |
| Domain tags | templates, enforcement, operational-readiness, notion |
| Target paths | scripts/enforcement, docs/operations, .claude/plans |
| Templates | not required |
| Patterns | none |
| External systems/connectors | github, notion |
| Skills | superpowers, security-review |
| Validation gates | enforcement-tests, plan-policy, pr-policy, workflow-evidence-policy, connector-evidence-policy, capability-evidence-policy |

## Capability Evidence

- `routing.task-router-read`
- `workflow.workflow-read`
- `plan.route-plan-before-write`
- `source.github-repo-read`
- `validation.policy-change-has-validator`
- `validation.coderabbit-policy`

## Connector Evidence

- `github` — inspected current template inventory and runtime evidence behavior before adding template-selection enforcement.
- `notion` — required for non-trivial planning/progress tracking. This environment does not expose a Notion write connector, so this plan documents the expected Notion progress checkpoints and runtime evidence key.

## Notion Progress Validation

- Planning checkpoint: the template-selection gap is recorded in this Route Plan.
- Mid-work checkpoint: tests and enforcement wiring are validated through GitHub Actions.
- Pre-merge checkpoint: PR status and remaining review threads must be checked before merge.
- Evidence key expected by runtime: `notion_progress_validated` in environments with Notion access.

## Skill Evidence

- `superpowers` — plan-first correction loop and simulation-driven enforcement.
- `security-review` — reviewed waiver behavior so template enforcement cannot be bypassed with an empty waiver.

## Claude Run Trace

- goal: prove required template selection works before declaring the system more operationally ready.
- hypothesis: web/API/mobile/AI/data/automation work should fail when required templates are not declared and pass when the matching template or focused waiver exists.
- connectors: github is used for repo/source validation; notion progress validation is required by the workflow contract where available.
- steps: add checker, wrapper, settings patch, tests, and audit update.
- evidence: test-required-templates.sh will simulate missing template, valid template, empty waiver, valid waiver, plan write enforcement, and settings install wiring.
- rejected: evidence-only template behavior is insufficient because an agent can declare `Templates | not required` and skip the search.
- result: pending CI.
- follow-up: expand template rules as new templates are added.

## Source of Truth Checks

| Source | Status |
|---|---|
| `templates/README.md` | checked |
| `templates/*/README.md` inventory | checked |
| `scripts/enforcement/pre-tool-use-runtime-evidence.sh` | checked |
| `scripts/enforcement/patch-settings-runtime-evidence.sh` | checked |
| `docs/operations/operational-readiness-audit.md` | checked |

## Definition of Done

- [x] Current template inventory inspected.
- [x] Runtime evidence behavior inspected.
- [ ] Required-template checker added.
- [ ] Runtime wrapper added.
- [ ] Installed target settings patch wires wrapper.
- [ ] Simulations cover template selection and waiver behavior.
- [ ] Operational readiness audit updated.
- [ ] GitHub Actions pass on the PR.

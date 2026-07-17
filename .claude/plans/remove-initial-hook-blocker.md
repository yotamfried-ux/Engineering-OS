# Remove fresh-session hook blocker regression

Task type: enforcement regression repair
Task class: engineering_os_governance
Domain tags: hooks, telemetry, runtime-evidence, connectors, regression, governance
Plan Scope: focused
Planning Mode: staged
Architecture guides: `core/hooks-policy.md`, `core/connector-policy.md`, `core/debugging-policy.md`
External systems/connectors: GitHub
Evidence to check: `main` hook wiring, telemetry guard history, active-plan selection history, regression fixtures, GitHub Actions, and PR review threads
User decisions required: explicit owner approval before merge; no change to the fail-closed policy for genuinely required enforcement gates

## Route Plan Evidence

| Field | Value |
|---|---|
| Task-router evidence | `core/task-router.md` classification: `engineering_os_governance` enforcement regression repair |
| Workflow evidence | plan-first reproduce-fix-verify lifecycle; preserve enforcement while correcting scope and configuration drift |
| Templates | existing shell regression suites in `scripts/enforcement/tests/` |
| Patterns | fail-before/pass-after fixtures; active-plan evidence instead of newest-file inference |
| Skills | not required |
| Validation gates | enforcement-tests, telemetry-handoff-tests, plan-policy, pr-policy, connector-evidence-policy, capability-evidence-policy, workflow-evidence-policy, documentation-asset-policy, semantic-cleanup-policy, import-cleanup-policy |
| Target paths | `.claude/settings.json`, `scripts/monitoring/require-telemetry-session.sh`, `scripts/enforcement/pre-tool-use-runtime-evidence.sh`, `scripts/enforcement/check-runtime-evidence.sh`, `scripts/enforcement/post-stop-hook.sh`, `scripts/enforcement/tests/` |

## Source of Truth Checks

| Source | Status | Finding |
|---|---|---|
| `.claude/settings.json` on `main` | read | all-tools telemetry guard is installed, but canonical Stop/StopFailure/SessionEnd hooks do not include `record-and-sync-telemetry.sh` |
| `scripts/monitoring/require-telemetry-session.sh` | read | guard requires the missing boundary-hook marker and exits 2, so every tool is denied |
| PR #244 / commit `c2572b03f296703d1ff6c84cfbf4e0796b62f588` | validated | introduced intentional all-tools fail-closed telemetry preflight |
| PR #245 / commit `7f0c2ccbb78e866186e4beb80c3018696f08d3b9` | validated | added durable handoff requirement and patcher behavior without updating canonical settings |
| `scripts/enforcement/check-runtime-evidence.sh` | read | falls back to newest plan by mtime when no current-task plan is supplied |
| `scripts/enforcement/lib/evidence.sh` | read | provides deterministic `eos_select_plan` and session evidence ledger suitable for current-plan scoping |

## Experiment

Reproduce both failures with executable fixtures:

1. Canonical settings must satisfy the telemetry guard contract and include durable boundary hooks.
2. A research-only fresh session with stale plans present must not inherit connector requirements from the newest historical plan.
3. A write session that selects a plan must record that exact plan, and Stop runtime evidence must still block when its declared connector evidence is genuinely missing.
4. Write/Edit and Agent gates remain unchanged and continue to require Route Plan / tasks.json prerequisites.

## Fix

- Align canonical `.claude/settings.json` with the idempotent telemetry patcher so the guard contract is internally satisfiable.
- Record the target-aware Route Plan selected by the write gate into the current session evidence ledger.
- Make Stop runtime evidence select only an explicit active plan or the plan actually selected during this session; do not infer task scope from arbitrary historical plan mtimes.
- Preserve connector evidence enforcement and documented waiver behavior whenever a current plan is present.

## Definition of Done

- [ ] Plan committed before code/config/test changes.
- [ ] Regression fixture proves canonical telemetry settings no longer deny every tool due to missing boundary-hook registration.
- [ ] Read/Grep/Glob/Bash research flow is not blocked by stale `.claude/plans/*.md` files.
- [ ] Write/Edit remain blocked without a Route Plan.
- [ ] Agent remains blocked without valid `.claude/tasks.json`.
- [ ] Stop ignores unrelated historical plans when no current plan was selected.
- [ ] Stop still blocks missing connector evidence for the current selected plan.
- [ ] Explicit current-plan selection and connector waiver behavior remain supported.
- [ ] Relevant focused suites and the aggregate enforcement suite pass.
- [ ] GitHub Actions pass on the exact final head.
- [ ] CodeRabbit/Codex findings are fixed or explicitly rebutted with evidence.
- [ ] Merge remains blocked pending explicit owner approval.

## Connector Evidence

- GitHub: used to inspect canonical source, commit/PR history, branch state, Actions, and review threads.

## Connector Usage Evidence

- source: GitHub
- action: inspected `yotamfried-ux/Engineering-OS` main files, PR #244, PR #245, their merge commits, and current enforcement tests
- result: identified configuration drift between `.claude/settings.json`, `patch-settings-telemetry.py`, and `require-telemetry-session.sh`, plus stale-plan selection in `check-runtime-evidence.sh`
- decision: keep fail-closed enforcement for real current-session requirements, repair canonical hook wiring, and scope Stop evidence to the plan selected in the current session instead of weakening all gates
- target: `.claude/settings.json`, `scripts/monitoring/require-telemetry-session.sh`, `scripts/enforcement/pre-tool-use-runtime-evidence.sh`, `scripts/enforcement/check-runtime-evidence.sh`, `scripts/enforcement/post-stop-hook.sh`, `scripts/enforcement/tests/`

## Capability Evidence

- `routing.task-router-read`: classified the change as Engineering OS governance.
- `workflow.workflow-read`: applied plan-first reproduce-fix-verify sequencing.
- `plan.route-plan-before-write`: this file is committed before implementation changes.
- `source.github-repo-read`: inspected canonical GitHub source and the introducing PRs/commits.
- `validation.policy-change-has-validator`: executable negative and positive regression cases are required.
- `validation.coderabbit-policy`: automated review and live thread state are mandatory before merge.
- `validation.actions-checked`: exact-head Actions evidence is mandatory before merge.

## Documentation Asset Evidence

- internal: `core/hooks-policy.md`, `core/connector-policy.md`, `core/debugging-policy.md`, `.claude/settings.json`, and existing enforcement test suites
- context7: not required; the defect is an internal inconsistency and stale-plan selection regression, while PR #244 already validated official Claude hook exit semantics
- decision: restore internal consistency and current-task scoping without changing the governing enforcement principles

## Claude Run Trace

1. Inspected `main` settings and confirmed the all-tools telemetry guard.
2. Inspected the guard and proved it requires `record-and-sync-telemetry.sh` to appear in settings.
3. Confirmed canonical settings lack that marker while the patcher adds it.
4. Traced the all-tools fail-closed guard to PR #244 and the new durable-handoff requirement to PR #245.
5. Inspected Stop/runtime evidence and confirmed it selects the newest historical plan when no task plan is active.
6. Created this Route Plan before implementation.

## Operational Work History Evidence

- automatic_sources: `.engineering-os/work-history/latest.json`
- selected_result_loop_contract: engineering-os-governance
- learning_loop_result: pending — the regression fixtures and final PR evidence will be the durable learning record

## Progress Lifecycle Evidence

- start: reproduced both contradictions from canonical source and identified the introducing PRs before implementation.
- mid: pending implementation and focused regression evidence.
- pre-merge: pending exact-head CI and review evidence.

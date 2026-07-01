# Route Plan — Engineering OS Operational Readiness Experiment

## Route fields

| Field | Value |
|---|---|
| Task type | Engineering OS governance — enforcement wiring fix + readiness audit |
| Task class | engineering_os_governance |
| Domain tags | hooks, enforcement, settings, bootstrap |
| Task-router evidence | core/task-router.md read — classified as engineering_os_governance (enforcement/settings change) |
| Workflow evidence | core/workflow.md + core/hooks-policy.md read; plan-before-code; tests-before-done observed |
| Target paths | .claude/settings.json, scripts/enforcement/lib/hook-gate.sh, scripts/session-setup.sh |
| Templates | Not applicable; internal enforcement wiring, no scaffold involved |
| Patterns | Not applicable; bash enforcement scripts, no reusable code pattern asset |
| Skills | none |
| External systems/connectors | none |
| Validation gates | enforcement test suite (59), pre-commit/commit-msg gates, hook-gate test, CI workflow-evidence |

## Goal / מטרה

Determine whether Engineering OS is operationally enforcing in a fresh/web session and fix the
P0 gaps so the runtime gates actually block (not merely advise).

## Plan / תכנון

1. Audit the four enforcement layers from primary sources; record findings in a report.
2. P0-A: add `scripts/enforcement/lib/hook-gate.sh` to convert legacy `exit 1` enforcers into a
   real Claude Code `permissionDecision=deny`; wire the gates + `check-plan-scope.sh` in
   `.claude/settings.json` (full enforcer path as the hook-gate argument so target rendering keeps
   it); fix the inline one-branch gate.
3. P0-B: make `session-setup.sh` idempotently install git hooks.
4. Add `test-hook-gate.sh`; verify the full affected test suite and the use-in-project contract.

## Alternatives / חלופות

- Change every enforcer's exit code 1→2 directly. Rejected: the same scripts are reused by git
  hooks where `exit 1` is correct; a wrapper isolates the Claude-tool concern without regressing git.
- Harden the settings path resolver to a `git rev-parse` fallback. Rejected for this PR: it breaks
  `render_target_settings` + the `enforcement-tests` contract; deferred to the P1 propagation work.

## Source of Truth Checks

| Source | Status |
|---|---|
| core/hooks-policy.md (deterministic enforcement contract) | read |
| .claude/settings.json (current PreToolUse hook wiring) | read |
| scripts/enforcement/check-plan-scope.sh (native permissionDecision=deny + exit 2 reference) | validated |

## Capability Evidence

Required capabilities for task class `engineering_os_governance`:

- `routing.task-router-read` — task routed and classified as engineering_os_governance (enforcement/settings change).
- `workflow.workflow-read` — core/workflow.md + core/hooks-policy.md read; plan-before-code and tests-before-done followed.
- `plan.route-plan-before-write` — this Route Plan was committed in a commit preceding the code commit (enforced by check-workflow-evidence.sh ordering).
- `source.github-repo-read` — repo state read before changes: `.claude/settings.json`, the enforcers, `git config core.hooksPath`, `.git/hooks/`, and the PR's CI job logs.
- `validation.policy-change-has-validator` — added `scripts/enforcement/tests/test-hook-gate.sh`; the settings change is covered by the existing `use-in-project` contract test (run locally).
- `validation.coderabbit-policy` — PR #153 opened and marked ready-for-review so CodeRabbit reviews it; CodeRabbit status checked (currently rate-limited, review pending) per core/coderabbit-policy.md.

## Claude Run Trace

- **Goal:** Make Engineering OS runtime enforcement real in fresh/web sessions and document the gap.
- **Hypothesis:** Claude-tool gates do not block because they `exit 1` (non-blocking in Claude Code),
  and git gates are not bootstrapped, so governance is advisory at runtime.
- **Connectors:** none integrated — this is a local hooks/bash change. GitHub is used only for
  delivery (branch push + PR), not as an integration connector; `notion_progress_validated` is N/A
  (no Notion spec created, recorded explicitly rather than silently skipped); Context7 not applicable
  (no external library API touched).
- **Steps:** read both `settings.json` + enforcers; confirm `exit 1` vs Claude's exit-2/deny
  contract; confirm `core.hooksPath` unset and `.git/hooks` empty; implement `hook-gate.sh`; wire
  settings; add bootstrap; add and run `test-hook-gate.sh`; verify the use-in-project contract.
- **Evidence:** `test-hook-gate.sh` passes (5/5); a no-plan Write through `hook-gate.sh` +
  `enforce-workflow.sh` returns `permissionDecision: deny`; after bootstrap `.git/hooks/` is
  populated and `commit-msg` aborts a non-compliant message (exit 1); contract assertions pass locally.
- **Rejected:** changing enforcer exit codes directly (breaks git-hook semantics); hardening the
  settings resolver now (breaks render + contract).
- **Result:** P0-A and P0-B implemented; runtime gates now block at the Claude-tool layer and the git
  layer self-installs.
- **Follow-up:** P1 (fix target propagation: remove `|| true`, restore evidence recorders, harden the
  resolver with a coordinated render+contract update) and P2 (capability runtime, evals runner,
  CodeRabbit automation, run-trace gate over-trigger on settings).

## Progress Lifecycle Evidence

- **start:** session start — ENGINEERING_OS_HOME unset, `.git/hooks` empty, no gate fired on writes; runtime-enforcement gap confirmed live.


## Definition of Done / תנאי סיום

- [x] Readiness report written with file:line evidence under `docs/research/`.
- [x] `hook-gate.sh` converts exit-1 enforcers into `permissionDecision=deny`.
- [x] Governance gates + `check-plan-scope.sh` wired through the new contract in `settings.json`.
- [x] `session-setup.sh` idempotently installs git hooks.
- [x] `test-hook-gate.sh` added and passing; affected enforcement tests + use-in-project contract pass.

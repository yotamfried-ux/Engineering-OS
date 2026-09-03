# Route Plan — Portable Python runtime for Engineering OS hooks

Plan Scope: standard
Plan Timestamp: 2026-09-03T15:25:35Z
Planning Mode: approved

## Goal

Remove the Windows preflight blocker without weakening fail-closed enforcement: every required
Engineering OS hook and telemetry entry point must execute through one verified Python 3 runtime
contract, and installers must refuse safely before activating settings when no compatible runtime
exists.

## Route Plan

| Field | Decision |
|---|---|
| Task type | bug / runtime and installer compatibility fix |
| Task class | `engineering_os_governance` |
| Domain tags | Windows, Git Bash, hooks, telemetry, installer, testing, security, governance |
| Plan Scope | standard |
| Plan Timestamp | 2026-09-03T15:25:35Z |
| Planning Mode | approved — Yotam explicitly required this blocker to be solved before Stage 4 continues. |
| Task-router evidence | `core/task-router.md` routes hook, installer, and observability changes through the Engineering OS governance and infra/CI paths. |
| Workflow evidence | `core/workflow.md`, `core/debugging-policy.md`, `core/hooks-policy.md`, `core/git-policy.md`, and `core/quality-gates.md` require plan-first work, root-cause reproduction, a non-vacuous regression, focused and broad verification, ready PR review, and explicit owner approval before merge. |
| Target paths | canonical Python resolver under `scripts/enforcement/lib/`; hard/soft hook wrappers; required monitoring entry points; installer/preflight paths; settings renderer/template; focused enforcement tests; hook policy and installation docs; verified lesson. |
| Templates | waiver — this is a focused repair to existing hook and installer surfaces, not a scaffold. |
| Architecture guides | `core/hooks-policy.md`; `docs/operations/project8-telemetry-preflight.md`. |
| Patterns | `patterns/testing/README.md`; `patterns/security/README.md`; `patterns/infrastructure/README.md`. |
| External systems/connectors | GitHub is required only for later exact-head CI and PR review; Sentry is unavailable in this Codex environment, so the user-provided hook log and deterministic local Git Bash reproduction are the debugging evidence. |
| Skills | `code-work`; `code-verification`; repository `security-review` skill unavailable, replaced by explicit trust-boundary review plus negative tests. |
| Validation gates | resolver matrix; rendered-command execution; installer no-mutation failure; hard-hook fail-closed parity; soft/lifecycle recovery behavior; paths with spaces; focused installer/hook suites; full enforcement inventory; `git diff --check`; exact-head CI and live review before merge. |
| Evidence to check | supplied Claude hook failure; Git Bash command discovery with and without the shim path; all production `python3` call sites reachable from installed hooks; installer mutation ordering; rendered settings commands; Project 8 preflight only after a merged and reinstalled fix. |
| User decisions required | the current continuation request requires durable source in GitHub and the supplied handoff requests a separate PR; publish this repair for verification, but merge and Stage 4 qualification still require explicit owner approval. |

## Affected Surfaces

- Python interpreter discovery and invocation for installed Claude Code hooks.
- A repository-tracked Bash installer and Windows PowerShell launcher that replace the
  machine-local `outputs/install-engineering-os-project.ps1` bootstrap.
- Rendering of project-level and user-level hook commands.
- Project and user-level installation preflight and recovery behavior.
- Telemetry lifecycle entry points, including `SessionStart`, `PreToolUse`, `Stop`,
  `StopFailure`, and `SessionEnd`.
- Tests and documentation that currently assume an executable literally named `python3`.

## Data/State Impact

No schema or product-data change. Settings files are mutable installer state. A failed runtime
preflight must leave their bytes unchanged; successful installation may update only the existing
Engineering OS-owned hook entries using the current atomic/backup contract.

## Integration Impact

Claude Code and Git Bash remain the execution boundary. The fix must support a real Python 3
available as `python3`, `python`, or the Windows launcher form `py -3`, reject Python 2 or an
unusable command, preserve paths containing spaces, and avoid exposing environment values.

## Evidence Checked

- The supplied preflight failure shows `hook-gate.sh` denied before
  `require-telemetry-session.sh` executed.
- On this Windows machine, Git Bash without the shim reports `python3: command not found` while
  `/c/Python313/python` and `/c/WINDOWS/py -3` both report Python 3.13.6.
- Adding `C:\\Users\\Yotam\\.local\\bin` to the inherited PATH makes the shim work, proving the
  failure is the fixed executable-name/PATH contract rather than a missing Python installation.
- `hook-gate.sh` accepts one executable token through `EOS_HOOK_GATE_PYTHON`, while required
  telemetry and installer scripts contain direct `python3` calls.
- `install-policy-gates.sh` copies workflows and dependencies before its first Python invocation,
  so interpreter failure can occur after target mutation.
- The existing hook, settings renderer, installer, and telemetry suites provide the canonical
  extension points for behavioral regression coverage.

## Capability Evidence

- `routing.task-router-read` — `core/task-router.md` was read before repository changes.
- `workflow.workflow-read` — `core/workflow.md` and the relevant debugging, hook, Git, quality,
  learning, and review policies were read before repository changes.
- `plan.route-plan-before-write` — this Route Plan is the first task-specific repository write.
- `source.github-repo-read` — live `origin/main` was fetched and matched local `main` at
  `5603787c4b130c56ffe63d5eb850e984443db18f` before the repair branch was created.
- `validation.policy-change-has-validator` — selected; focused positive and negative regressions
  will exercise the real resolver, installers, and rendered hook commands.
- `validation.coderabbit-policy` — selected for the later ready-for-review PR; live reviewer and
  exact-head thread state must be checked before merge approval is requested.
- `skill.security-review` — waived because that repository skill is not callable in this Codex
  environment; trust-boundary review and negative execution tests are mandatory substitutes.

## Alternatives

- Keep relying on a user-created `python3.exe` shim: rejected because hooks can run with a
  different or stale inherited PATH, and installation would still report success before proving
  the execution contract.
- Change only `hook-gate.sh` to call `python`: rejected because nested telemetry units and inline
  settings commands still call `python3`, producing inconsistent behavior.
- Disable or soften the gate on Windows: rejected because it would allow Stage 4 to proceed
  without trustworthy enforcement or telemetry.
- Require a manual environment variable containing a command string: rejected as the default
  because `py -3` is an argv pair and evaluating strings would introduce quoting/injection risk.

## Plan

1. Add a canonical, argv-safe Python 3 resolver and a regression matrix that proves discovery,
   version validation, explicit override behavior, missing-runtime failure, and paths with spaces.
2. Route hard/soft wrappers, installed telemetry entry points, and rendered inline commands through
   the resolver while preserving each hook's existing failure semantics.
3. Move interpreter preflight ahead of installer mutation and prove settings/target state remains
   unchanged on failure; cover disappearance after installation and terminal-boundary recovery.
4. Add repository-tracked Bash and PowerShell install entry points so a fresh machine can bootstrap
   exclusively from GitHub, without a persistent shim or a machine-specific helper under `outputs/`.
5. Update the hook policy, installation/preflight documentation, and a verified lesson; run focused
   tests, the full enforcement suite, static scans, and a final diff/security review.
6. Under the current request to keep the repair in GitHub, create structured commits, open a ready PR, verify the
   exact head in GitHub Actions and live review, then stop for explicit merge approval.

## Validation Plan

- Demonstrate the old implementation fails the Windows no-`python3` fixture for the intended
  reason.
- Run focused resolver, hard-hook, boundary parity, user-level installer, policy installer, and
  settings renderer tests under Git Bash.
- Verify production hook/telemetry paths contain no unmanaged literal `python3` invocation.
- Run the repository's canonical full enforcement suite and inventory/evidence checks.
- Run `git diff --check` and inspect every changed path for secrets, command injection, quoting,
  weakened denial status, partial-install mutation, and unrelated cleanup.
- Project 8 remains BLOCKED until the fix is merged, installed into the canonical checkout, and a
  genuinely fresh Claude session returns both positive telemetry readiness lines.

## Open Questions

None. The observable contract and safety boundaries are determined by the supplied failure, local
runtime evidence, and repository policy. Live Claude hook verification is a post-merge acceptance
step, not a reason to weaken local or CI regressions.

## Definition of Done

- [x] A single canonical resolver safely invokes Python 3 through supported Windows and Unix forms.
- [x] Required hook and telemetry runtime paths use the same resolver contract.
- [x] Installers preflight before activating or modifying hook settings and fail without mutation.
- [x] Fresh Windows and Bash installs have repository-tracked bootstrap entry points;
      local integration proves no machine-local helper or `python3` shim is required.
- [x] Missing or disappearing Python blocks required work while terminal hooks remain recoverable.
- [x] Focused regressions cover `python3`, `python`, `py -3`, no runtime, and paths with spaces.
- [x] Policy/docs and the verified lesson describe the portable contract and recovery behavior.
- [x] Focused Windows integration and static verification pass on the final local tree; full Linux corpus verification remains a required external gate below.
- [x] Final diff review finds no weakened fail-closed behavior, secret exposure, or unrelated change.

## Live External Gates Before Merge

These are intentionally not DoD checklist items because they can only be established after a
commit and push: exact-head GitHub Actions success, live review availability/status, reconciliation
of all current and outdated valid review threads, and explicit owner approval for that exact head.

The canonical complete enforcement workflow runs on Ubuntu. This Windows host has no Linux
distribution or running Docker engine. A full Git Bash attempt was stopped after exposing
platform-dependent fixture failures (POSIX paths embedded in Python strings, mode/symlink
semantics, default Windows console encoding, and stale CRLF fixtures). It is not a green full
corpus result. The full Linux run is therefore a required GitHub Actions gate, not a local
checkbox that can honestly be completed here. No required test is removed or bypassed.

Live download/bootstrap from the published GitHub ref must also be tested after publication.
The repository security-review command and Nemotron tool are unavailable in this host;
the exact-head security CI/reviewer gate is still required before merge. The local review
and negative tests do not claim that unavailable external gate ran.

## Claude Run Trace

- Goal: publish a reproducible GitHub-owned installer and resolve the Python-name lockout.
- Hypothesis: a temporary installer-only shim cannot satisfy later non-interactive hook shells.
- Connectors/tools: Git Bash, Windows PowerShell 5.1, Python 3.13.6, ShellCheck 0.11.0 and the
  GitHub connector. GitHub main was checked at `4d517840f18d8c1699a95110e0790d6919450ba4`.
  Notion progress is not claimed: this continuation is scoped to GitHub; the plan, PR, and
  validation report are the progress fallback. `notion_progress_validated` is not fabricated.
- Steps: inspect the supplied failure and both installers; implement one argv resolver;
  preflight before settings activation; test fresh no-python3 shells and PowerShell quoting;
  compare unrelated failures with an isolated main worktree; verify and publish a separate PR.
- Evidence: resolver and gate regressions, installed inline recorder evidence, positive local
  fixture telemetry, settings verification, preserved dirty-reference bytes, and ShellCheck.
  None of these is a real Project 8 session or remote-handoff qualification receipt.
- Rejected: a persistent local shim, disabling hard hooks, shell aliases, evaluating an
  interpreter command string, and presenting Windows-incompatible fixtures as passing.
- Result: the installation/runtime repair is locally testable without a python3 executable;
  full Linux CI and fresh Claude acceptance remain external requirements.
- Follow-up: verify the published exact head and live review; after owner-approved merge,
  reinstall from GitHub and perform the documented fresh-session preflight without product work.

## Progress Lifecycle Evidence

- start: Stage 4 telemetry preflight is BLOCKED before script execution because the hard-hook
  wrapper requires an executable named `python3`.
- mid: portable resolver, tracked launchers and pre-mutation guards implemented; focused
  Windows execution and baseline comparison completed. Full Linux validation remains external.
- pre-merge: all 10 focused Windows suites passed together; ShellCheck (error severity),
  Python compilation, corpus inventory (126 standalone tests), and whitespace checks passed.
  Exact-head CI, provider review/security evidence, and owner merge approval remain pending.


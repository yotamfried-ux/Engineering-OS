# Portable Python runtime and GitHub-owned installer validation

Date: 2026-09-03. Baseline: `4d517840f18d8c1699a95110e0790d6919450ba4`.

## Acceptance boundary

This repair removes the dependency on a machine-local installer and an executable named
exactly `python3`. It does **not** declare Project 8 or Stage 4 ready. The real Project 8
checkout and the shared installed Engineering OS checkout were not changed during this repair.
`remote_handoff.mode=required` must remain unchanged.

The source of truth is GitHub: the resolver, Bash installer, PowerShell launcher, settings
template, tests, and instructions are versioned together. Git Bash and a usable Python 3
installation remain host prerequisites. A local clone and generated Claude settings are
reproducible runtime state, not a second source of truth. No file from an old `outputs/`
directory and no persistent `python3` shim is needed.

## Failure mechanism and repair

The old helper supplied a temporary Python shim only while installing. Subsequent hard hooks
used a literal `python3`, creating a catch-all PreToolUse lockout when that executable was not
visible. The shared resolver probes `python3`, `python`, then the argv pair `py -3`, verifies
Python 3, and never evaluates an interpreter command string. All installed Claude Python
commands, including the inline evidence recorders, inherit this resolver.

The tracked installer checks the interpreter before target/settings mutation, verifies both
project and user hook settings, rejects a self-target before updating, and preserves a dirty
reference by refusing to update it. Missing runtime still blocks work. Only terminal recovery
is permitted when the interpreter disappears; an actual required-handoff failure still
propagates when the runtime is available.

## Evidence and limits

The focused Windows checks cover interpreter choice, malformed payloads, missing dependencies,
no-runtime refusal, paths with spaces, inline evidence, direct telemetry preflight, and the
Windows PowerShell 5.1 launcher. The installer integration fixture deliberately removes every
`python3` executable from PATH and uses a real Windows Python through `python`.

Run the focused integration suite with:

```bash
bash scripts/enforcement/run-enforcement-tests.sh \
  scripts/enforcement/tests/test-python-runtime.sh \
  scripts/enforcement/tests/test-hook-gate.sh \
  scripts/enforcement/tests/test-hook-boundary-parity.sh \
  scripts/enforcement/tests/test-project-installer.sh \
  scripts/enforcement/tests/test-use-in-project-update.sh \
  scripts/enforcement/tests/test-install-policy-gate-coverage.sh \
  scripts/enforcement/tests/test-user-level-telemetry-installer.sh \
  scripts/enforcement/tests/test-hard-hook-fail-closed.sh \
  scripts/enforcement/tests/test-hook-home-resolution.sh \
  scripts/enforcement/tests/test-eos-telemetry.sh
```

ShellCheck error-severity validation and corpus inventory validation are additional checks.
Execution receipts from an uncommitted local tree are not exact-final-commit CI evidence.

Local integrated result: all 10 named suites passed together. The installer suite passed
9 assertions, resolver 7, hard gate 22, boundary parity 19 and fail-closed regressions 15.
ShellCheck returned no error-severity findings, Python compilation passed, corpus inventory
validated 126 standalone tests, and `git diff --check` passed.

Three broader tests failed identically on the repaired tree and an isolated clean baseline
under Git Bash/Windows Python:

| Test | Observed failure on both trees |
| --- | --- |
| `test-project8-telemetry-readiness.sh` | `settings_rendered_to_reference` expects a POSIX path while Python receives a Windows-converted path. |
| `test-remote-telemetry-handoff.sh` | Local remote identity does not match the fixture's expected `example/target` identity. |
| `test-multirepo-dispatch.sh` | Parent discovery fixture produces no Project 8 run ID. |

These failures are not waived as Stage 4 evidence. A full Windows corpus attempt also exposed
encoding/path/CRLF fixture incompatibilities and was stopped; no full-corpus pass is claimed.
The canonical complete workflow runs on Ubuntu. Real POSIX modes and symlinks must be checked
there; Windows skips only those unsupported assertions, with explicit messages.

## Required next gates

1. Exact-head Windows installer CI and the full existing Linux checks must pass in GitHub.
2. Review findings must be reconciled; merge still requires explicit owner approval.
3. Install the merged version using the GitHub command in the README, outside the locked
   Claude session, then start a genuinely new Claude process.
4. Follow [Project 8 telemetry preflight](project8-telemetry-preflight.md). Require positive
   local event count **and** positive remote-handoff event count, not synthetic test receipts.
5. Obtain explicit approval before the Stage 4 qualification experiment or any product work.

If the new session's PATH exposes none of the supported Python commands, a host prerequisite
still needs installation. GitHub-hosted code cannot supply a missing executable by itself.

## Claude Desktop run surface

Use the **Code** tab, select **Local**, and choose Project 8. This is not a Chat or Cowork
session. Desktop shares Claude Code hook settings but on Windows inherits user/system
environment variables rather than PowerShell profiles. Restart the whole app after changing
host prerequisites; a successful command in an already-open terminal is not desktop proof.

Desktop may start a Git worktree. The preparation changes must be reviewed and committed to
the Project 8 branch used by that worktree; an uncommitted settings file in the original
checkout is not evidence that the new worktree has the same configuration. Confirm the actual
workspace root, reference SHA, required policy, settings verification and both positive
telemetry lines in the new session before the bounded qualification task.

Source: [official Claude Code Desktop documentation](https://code.claude.com/docs/en/desktop).

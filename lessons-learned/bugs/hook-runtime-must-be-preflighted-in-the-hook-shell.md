# Hook runtime availability must be proved in the shell that executes the hook

## מה קרה

The Project 8 installer reported success on Windows, and `python3 --version` succeeded
in the PowerShell process that launched Claude Code. The first Claude tool call still
failed before its unit ran with `required hard-hook interpreter is unavailable: python3`.
Because the catch-all PreToolUse gate covered every tool, the session could not repair
the dependency from inside Claude; the Stop gate could repeat the same failure.

## שורש הבעיה

The machine-local installer injected a temporary `python3` shim only into the installer
process. Installed hooks later ran in a separate non-interactive Git Bash environment
and assumed the literal executable name `python3`. Other required telemetry scripts made
the same direct assumption, and the installer activated settings before proving the
runtime contract that the future hook shell would use.

## השערות שנבדקו

- Python was absent — rejected: `C:\Python313\python.exe` and `py -3` both reported
  Python 3.13.6.
- Git Bash could not execute Windows Python — rejected: Git Bash executed both
  `/c/Python313/python` and `/c/WINDOWS/py -3` successfully.
- Adding a `python3` shim solved the contract — rejected: it helped only processes whose
  inherited PATH contained the shim and left the distributed installer dependent on a
  machine-specific file.
- The fixed executable-name assumption was the root — confirmed by the resolver matrix
  and a no-shim Git Bash run that selected `python` and executed Python 3.

## ראיה

`scripts/enforcement/tests/test-python-runtime.sh` exercises `python3`, `python`, `py -3`,
Python 2 rejection, no-runtime failure, an argv-safe path with spaces, and rejection of a
command-shaped override. `scripts/enforcement/tests/test-project-installer.sh` proves the
full installer fails before target mutation without a runtime and verifies project plus
user settings in a target path containing spaces. Hook-gate and lifecycle tests prove
that active work remains fail-closed while terminal recovery cannot trap the session.

## רמת ביטחון

High — the original environment boundary was reproduced in Git Bash, and the regression
matrix covers the supported Windows and Unix executable forms without a persistent shim.

## איך מזהים מוקדם

Run the resolver preflight from the same non-interactive Git Bash executable used by the
hook command, with the candidate PATH that the future Claude process will inherit. A
PowerShell-only version check is not installation evidence.

## איך מונעים בעתיד

- Keep one argv-safe resolver under `scripts/enforcement/lib/python-runtime.sh`.
- Source or execute it from every required hook and telemetry boundary.
- Preflight before settings mutation and verify the rendered project and dispatcher
  settings after installation.
- Bootstrap from the repository-tracked installers so a local helper cannot drift from
  GitHub.
- Allow terminal recovery only for missing runtime infrastructure; preserve failure
  propagation for real durable-handoff failures.

## טסט רגרסיה

- `scripts/enforcement/tests/test-python-runtime.sh`
- `scripts/enforcement/tests/test-hook-gate.sh`
- `scripts/enforcement/tests/test-hook-boundary-parity.sh`
- `scripts/enforcement/tests/test-project-installer.sh`
- `scripts/enforcement/tests/test-use-in-project-update.sh`

## סטטוס הבשלה

Verified Lesson

## Prevented Future Issues: 0


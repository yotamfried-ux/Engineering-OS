# Engineering OS — Operational Readiness Experiment (2026-06)

This document records an **operational-readiness experiment** run against Engineering OS,
using the `Expiriens-saas-0.8` (ClientPulse) repository as a real governed target project.
It is a companion to [`official-patterns-adoption-audit.md`](./official-patterns-adoption-audit.md):
that audit identified — from a prior ClientPulse run — that *"rules existed as text only"* and
that *"runtime lifecycle hooks must enforce critical workflow boundaries."* This experiment
**empirically confirms that gap is still live at runtime**, pinpoints the three exact
mechanisms that cause it, and implements the P0 corrections (which deliver step 2 of that
audit's *Minimal PR sequence* — "Official hook decision format").

The guiding question: **when Claude edits code inside a governed project in a fresh / web
session, does anything actually stop a workflow violation?**

## Method

All findings come from reading primary sources in both repos and checking live runtime state
(not from memory or summaries):
- `Engineering-OS/.claude/settings.json`, `Expiriens-saas-0.8/.claude/settings.json`
- `scripts/enforcement/*.sh`, `scripts/hooks/*.sh`, `scripts/session-setup.sh`
- Live state: `git config core.hooksPath`, `.git/hooks/`, `$ENGINEERING_OS_HOME`, `~/.engineering-os`

## Findings — four enforcement layers, very different readiness

| Layer | Mechanism | Genuinely blocks? | State in a fresh / web session |
|---|---|---|---|
| CI (GitHub Actions) | 7 workflows + 58-test suite + PR/evidence policies | Yes | Active and environment-independent — the one layer that enforced before this PR |
| Git commit hooks | `pre-commit.sh` / `commit-msg.sh`, `exit 1` aborts the commit | Yes (only when installed) | Was dormant — `core.hooksPath` unset and `.git/hooks/` empty in both repos; no bootstrap ran |
| Claude PreToolUse gates | `enforce-*.sh` wired in `.claude/settings.json` | No (before this PR) | Advisory only — wrong exit contract (root cause A) |
| Target-project propagation | Expiriens `.claude/settings.json` + `.githooks/` | No | Triple fail-open (root cause C) |

### Root cause A — Claude-tool gates used the wrong exit contract
Every `enforce-*.sh` signals a violation with `exit 1` and an `ERROR_FOR_AGENT:` message
(e.g. `enforce-workflow.sh` lines 87–358; `enforce-bash-entry.sh` 64/72;
`pre-tool-use-json-guard.sh` 8/22/32). But Claude Code only **blocks** a PreToolUse tool on
**exit code 2** or a stdout JSON `hookSpecificOutput.permissionDecision="deny"`. `exit 1` is a
*non-blocking* error: Claude sees the message and may proceed anyway. So entry gates such as
"no plan → no write" and "no `tasks.json` → no agent" did not actually prevent the action at the
Claude layer — they relied on Claude voluntarily complying.

The correct pattern already existed in the repo but was unused by the gates:
`check-plan-scope.sh` emits `permissionDecision="deny"` + `exit 2` (lines 15/162/166, with a
passing `test-plan-scope.sh`) and `post-stop-hook.sh` emits `{"decision":"block"}`. Yet
`check-plan-scope.sh` was **not wired into either `settings.json`**, and the entry gates were
never migrated to it.

### Root cause B — local bootstrap never ran in ephemeral / web sessions
`ENGINEERING_OS_HOME` was unset, `~/.engineering-os` absent, and no git hooks installed. Nothing
in a fresh clone runs `install-self-hooks.sh` / `use-in-project.sh`, so both the git-commit teeth
and the env-based hook resolution stayed dormant. The SessionStart hook also resolved its own path
via `${ENGINEERING_OS_HOME:-$(pwd)}`, which is wrong whenever the session's working directory is not
the repo root (as in the audit session, CWD `/home/user`).

### Root cause C — target propagation was fail-open by construction
Expiriens `.claude/settings.json` wrapped **every** enforcer in `|| true` (lines 19/23/32/42),
which swallows any exit code, so it could never block even if reachable. It was also a stripped
subset: it omitted the PostToolUse evidence recorders and the git/debugging gates present in the
home settings, so the evidence ledger never populated in the target and every evidence-gated check
there was inert. `core.hooksPath` was also unset in Expiriens, so its `.githooks/` wrappers never ran.

### Meta-evidence — the experiment proved itself
During the audit session, a plan file was written and Bash commands ran with **no gate firing**,
because `ENGINEERING_OS_HOME` was unset and no hooks were installed — a live demonstration of the
gap, in exactly the environment the system is meant to govern.

### What was already strong
The enforcement *content* and *test coverage* are substantial: 14 enforcers, 60+ regression tests,
the `MANIFEST.tsv` md↔enforcer registry, real secret / quality / git / learning gates that block at
git-commit time when installed, and an active CI layer. The deficit was **activation and wiring**,
not policy substance.

## Verdict

Before this PR, Engineering OS was **content-ready but not operationally-ready** for its stated use
case. On PRs (CI) it enforced well, but in the day-to-day loop it is built for — Claude editing code
inside a governed project in a web / ephemeral session — enforcement reduced to "Claude voluntarily
follows `CLAUDE.md`," because (A) Claude-tool gates could not block, (B) git gates were not
bootstrapped, and (C) target propagation was fail-open.

## Corrections implemented in this PR (P0, Engineering-OS repo only)

1. **Claude-tool gates now genuinely block.** New `scripts/enforcement/lib/hook-gate.sh` runs a
   legacy `exit 1` enforcer for the Claude-tool layer and converts a clean non-zero into a
   `permissionDecision="deny"` on stdout (exit 0), without changing the enforcers' exit codes (git
   hooks still rely on `exit 1`). It fails *open* on infrastructure errors and *closed* only on a
   genuine block. The four governance gates plus the JSON guard are wired through it in
   `.claude/settings.json`, and `check-plan-scope.sh` (native deny) is now wired into the Write path.
   The inline one-branch-policy gate now emits a deny instead of a non-blocking `exit 1`.
   Covered by `scripts/enforcement/tests/test-hook-gate.sh`.
2. **Reliable git-hook bootstrap.** `scripts/session-setup.sh` now idempotently installs the
   `pre-commit` / `commit-msg` / `post-commit` hooks into this repo's `.git/hooks/` when missing or
   stale, so the genuinely-blocking git layer comes up automatically in a fresh clone.

The `.claude/settings.json` hooks keep the inline `${ENGINEERING_OS_HOME:-$(pwd)}` resolution: it is
the literal pattern that `use-in-project.sh`'s `render_target_settings` substitutes to an absolute
path when propagating into a governed project, and the `enforcement-tests` contract test asserts on
it. Hardening that fallback (e.g. a `git rev-parse --show-toplevel` branch) would require a
coordinated update to `render_target_settings` **and** the contract test, so it is deferred to the P1
propagation work. The operational requirement remains: set `ENGINEERING_OS_HOME` in the web/managed
environment configuration so hook resolution never depends on the working directory.

## Recommended follow-up (out of scope for this PR)

- **P1 — Fix target propagation.** Regenerate the target `.claude/settings.json` from the full home
  template through `hook-gate.sh`, **remove the `|| true`** wrappers, and restore the PostToolUse
  evidence recorders so evidence-gated checks function inside governed projects. Have
  `use-in-project.sh` set `core.hooksPath` (or copy hooks) and export `ENGINEERING_OS_HOME`.
- **P2 — Close remaining soft spots.** Activate the planned `capability-registry.yaml` runtime gate,
  automate the CodeRabbit-review/approval check, add an executable runner for the `evals/*.jsonl`
  scenarios, and implement the documented-but-partial Stop-hook DoD verification.
- **P2 — Refine `enforce-run-trace.sh` connector trigger.** Surfaced while dogfooding this PR: the
  gate treats any staged `.claude/settings.json` change as connector-related and demands a
  `notion_progress_validated` token even when no external connector is involved (a pure hooks-wiring
  change). It should scope the connector-evidence requirement to actual connector/MCP edits.

## How to re-verify

- `bash scripts/enforcement/tests/test-hook-gate.sh` — translator behaves (deny on exit 1, pass on 0).
- Feed a no-plan Write event through the wrapped hook and confirm stdout contains
  `permissionDecision` `deny`:
  `echo '{"tool_name":"Write","tool_input":{"file_path":"app.js"}}' | ENGINEERING_OS_HOME=$(pwd) bash scripts/enforcement/lib/hook-gate.sh enforce-workflow.sh`
- After `session-setup.sh` runs in a clean checkout, confirm `.git/hooks/` is populated and a
  non-compliant `git commit` is aborted by the commit-msg / pre-commit gate.

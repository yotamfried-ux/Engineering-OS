# Live Host Qualification — Claude Code cloud container (2026-09-23)

First **live** execution qualification of the core agent/testing capabilities on a real Claude Code host, performed while preparing SportReel's UPL-01 Android upload E2E. It complements the upstream-only [QUALIFICATION-REPORT](../QUALIFICATION-REPORT.md) (which could not run a Claude Code host) with evidence from one.

## Host identity

| Item | Value |
|---|---|
| Host | Claude Code on the web, disposable cloud container |
| Claude Code | 2.1.280 |
| OS | Ubuntu 24.04.4 LTS, x86_64, 4 vCPU, 15 GB RAM |
| Runtimes | Node 22.22.2, npm 10.9.7, Python 3.11.15, uv 0.8.17, OpenJDK 21.0.10 |
| Android | no Android SDK, no `adb`, **no `/dev/kvm`** (no local emulator possible) |
| Network | egress through an allow-listing proxy; `get.maestro.mobile.dev` and `api.github.com` release lookups were denied, `github.com` release downloads and `raw.githubusercontent.com` allowed |
| Pre-connected connectors | GitHub, Supabase, Vercel (and others unrelated to this workload) |

## Results

| Capability | Version | Status | Evidence | Residual gaps |
|---|---|---|---|---|
| Superpowers | 6.4.1 (`superpowers@claude-plugins-official`) | **PASS** | `claude plugin list` shows enabled; a fresh headless session emitted `SessionStart:startup` hook_response injecting `using-superpowers`, and listed `superpowers:*` skills | Installing mid-session does not load skills into the *current* session; they appear from the next session |
| RTK | 0.49.0 | **PASS** | `rtk init -g --auto-patch` registered `PreToolUse` `rtk hook claude`; the very next Bash `git status` returned RTK's compact form without restart; `rtk gain` recorded the rewritten command | Built-in Read/Grep/Glob bypass the hook (upstream-documented); RTK's `grep` rewrite truncates long lines, so use `rtk proxy <cmd>` or Read when exact text matters |
| Graphify CLI | 0.9.66 (`graphifyy`, upstream `Graphify-Labs/graphify`) | **PASS** | `graphify extract . --code-only` on SportReel: 403 code files → 3,625 nodes / 9,091 edges in 8 s; a query for the upload path returned exactly the mobile screen, upload client, API routes and manifest helper later confirmed by reading source | Headless `extract` without `--code-only` requires an LLM API key for docs; `.sql` needs the `[sql]` extra |
| Graphify MCP | 0.9.66 | **PASS** | `claude mcp add -s local graphify -- graphify-mcp <abs>/graphify-out/graph.json` → `claude mcp list` “Connected”; fresh session reports `graphify: connected` | Graph is a navigation aid, not source of truth |
| Maestro CLI | 2.10.0 | **PASS** | `maestro --version` = 2.10.0 (Java 21); `maestro check-syntax` validated 8 SportReel flow files offline | — |
| Maestro MCP | bundled in 2.10.0 | **PARTIAL** | stdio `initialize` → serverInfo `maestro`; `tools/list` = `list_devices, take_screenshot, run, inspect_screen, cheat_sheet, open_maestro_viewer, list_cloud_devices, run_on_cloud, get_cloud_run_status, describe_cloud_run`; `list_devices` returned only a Chromium web target | Agentic mobile exploration (Mode A) is **BLOCKED** on this host: no KVM/emulator/device. Deterministic flows run in GitHub Actions instead (Mode B). Cloud tools need a Maestro Cloud account — not used |
| GitHub connector | — | **PASS** | listed runs/jobs/step conclusions, created a draft PR, subscribed to PR activity | Job-log tail can be dominated by post-job cleanup; target the failing step or artifacts |
| Supabase connector | — | **PASS** | `list_projects`; read-only `information_schema` and `source_uploads` queries | The same connector exposes write/migration tools — restrict qualification use to read-only SQL |
| Vercel connector | — | **PASS** | resolved team → project → current production deployment and its Git SHA | — |

## Not installed (no trigger)

| Capability | Status | Reason |
|---|---|---|
| Appium MCP | NOT TESTED | Escalation only; Maestro covers the required journey. Would also need Android SDK + target |
| Mobile Next MCP | NOT TESTED | No physical device / MCP-visible target on this host |
| Playwright MCP / CLI | NOT TESTED | No web journey in this workload |
| Chrome DevTools MCP | NOT TESTED | Only added when a Playwright failure needs browser internals |
| claude-mem | NOT APPLICABLE | Disposable container; GitHub + audits are the durable memory |
| gstack / OpenHands | NOT APPLICABLE | Overlap with Superpowers + native subagents; no missing capability identified |
| claude-code-workflows | NOT TESTED | Template, not plugin; evaluate only for a PR-review outer loop |

## Corrections discovered (applied to wrappers)

1. **Superpowers** — on a fresh host with no marketplace configured, `plugin install superpowers@claude-plugins-official` fails until `claude plugin marketplace add anthropics/claude-plugins-official` has been run. Both steps work non-interactively via the `claude plugin` CLI.
2. **RTK** — the current upstream quick-install URL is `https://raw.githubusercontent.com/rtk-ai/rtk/refs/heads/master/install.sh`. The installer resolves the latest version through GitHub; behind a restrictive proxy, pin it with `RTK_VERSION=vX.Y.Z` (the installer still verifies release checksums).
3. **Graphify** — `python -m graphify.serve` does not work after `uv tool install` (isolated venv); use the installed `graphify-mcp` entry point with an absolute graph path. Use `--code-only` for keyless headless builds. `graphify hook install` writes an untracked `.gitattributes` and a `merge.graphify` git config; remove both in repositories that do not commit `graphify-out/`, and exclude `graphify-out/` via `.git/info/exclude`.
4. **Maestro** — when `get.maestro.mobile.dev` is blocked, install the same artifact from `https://github.com/mobile-dev-inc/Maestro/releases/download/cli-<version>/maestro.zip`. Set `MAESTRO_CLI_NO_ANALYTICS=1` in CI/sandboxes (the CLI otherwise contacts analytics endpoints).

## What this proves / does not prove

Proves: on this host class these capabilities install, register with Claude Code and perform a representative harmless action. Does **not** prove: availability on other hosts, mobile-device control on a host without an emulator, or correctness of any application tested with them. Application results belong in that application's repository (for SportReel: UPL-01 audit).

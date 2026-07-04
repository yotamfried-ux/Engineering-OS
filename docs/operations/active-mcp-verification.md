# Active MCP Verification

## Purpose

This runbook proves that the installed project-scoped MCP configuration can be activated and verified safely on a real workstation or target test project.

Engineering OS now installs MCP server profiles automatically through:

```text
templates/connectors/github-readonly.json
templates/connectors/engineering-os-mcp.json
scripts/install-mcp-servers.sh
scripts/use-in-project.sh
```

This is a configuration, activation, and verification proof. It does not broaden GitHub permissions, does not install secrets, and does not prove live access until the operator authenticates and records smoke-check evidence.

## Current source profiles

The approved default profiles are:

```text
github-readonly
context7
notion
supabase
stripe
playwright
nemotron
figma
sentry
postman
composio
```

GitHub remains the only default GitHub profile and must stay read-only with the narrow toolset `context,repos,pull_requests,issues,actions`.

## What this proof does

This proof verifies the following operational path:

```text
Engineering OS templates -> target .mcp.json -> Claude Code MCP status evidence -> read-only smoke checks -> auth/fallback record
```

It proves that project-scoped MCP profiles can be loaded and used as source-of-truth connectors for repository state, project tracking, docs, API testing, design context, database/backend state, and fallback connector access.

## What this proof does not do

Do not use this runbook to:

- Commit a real token or OAuth credential.
- Add a write-capable GitHub MCP profile.
- Add broad GitHub toolsets such as `all` or `default`.
- Add `git`, `copilot`, `notifications`, `gists`, `dependabot`, `code_security`, or `discussions` to the GitHub read-only profile.
- Perform a real write operation as a negative test.
- Merge, close, edit, label, delete, or mutate GitHub resources through `github-readonly`.

A future write-capable profile must be added as a separate explicit PR with its own name, scope, approval rules, runbook, and validator.

## Required static validation

Before any workstation action, validate the source profiles:

```bash
bash scripts/enforcement/tests/test-github-connector-profile.sh
bash scripts/enforcement/tests/test-mcp-auto-install.sh
bash scripts/enforcement/tests/test-active-mcp-verification.sh
```

Expected result:

```text
GitHub connector profile is valid
MCP auto-install tests passed
active MCP verification proof is valid
```

## Preflight

Run these checks before relying on live MCP data.

### 1. Verify required local runners are available

```bash
command -v docker >/dev/null   # needed for github-readonly
command -v npx >/dev/null      # needed for playwright
command -v uv >/dev/null       # needed for nemotron
```

### 2. Verify secrets without printing them

Check only presence, never values. Examples:

```bash
test -n "${GITHUB_PERSONAL_ACCESS_TOKEN:-}"
test -n "${Nemotron_api_key:-}${NEMOTRON_API_KEY:-}"
```

Do not echo, log, paste, commit, or screenshot tokens.

### 3. Install or refresh target project MCP profiles

From the target project root:

```bash
ENGINEERING_OS_HOME=/path/to/Engineering-OS bash /path/to/Engineering-OS/scripts/use-in-project.sh
```

or directly:

```bash
ENGINEERING_OS_HOME=/path/to/Engineering-OS bash /path/to/Engineering-OS/scripts/install-mcp-servers.sh .
```

## Claude Code verification

Start a fresh Claude Code session from the target directory after `.mcp.json` exists.

Record evidence that:

1. The active MCP server list includes the expected Engineering OS profiles.
2. The loaded configuration uses the local `.mcp.json` file.
3. The GitHub MCP server starts without token disclosure.
4. The exposed GitHub MCP tools are scoped to read-only repository, PR, issue, context, and Actions/CI inspection.
5. No write-capable GitHub profile is active.
6. Required task-specific servers are approved/authenticated or have an explicit fallback/waiver.

Use the MCP status/list command available in the installed Claude Code version, and record the exact command used:

```bash
claude mcp list
claude mcp get github-readonly
```

Inside Claude Code:

```text
/mcp
```

## Read-only smoke checks

Use active MCP servers only for safe non-mutating checks unless the user explicitly approved a write-capable workflow.

Required smoke checks for baseline readiness:

```text
Read repository metadata for the target repository through github-readonly.
Read pull request or issue metadata from the target repository through github-readonly.
Read recent workflow run or CI status metadata through github-readonly.
Confirm at least one non-GitHub MCP server is visible in /mcp or document its auth/fallback state.
```

Expected result: each check returns state without mutating external resources.

## Negative checks

Do not perform a real write operation as a negative test.

Instead, verify by inspection that:

```text
GitHub read-only mode is active.
No write-capable GitHub MCP profile is active.
The GitHub toolsets are exactly context,repos,pull_requests,issues,actions.
The GitHub profile does not include all, default, git, copilot, notifications, gists, dependabot, code_security, or discussions.
No runbook step asks the operator to merge, close, edit, label, delete, or mutate GitHub resources through github-readonly.
```

## Evidence record

Fill this section after a real workstation or target-project proof. Do not commit secrets, tokens, screenshots containing private paths, or account identifiers.

```text
Date:
Operator:
Machine:
OS:
Claude Code version:
Target repository:
Target directory:
Installed .mcp.json checksum:
Existing .mcp.json present: yes/no
Backup path, if created:
MCP status/list command used:
github-readonly server visible: yes/no
Required non-GitHub MCP profiles visible: yes/no
Read repository metadata check: pass/fail
Read PR or issue metadata check: pass/fail
Read workflow/CI metadata check: pass/fail
Write-capable GitHub profile active: yes/no
Forbidden GitHub toolsets visible: yes/no
Notes:
```

## Failure modes

| Failure | Likely cause | Action |
|---|---|---|
| Docker is missing | Workstation cannot run the official GitHub MCP image | Install Docker or run the proof on a machine with Docker |
| Token preflight fails | Required token is not set in the shell that starts Claude Code | Export the token locally or use Claude Code OAuth without writing it to git |
| MCP server does not appear | `.mcp.json` is in the wrong directory or Claude Code was not restarted | Confirm target directory and restart Claude Code |
| Token appears in logs or files | Operator printed or committed a secret | Stop, rotate the token, and remove leaked material |
| Forbidden GitHub toolset appears | Profile was broadened beyond the approved read-only scope | Revert the profile and rerun CI validators |
| Write-capable GitHub profile is active | A different MCP config is loaded or a future profile was enabled accidentally | Disable the write profile and rerun the proof |

## Completion criteria

This proof path is complete when:

1. CI validates the GitHub read-only profile boundaries.
2. CI validates MCP auto-install behavior.
3. The active proof path requires MCP status evidence.
4. The active proof path requires read-only smoke checks.
5. The runbook forbids real write operations as negative tests.
6. The evidence record is filled after one real workstation or target test project run.

Full active MCP proof is complete only after this runbook is executed on one real workstation or target test project and the evidence record is filled without secrets.

# Active MCP Verification

## Purpose

This runbook proves that the approved GitHub MCP profile can be activated and verified safely on a real workstation or target test project.

The source profile remains:

```text
templates/connectors/github-readonly.json
```

This is an activation and verification proof. It does not broaden the connector profile and does not enable MCP automatically for target projects.

## Current source profile

The only approved server for this proof is:

```text
github-readonly
```

The source template must keep:

```text
GITHUB_READ_ONLY=1
GITHUB_PERSONAL_ACCESS_TOKEN=${GITHUB_PERSONAL_ACCESS_TOKEN}
GITHUB_TOOLSETS=context,repos,pull_requests,issues,actions
```

## What this proof does

This proof verifies the following operational path:

```text
repository MCP template -> local target .mcp.json -> Claude Code MCP status evidence -> read-only smoke checks -> rollback or restore
```

It proves that the profile can be loaded and used as a source-of-truth connector for repository state, PR state, issue/spec context, and Actions/CI state.

## What this proof does not do

Do not use this runbook to:

- Commit a real GitHub token.
- Add a write-capable GitHub MCP profile.
- Add broad toolsets such as `all` or `default`.
- Add `git`, `copilot`, `notifications`, `gists`, `dependabot`, `code_security`, or `discussions` to this profile.
- Enable MCP from `use-in-project.sh`.
- Auto-install `.mcp.json` into target projects.
- Perform a real write operation as a negative test.
- Merge, close, edit, label, delete, or mutate GitHub resources through this profile.

A future write-capable profile must be added as a separate explicit PR with its own name, scope, approval rules, runbook, and validator.

## Required static validation

Before any workstation action, validate the source profile:

```bash
bash scripts/enforcement/tests/test-github-connector-profile.sh
bash scripts/enforcement/tests/test-active-mcp-verification.sh
```

Expected result:

```text
✅ GitHub connector profile is valid
✅ active MCP verification proof is valid
```

## Preflight

Run these checks before copying any MCP file.

### 1. Verify Docker is available

```bash
command -v docker >/dev/null
```

### 2. Verify token presence without printing it

```bash
test -n "${GITHUB_PERSONAL_ACCESS_TOKEN:-}"
```

Do not echo, log, paste, commit, or screenshot the token.

Use a least-privilege read-only token for the target repository whenever possible.

### 3. Verify the source template still has the approved profile shape

```bash
python3 - <<'PY'
import json
from pathlib import Path

profile = json.loads(Path("templates/connectors/github-readonly.json").read_text())
server = profile["mcpServers"]["github-readonly"]
env = server["env"]
items = {item.strip() for item in env["GITHUB_TOOLSETS"].split(",") if item.strip()}
expected = {"context", "repos", "pull_requests", "issues", "actions"}
forbidden = {"all", "default", "git", "copilot", "notifications", "gists", "dependabot", "code_security", "discussions"}
if env.get("GITHUB_READ_ONLY") != "1":
    raise SystemExit("STOP: github-readonly must keep GITHUB_READ_ONLY=1")
if env.get("GITHUB_PERSONAL_ACCESS_TOKEN") != "${GITHUB_PERSONAL_ACCESS_TOKEN}":
    raise SystemExit("STOP: token must use environment expansion only")
if items != expected:
    raise SystemExit(f"STOP: unexpected GitHub MCP toolsets: {sorted(items)}")
if items & forbidden:
    raise SystemExit(f"STOP: forbidden GitHub MCP toolsets: {sorted(items & forbidden)}")
print("✅ GitHub MCP profile preflight passed")
PY
```

## Safe activation

Use a temporary target repository or a target project that explicitly opts in.

Do not commit `.mcp.json` as part of this proof unless the target project intentionally wants project-scoped MCP configuration reviewed in its own PR.

### Backup any existing `.mcp.json`

```bash
MCP_PATH=.mcp.json
BACKUP_PATH=""
if [ -f "$MCP_PATH" ]; then
  BACKUP_PATH="${MCP_PATH}.backup.$(date +%Y%m%d%H%M%S)"
  cp -p "$MCP_PATH" "$BACKUP_PATH"
  echo "Backed up existing MCP config to: $BACKUP_PATH"
fi
cp templates/connectors/github-readonly.json "$MCP_PATH"
```

### Optional local ignore for proof-only activation

If this is a temporary proof file, keep it out of git:

```bash
printf '\n.mcp.json\n.mcp.json.backup.*\n' >> .git/info/exclude
```

## Claude Code verification

Start a fresh Claude Code session from the target directory after `.mcp.json` exists.

Record evidence that:

1. The active MCP server list includes `github-readonly`.
2. The loaded configuration uses the local `.mcp.json` file.
3. The GitHub MCP server starts without token disclosure.
4. The exposed GitHub MCP tools are scoped to read-only repository, PR, issue, context, and Actions/CI inspection.
5. No write profile is active.

Use the MCP status/list command available in the installed Claude Code version, and record the exact command used in the evidence record.

## Read-only smoke checks

Use the active `github-readonly` MCP server only for non-mutating checks.

Required smoke checks:

```text
Read repository metadata for the target repository.
Read pull request or issue metadata from the target repository.
Read recent workflow run or CI status metadata from the target repository.
```

Expected result: each check returns repository state without mutating GitHub resources.

## Negative checks

Do not perform a real write operation as a negative test.

Instead, verify by inspection that:

```text
GITHUB_READ_ONLY=1 is active.
No write-capable GitHub MCP profile is active.
The toolsets are exactly context,repos,pull_requests,issues,actions.
The profile does not include all, default, git, copilot, notifications, gists, dependabot, code_security, or discussions.
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
Source profile checksum:
Activated .mcp.json checksum:
Existing .mcp.json present: yes/no
Backup path, if created:
MCP status/list command used:
github-readonly server visible: yes/no
Read repository metadata check: pass/fail
Read PR or issue metadata check: pass/fail
Read workflow/CI metadata check: pass/fail
Write profile active: yes/no
Forbidden toolsets visible: yes/no
Rollback or restore tested: yes/no
Notes:
```

## Rollback or restore

If a backup was created, restore it. If no previous `.mcp.json` existed, remove only the proof activation artifact.

Restore previous MCP config:

```bash
BACKUP_PATH="<paste the recorded backup path here>"
cp -p "$BACKUP_PATH" .mcp.json
```

Remove proof artifact when there was no previous MCP config:

```bash
rm -f .mcp.json
```

Remove proof-only ignore entries manually if they were added to `.git/info/exclude` and are no longer desired.

After rollback or restore, start a fresh Claude Code session and confirm that `github-readonly` is no longer active unless it was part of the restored configuration.

## Failure modes

| Failure | Likely cause | Action |
|---|---|---|
| Docker is missing | Workstation cannot run the official GitHub MCP image | Install Docker or run the proof on a machine with Docker |
| Token preflight fails | `GITHUB_PERSONAL_ACCESS_TOKEN` is not set in the shell that starts Claude Code | Export the token in the local shell without writing it to git |
| MCP server does not appear | `.mcp.json` is in the wrong directory or Claude Code was not restarted | Confirm target directory and restart Claude Code |
| Token appears in logs or files | Operator printed or committed a secret | Stop, rotate the token, and remove leaked material |
| Forbidden toolset appears | Profile was broadened beyond the approved read-only scope | Revert the profile and rerun CI validators |
| Write-capable profile is active | A different MCP config is loaded or a future profile was enabled accidentally | Disable the write profile and rerun the proof |

## Completion criteria

This PR step is complete when:

1. This runbook exists.
2. CI validates this runbook and the GitHub read-only profile boundaries.
3. The active proof path requires `.mcp.json` backup or rollback.
4. The active proof path requires MCP status evidence.
5. The active proof path requires read-only smoke checks.
6. The runbook forbids real write operations as negative tests.

Full active MCP proof is complete only after this runbook is executed on one real workstation or target test project and the evidence record is filled without secrets.

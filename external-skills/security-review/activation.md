# Security Review — Activation

## Prerequisites

| Requirement | Details |
|---|---|
| Anthropic API key | Required by both the Action and the slash command. Obtain from https://console.anthropic.com |
| GitHub repository | Required for the GitHub Action path only |
| Claude Code CLI | Required for the `/security-review` slash command path |
| Repository permissions | `pull-requests: write`, `contents: read` (GitHub Action) |

---

## Install — Option A: GitHub Action (automated, PR-triggered)

Add the following file to the target repository. The workflow triggers on every pull request and posts findings as inline PR comments.

**File:** `.github/workflows/security.yml`

```yaml
name: Claude Code Security Review

on:
  pull_request:
    types: [opened, synchronize, reopened]

permissions:
  pull-requests: write
  contents: read

jobs:
  security-review:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 2

      - name: Run Claude Code Security Review
        uses: anthropics/claude-code-security-review@main
        with:
          comment-pr: true
          claude-api-key: ${{ secrets.CLAUDE_API_KEY }}
```

**Important:** `fetch-depth: 2` is required so the action can compute the diff against the previous commit. Without it, the diff-aware scanning cannot function.

### Optional Action Inputs

| Input | Default | Description |
|---|---|---|
| `comment-pr` | `false` | Post findings as inline PR comments |
| `upload-results` | `false` | Upload findings as a workflow artifact |
| `exclude-directories` | (none) | Comma-separated list of directories to skip |
| `claude-model` | `claude-opus-4-1-20250805` | Override the Claude model used for analysis |
| `claudecode-timeout` | (default) | Timeout for Claude Code execution |
| `run-every-commit` | `false` | Run on every commit push, not just PR events |

---

## Install — Option B: Slash Command (interactive, Claude Code)

Copy the command definition file into the target repository's Claude commands directory:

```bash
# From inside the target repository:
mkdir -p .claude/commands
cp <path-to-cloned-skill-repo>/.claude/commands/security-review.md .claude/commands/security-review.md
```

The `/security-review` slash command is then available in Claude Code sessions in that repository. It runs the review on all pending changes on the current branch.

To customize review behavior (scope, focus areas, output format), edit `.claude/commands/security-review.md` in the target repository directly.

---

## Configure Secrets

### CLAUDE_API_KEY (required)

Set this as a GitHub Actions repository secret:

1. Go to the target repository → **Settings** → **Secrets and variables** → **Actions**.
2. Click **New repository secret**.
3. Name: `CLAUDE_API_KEY`
4. Value: your Anthropic API key from https://console.anthropic.com

### GITHUB_TOKEN (automatic)

The action uses the default `GITHUB_TOKEN` provided by GitHub Actions for posting PR comments. No additional configuration is needed — the `permissions` block in the workflow YAML grants the required access.

---

## Verify Installation

### Verify the GitHub Action

```bash
# Check the workflow file exists and is syntactically valid:
cat .github/workflows/security.yml

# Confirm the secret is set (GitHub CLI):
gh secret list | grep CLAUDE_API_KEY

# Trigger a test run by opening or updating a PR; then check:
gh run list --workflow=security.yml
```

### Verify the Slash Command

In a Claude Code session in the target repository, type `/security-review` and confirm the command is recognized and begins analyzing the current branch's pending changes.

---

## Trusted-PR Gating (Mandatory for Public Repositories)

Because the skill is not hardened against prompt injection, external contributor PRs must be approval-gated before the workflow runs. Configure this in GitHub:

1. Go to the repository → **Settings** → **Actions** → **General**.
2. Under "Fork pull request workflows from outside collaborators", select **"Require approval for first-time contributors"** (minimum) or **"Require approval for all outside collaborators"** (recommended for security-sensitive repositories).

---

## Reference

For advanced setup and scripting, see `scripts/skill-bootstrap.sh` in the source repository:
https://github.com/anthropics/claude-code-security-review

---

## Disable / Uninstall

### Disable the GitHub Action

Remove or rename the workflow file:

```bash
git mv .github/workflows/security.yml .github/workflows/security.yml.disabled
git commit -m "chore: disable security-review action"
```

Or delete it entirely if the skill is being removed permanently. This does not affect the slash command.

### Disable the Slash Command

Remove the command definition file:

```bash
git rm .claude/commands/security-review.md
git commit -m "chore: remove security-review slash command"
```

### Full Removal

Remove both the workflow file and the slash command file, then optionally delete the `CLAUDE_API_KEY` secret from repository settings if it is not used by other workflows.

**Note:** Disabling this skill removes the LEVEL 2 mandatory gate. Ensure an alternative security review process is in place before disabling in a production repository.

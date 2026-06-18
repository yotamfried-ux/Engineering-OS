# Security Review — Activation

## Prerequisites

| Requirement | Details |
|---|---|
| Anthropic API key | Required by both the Action and the slash command. Obtain from https://console.anthropic.com |
| GitHub repository | Required for the GitHub Action path only |
| Claude Code CLI | Required for the `/security-review` slash command path |
| Repository permissions | `pull-requests: write`, `contents: read` (GitHub Action) |

---

## Install — Option A: Slash Command (interactive, Claude Code) ← מומלץ

**זוהי הדרך המועדפת** — רצה בתוך סשן Claude Code הקיים ללא API key נוסף.
Claude Code משתמש ב-model context של הסשן הנוכחי; אין עלות LLM נפרדת.

Copy the command definition file into the target repository's Claude commands directory:

```bash
# From inside the target repository:
mkdir -p .claude/commands
cp <path-to-cloned-skill-repo>/.claude/commands/security-review.md .claude/commands/security-review.md
```

The `/security-review` slash command is then available in Claude Code sessions in that repository.
It runs the review on all pending changes on the current branch.

To customize review behavior, edit `.claude/commands/security-review.md` directly.

**אימות:** בתוך Claude Code session, הקלד `/security-review` — הפקודה אמורה להתחיל מיד.

---

## Install — Option B: GitHub Action (automated, CI/CD only)

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

*(Option B was the slash command — moved to Option A above.)*

---

## Install — Option C: NVIDIA NIM (ספק חלופי — ללא Anthropic API)

שימוש ב-NVIDIA NIM (מודלים פתוחים: Llama, Nemotron) במקום Anthropic. המסלול הזה
**עצמאי לחלוטין** — לא דורש Claude API key, ורץ גם ב-CI/CD וגם locally.

### Option C1: GitHub Action

העתק את ה-workflow לפרויקט היעד:

```bash
mkdir -p .github/workflows
cp <path-to-engineering-os>/templates/github-actions/security-review-nvidia.yml \
   .github/workflows/security-review-nvidia.yml
```

הוסף את הסקריפט:

```bash
mkdir -p scripts
cp <path-to-engineering-os>/scripts/security-review-nvidia.py scripts/security-review-nvidia.py
```

הגדר secret אחד בלבד (ראה "Configure Secrets" → NVIDIA_API_KEY):

```
NVIDIA_API_KEY=nvapi-...
```

### Option C2: Slash Command (Claude Code session)

```bash
mkdir -p .claude/commands
cp <path-to-engineering-os>/templates/commands/security-review-nvidia.md \
   .claude/commands/security-review-nvidia.md
```

הגדר את המשתנה בסביבה הנוכחית:

```bash
export NVIDIA_API_KEY=nvapi-...
```

הפעלה: `/security-review-nvidia` בתוך Claude Code session.

### משתני סביבה

| משתנה | ברירת מחדל | תיאור |
|---|---|---|
| `NVIDIA_API_KEY` | **חובה** | מפתח API מ-build.nvidia.com |
| `NVIDIA_MODEL` | `meta/llama-3.1-70b-instruct` | מודל להרצה |
| `NVIDIA_BASE_URL` | `https://integrate.api.nvidia.com/v1` | endpoint |

### מודלים מומלצים

| מודל | ID | הערות |
|---|---|---|
| Llama 3.1 70B | `meta/llama-3.1-70b-instruct` | ברירת מחדל — איכות גבוהה |
| Llama 3.1 8B | `meta/llama-3.1-8b-instruct` | מהיר, tier חינמי |
| Llama 3.1 405B | `meta/llama-3.1-405b-instruct` | עמוק ביותר |

### תיעוד מלא

ראה `external-systems/nvidia/README.md` ו-`scripts/security-review-nvidia.py`.

---

## Configure Secrets

### CLAUDE_API_KEY (required)

Set this as a GitHub Actions repository secret:

1. Go to the target repository → **Settings** → **Secrets and variables** → **Actions**.
2. Click **New repository secret**.
3. Name: `CLAUDE_API_KEY`
4. Value: your Anthropic API key from https://console.anthropic.com

### NVIDIA_API_KEY (required for Option C only)

Set this as a GitHub Actions repository secret (Option C1), or export it in your shell (Option C2):

1. Sign up at [build.nvidia.com](https://build.nvidia.com) and generate an API key.
2. For GitHub Actions: **Settings** → **Secrets and variables** → **Actions** → **New repository secret**.
   - Name: `NVIDIA_API_KEY`
   - Value: `nvapi-...`
3. For local use: `export NVIDIA_API_KEY=nvapi-...` (add to `.env` for persistence).

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

#!/usr/bin/env bash
#
# use-in-project.sh — apply Engineering OS as a READ-ONLY governance + knowledge
# layer to ANOTHER project. Safe, idempotent, repeatable across any project.

set -euo pipefail

EOS_REPO="${ENGINEERING_OS_REPO:-https://github.com/yotamfried-ux/Engineering-OS}"
EOS_HOME="${ENGINEERING_OS_HOME:-$HOME/.engineering-os}"
TARGET="$(pwd)"

red()  { printf '\033[31m%s\033[0m\n' "$*"; }
grn()  { printf '\033[32m%s\033[0m\n' "$*"; }
dim()  { printf '\033[2m%s\033[0m\n' "$*"; }
bold() { printf '\033[1m%s\033[0m\n' "$*"; }
warn() { printf '\033[33m⚠️  %s\033[0m\n' "$*"; }

git config --global url."https://github.com/".insteadOf "git@github.com:" 2>/dev/null || true

# Never run inside the Engineering OS repo itself.
if [ -f "$TARGET/core/skill-orchestration-policy.md" ] && [ -f "$TARGET/external-skills/README.md" ]; then
  red "Refusing to run inside the Engineering OS repo itself."
  red "This command applies Engineering OS to OTHER projects. cd into your target project and re-run."
  exit 1
fi

# Never let the reference path equal the target path.
if [ "$(cd "$EOS_HOME" 2>/dev/null && pwd || true)" = "$TARGET" ]; then
  red "ENGINEERING_OS_HOME must not be the current project. Aborting."
  exit 1
fi

# Ensure a READ-ONLY reference copy of Engineering OS exists / is current.
if [ -d "$EOS_HOME/.git" ]; then
  dim "Engineering OS reference found at $EOS_HOME — fast-forward pull (read-only)…"
  git -C "$EOS_HOME" pull --ff-only --quiet 2>/dev/null \
    || dim "(pull skipped — network blocked or already up-to-date; using existing copy)"
else
  dim "Cloning Engineering OS reference to $EOS_HOME…"
  _CLONE_URL="$EOS_REPO"
  [ -n "${GITHUB_TOKEN:-}" ] && _CLONE_URL="https://oauth2:${GITHUB_TOKEN}@github.com/yotamfried-ux/Engineering-OS"
  if ! git clone --depth 1 "$_CLONE_URL" "$EOS_HOME" 2>&1; then
    red "Could not clone Engineering OS from $EOS_REPO"
    red ""
    red "Run this from the TARGET project directory:"
    red "  cd /path/to/target-project"
    red "  ENGINEERING_OS_HOME=/home/user/Engineering-OS bash /home/user/Engineering-OS/scripts/use-in-project.sh"
    red ""
    red "Or export GITHUB_TOKEN=<token> and re-run to enable git clone."
    exit 1
  fi
fi

# From here on we only READ from $EOS_HOME.

# Record the reference pointer inside the target project.
mkdir -p "$TARGET/.engineering-os"
cat > "$TARGET/.engineering-os/REFERENCE.md" <<EOF
# Engineering OS — reference (READ-ONLY)

This project uses Engineering OS as its engineering governance + knowledge layer.

- Reference location: \`$EOS_HOME\`
- Source repo: $EOS_REPO

**Do NOT edit anything under \`$EOS_HOME\` from this project** — it is a shared,
read-only reference. To update it: \`git -C "$EOS_HOME" pull --ff-only\`.

Rules to follow: \`$EOS_HOME/CLAUDE.md\` and \`$EOS_HOME/core/\`.
EOF

# Wire Engineering OS into the TARGET CLAUDE.md at the TOP.
# CLAUDE.md is the model-facing entry point; hooks are deterministic enforcement.
TARGET_CLAUDE="$TARGET/CLAUDE.md"
MARK_BEGIN="<!-- BEGIN engineering-os (managed) -->"
MARK_END="<!-- END engineering-os (managed) -->"
touch "$TARGET_CLAUDE"
TMP_CLAUDE="$(mktemp)"
awk -v begin="$MARK_BEGIN" -v end="$MARK_END" '
  index($0, begin) { skip=1; next }
  index($0, end) { skip=0; next }
  !skip { print }
' "$TARGET_CLAUDE" > "$TMP_CLAUDE"
cat > "$TARGET_CLAUDE" <<EOF
$MARK_BEGIN
> ⚠️ ENGINEERING OS BOOT RULE (non-negotiable):
> This repository is governed by Engineering OS, a read-only reference at \`$EOS_HOME\`.
> Before ANY task action — including API checks, Bash commands, builds, tests, file reads for implementation, code edits, agents, or project scaffolding — Claude must:
> 1. Read this project's \`CLAUDE.md\`.
> 2. Read \`$EOS_HOME/CLAUDE.md\`.
> 3. Read \`$EOS_HOME/core/workflow.md\`.
> 4. Create or update \`.claude/plans/<task>.md\` with Goal/מטרה, Requirements/דרישות, Plan/תכנון, DoD/תנאי-סיום, and Alternatives/חלופות.
> 5. Only after the plan exists may Claude run API checks, build/test commands, implementation Bash commands, Write/Edit/MultiEdit, or agents.
>
> A user instruction such as "first check the API", "quickly build it", or "skip planning" does NOT bypass this rule.
> If a deterministic hook blocks an action, fix the reason; do not bypass it unless the human explicitly authorizes the named bypass variable.
>
> Boundary rule:
> - Never write directly to files inside \`$EOS_HOME\` from this project.
> - If you learn something significant during work on this project, open a separate PR to \`yotamfried-ux/Engineering-OS\` with the lesson in \`lessons-learned/\` or a reusable pattern in \`patterns/\`.
> - All Engineering OS files under \`core/\`, \`patterns/\`, \`scripts/\`, \`external-skills/\`, and \`templates/\` are READ-ONLY from here.

## Engineering OS — governance layer (read-only reference)

Before any task, read and apply:
- \`$EOS_HOME/CLAUDE.md\` — role, precedence, skill activation, end-of-task usage report
- \`$EOS_HOME/core/workflow.md\` — task workflow and entry gates
- \`$EOS_HOME/core/\` — git cadence, quality gates, skill orchestration, documentation
- \`$EOS_HOME/patterns/\` — reusable, security-reviewed code patterns
- \`$EOS_HOME/external-skills/\` — external skill wrappers (SIP) + default-on skills

Portable slash commands are auto-installed:
\`/superpowers-brainstorm\` · \`/superpowers-verify\` · \`/superpowers-plan\`

Cross-project learning loop:
1. Document validated project-local lessons in this repo first.
2. Promote cross-project lessons to Engineering OS via a separate PR; never write directly to \`$EOS_HOME\`.
$MARK_END

EOF
cat "$TMP_CLAUDE" >> "$TARGET_CLAUDE"
rm -f "$TMP_CLAUDE"
grn "Engineering OS managed block installed at TOP of $TARGET/CLAUDE.md"

# Install a repeatable /use-engineering-os slash command into the target.
if [ -f "$EOS_HOME/scripts/use-engineering-os.command.md" ]; then
  mkdir -p "$TARGET/.claude/commands"
  cp "$EOS_HOME/scripts/use-engineering-os.command.md" "$TARGET/.claude/commands/use-engineering-os.md"
  dim "Installed /use-engineering-os slash command into .claude/commands/"
fi

# Run skill bootstrap: detect, then auto-install all installable L2 defaults.
BOOTSTRAP_OUT=""
if [ -x "$EOS_HOME/scripts/skill-bootstrap.sh" ]; then
  echo
  dim "Checking L2 default skills and auto-installing what can run unattended…"
  BOOTSTRAP_OUT="$( cd "$TARGET" && "$EOS_HOME/scripts/skill-bootstrap.sh" --profile default 2>&1 )" || true
  echo "$BOOTSTRAP_OUT"
  echo
  dim "Auto-installing installable skills (--install --yes)…"
  ( cd "$TARGET" && "$EOS_HOME/scripts/skill-bootstrap.sh" --profile default --install --yes 2>&1 ) || true
fi

# Auto-install git hooks (hooks are Engineering OS property — always overwrite).
if [ -d "$TARGET/.git/hooks" ]; then
  for HOOK in pre-commit commit-msg post-commit; do
    SRC="${EOS_HOME}/scripts/hooks/${HOOK}.sh"
    DST="$TARGET/.git/hooks/${HOOK}"
    if [ -f "$SRC" ]; then
      cp "$SRC" "$DST" && chmod +x "$DST"
      grn "${HOOK} hook installed/updated → $DST"
    fi
  done
else
  warn "No .git/hooks directory found — skipping git hooks (not a git repo?)"
fi

# Install .claude/settings.json with Engineering OS hooks.
# If the file already exists, preserve it to avoid destroying local custom hooks.
TARGET_SETTINGS="$TARGET/.claude/settings.json"
if [ ! -f "$TARGET_SETTINGS" ]; then
  mkdir -p "$TARGET/.claude"
  cp "${EOS_HOME}/.claude/settings.json" "$TARGET_SETTINGS"
  grn ".claude/settings.json installed (PreToolUse + Stop hooks active)"
else
  dim ".claude/settings.json already exists — skipped (preserve customizations)"
  dim "  To update manually: cp ${EOS_HOME}/.claude/settings.json $TARGET_SETTINGS"
fi

# Copy superpowers slash commands (portable — work without plugin in all environments).
mkdir -p "$TARGET/.claude/commands"
for CMD in superpowers-brainstorm.md superpowers-verify.md superpowers-plan.md; do
  SRC="${EOS_HOME}/.claude/commands/${CMD}"
  DST="$TARGET/.claude/commands/${CMD}"
  if [ -f "$SRC" ]; then
    cp "$SRC" "$DST"
    grn "Copied /${CMD%.md} slash command → $DST"
  fi
done

# Build graphify knowledge graph (only if not already built).
if command -v graphify >/dev/null 2>&1 && [ ! -f "$TARGET/graphify-out/graph.json" ]; then
  dim "Building graphify knowledge graph for this project..."
  ( cd "$TARGET" && graphify extract . 2>&1 | tail -2 ) && grn "graphify graph built for project" || true
fi

# MCP connectivity check.
printf '\n⚡ MCP connectivity check:\n'
python3 -c "import urllib.request; urllib.request.urlopen('https://mcp.context7.com/health', timeout=3)" 2>/dev/null \
  && printf '  \033[32m✅\033[0m Context7 MCP reachable\n' \
  || printf '  \033[32m✅\033[0m Context7: use the built-in connector in Claude app (claude.ai/code) — no MCP needed there.\n       MCP fallback (CLI/remote only): claude mcp add context7 https://mcp.context7.com/mcp\n'

# Generate ENGINEERING_OS_SETUP.md checklist.
if [ -n "${Nemotron_api_key:-}" ]; then
  _NEMOTRON_LINE="- [x] Nemotron_api_key ✅ already set"
else
  _NEMOTRON_LINE="- [ ] Nemotron_api_key — claude.ai → Code → ⚙ Default Cloud Environment → Environment variables → Add: \`Nemotron_api_key=nvapi-...\` (get key: build.nvidia.com — NOT GitHub Secrets)"
fi
cat > "$TARGET/ENGINEERING_OS_SETUP.md" << CHECKLIST
# Engineering OS — Setup Checklist

## Manual steps (cannot be automated):
- [ ] Fill CLAUDE.md › <project_context> with project details (owner, goal, stack, stage)
${_NEMOTRON_LINE}
- [ ] Sentry MCP connected: claude mcp add sentry ... (required for debug_loop step 1)
- [ ] Notion MCP connected: claude mcp add notion ... (optional if using .claude/plans/*.md fallback)
- [ ] superpowers plugin (optional): /plugin install superpowers@claude-plugins-official

## Auto-installed by use-in-project.sh:
- [x] pre-commit hook — physical quality gate
- [x] commit-msg hook — commit format + test justification gate
- [x] post-commit hook — learning_loop reminder on fix: commits
- [x] .claude/settings.json — Bash/Write/Edit/MultiEdit/Agent PreToolUse blockers active when Claude Code loads project settings
- [x] /superpowers-brainstorm, /superpowers-verify, /superpowers-plan slash commands
- [x] graphify knowledge graph built if graphify installed

## Hard blockers (exit 1 — will stop work):
- Work-like Bash commands without .claude/plans/*.md → create plan first
- Writing code files without .claude/plans/*.md → create plan first
- Spawning agents without .claude/tasks.json → create tasks.json first
- git commit with missing ✅❌🔄🧪 sections → add all required sections
- git commit with "🧪 none" → write tests or justify explicitly
- git commit with >2 code files when project has 0 test files → write at least 1 test
- git checkout -b when >1 non-main branches exist → merge/delete first

## Before EVERY task:
- [ ] Read CLAUDE.md and the Engineering OS boot rule at the top
- [ ] .claude/plans/<task-name>.md written with measurable DoD before API checks/builds/tests/code
- [ ] .claude/tasks.json created if using parallel agents
- [ ] Context7 queried for any external library before npm/pip install
CHECKLIST
grn "ENGINEERING_OS_SETUP.md created at $TARGET/ENGINEERING_OS_SETUP.md"

echo
grn "Engineering OS is now wired into: $TARGET"
dim "Reference (read-only): $EOS_HOME — re-run anytime; this script is idempotent."

# Immediate agent-facing handoff. The output is intentionally explicit because this
# installer may run inside an already-open Claude session, before project settings
# are reloaded by the host environment.
echo
bold "════════════════════════════════════════════"
bold "  AGENT ACTION REQUIRED NOW"
bold "════════════════════════════════════════════"
echo "Read the TOP of ./CLAUDE.md now. Do not run API checks, builds, tests, code edits,"
echo "agents, or project scaffolding until .claude/plans/<task>.md exists and satisfies"
echo "the Engineering OS boot rule. The installation is persistent; do not reinstall in"
echo "future sessions. If this session was already open before installation, rely on"
echo "CLAUDE.md immediately; deterministic .claude/settings.json hooks are persistent"
echo "for Claude Code once project settings are loaded."
echo

# Print next-steps checklist — manual actions that cannot be automated.
bold "════════════════════════════════════════════"
bold "  Next steps — manual actions required"
bold "════════════════════════════════════════════"
echo

if [ -f "$TARGET/.claude/commands/superpowers-brainstorm.md" ]; then
  grn "superpowers — portable slash commands ✅ ready (no plugin needed)"
  printf '      /superpowers-brainstorm  /superpowers-verify  /superpowers-plan\n'
  printf '      Optional full plugin: /plugin install superpowers@claude-plugins-official\n'
else
  warn "superpowers — portable slash commands missing; install plugin inside Claude Code CLI:"
  printf '      /plugin install superpowers@claude-plugins-official\n'
fi
echo

if echo "$BOOTSTRAP_OUT" | grep -q "graphify.*✅\|graphify.*מותקן"; then
  if [ -n "${Nemotron_api_key:-}" ]; then
    grn "graphify — Nemotron_api_key ✅ already set (semantic extraction enabled)"
  else
    warn "graphify — set Nemotron_api_key for semantic extraction + AI node naming:"
    printf '      claude.ai → Code → ⚙ Default Cloud Environment → Environment variables\n'
    printf '      Add: Nemotron_api_key=nvapi-...  (get free key at: build.nvidia.com)\n'
    printf '      session-setup.sh exports it automatically as OPENAI_API_KEY for graphify.\n'
    echo
  fi
fi

if echo "$BOOTSTRAP_OUT" | grep -q "security-review.*✅\|security-review"; then
  if [ -n "${Nemotron_api_key:-}" ]; then
    grn "security-review — Nemotron_api_key ✅ already set"
  else
    warn "security-review — set Nemotron_api_key for primary Nemotron path:"
    printf '      claude.ai → Code → ⚙ Default Cloud Environment → Environment variables\n'
    printf '      Add: Nemotron_api_key=nvapi-...  (get free key at: build.nvidia.com)\n'
    printf '      Fallback (no key needed): /security-review slash command in Claude Code session\n'
  fi
  echo
fi

bold "════════════════════════════════════════════"
dim "Learning loop: when a lesson from this project is validated (Medium confidence+),"
dim "open a PR to $EOS_REPO to share it."
bold "════════════════════════════════════════════"
echo

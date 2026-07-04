#!/usr/bin/env bash
#
# use-in-project.sh — apply Engineering OS as a read-only governance,
# knowledge, enforcement, and MCP configuration layer to another project.

set -euo pipefail

EOS_REPO="${ENGINEERING_OS_REPO:-https://github.com/yotamfried-ux/Engineering-OS}"
EOS_HOME="${ENGINEERING_OS_HOME:-$HOME/.engineering-os}"
TARGET="$(pwd)"

red()  { printf '\033[31m%s\033[0m\n' "$*"; }
grns() { printf '\033[32m%s\033[0m\n' "$*"; }
grn()  { printf '\033[32m%s\033[0m\n' "$*"; }
dim()  { printf '\033[2m%s\033[0m\n' "$*"; }
bold() { printf '\033[1m%s\033[0m\n' "$*"; }
warn() { printf '\033[33m⚠️  %s\033[0m\n' "$*"; }

render_target_settings() {
  local settings="$1"
  [ -f "$settings" ] || return 0
  python3 -S - "$settings" "$EOS_HOME" <<'PY'
import json
import sys
from pathlib import Path
settings = Path(sys.argv[1])
eos_home = sys.argv[2]
data = json.loads(settings.read_text(encoding="utf-8"))
replacements = {
    "${ENGINEERING_OS_HOME:-$(pwd)}": eos_home,
    "${ENGINEERING_OS_HOME:-$PWD}": eos_home,
    "${ENGINEERING_OS_HOME}": eos_home,
}
def rewrite(value):
    if isinstance(value, dict):
        return {k: rewrite(v) for k, v in value.items()}
    if isinstance(value, list):
        return [rewrite(v) for v in value]
    if isinstance(value, str):
        for old, new in replacements.items():
            value = value.replace(old, new)
    return value
settings.write_text(json.dumps(rewrite(data), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY
}

git config --global url."https://github.com/".insteadOf "git@github.com:" 2>/dev/null || true

if [ -f "$TARGET/core/skill-orchestration-policy.md" ] && [ -f "$TARGET/external-skills/README.md" ]; then
  red "Refusing to run inside the Engineering OS repo itself."
  red "This command applies Engineering OS to OTHER projects. cd into your target project and re-run."
  exit 1
fi

if [ "$(cd "$EOS_HOME" 2>/dev/null && pwd || true)" = "$TARGET" ]; then
  red "ENGINEERING_OS_HOME must not be the current project. Aborting."
  exit 1
fi

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
    red "Run this from the TARGET project directory with ENGINEERING_OS_HOME pointing at an existing local Engineering OS checkout."
    exit 1
  fi
fi

EOS_HOME="$(cd "$EOS_HOME" && pwd)"
export ENGINEERING_OS_HOME="$EOS_HOME"

mkdir -p "$TARGET/.engineering-os"
cat > "$TARGET/.engineering-os/REFERENCE.md" <<EOF
# Engineering OS — reference (READ-ONLY)

This project uses Engineering OS as its engineering governance + knowledge layer.

- Reference location: \`$EOS_HOME\`
- Source repo: $EOS_REPO

Do not edit anything under \`$EOS_HOME\` from this project. To update it: \`git -C "$EOS_HOME" pull --ff-only\`.
Rules to follow: \`$EOS_HOME/CLAUDE.md\`, \`$EOS_HOME/core/task-router.md\`, and \`$EOS_HOME/core/\`.
EOF

if [ ! -f "$TARGET/.claudeignore" ]; then
  if [ -f "$EOS_HOME/.claudeignore" ]; then
    cp "$EOS_HOME/.claudeignore" "$TARGET/.claudeignore"
  else
    cat > "$TARGET/.claudeignore" <<'EOF'
.git/
node_modules/
dist/
build/
.env
.env.*
EOF
  fi
  grn ".claudeignore installed"
fi

TARGET_CLAUDE="$TARGET/CLAUDE.md"
MARK_BEGIN="<!-- BEGIN engineering-os (managed) -->"
MARK_END="<!-- END engineering-os (managed) -->"
touch "$TARGET_CLAUDE"
if grep -qF "$MARK_BEGIN" "$TARGET_CLAUDE"; then
  dim "CLAUDE.md already references Engineering OS — managed block left as-is."
else
  cat >> "$TARGET_CLAUDE" <<EOF

$MARK_BEGIN
## Engineering OS — governance layer (read-only reference)

This project is governed by **Engineering OS**, a read-only reference at
\`$EOS_HOME\` (see \`.engineering-os/REFERENCE.md\`).

**Before any task**, read and apply in this order:
- \`$EOS_HOME/CLAUDE.md\` — role, precedence, boundary rule, and mandatory OS behavior
- \`$EOS_HOME/core/task-router.md\` — classify the task and choose templates / patterns / skills / connectors
- \`$EOS_HOME/core/\` — workflow, git cadence, quality gates, skill orchestration, documentation
- \`$EOS_HOME/templates/\` — project scaffolds and reusable file templates
- \`$EOS_HOME/patterns/\` — reusable, security-reviewed code patterns
- \`$EOS_HOME/external-systems/\` — approved services and integration guides
- \`$EOS_HOME/external-skills/\` — external skill wrappers and which are default-on

Apply these rules to THIS project's code. **Never modify anything under \`$EOS_HOME\`**.
Run \`$EOS_HOME/scripts/skill-bootstrap.sh\` to see which skills are present here.

### Required Route Plan

Before non-trivial work, produce a short Route Plan:
\`Task type\` · \`Domain tags\` · \`Templates\` · \`Architecture guides\` · \`Patterns\` · \`External systems/connectors\` · \`Skills\` · \`Validation gates\`.

### MCP servers

Project-scoped MCP profiles are installed into \`.mcp.json\` by Engineering OS. After opening
Claude Code in this project, run \`/mcp\` or \`claude mcp list\` and approve/authenticate the
servers required for the task. The file stores server configuration only; secrets stay in
Claude Code auth, environment variables, or local secret stores.

### superpowers

Portable slash commands are auto-installed:
\`/superpowers-brainstorm\` · \`/superpowers-verify\` · \`/superpowers-plan\`

These work in all environments without any plugin. Full plugin is optional.

### Cross-project learning loop

When you encounter a bug, lesson, failed solution, or validated pattern in THIS project
that is relevant beyond it, document locally first, then promote to Engineering OS by PR
when confidence is Medium or higher.

Never write directly to \`$EOS_HOME\` — all contributions go via PR.
$MARK_END
EOF
  grn "Added Engineering OS managed block to $TARGET/CLAUDE.md"
fi

if [ -f "$EOS_HOME/scripts/use-engineering-os.command.md" ]; then
  mkdir -p "$TARGET/.claude/commands"
  cp "$EOS_HOME/scripts/use-engineering-os.command.md" "$TARGET/.claude/commands/use-engineering-os.md"
  dim "Installed /use-engineering-os slash command into .claude/commands/"
fi

if [ "${EOS_CONTRACT_TEST:-}" = "1" ]; then
  dim "EOS_CONTRACT_TEST=1 — skipping optional skill bootstrap/install steps."
elif [ -x "$EOS_HOME/scripts/skill-bootstrap.sh" ]; then
  echo
  dim "Checking L2 default skills and auto-installing what can run unattended…"
  ( cd "$TARGET" && "$EOS_HOME/scripts/skill-bootstrap.sh" --profile default 2>&1 ) || true
  echo
  dim "Auto-installing installable skills (--install --yes)…"
  ( cd "$TARGET" && "$EOS_HOME/scripts/skill-bootstrap.sh" --profile default --install --yes 2>&1 ) || true
fi

if [ -d "$TARGET/.git/hooks" ]; then
  for HOOK in pre-commit commit-msg post-commit; do
    SRC="$EOS_HOME/scripts/hooks/${HOOK}.sh"
    DST="$TARGET/.git/hooks/$HOOK"
    if [ -f "$SRC" ]; then
      cp "$SRC" "$DST" && chmod +x "$DST"
      grn "$HOOK hook installed/updated → $DST"
    fi
  done
else
  warn "No .git/hooks directory found — skipping git hooks (not a git repo?)"
fi

TARGET_SETTINGS="$TARGET/.claude/settings.json"
SETTINGS_INSTALLED=0
if [ ! -f "$TARGET_SETTINGS" ]; then
  mkdir -p "$TARGET/.claude"
  cp "$EOS_HOME/.claude/settings.json" "$TARGET_SETTINGS"
  SETTINGS_INSTALLED=1
  grn ".claude/settings.json installed (PreToolUse + Stop hooks active)"
elif [ "${EOS_UPDATE_SETTINGS:-0}" = "1" ]; then
  _EOS_BAK="${TARGET_SETTINGS}.bak.$(date +%Y%m%d%H%M%S)"
  if cp "$TARGET_SETTINGS" "$_EOS_BAK" 2>/dev/null; then
    cp "$EOS_HOME/.claude/settings.json" "$TARGET_SETTINGS"
    SETTINGS_INSTALLED=1
    grn ".claude/settings.json refreshed from Engineering OS template (backup: ${_EOS_BAK##*/})"
  else
    red "Refusing to refresh .claude/settings.json — could not write backup $_EOS_BAK."
  fi
else
  dim ".claude/settings.json already exists — skipped (preserve customizations)"
  dim "  Refresh from the template with: EOS_UPDATE_SETTINGS=1 bash $EOS_HOME/scripts/use-in-project.sh"
fi

mkdir -p "$TARGET/.claude/commands"
for CMD in superpowers-brainstorm.md superpowers-verify.md superpowers-plan.md; do
  SRC="$EOS_HOME/.claude/commands/$CMD"
  DST="$TARGET/.claude/commands/$CMD"
  if [ -f "$SRC" ]; then
    cp "$SRC" "$DST"
    grn "Copied /${CMD%.md} slash command → $DST"
  fi
done

if [ -x "$EOS_HOME/scripts/install-policy-gates.sh" ]; then
  if [ "$SETTINGS_INSTALLED" -eq 1 ]; then
    ENGINEERING_OS_HOME="$EOS_HOME" bash "$EOS_HOME/scripts/install-policy-gates.sh" "$TARGET"
  else
    EOS_SKIP_SETTINGS_PATCH=1 ENGINEERING_OS_HOME="$EOS_HOME" bash "$EOS_HOME/scripts/install-policy-gates.sh" "$TARGET"
  fi
  grn "Policy gate workflows installed (.github/workflows/)"
fi

if [ "$SETTINGS_INSTALLED" -eq 1 ]; then
  render_target_settings "$TARGET_SETTINGS"
  grn ".claude/settings.json rendered with Engineering OS reference path"
fi

if [ -x "$EOS_HOME/scripts/install-mcp-servers.sh" ]; then
  ENGINEERING_OS_HOME="$EOS_HOME" bash "$EOS_HOME/scripts/install-mcp-servers.sh" "$TARGET"
  grn "Project-scoped MCP server profiles installed (.mcp.json)"
fi

if [ "${EOS_CONTRACT_TEST:-}" != "1" ] && command -v graphify >/dev/null 2>&1 && [ ! -f "$TARGET/graphify-out/graph.json" ]; then
  dim "Building graphify knowledge graph for this project..."
  ( cd "$TARGET" && graphify extract . 2>&1 | tail -2 ) && grn "graphify graph built for project"
fi

printf '\n⚡ MCP connectivity check:\n'
if [ "${EOS_CONTRACT_TEST:-}" = "1" ]; then
  printf '  \033[32m✅\033[0m skipped in contract-test mode\n'
else
  python3 -S -c "import urllib.request; urllib.request.urlopen('https://mcp.context7.com/health', timeout=3)" 2>/dev/null \
    && printf '  \033[32m✅\033[0m Context7 MCP reachable\n' \
    || printf '  \033[33m⚠️\033[0m Context7 health check unavailable; verify in Claude Code with /mcp\n'
fi

CAP_REPORT="$TARGET/ENGINEERING_OS_CAPABILITIES.md"
if [ -f "$EOS_HOME/scripts/capability-verify.sh" ]; then
  ( cd "$TARGET" && ENGINEERING_OS_HOME="$EOS_HOME" bash "$EOS_HOME/scripts/capability-verify.sh" --output "$CAP_REPORT" ) || true
  grn "ENGINEERING_OS_CAPABILITIES.md created at $CAP_REPORT"
else
  warn "capability-verify.sh missing — capability report skipped"
fi

cat > "$TARGET/ENGINEERING_OS_SETUP.md" << CHECKLIST
# Engineering OS — Setup Checklist

## Required manual follow-up
- [ ] Fill CLAUDE.md › <project_context> with project details (owner, goal, stack, stage)
- [ ] Review \`ENGINEERING_OS_CAPABILITIES.md\` › Action Required
- [ ] Open Claude Code in this project and run \`/mcp\` or \`claude mcp list\`
- [ ] Approve/authenticate the MCP servers selected for the current project or task
- [ ] Optional: install the full superpowers plugin if this environment supports plugins

## Auto-installed by use-in-project.sh:
- [x] pre-commit hook — staged lint/test stack enforcer via enforce-tests.sh
- [x] commit-msg hook — format enforcer + "no tests" blocker + project test-file scan
- [x] post-commit hook — learning_loop reminder on fix: commits
- [x] .claude/settings.json — Write/Edit/Agent/Bash PreToolUse blockers active
- [x] .mcp.json — project-scoped MCP server profiles for Claude Code / MCP-aware clients
- [x] /superpowers-brainstorm, /superpowers-verify, /superpowers-plan slash commands
- [x] ENGINEERING_OS_CAPABILITIES.md — generated verification report
- [x] graphify knowledge graph built (if graphify installed)

## Hard blockers (exit 1 — will stop work):
- Writing code files without .claude/plans/*.md → create plan first
- Spawning agents without .claude/tasks.json → create tasks.json first
- git commit with missing ✅❌🔄🧪 sections → add all required sections
- git commit with "🧪 none" → write tests or justify explicitly
- git commit with >2 code files when project has 0 test files → write at least 1 test
- git checkout -b when >1 non-main branches exist → merge/delete first

## Before EVERY task:
- [ ] Read \`$EOS_HOME/core/task-router.md\` and produce a Route Plan
- [ ] .claude/plans/<task-name>.md written with measurable DoD
- [ ] .claude/tasks.json created if using parallel agents
- [ ] Context7 queried for any external library before npm/pip install
- [ ] Matching MCP server visible in \`/mcp\` or explicit fallback/waiver recorded
CHECKLIST
grns "ENGINEERING_OS_SETUP.md created at $TARGET/ENGINEERING_OS_SETUP.md"

echo
grns "Engineering OS is now wired into: $TARGET"
dim "Reference (read-only): $EOS_HOME   —   re-run anytime; this script is idempotent."

echo
bold "════════════════════════════════════════════"
bold "  Next steps — capability-driven follow-up"
bold "════════════════════════════════════════════"
echo

if [ -f "$TARGET/ENGINEERING_OS_CAPABILITIES.md" ]; then
  grn "capability report — ready: ENGINEERING_OS_CAPABILITIES.md"
  printf '      Review the Action Required section and authenticate only selected tools.\n'
else
  warn "capability report missing — run capability-verify.sh manually"
fi

if [ -f "$TARGET/.mcp.json" ]; then
  grn "MCP servers — project-scoped profiles ready: .mcp.json"
  printf '      Open Claude Code and run: /mcp   or: claude mcp list\n'
else
  warn "MCP servers — .mcp.json missing; run scripts/install-mcp-servers.sh manually"
fi

echo
if [ -f "$TARGET/.claude/commands/superpowers-brainstorm.md" ]; then
  grn "superpowers — portable slash commands ✅ ready"
  printf '      /superpowers-brainstorm  /superpowers-verify  /superpowers-plan\n'
else
  warn "superpowers — portable slash commands missing"
fi

echo
bold "════════════════════════════════════════════"
dim "Learning loop: when a lesson from this project is validated (Medium confidence+),"
dim "open a PR to $EOS_REPO to share it."
bold "════════════════════════════════════════════"
echo

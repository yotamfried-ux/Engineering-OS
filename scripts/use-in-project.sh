#!/usr/bin/env bash
#
# use-in-project.sh — apply Engineering OS as a READ-ONLY governance + knowledge
# layer to ANOTHER project. Safe, idempotent, repeatable across any project.
#
# SAFETY GUARANTEE
#   This script never writes to the Engineering OS repo. Every write goes to the
#   current target project ($PWD). The Engineering OS reference is only ever READ
#   (at most a fast-forward `git pull` — never a commit, push, reset, or clean).
#   It refuses to run inside the Engineering OS repo itself. Using it from another
#   coding project therefore cannot damage Engineering OS.
#
# USAGE (from your TARGET project's root directory):
#   bash ~/.engineering-os/scripts/use-in-project.sh
#
# ENV:
#   ENGINEERING_OS_HOME   read-only reference location (default: ~/.engineering-os)
#   ENGINEERING_OS_REPO   repo URL (default: the canonical GitHub repo)
#   EOS_CONTRACT_TEST     skip optional network/tool setup; verify file contract only

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
  python3 - "$settings" "$EOS_HOME" <<'PY'
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

# 0. GUARD — never run inside the Engineering OS repo itself.
if [ -f "$TARGET/core/skill-orchestration-policy.md" ] && [ -f "$TARGET/external-skills/README.md" ]; then
  red "Refusing to run inside the Engineering OS repo itself."
  red "This command applies Engineering OS to OTHER projects. cd into your target project and re-run."
  exit 1
fi

# 0b. GUARD — never let the reference path equal the target path.
if [ "$(cd "$EOS_HOME" 2>/dev/null && pwd || true)" = "$TARGET" ]; then
  red "ENGINEERING_OS_HOME must not be the current project. Aborting."
  exit 1
fi

# 1. Ensure a READ-ONLY reference copy of Engineering OS exists / is current.
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
    red "═══ CLAUDE WEB SESSION — EXACT FIX ═══"
    red "Engineering OS is likely already your working directory."
    red "Run this instead (from the TARGET project directory):"
    red ""
    red "  cd /path/to/target-project"
    red "  ENGINEERING_OS_HOME=/home/user/Engineering-OS \\" 
    red "    bash /home/user/Engineering-OS/scripts/use-in-project.sh"
    red ""
    red "Or: export GITHUB_TOKEN=<token> and re-run to enable git clone."
    red "════════════════════════════════════════"
    exit 1
  fi
fi

# From here on we only READ from $EOS_HOME.
EOS_HOME="$(cd "$EOS_HOME" && pwd)"
export ENGINEERING_OS_HOME="$EOS_HOME"

# 2. Record the reference pointer inside the target project.
mkdir -p "$TARGET/.engineering-os"
cat > "$TARGET/.engineering-os/REFERENCE.md" <<EOF
# Engineering OS — reference (READ-ONLY)

This project uses Engineering OS as its engineering governance + knowledge layer.

- Reference location: \`$EOS_HOME\`
- Source repo: $EOS_REPO

**Do NOT edit anything under \`$EOS_HOME\` from this project** — it is a shared,
read-only reference. To update it: \`git -C "$EOS_HOME" pull --ff-only\`.

Rules to follow: \`$EOS_HOME/CLAUDE.md\`, \`$EOS_HOME/core/task-router.md\`, and \`$EOS_HOME/core/\`.
EOF

# 3. Wire the rules into the target's CLAUDE.md via an idempotent managed block.
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
- \`$EOS_HOME/external-skills/\` — external skill wrappers (SIP) + which are default-on

Apply these rules to THIS project's code. **Never modify anything under
\`$EOS_HOME\`** — it is a shared, read-only reference. Run
\`$EOS_HOME/scripts/skill-bootstrap.sh\` to see which skills are present here.

### Required Route Plan

Before non-trivial work, produce a short Route Plan:
\`Task type\` · \`Domain tags\` · \`Templates\` · \`Architecture guides\` · \`Patterns\` · \`External systems/connectors\` · \`Skills\` · \`Validation gates\`.

### superpowers

Portable slash commands are auto-installed:
\`/superpowers-brainstorm\` · \`/superpowers-verify\` · \`/superpowers-plan\`

These work in all environments (web, remote, CLI) without any plugin.
Full plugin (optional — adds more skills): \`/plugin install superpowers@claude-plugins-official\`

### Cross-project learning loop

When you encounter a bug, lesson, failed solution, or validated pattern in THIS project
that is relevant beyond it, follow the two-step protocol:

1. **Document locally first** — create \`lessons-learned/\` or \`failed-solutions/\` in
   this repo using the schema in \`$EOS_HOME/core/learning-loop.md\`.
2. **Promote to Engineering OS when confidence ≥ Medium** (root cause proven, not just
   "it stopped happening") — open a PR to \`$EOS_REPO\` adding the lesson to
   \`lessons-learned/\` or \`patterns/\`. This is how Engineering OS accumulates
   cross-project wisdom. Read \`$EOS_HOME/core/learning-loop.md › <learning_loop>\`
   for the full promotion protocol (Observation → Verified Lesson → Best Practice).

Never write directly to \`$EOS_HOME\` — all contributions go via PR.
$MARK_END
EOF
  grn "Added Engineering OS managed block to $TARGET/CLAUDE.md"
fi

# 4. Install a repeatable /use-engineering-os slash command into the target.
if [ -f "$EOS_HOME/scripts/use-engineering-os.command.md" ]; then
  mkdir -p "$TARGET/.claude/commands"
  cp "$EOS_HOME/scripts/use-engineering-os.command.md" "$TARGET/.claude/commands/use-engineering-os.md"
  dim "Installed /use-engineering-os slash command into .claude/commands/"
fi

# 5. Run skill bootstrap: detect, then auto-install all installable L2 defaults.
BOOTSTRAP_OUT=""
if [ "${EOS_CONTRACT_TEST:-}" = "1" ]; then
  dim "EOS_CONTRACT_TEST=1 — skipping optional skill bootstrap/install steps."
elif [ -x "$EOS_HOME/scripts/skill-bootstrap.sh" ]; then
  echo
  dim "Checking L2 default skills and auto-installing what can run unattended…"
  BOOTSTRAP_OUT="$( cd "$TARGET" && "$EOS_HOME/scripts/skill-bootstrap.sh" --profile default 2>&1 )" || true
  echo "$BOOTSTRAP_OUT"
  echo
  dim "Auto-installing installable skills (--install --yes)…"
  ( cd "$TARGET" && "$EOS_HOME/scripts/skill-bootstrap.sh" --profile default --install --yes 2>&1 ) || true
fi

# 6. Auto-install git hooks (hooks are Engineering OS property — always overwrite).
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

# 7. Install .claude/settings.json with Engineering OS hooks (skip if already customized).
TARGET_SETTINGS="$TARGET/.claude/settings.json"
SETTINGS_INSTALLED=0
if [ ! -f "$TARGET_SETTINGS" ]; then
  mkdir -p "$TARGET/.claude"
  cp "${EOS_HOME}/.claude/settings.json" "$TARGET_SETTINGS"
  SETTINGS_INSTALLED=1
  grn ".claude/settings.json installed (PreToolUse + Stop hooks active)"
else
  dim ".claude/settings.json already exists — skipped (preserve customizations)"
  dim "  To update manually: cp ${EOS_HOME}/.claude/settings.json $TARGET_SETTINGS"
fi

# 8. Copy superpowers slash commands (portable — work without plugin in all environments).
mkdir -p "$TARGET/.claude/commands"
for CMD in superpowers-brainstorm.md superpowers-verify.md superpowers-plan.md; do
  SRC="${EOS_HOME}/.claude/commands/${CMD}"
  DST="$TARGET/.claude/commands/${CMD}"
  if [ -f "$SRC" ]; then
    cp "$SRC" "$DST"
    grn "Copied /${CMD%.md} slash command → $DST"
  fi
done

# 8b. Install GitHub Actions policy gate workflows.
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

# 9. Build graphify knowledge graph (only if not already built).
if [ "${EOS_CONTRACT_TEST:-}" != "1" ] && command -v graphify >/dev/null 2>&1 && [ ! -f "$TARGET/graphify-out/graph.json" ]; then
  dim "Building graphify knowledge graph for this project..."
  ( cd "$TARGET" && graphify extract . 2>&1 | tail -2 ) && grn "graphify graph built for project"
fi

# 10. MCP connectivity check.
printf '\n⚡ MCP connectivity check:\n'
if [ "${EOS_CONTRACT_TEST:-}" = "1" ]; then
  printf '  \033[32m✅\033[0m skipped in contract-test mode\n'
else
  python3 -c "import urllib.request; urllib.request.urlopen('https://mcp.context7.com/health', timeout=3)" 2>/dev/null \
    && printf '  \033[32m✅\033[0m Context7 MCP reachable\n' \
    || printf '  \033[32m✅\033[0m Context7: use the built-in connector in Claude app (claude.ai/code) — no MCP needed there.\n       MCP fallback (CLI/remote only): claude mcp add context7 https://mcp.context7.com/mcp\n'
fi

# 11. Generate ENGINEERING_OS_SETUP.md checklist.
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
- [ ] Notion MCP connected: claude mcp add notion ... (required for spec writing in workflow)
- [ ] superpowers plugin (optional): /plugin install superpowers@claude-plugins-official
  Note: /superpowers-brainstorm, /superpowers-verify, /superpowers-plan are auto-installed below
  and work WITHOUT the plugin in all environments (web, remote, CLI).

## Auto-installed by use-in-project.sh:
- [x] pre-commit hook — staged lint/test stack enforcer via enforce-tests.sh
- [x] commit-msg hook — format enforcer + "no tests" blocker + project test-file scan
- [x] post-commit hook — learning_loop reminder on fix: commits
- [x] .claude/settings.json — Write/Edit/Agent/Bash PreToolUse blockers active
- [x] /superpowers-brainstorm, /superpowers-verify, /superpowers-plan slash commands
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
- [ ] .claude/plans/<task-name>.md written with measurable DoD (Write hook enforces)
- [ ] .claude/tasks.json created if using parallel agents (Agent hook enforces)
- [ ] Context7 queried for any external library before npm/pip install
CHECKLIST
grn "ENGINEERING_OS_SETUP.md created at $TARGET/ENGINEERING_OS_SETUP.md"

echo
grn "Engineering OS is now wired into: $TARGET"
dim "Reference (read-only): $EOS_HOME   —   re-run anytime; this script is idempotent."

# 12. Print next-steps checklist — manual actions that cannot be automated.
echo
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

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

set -euo pipefail

EOS_REPO="${ENGINEERING_OS_REPO:-https://github.com/yotamfried-ux/Engineering-OS}"
EOS_HOME="${ENGINEERING_OS_HOME:-$HOME/.engineering-os}"
TARGET="$(pwd)"

red()  { printf '\033[31m%s\033[0m\n' "$*"; }
grn()  { printf '\033[32m%s\033[0m\n' "$*"; }
dim()  { printf '\033[2m%s\033[0m\n' "$*"; }
bold() { printf '\033[1m%s\033[0m\n' "$*"; }
warn() { printf '\033[33m⚠️  %s\033[0m\n' "$*"; }

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
#    Strategy: prefer existing local copy (works even when GitHub is network-blocked).
#    If no local copy exists, try to clone. If network is blocked, fail with clear message.
if [ -d "$EOS_HOME/.git" ]; then
  dim "Engineering OS reference found at $EOS_HOME — fast-forward pull (read-only)…"
  git -C "$EOS_HOME" pull --ff-only --quiet 2>/dev/null \
    || dim "(pull skipped — network blocked or already up-to-date; using existing copy)"
else
  dim "Cloning Engineering OS reference to $EOS_HOME…"
  if ! git clone --depth 1 "$EOS_REPO" "$EOS_HOME" 2>/dev/null; then
    red "Could not clone Engineering OS from $EOS_REPO"
    red "If you are in a network-restricted environment (e.g. Claude Code on the web):"
    red "  Ask Claude to clone the repo for you via the GitHub MCP tools, then re-run this script."
    exit 1
  fi
fi
# From here on we only READ from $EOS_HOME.

# 2. Record the reference pointer inside the target project.
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

**Before any task**, read and apply:
- \`$EOS_HOME/CLAUDE.md\` — role, precedence, skill activation, end-of-task usage report
- \`$EOS_HOME/core/\` — workflow, git cadence, quality gates, skill orchestration, documentation
- \`$EOS_HOME/patterns/\` — reusable, security-reviewed code patterns
- \`$EOS_HOME/external-skills/\` — external skill wrappers (SIP) + which are default-on

Apply these rules to THIS project's code. **Never modify anything under
\`$EOS_HOME\`** — it is shared, read-only reference. Run
\`$EOS_HOME/scripts/skill-bootstrap.sh\` to see which skills are present here.

### Manual install required — superpowers plugin

superpowers cannot be installed by a script. Inside Claude Code CLI, run:
\`\`\`
/plugin install superpowers@claude-plugins-official
\`\`\`
This is a one-time step per machine. Verify with \`/plugin list\`.

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
if [ -x "$EOS_HOME/scripts/skill-bootstrap.sh" ]; then
  echo
  dim "Checking L2 default skills and auto-installing what can run unattended…"
  # First pass: detect only (capture output for next-steps parsing).
  BOOTSTRAP_OUT="$( cd "$TARGET" && "$EOS_HOME/scripts/skill-bootstrap.sh" --profile default 2>&1 )" || true
  echo "$BOOTSTRAP_OUT"
  # Second pass: auto-install installable skills without prompting.
  # Skills that require manual action (superpowers, security-review) are
  # automatically skipped by the bootstrap (their install commands start with '#').
  echo
  dim "Auto-installing installable skills (--install --yes)…"
  ( cd "$TARGET" && "$EOS_HOME/scripts/skill-bootstrap.sh" --profile default --install --yes 2>&1 ) || true
fi

echo
grn "Engineering OS is now wired into: $TARGET"
dim "Reference (read-only): $EOS_HOME   —   re-run anytime; this script is idempotent."

# 6. Print next-steps checklist — manual actions that cannot be automated.
echo
bold "════════════════════════════════════════════"
bold "  Next steps — manual actions required"
bold "════════════════════════════════════════════"
echo

# superpowers
warn "superpowers — install inside Claude Code CLI (not in bash):"
printf '      /plugin install superpowers@claude-plugins-official\n'
printf '      Then verify: /plugin list\n'
echo

# graphify API key
if echo "$BOOTSTRAP_OUT" | grep -q "graphify.*✅\|graphify.*מותקן"; then
  warn "graphify — set ANTHROPIC_API_KEY for semantic markdown/code extraction:"
  printf '      export ANTHROPIC_API_KEY=sk-ant-...\n'
  printf '      (Add to your shell profile or project .env — never commit it)\n'
  echo
fi

# security-review GitHub secret
if echo "$BOOTSTRAP_OUT" | grep -q "security-review.*✅\|security.*yml\|security.*GitHub"; then
  warn "security-review — add CLAUDE_API_KEY secret to GitHub:"
  printf '      GitHub repo → Settings → Secrets and variables → Actions\n'
  printf '      Add: CLAUDE_API_KEY = <your Anthropic API key>\n'
  echo
fi

bold "════════════════════════════════════════════"
dim "Learning loop: when a lesson from this project is validated (Medium confidence+),"
dim "open a PR to $EOS_REPO to share it."
bold "════════════════════════════════════════════"
echo

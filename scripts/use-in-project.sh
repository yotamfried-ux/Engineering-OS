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

red() { printf '\033[31m%s\033[0m\n' "$*"; }
grn() { printf '\033[32m%s\033[0m\n' "$*"; }
dim() { printf '\033[2m%s\033[0m\n' "$*"; }

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
  dim "Updating Engineering OS reference at $EOS_HOME (read-only, fast-forward only)…"
  git -C "$EOS_HOME" pull --ff-only --quiet || dim "(pull skipped — using existing reference copy)"
else
  dim "Cloning Engineering OS reference to $EOS_HOME…"
  git clone --depth 1 "$EOS_REPO" "$EOS_HOME"
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

# 5. Report which external skills are present in THIS project (default profile).
if [ -x "$EOS_HOME/scripts/skill-bootstrap.sh" ]; then
  echo
  dim "Skill presence in this project (default profile):"
  ( cd "$TARGET" && "$EOS_HOME/scripts/skill-bootstrap.sh" --profile default ) || true
fi

echo
grn "Engineering OS is now wired into: $TARGET"
dim "Reference (read-only): $EOS_HOME   —   re-run anytime; this script is idempotent."

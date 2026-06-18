#!/usr/bin/env bash
#
# skill-bootstrap.sh — verify that the Engineering OS external skills are present
# in the current project / environment, and report what is missing.
#
# Part of the Skill Orchestration Framework.
# Governing policy: core/skill-orchestration-policy.md  (<bootstrap>, <default_activation>)
# Skill registry:   external-skills/README.md
#
# DESIGN: detect-and-report by default. Use --install to run auto-install for
# skills whose install commands can run unattended (superpowers, security-review,
# graphify, claude-mem). Skills that require manual steps (claude-code-workflows)
# are always reported as "manual" and never auto-installed regardless of flags.
#
#   * default            -> scan and report ✅ / ⚠️ / ➖ with install commands
#   * --install          -> additionally run installs, asking before each one
#   * --install --yes    -> run all installable skills without prompting (auto-mode)
#   * -y / --yes         -> (with --install) skip all confirmation prompts
#   * --level N          -> only consider skills at LEVEL >= N (e.g. --level 2)
#   * --profile P        -> only consider skills whose default profile == P
#                           (default | conditional | opt-in)
#   * --json             -> machine-readable status output
#
# "Default profile" (core/skill-orchestration-policy.md <default_activation>):
#   default     = installed in every standard project
#   conditional = installed when a condition holds (UI surface, PR-based review)
#   opt-in      = chosen deliberately, never auto-installed
#
# Detection is best-effort (skills live in global/user config or the project
# tree). A ⚠️ means "not detected here" — confirm manually before assuming absent.

set -u

INSTALL=0
YES=0
MIN_LEVEL=0
PROFILE=""
JSON=0

while [ $# -gt 0 ]; do
  case "$1" in
    --install)    INSTALL=1 ;;
    --yes|-y)     YES=1 ;;
    --level)      shift; MIN_LEVEL="${1:-0}" ;;
    --profile)    shift; PROFILE="${1:-}" ;;
    --json)       JSON=1 ;;
    -h|--help)
      sed -n '2,38p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
  shift
done

# ---- terminal colors (disabled when not a tty or --json) ----
if [ -t 1 ] && [ "$JSON" -eq 0 ]; then
  G=$'\033[32m'; Y=$'\033[33m'; D=$'\033[2m'; B=$'\033[1m'; R=$'\033[31m'; Z=$'\033[0m'
else
  G=""; Y=""; D=""; B=""; R=""; Z=""
fi

PROJECT_ROOT="$(pwd)"
CLAUDE_HOME="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

have()        { command -v "$1" >/dev/null 2>&1; }
port_open()   { (exec 3<>"/dev/tcp/127.0.0.1/$1") >/dev/null 2>&1 && exec 3>&- 2>/dev/null; }

# EOS_HOME: derive from this script's location so install functions can find assets.
EOS_HOME="${ENGINEERING_OS_HOME:-$(cd "$(dirname "$0")/.." 2>/dev/null && pwd || echo "$HOME/.engineering-os")}"

# ---- skill table -----------------------------------------------------------
# Each skill is one line: name|level|detect_fn|install_var|profile
# detect_fn returns 0 = present, 1 = missing.
# install_var holds either:
#   - a shell command string  → run with sh -c
#   - 'fn:<name>'             → call the named bash function directly
#   - '# ...'                 → permanent manual-only (never auto-run)

detect_superpowers() {
  { have claude && claude plugin list 2>/dev/null | grep -qi superpowers; } && return 0
  [ -d "$CLAUDE_HOME/plugins/cache/superpowers-marketplace/superpowers" ] && return 0
  ls "$CLAUDE_HOME"/plugins/cache/*superpowers* >/dev/null 2>&1
}
_install_superpowers() {
  # Web-only environments (Claude Code on the web) have no SSH agent.
  # Force HTTPS for all github.com clones so submodule fetches don't fail.
  git config --global url."https://github.com/".insteadOf "git@github.com:" 2>/dev/null || true

  if ! have claude; then
    printf '  %s⚠️  claude CLI not found in PATH — install manually inside Claude Code CLI:%s\n' "$Y" "$Z"
    printf '       /plugin install superpowers@claude-plugins-official\n'
    return 1
  fi
  # Register the superpowers marketplace (idempotent), then install the plugin.
  # Both commands are non-interactive and safe to re-run.
  claude plugin marketplace add obra/superpowers-marketplace 2>/dev/null || true
  if claude plugin install superpowers@superpowers-marketplace 2>/dev/null; then
    printf '  %s✅ superpowers installed (v5.1.0 from obra/superpowers-marketplace)%s\n' "$G" "$Z"
    return 0
  fi
  printf '  %s⚠️  superpowers CLI install failed — install manually inside Claude Code CLI:%s\n' "$Y" "$Z"
  printf '       /plugin install superpowers@claude-plugins-official\n'
  return 1
}
install_superpowers='fn:_install_superpowers'

detect_rtk() {
  have rtk && return 0
  grep -q '"rtk hook"' "$HOME/.claude/settings.json" 2>/dev/null
}
_install_rtk() {
  # Web-only environments (Claude Code on the web) have no SSH agent.
  git config --global url."https://github.com/".insteadOf "git@github.com:" 2>/dev/null || true

  if have brew; then
    brew install rtk 2>/dev/null && rtk init -g 2>/dev/null && return 0
  fi
  if have cargo; then
    printf '  %sInstalling RTK via cargo (may take 2-3 min)…%s\n' "$D" "$Z"
    cargo install --git https://github.com/rtk-ai/rtk 2>/dev/null \
      && rtk init -g 2>/dev/null \
      && printf '  %s✅ RTK installed%s\n' "$G" "$Z" && return 0
  fi
  printf '  %s⚠️  RTK install failed — no brew or cargo. Install manually:%s\n' "$Y" "$Z"
  printf '       curl -fsSL https://rtk.ai/install.sh | sh && rtk init -g\n'
  return 1
}
install_rtk='fn:_install_rtk'

detect_ui_ux_pro_max() {
  { have claude && claude plugin list 2>/dev/null | grep -qi 'ui-ux-pro-max'; } && return 0
  [ -d "$CLAUDE_HOME/plugins/cache/ui-ux-pro-max-skill" ] && return 0
}
_install_ui_ux_pro_max() {
  if ! have claude; then
    printf '  %s⚠️  claude CLI not found — install manually inside Claude Code:%s\n' "$Y" "$Z"
    printf '       /plugin marketplace add nextlevelbuilder/ui-ux-pro-max-skill\n'
    printf '       /plugin install ui-ux-pro-max@ui-ux-pro-max-skill\n'
    return 1
  fi
  claude plugin marketplace add nextlevelbuilder/ui-ux-pro-max-skill 2>/dev/null || true
  if claude plugin install ui-ux-pro-max@ui-ux-pro-max-skill 2>/dev/null; then
    printf '  %s✅ ui-ux-pro-max installed%s\n' "$G" "$Z"
    return 0
  fi
  printf '  %s⚠️  ui-ux-pro-max install failed — install manually inside Claude Code:%s\n' "$Y" "$Z"
  printf '       /plugin marketplace add nextlevelbuilder/ui-ux-pro-max-skill\n'
  printf '       /plugin install ui-ux-pro-max@ui-ux-pro-max-skill\n'
  return 1
}
install_ui_ux_pro_max='fn:_install_ui_ux_pro_max'

detect_frontend_design() {
  [ -d "$CLAUDE_HOME/skills/frontend-design" ] && return 0
  { have claude && claude plugin list 2>/dev/null | grep -qi 'example-skills\|anthropic-agent-skills'; }
}
install_frontend_design='# DEPRECATED — use ui-ux-pro-max instead (see external-skills/frontend-design/README.md)'

detect_claude_code_workflows() {
  ls "$PROJECT_ROOT"/.claude/agents/*code-review* >/dev/null 2>&1 \
    || ls "$PROJECT_ROOT"/.claude/agents/*design-review* >/dev/null 2>&1 \
    || ls "$PROJECT_ROOT"/.claude/commands/design-review* >/dev/null 2>&1
}
install_claude_code_workflows='# manual copy — see external-skills/claude-code-workflows/activation.md'

detect_security_review() {
  [ -f "$PROJECT_ROOT/.claude/commands/security-review.md" ] && return 0
  grep -rqs 'security-review-nemotron\|Nemotron_api_key\|nemotron_review_code' "$PROJECT_ROOT/.github/workflows" 2>/dev/null
}
_install_security_review() {
  local target="$PROJECT_ROOT"
  # 1. Create GitHub Actions workflow (Nemotron — never Anthropic API).
  mkdir -p "$target/.github/workflows"
  cat > "$target/.github/workflows/security-review-nemotron.yml" << 'WORKFLOW'
name: Security Review — Nemotron

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
      - uses: actions/checkout@v4
        with:
          fetch-depth: 2
      - name: Run Nemotron Security Review
        env:
          Nemotron_api_key: ${{ secrets.Nemotron_api_key }}
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          pip install openai --quiet
          python3 -c "
import os, sys, subprocess
api_key = os.environ.get('Nemotron_api_key') or os.environ.get('NVIDIA_API_KEY')
if not api_key:
    print('Nemotron_api_key not set — skipping CI security review. Run /security-review in Claude Code session instead.')
    sys.exit(0)
from openai import OpenAI
diff = subprocess.check_output(['git', 'diff', 'HEAD~1', 'HEAD'], text=True)
client = OpenAI(base_url='https://integrate.api.nvidia.com/v1', api_key=api_key)
resp = client.chat.completions.create(
    model='nvidia/llama-3.1-nemotron-ultra-253b-v1',
    messages=[{'role':'system','content':'You are a security code reviewer. Analyze the diff for OWASP Top 10, injection, auth gaps, secrets. Rate findings CRITICAL/HIGH/MEDIUM/LOW/INFO. End with go/no-go.'},
              {'role':'user','content':f'Review this diff:\n{diff[:12000]}'}],
    max_tokens=2048
)
print(resp.choices[0].message.content)
"
WORKFLOW
  printf '  %s✅ created .github/workflows/security-review-nemotron.yml%s\n' "$G" "$Z"
  # 2. Create /security-review slash command.
  mkdir -p "$target/.claude/commands"
  cat > "$target/.claude/commands/security-review.md" << 'CMD'
---
description: Run a security review of the pending changes on the current branch
---

Run a security review on all pending changes in the current branch.

**Routing (in order):**
1. If `mcp__nemotron__nemotron_review_code` is available → use it (primary path).
2. Otherwise → run the review inline using the current Claude Code session.
Never use the Anthropic API or CLAUDE_API_KEY for security review.

Steps:
1. Identify all changed files since the branch diverged from main.
2. For each changed file, check for: injection vulnerabilities, authentication/authorization
   gaps, insecure data handling, secrets or credentials in code, unsafe dependencies,
   broken access control, OWASP Top 10 issues relevant to the change.
3. Report findings grouped by severity (CRITICAL / HIGH / MEDIUM / LOW / INFO).
4. For each finding: file path + line range, description, recommendation.
5. End with a go/no-go recommendation for merging.

Focus on actual security impact, not style. A finding without a concrete attack vector
should be INFO at most.
CMD
  printf '  %s✅ created .claude/commands/security-review.md%s\n' "$G" "$Z"
  if [ -n "${Nemotron_api_key:-}" ]; then
    printf '  %s✅ Nemotron_api_key already set — CI workflow will use it automatically%s\n' "$G" "$Z"
  else
    printf '  %s⚠️  ACTION REQUIRED: add Nemotron_api_key secret to GitHub repo%s\n' "$Y" "$Z"
    printf '       Settings → Secrets and variables → Actions → New repository secret\n'
    printf '       Name: Nemotron_api_key   Value: nvapi-...\n'
    printf '       Get key at: build.nvidia.com\n'
  fi
}
install_security_review='fn:_install_security_review'

detect_claude_mem() {
  have claude-mem && return 0
  [ -d "$HOME/.claude-mem" ] && return 0
  port_open 37777
}
install_claude_mem='npx claude-mem install'

detect_gstack() {
  [ -d "$CLAUDE_HOME/skills/gstack" ]
}
install_gstack='git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack && cd ~/.claude/skills/gstack && ./setup'

detect_graphify() {
  have graphify && return 0
  [ -f "$PROJECT_ROOT/graphify-out/graph.json" ]
}
install_graphify='uv tool install graphifyy && graphify install'

detect_nemotron() {
  # Present if .mcp.json registers the server AND the API key is set
  { [ -f "$PROJECT_ROOT/.mcp.json" ] && grep -q '"nemotron"' "$PROJECT_ROOT/.mcp.json"; } && return 0
  # Also present if just the API key exists (server can be registered separately)
  [ -n "${Nemotron_api_key:-}" ] && [ -f "$PROJECT_ROOT/scripts/nemotron-mcp-server.py" ]
}
install_nemotron='# Register with: claude mcp add --scope project nemotron -- uv run scripts/nemotron-mcp-server.py  |  Requires Nemotron_api_key Claude Code secret — see external-skills/nemotron/activation.md'

SKILLS="
superpowers|2|detect_superpowers|install_superpowers|default
security-review|2|detect_security_review|install_security_review|default
graphify|2|detect_graphify|install_graphify|default
rtk|2|detect_rtk|install_rtk|default
claude-mem|2|detect_claude_mem|install_claude_mem|default
nemotron|1|detect_nemotron|install_nemotron|conditional
ui-ux-pro-max|2|detect_ui_ux_pro_max|install_ui_ux_pro_max|conditional
frontend-design|0|detect_frontend_design|install_frontend_design|conditional
claude-code-workflows|1|detect_claude_code_workflows|install_claude_code_workflows|conditional
gstack|1|detect_gstack|install_gstack|opt-in
"

# ---- run -------------------------------------------------------------------
present=0; missing=0; skipped=0
declare -a MISSING_NAMES MISSING_CMDS

[ "$JSON" -eq 1 ] && printf '{"skills":['
first=1

[ "$JSON" -eq 0 ] && {
  printf '%s\n' "${B}Engineering OS — Skill Bootstrap${Z}"
  printf '%s\n' "${D}project: $PROJECT_ROOT   |   claude home: $CLAUDE_HOME${Z}"
  [ -n "$PROFILE" ] && printf '%s\n' "${D}profile filter: $PROFILE${Z}"
  printf '%s\n\n' "${D}policy: core/skill-orchestration-policy.md${Z}"
}

while IFS='|' read -r name level detect installvar profile; do
  [ -z "$name" ] && continue
  [ "$level" -lt "$MIN_LEVEL" ] && continue
  [ -n "$PROFILE" ] && [ "$profile" != "$PROFILE" ] && continue

  if "$detect" 2>/dev/null; then
    status="present"; present=$((present+1))
    [ "$JSON" -eq 0 ] && printf '  %s✅ %-24s%s L%s %-11s %sdetected%s\n' "$G" "$name" "$Z" "$level" "$profile" "$D" "$Z"
  else
    status="missing"; missing=$((missing+1))
    cmd="${!installvar}"
    MISSING_NAMES+=("$name"); MISSING_CMDS+=("$cmd")
    if [ "$JSON" -eq 0 ]; then
      printf '  %s⚠️  %-24s%s L%s %-11s %snot detected%s\n' "$Y" "$name" "$Z" "$level" "$profile" "$Y" "$Z"
      printf '       %sinstall:%s %s\n' "$D" "$Z" "$cmd"
    fi
  fi

  if [ "$JSON" -eq 1 ]; then
    [ $first -eq 0 ] && printf ','
    first=0
    printf '{"name":"%s","level":%s,"profile":"%s","status":"%s"}' "$name" "$level" "$profile" "$status"
  fi
done <<EOF
$SKILLS
EOF

[ "$JSON" -eq 1 ] && { printf ']}\n'; exit 0; }

printf '\n%s\n' "${B}Summary:${Z} ${G}$present present${Z}, ${Y}$missing missing${Z} (level >= $MIN_LEVEL${PROFILE:+, profile=$PROFILE})"

if [ "$missing" -eq 0 ]; then
  printf '%s\n' "${G}All required skills detected.${Z}"
  exit 0
fi

# ---- optional install ------------------------------------------------------
if [ "$INSTALL" -eq 0 ]; then
  printf '\n%s\n' "${D}Re-run with --install to install missing skills.${Z}"
  printf '%s\n' "${D}Add --yes to skip all confirmation prompts (auto-mode).${Z}"
  printf '%s\n' "${D}Tip: --profile default checks only the skills every standard project needs.${Z}"
  exit 1
fi

if [ "$YES" -eq 1 ]; then
  printf '\n%s\n' "${B}Auto-installing missing skills${Z} ${D}(--yes: no prompts)${Z}"
else
  printf '\n%s\n' "${B}--install requested.${Z} Installing external skills mutates this environment."
fi

i=0
for name in "${MISSING_NAMES[@]}"; do
  cmd="${MISSING_CMDS[$i]}"; i=$((i+1))
  case "$cmd" in
    '#'*)
      # Permanent manual-only (legacy) — extract note after '# '
      note="${cmd#\# }"
      printf '  %s⚠️  %-20s%s manual action required:\n       %s%s%s\n' "$Y" "$name" "$Z" "$D" "$note" "$Z"
      skipped=$((skipped+1))
      continue
      ;;
  esac
  printf '\n  %s%s%s\n' "$B" "$name" "$Z"
  case "$cmd" in fn:*)
    printf '  run: (function %s)\n' "${cmd#fn:}" ;;
  *)
    printf '  run: %s\n' "$cmd" ;;
  esac
  if [ "$YES" -eq 1 ]; then
    ans="y"
  else
    printf '  proceed? [y/N] '
    read -r ans </dev/tty 2>/dev/null || ans="n"
  fi
  case "$ans" in
    y|Y)
      case "$cmd" in
        fn:*) "${cmd#fn:}" || { printf '  %s❌ install failed for %s%s\n' "$R" "$name" "$Z"; skipped=$((skipped+1)); } ;;
        *)    sh -c "$cmd" && printf '  %s✅ installed%s\n' "$G" "$Z" || printf '  %s❌ install failed for %s — check manually%s\n' "$R" "$name" "$Z" ;;
      esac
      ;;
    *) printf '  %sskipped%s\n' "$D" "$Z"; skipped=$((skipped+1)) ;;
  esac
done

printf '\n%sdone — %s skipped/manual.%s\n' "$D" "$skipped" "$Z"
exit 1

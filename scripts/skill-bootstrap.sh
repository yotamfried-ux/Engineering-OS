#!/usr/bin/env bash
#
# skill-bootstrap.sh — verify that Engineering OS external skills and support
# engines are present in the current project/environment, and report what is
# missing.
#
# Skills are workflow capabilities governed by core/skill-orchestration-policy.md
# and external-skills/README.md. Engines are support runtimes/backends governed
# by external-systems/.

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
      sed -n '2,36p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
  shift
done

if [ -t 1 ] && [ "$JSON" -eq 0 ]; then
  G=$'\033[32m'; Y=$'\033[33m'; D=$'\033[2m'; B=$'\033[1m'; R=$'\033[31m'; Z=$'\033[0m'
else
  G=""; Y=""; D=""; B=""; R=""; Z=""
fi

PROJECT_ROOT="$(pwd)"
CLAUDE_HOME="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
EOS_HOME="${ENGINEERING_OS_HOME:-$(cd "$(dirname "$0")/.." 2>/dev/null && pwd || echo "$HOME/.engineering-os")}"

have()      { command -v "$1" >/dev/null 2>&1; }
port_open() { (exec 3<>"/dev/tcp/127.0.0.1/$1") >/dev/null 2>&1 && exec 3>&- 2>/dev/null; }

# ---- skills -----------------------------------------------------------------
# Format: name|level|detect_fn|install_var|profile

detect_superpowers() {
  { have claude && claude plugin list 2>/dev/null | grep -qi superpowers; } && return 0
  [ -d "$CLAUDE_HOME/plugins/cache/superpowers-marketplace/superpowers" ] && return 0
  ls "$CLAUDE_HOME"/plugins/cache/*superpowers* >/dev/null 2>&1 && return 0
  [ -f "$PROJECT_ROOT/.claude/commands/superpowers-brainstorm.md" ]
}
_install_superpowers_slash_commands() {
  local dst="$PROJECT_ROOT/.claude/commands"
  local src="$EOS_HOME/.claude/commands"
  [ -d "$src" ] || return 1
  mkdir -p "$dst"
  local installed=0
  for cmd in superpowers-brainstorm.md superpowers-verify.md superpowers-plan.md; do
    [ -f "$src/$cmd" ] && cp "$src/$cmd" "$dst/$cmd" && installed=$((installed+1))
  done
  [ "$installed" -gt 0 ] || return 1
  printf '  %s✅ superpowers slash commands installed%s\n' "$G" "$Z"
  return 0
}
_install_superpowers() {
  git config --global url."https://github.com/".insteadOf "git@github.com:" 2>/dev/null || true
  if have claude; then
    claude plugin marketplace add obra/superpowers-marketplace 2>/dev/null || true
    claude plugin install superpowers@superpowers-marketplace 2>/dev/null && return 0
  fi
  _install_superpowers_slash_commands
}
install_superpowers='fn:_install_superpowers'

detect_rtk() {
  have rtk && return 0
  grep -q '"rtk hook"' "$HOME/.claude/settings.json" 2>/dev/null
}
_install_rtk() {
  git config --global url."https://github.com/".insteadOf "git@github.com:" 2>/dev/null || true
  if have brew; then
    brew install rtk 2>/dev/null && rtk init -g 2>/dev/null && return 0
  fi
  if have cargo; then
    cargo install --git https://github.com/rtk-ai/rtk 2>/dev/null && rtk init -g 2>/dev/null && return 0
  fi
  printf '  %s⚠️  RTK install failed — install manually: curl -fsSL https://rtk.ai/install.sh | sh && rtk init -g%s\n' "$Y" "$Z"
  return 1
}
install_rtk='fn:_install_rtk'

detect_ui_ux_pro_max() {
  { have claude && claude plugin list 2>/dev/null | grep -qi 'ui-ux-pro-max'; } && return 0
  [ -d "$CLAUDE_HOME/plugins/cache/ui-ux-pro-max-skill" ]
}
_install_ui_ux_pro_max() {
  have claude || return 1
  claude plugin marketplace add nextlevelbuilder/ui-ux-pro-max-skill 2>/dev/null || true
  claude plugin install ui-ux-pro-max@ui-ux-pro-max-skill 2>/dev/null
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
  mkdir -p "$target/.github/workflows" "$target/.claude/commands"
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
      - name: Run Nemotron Security Review
        env:
          Nemotron_api_key: ${{ secrets.Nemotron_api_key }}
        run: |
          echo "Run /security-review in Claude Code when Nemotron_api_key is unavailable."
WORKFLOW
  cat > "$target/.claude/commands/security-review.md" << 'CMD'
---
description: Run a mandatory security review of the pending changes
---

Run `/security-review` on all pending changes. The gate may use Nemotron as its engine, but a raw `nemotron_review_code` call is first-pass review only.
CMD
}
install_security_review='fn:_install_security_review'

detect_claude_mem() {
  have claude-mem && return 0
  [ -d "$HOME/.claude-mem" ] && return 0
  port_open 37777 && return 0
  npm list -g claude-mem >/dev/null 2>&1
}
_install_claude_mem() {
  if have npm && npm install -g claude-mem --quiet 2>/dev/null && have claude-mem; then
    claude-mem install 2>/dev/null || true
    return 0
  fi
  if have npx; then
    npx --yes claude-mem install 2>/dev/null && return 0
  fi
  return 1
}
install_claude_mem='fn:_install_claude_mem'

detect_gstack() { [ -d "$CLAUDE_HOME/skills/gstack" ]; }
install_gstack='git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack && cd ~/.claude/skills/gstack && ./setup'

detect_graphify() {
  have graphify && return 0
  [ -f "$PROJECT_ROOT/graphify-out/graph.json" ]
}
install_graphify='uv tool install graphifyy && graphify install'

SKILLS="
superpowers|2|detect_superpowers|install_superpowers|default
security-review|2|detect_security_review|install_security_review|default
graphify|2|detect_graphify|install_graphify|default
rtk|2|detect_rtk|install_rtk|default
claude-mem|2|detect_claude_mem|install_claude_mem|default
ui-ux-pro-max|2|detect_ui_ux_pro_max|install_ui_ux_pro_max|conditional
frontend-design|0|detect_frontend_design|install_frontend_design|conditional
claude-code-workflows|1|detect_claude_code_workflows|install_claude_code_workflows|conditional
gstack|1|detect_gstack|install_gstack|opt-in
"

# ---- engines / support runtimes --------------------------------------------

detect_nemotron() {
  { [ -f "$PROJECT_ROOT/.mcp.json" ] && grep -q '"nemotron"' "$PROJECT_ROOT/.mcp.json"; } && return 0
  [ -n "${Nemotron_api_key:-}" ] && { [ -f "$PROJECT_ROOT/scripts/nemotron-mcp-server.py" ] || [ -f "$EOS_HOME/scripts/nemotron-mcp-server.py" ]; }
}
install_nemotron='# Register with: claude mcp add --scope project nemotron -- uv run scripts/nemotron-mcp-server.py  |  Requires Nemotron_api_key Claude Code secret — see external-systems/nvidia-nemotron/activation.md'

ENGINES="
nemotron|1|detect_nemotron|install_nemotron|conditional
"

# ---- run --------------------------------------------------------------------
present=0; missing=0; skipped=0
first=1
declare -a MISSING_NAMES MISSING_CMDS

print_header() {
  [ "$JSON" -eq 0 ] || return 0
  printf '%s\n' "${B}Engineering OS — Skill + Engine Bootstrap${Z}"
  printf '%s\n' "${D}project: $PROJECT_ROOT   |   claude home: $CLAUDE_HOME${Z}"
  [ -n "$PROFILE" ] && printf '%s\n' "${D}profile filter: $PROFILE${Z}"
  printf '%s\n\n' "${D}skills: external-skills/README.md | engines: external-systems/${Z}"
}

process_entry() {
  local group="$1" name="$2" level="$3" detect="$4" installvar="$5" profile="$6" status cmd
  [ -z "$name" ] && return 0
  [ "$level" -lt "$MIN_LEVEL" ] && return 0
  [ -n "$PROFILE" ] && [ "$profile" != "$PROFILE" ] && return 0

  if "$detect" 2>/dev/null; then
    status="present"; present=$((present+1))
    [ "$JSON" -eq 0 ] && printf '  %s✅ %-24s%s %-7s L%s %-11s %sdetected%s\n' "$G" "$name" "$Z" "$group" "$level" "$profile" "$D" "$Z"
  else
    status="missing"; missing=$((missing+1))
    cmd="${!installvar}"
    MISSING_NAMES+=("$name"); MISSING_CMDS+=("$cmd")
    if [ "$JSON" -eq 0 ]; then
      printf '  %s⚠️  %-24s%s %-7s L%s %-11s %snot detected%s\n' "$Y" "$name" "$Z" "$group" "$level" "$profile" "$Y" "$Z"
      printf '       %sinstall:%s %s\n' "$D" "$Z" "$cmd"
    fi
  fi

  if [ "$JSON" -eq 1 ]; then
    [ $first -eq 0 ] && printf ','
    first=0
    printf '{"name":"%s","kind":"%s","level":%s,"profile":"%s","status":"%s"}' "$name" "$group" "$level" "$profile" "$status"
  fi
}

print_header
[ "$JSON" -eq 1 ] && printf '{"capabilities":['

while IFS='|' read -r name level detect installvar profile; do
  process_entry "skill" "$name" "$level" "$detect" "$installvar" "$profile"
done <<EOF
$SKILLS
EOF

while IFS='|' read -r name level detect installvar profile; do
  process_entry "engine" "$name" "$level" "$detect" "$installvar" "$profile"
done <<EOF
$ENGINES
EOF

[ "$JSON" -eq 1 ] && { printf ']}\n'; exit 0; }

printf '\n%s\n' "${B}Summary:${Z} ${G}$present present${Z}, ${Y}$missing missing${Z} (level >= $MIN_LEVEL${PROFILE:+, profile=$PROFILE})"

if [ "$missing" -eq 0 ]; then
  printf '%s\n' "${G}All required capabilities detected.${Z}"
  exit 0
fi

if [ "$INSTALL" -eq 0 ]; then
  printf '\n%s\n' "${D}Re-run with --install to install missing installable skills. Engine entries may require connector/secret activation.${Z}"
  printf '%s\n' "${D}Add --yes to skip all confirmation prompts (auto-mode).${Z}"
  exit 1
fi

if [ "$YES" -eq 1 ]; then
  printf '\n%s\n' "${B}Auto-installing missing installable skills${Z} ${D}(--yes: no prompts)${Z}"
else
  printf '\n%s\n' "${B}--install requested.${Z} Installing external capabilities mutates this environment."
fi

i=0
for name in "${MISSING_NAMES[@]}"; do
  cmd="${MISSING_CMDS[$i]}"; i=$((i+1))
  case "$cmd" in
    '#'* )
      note="${cmd#\# }"
      printf '  %s⚠️  %-20s%s manual action required:\n       %s%s%s\n' "$Y" "$name" "$Z" "$D" "$note" "$Z"
      skipped=$((skipped+1))
      continue ;;
  esac
  printf '\n  %s%s%s\n' "$B" "$name" "$Z"
  case "$cmd" in fn:*) printf '  run: (function %s)\n' "${cmd#fn:}" ;; *) printf '  run: %s\n' "$cmd" ;; esac
  if [ "$YES" -eq 1 ]; then ans="y"; else printf '  proceed? [y/N] '; read -r ans </dev/tty 2>/dev/null || ans="n"; fi
  case "$ans" in
    y|Y)
      case "$cmd" in
        fn:*) "${cmd#fn:}" || { printf '  %s❌ install failed for %s%s\n' "$R" "$name" "$Z"; skipped=$((skipped+1)); } ;;
        *) sh -c "$cmd" && printf '  %s✅ installed%s\n' "$G" "$Z" || { printf '  %s❌ install failed for %s%s\n' "$R" "$name" "$Z"; skipped=$((skipped+1)); } ;;
      esac ;;
    *) printf '  %sskipped%s\n' "$D" "$Z"; skipped=$((skipped+1)) ;;
  esac
done

printf '\n%sdone — %s skipped/manual.%s\n' "$D" "$skipped" "$Z"
exit 1

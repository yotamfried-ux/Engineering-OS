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
# skills whose install commands can run unattended (graphify, claude-mem).
# Skills that require an interactive CLI command or manual steps (superpowers,
# security-review, claude-code-workflows) are always reported as "manual" and
# never auto-installed regardless of flags.
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

# ---- skill table -----------------------------------------------------------
# Each skill is one line: name|level|detect_fn|install_var|profile
# detect_fn returns 0 = present, 1 = missing.

detect_superpowers() {
  { have claude && claude plugin list 2>/dev/null | grep -qi superpowers; } && return 0
  [ -d "$CLAUDE_HOME/skills/superpowers" ] || ls "$CLAUDE_HOME"/plugins/*superpowers* >/dev/null 2>&1
}
install_superpowers='# MANUAL — inside Claude Code CLI run: /plugin install superpowers@claude-plugins-official'

detect_frontend_design() {
  [ -d "$CLAUDE_HOME/skills/frontend-design" ] && return 0
  { have claude && claude plugin list 2>/dev/null | grep -qi 'example-skills\|anthropic-agent-skills'; }
}
install_frontend_design='claude /plugin marketplace add anthropics/skills && claude /plugin install example-skills@anthropic-agent-skills'

detect_claude_code_workflows() {
  ls "$PROJECT_ROOT"/.claude/agents/*code-review* >/dev/null 2>&1 \
    || ls "$PROJECT_ROOT"/.claude/agents/*design-review* >/dev/null 2>&1 \
    || ls "$PROJECT_ROOT"/.claude/commands/design-review* >/dev/null 2>&1
}
install_claude_code_workflows='# manual copy — see external-skills/claude-code-workflows/activation.md'

detect_security_review() {
  [ -f "$PROJECT_ROOT/.claude/commands/security-review.md" ] && return 0
  grep -rqs 'claude-code-security-review' "$PROJECT_ROOT/.github/workflows" 2>/dev/null
}
install_security_review='# add anthropics/claude-code-security-review@main to .github/workflows — see activation.md'

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

SKILLS="
superpowers|2|detect_superpowers|install_superpowers|default
security-review|2|detect_security_review|install_security_review|default
graphify|2|detect_graphify|install_graphify|default
claude-mem|2|detect_claude_mem|install_claude_mem|default
frontend-design|2|detect_frontend_design|install_frontend_design|conditional
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
      # Manual-only skill — extract the human-readable note after '# '
      note="${cmd#\# }"
      printf '  %s⚠️  %-20s%s manual action required:\n       %s%s%s\n' "$Y" "$name" "$Z" "$D" "$note" "$Z"
      skipped=$((skipped+1))
      continue
      ;;
  esac
  printf '\n  %s%s%s\n  run: %s\n' "$B" "$name" "$Z" "$cmd"
  if [ "$YES" -eq 1 ]; then
    ans="y"
  else
    printf '  proceed? [y/N] '
    read -r ans </dev/tty 2>/dev/null || ans="n"
  fi
  case "$ans" in
    y|Y) sh -c "$cmd" && printf '  %s✅ installed%s\n' "$G" "$Z" || printf '  %s❌ install failed for %s — check manually%s\n' "$R" "$name" "$Z" ;;
    *)   printf '  %sskipped%s\n' "$D" "$Z"; skipped=$((skipped+1)) ;;
  esac
done

printf '\n%sdone — %s skipped/manual.%s\n' "$D" "$skipped" "$Z"
exit 1

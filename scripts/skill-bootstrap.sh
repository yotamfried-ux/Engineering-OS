#!/usr/bin/env bash
#
# skill-bootstrap.sh — verify that the Engineering OS external skills are present
# in the current project / environment, and report what is missing.
#
# Part of the Skill Orchestration Framework.
# Governing policy: core/skill-orchestration-policy.md  (<bootstrap>)
# Skill registry:   external-skills/README.md
#
# DESIGN: detect-and-report by default. Installing external skills mutates the
# environment (gstack runs ./setup, claude-mem spawns a worker on :37777,
# graphify needs uv), which per core/git-policy.md <safety> requires explicit
# human approval. So:
#   * default            -> scan, report ✅ / ⚠️ / ➖, print exact install commands
#   * --install          -> additionally run installs, asking before each one
#   * --level N          -> only consider skills at LEVEL >= N (e.g. --level 2)
#   * --json             -> machine-readable status output
#
# Detection is best-effort (skills live in global/user config or the project
# tree). A ⚠️ means "not detected here" — confirm manually before assuming absent.

set -u

INSTALL=0
MIN_LEVEL=0
JSON=0

while [ $# -gt 0 ]; do
  case "$1" in
    --install) INSTALL=1 ;;
    --level)   shift; MIN_LEVEL="${1:-0}" ;;
    --json)    JSON=1 ;;
    -h|--help)
      sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
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
# Each skill is one line: name|level|detect_fn|install_hint
# detect_fn returns 0 = present, 1 = missing.

detect_superpowers() {
  { have claude && claude plugin list 2>/dev/null | grep -qi superpowers; } && return 0
  [ -d "$CLAUDE_HOME/skills/superpowers" ] || ls "$CLAUDE_HOME"/plugins/*superpowers* >/dev/null 2>&1
}
install_superpowers='claude /plugin install superpowers@claude-plugins-official'

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
superpowers|2|detect_superpowers|install_superpowers
frontend-design|2|detect_frontend_design|install_frontend_design
claude-code-workflows|1|detect_claude_code_workflows|install_claude_code_workflows
security-review|2|detect_security_review|install_security_review
claude-mem|2|detect_claude_mem|install_claude_mem
gstack|1|detect_gstack|install_gstack
graphify|1|detect_graphify|install_graphify
"

# ---- run -------------------------------------------------------------------
present=0; missing=0; skipped=0
declare -a MISSING_NAMES MISSING_CMDS

[ "$JSON" -eq 1 ] && printf '{"skills":['
first=1

[ "$JSON" -eq 0 ] && {
  printf '%s\n' "${B}Engineering OS — Skill Bootstrap${Z}"
  printf '%s\n' "${D}project: $PROJECT_ROOT   |   claude home: $CLAUDE_HOME${Z}"
  printf '%s\n\n' "${D}policy: core/skill-orchestration-policy.md${Z}"
}

while IFS='|' read -r name level detect installvar; do
  [ -z "$name" ] && continue
  if [ "$level" -lt "$MIN_LEVEL" ]; then
    continue
  fi

  if "$detect" 2>/dev/null; then
    status="present"; present=$((present+1))
    [ "$JSON" -eq 0 ] && printf '  %s✅ %-24s%s L%s  %sdetected%s\n' "$G" "$name" "$Z" "$level" "$D" "$Z"
  else
    status="missing"; missing=$((missing+1))
    cmd="${!installvar}"
    MISSING_NAMES+=("$name"); MISSING_CMDS+=("$cmd")
    if [ "$JSON" -eq 0 ]; then
      printf '  %s⚠️  %-24s%s L%s  %snot detected%s\n' "$Y" "$name" "$Z" "$level" "$Y" "$Z"
      printf '       %sinstall:%s %s\n' "$D" "$Z" "$cmd"
    fi
  fi

  if [ "$JSON" -eq 1 ]; then
    [ $first -eq 0 ] && printf ','
    first=0
    printf '{"name":"%s","level":%s,"status":"%s"}' "$name" "$level" "$status"
  fi
done <<EOF
$SKILLS
EOF

[ "$JSON" -eq 1 ] && { printf ']}\n'; exit 0; }

printf '\n%s\n' "${B}Summary:${Z} ${G}$present present${Z}, ${Y}$missing missing${Z} (level >= $MIN_LEVEL)"

if [ "$missing" -eq 0 ]; then
  printf '%s\n' "${G}All required skills detected.${Z}"
  exit 0
fi

# ---- optional install ------------------------------------------------------
if [ "$INSTALL" -eq 0 ]; then
  printf '\n%s\n' "${D}Re-run with --install to install missing skills (you will be asked before each).${Z}"
  exit 1
fi

printf '\n%s\n' "${B}--install requested.${Z} Installing external skills mutates this environment."
i=0
for name in "${MISSING_NAMES[@]}"; do
  cmd="${MISSING_CMDS[$i]}"; i=$((i+1))
  case "$cmd" in
    '#'*) printf '  %s➖ %s%s needs a manual step — see external-skills/%s/activation.md\n' "$D" "$name" "$Z" "$name"; skipped=$((skipped+1)); continue ;;
  esac
  printf '\n  %s%s%s\n  run: %s\n' "$B" "$name" "$Z" "$cmd"
  printf '  proceed? [y/N] '
  read -r ans </dev/tty 2>/dev/null || ans="n"
  case "$ans" in
    y|Y) sh -c "$cmd" || printf '  %sinstall failed for %s%s\n' "$R" "$name" "$Z" ;;
    *)   printf '  %sskipped%s\n' "$D" "$Z"; skipped=$((skipped+1)) ;;
  esac
done

printf '\n%sdone — %s skipped/manual.%s\n' "$D" "$skipped" "$Z"
exit 1

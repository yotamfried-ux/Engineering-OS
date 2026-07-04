#!/usr/bin/env bash
# enforce-bash-entry.sh — block work-like Bash commands before a task plan exists.
#
# Purpose:
#   CLAUDE.md defines the workflow entry rule, but Bash commands can otherwise run
#   before Write/Edit gates fire. This hook blocks commands that clearly begin
#   implementation, API validation, builds, tests, or app execution until a valid
#   .claude/plans/*.md exists.
#
# Bypass:
#   EOS_BYPASS_ENTRY=1, only with explicit human authorization.

set -u
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/evidence.sh
. "$SCRIPT_DIR/lib/evidence.sh" 2>/dev/null || true

log() { printf 'INFO_FOR_AGENT: enforce-bash-entry: %s\n' "$*" >&2; }

bypass_active EOS_BYPASS_ENTRY && { log "bypassed via EOS_BYPASS_ENTRY"; exit 0; }
bypass_active EOS_BYPASS_WORKFLOW && { log "bypassed via EOS_BYPASS_WORKFLOW"; exit 0; }

INPUT="$(cat 2>/dev/null || true)"
CMD="$(printf '%s' "$INPUT" | python3 -c '
import json, sys
try:
    d=json.load(sys.stdin)
    t=d.get("tool_input", d)
    print(t.get("command", "") or "")
except Exception:
    print("")
' 2>/dev/null || true)"

[ -z "$CMD" ] && { log "no bash command found in hook payload; allowing"; exit 0; }

newest_plan() { ls -t .claude/plans/*.md 2>/dev/null | head -1 || true; }

# detect_plan_scope/plan_missing_sections mirror enforce-workflow.sh (core/workflow.md
# <evidence_backed_planning>) so a work-like Bash command is held to the same Plan
# Scope contract as Write/Edit — kept as a local copy rather than sourced, matching
# this file's existing standalone-hook convention.
detect_plan_scope() {
  local pf="$1"
  local line value
  line="$(grep -iE '^[[:space:]]*[-*]?[[:space:]]*(plan[[:space:]]*scope|סוג[[:space:]]*ה?תוכנית)[[:space:]]*:' "$pf" 2>/dev/null | head -1)"
  [ -z "$line" ] && { printf 'missing'; return; }
  value="${line#*:}"
  case "$value" in
    *[Pp]roject*|*פרויקט*) printf 'project'; return ;;
    *[Ss]tandard*|*רגיל*|*סטנדרטי*) printf 'standard'; return ;;
    *[Ss]imple*|*פשוט*) printf 'simple'; return ;;
  esac
  printf 'invalid'
}

plan_missing_sections() {
  local pf="$1" scope="$2" missing=""

  grep -qiE 'מטרה|goal|requirements|דרישות'        "$pf" || missing="${missing}Goal/מטרה "
  grep -qiE 'תכנון|\bplan\b|steps|שלבים'            "$pf" || missing="${missing}Plan/תכנון "
  grep -qiE 'DoD|Definition of Done|תנאי סיום'      "$pf" || missing="${missing}DoD/תנאי-סיום "
  grep -qiE 'brainstorm|חלופות|alternatives'        "$pf" || missing="${missing}Alternatives/חלופות "

  case "$scope" in
    standard)
      grep -qiE 'Affected Surfaces|משטחים מושפעים|רכיבים מושפעים'         "$pf" || missing="${missing}Affected-Surfaces "
      grep -qiE 'Data/State Impact|Data State Impact|השפעה על דאטה|השפעה על מצב' "$pf" || missing="${missing}Data/State-Impact "
      grep -qiE 'Integration Impact|השפעה על אינטגרציות|השפעה על קונקטורים' "$pf" || missing="${missing}Integration-Impact "
      grep -qiE 'Validation Plan|בדיקות|אימות'                            "$pf" || missing="${missing}Validation-Plan "
      grep -qiE 'Open Questions|שאלות פתוחות'                             "$pf" || missing="${missing}Open-Questions "
      ;;
    project)
      grep -qiE 'Project Type|סוג הפרויקט'                    "$pf" || missing="${missing}Project-Type "
      grep -qiE 'User Goal|מטרת המשתמש|מטרת הפרויקט'          "$pf" || missing="${missing}User-Goal "
      grep -qiE 'Target Users|Target Surfaces|קהל יעד|משטחי יעד' "$pf" || missing="${missing}Target-Users/Surfaces "
      grep -qiE 'Known Requirements|דרישות ידועות'             "$pf" || missing="${missing}Known-Requirements "
      grep -qiE 'MVP Features|פיצ.ר.*MVP|פיצרים'               "$pf" || missing="${missing}MVP-Features "
      grep -qiE 'Non-goals|Non goals|לא בהיקף|מחוץ להיקף'      "$pf" || missing="${missing}Non-goals "
      grep -qiE 'Architecture|ארכיטקטורה'                      "$pf" || missing="${missing}Architecture "
      grep -qiE 'Stack|טכנולוגיות|שפות'                         "$pf" || missing="${missing}Stack "
      grep -qiE 'Data Model|\bState\b|דאטה|מודל נתונים'         "$pf" || missing="${missing}Data-Model/State "
      grep -qiE 'Auth|Roles|הרשאות|הזדהות'                      "$pf" || missing="${missing}Auth/Roles "
      grep -qiE 'Integrations|Connectors|אינטגרציות|קונקטורים' "$pf" || missing="${missing}Integrations/Connectors "
      grep -qiE 'Environment|Deployment|סביבה|פריסה'           "$pf" || missing="${missing}Environment/Deployment "
      grep -qiE 'Evidence Checked|ראיות שנבדקו|מקורות שנבדקו'  "$pf" || missing="${missing}Evidence-Checked "
      grep -qiE 'Open Questions|שאלות פתוחות'                  "$pf" || missing="${missing}Open-Questions "
      grep -qiE 'Validation Plan|בדיקות|אימות'                 "$pf" || missing="${missing}Validation-Plan "
      grep -qiE 'User Approval|אישור משתמש'                    "$pf" || missing="${missing}User-Approval "
      ;;
  esac
  printf '%s' "$missing"
}

# Work-like commands: API checks, runtime execution, build/test/lint/typecheck,
# package manager scripts, docker/infra execution, or direct interpreter execution.
# Important: do NOT allowlist prefix commands before this check. A command like
# `ls && curl ...` must still be blocked because the full command contains curl.
if ! printf '%s' "$CMD" | grep -qiE '(^|[;&|[:space:]])(curl|wget|http|python|python3|node|npx|npm[[:space:]]+run|npm[[:space:]]+test|yarn[[:space:]]+(run|test)|pnpm[[:space:]]+(run|test|exec)|bun[[:space:]]+(run|test)|pytest|ruff|mypy|tsc|next[[:space:]]+(dev|build|start)|vite|vitest|jest|make|mvn|gradle|gradlew|ruby|php|java|dotnet|bash[[:space:]]+-c|sh[[:space:]]+-c|eval|cargo[[:space:]]+(run|test|build)|go[[:space:]]+(run|test|build)|docker|docker-compose|kubectl|terraform|gh[[:space:]]+workflow|vercel|supabase)([[:space:]]|$)'; then
  log "non-work-like command allowed"
  exit 0
fi

log "work-like command detected; validating task plan"
PLAN="$(newest_plan || true)"
if [ -z "$PLAN" ]; then
  echo "ERROR_FOR_AGENT: Engineering OS entry gate — no task plan exists before a work-like Bash command."
  echo "COMMAND: $CMD"
  echo "ACTION: create .claude/plans/<task>.md with Goal/מטרה, Plan/תכנון, DoD/תנאי-סיום, Alternatives/חלופות before API checks, builds, tests, app runs, or implementation commands."
  echo "BYPASS: EOS_BYPASS_ENTRY=1 — only with explicit user authorization in the current conversation."
  exit 1
fi

SCOPE="$(detect_plan_scope "$PLAN")"
case "$SCOPE" in
  simple|standard|project) ;;
  *)
    echo "ERROR_FOR_AGENT: Engineering OS entry gate — newest plan ($(basename "$PLAN")) has no valid 'Plan Scope' field (found: ${SCOPE})."
    echo "ACTION: add 'Plan Scope: simple|standard|project' (or 'סוג התוכנית: פשוט|רגיל|פרויקט') per workflow.md <evidence_backed_planning> before API checks, builds, tests, app runs, or implementation commands."
    echo "BYPASS: EOS_BYPASS_ENTRY=1 — only with explicit user authorization in the current conversation."
    exit 1
    ;;
esac

MISSING="$(plan_missing_sections "$PLAN" "$SCOPE")"
if [ -n "$MISSING" ]; then
  echo "ERROR_FOR_AGENT: Engineering OS entry gate — newest plan ($(basename "$PLAN"), Plan Scope: ${SCOPE}) is missing sections: ${MISSING}"
  echo "ACTION: complete the plan before API checks, builds, tests, app runs, or implementation commands."
  echo "BYPASS: EOS_BYPASS_ENTRY=1 — only with explicit user authorization in the current conversation."
  exit 1
fi

log "valid task plan found: $PLAN"
exit 0

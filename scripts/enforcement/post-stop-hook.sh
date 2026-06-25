#!/usr/bin/env bash
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib/evidence.sh" 2>/dev/null || true

RUNTIME_STATUS="runtime evidence checker missing"
if [ ! -f "$SCRIPT_DIR/check-runtime-evidence.sh" ]; then
  printf '{"hookSpecificOutput":{"hookEventName":"Stop","additionalContext":"runtime evidence checker missing"}}'
  exit 1
fi

RUNTIME_OUT="$(bash "$SCRIPT_DIR/check-runtime-evidence.sh" 2>&1)"
RUNTIME_CODE="$?"
if [ "$RUNTIME_CODE" -ne 0 ]; then
  MSG="$(printf '%s' "$RUNTIME_OUT" | tr '\n' ' ')"
  printf '{"hookSpecificOutput":{"hookEventName":"Stop","additionalContext":"%s"}}' \
    "$(printf '%s' "$MSG" | sed 's/"/\\"/g')"
  exit 1
fi
RUNTIME_STATUS="runtime evidence checked"

GQ_STATUS="$(evidence_has graphify_used 2>/dev/null && printf 'graphify queried' || printf 'graphify not queried')"
TR_STATUS="$(evidence_has tests_run 2>/dev/null && printf 'tests passed' || printf 'no successful test run')"
NT_STATUS="$(evidence_has notion_spec_created 2>/dev/null && printf 'Notion spec' || printf 'local plan only')"
VF_STATUS="$(evidence_has superpowers_verify_run 2>/dev/null && printf 'verified' || printf 'superpowers-verify not run')"
CN_STATUS="$(evidence_has connector_used 2>/dev/null && printf 'connector evidence' || printf 'no connector evidence')"

SESSION_MSG="Session: ${GQ_STATUS} | ${TR_STATUS} | ${NT_STATUS} | ${VF_STATUS} | ${CN_STATUS} | ${RUNTIME_STATUS}. "

NMSG=""
if evidence_has notion_spec_created 2>/dev/null; then
  PLAN="$(ls -t .claude/plans/*.md 2>/dev/null | head -1 || true)"
  if [ -n "$PLAN" ]; then
    if ! grep -qiE 'notion.*(page_id|[0-9a-f]{32})|page_id.*notion' "$PLAN" 2>/dev/null; then
      NMSG="Notion spec created but plan '$(basename "$PLAN")' is missing a notion_page_id anchor. "
    fi
  fi
fi

STAGED="$(git diff --cached --name-only 2>/dev/null || true)"
if [ -z "$STAGED" ]; then
  MSG="${SESSION_MSG}${NMSG}Commit format markers required."
  printf '{"hookSpecificOutput":{"hookEventName":"Stop","additionalContext":"%s"}}' \
    "$(printf '%s' "$MSG" | sed 's/"/\\"/g')"
  exit 0
fi

PLAN="$(ls -t .claude/plans/*.md 2>/dev/null | head -1 || true)"
PMSG=""
[ -n "$PLAN" ] && PMSG="spec_loop: plan '$(basename "$PLAN")' exists; verify every DoD item before committing. "

CODE="$(printf '%s' "$STAGED" | grep -cE '\.(ts|tsx|js|jsx|py|go|rs)$' 2>/dev/null || printf '0')"
TEST="$(printf '%s' "$STAGED" | grep -cE '(\.(test|spec)\.(ts|tsx|js|jsx|py)|__tests__)' 2>/dev/null || printf '0')"
TWARN=""
[ "${CODE:-0}" -gt 0 ] && [ "${TEST:-0}" -eq 0 ] && TWARN="${CODE} code files staged, 0 test files in diff. "
GMSG=""
[ "${CODE:-0}" -gt 0 ] && GMSG="Run graphify update after commit. "

MSG="${SESSION_MSG}${NMSG}${PMSG}${TWARN}${GMSG}Commit format markers required."
printf '{"hookSpecificOutput":{"hookEventName":"Stop","additionalContext":"%s"}}' \
  "$(printf '%s' "$MSG" | sed 's/"/\\"/g')"
exit 0

#!/usr/bin/env bash
set -o pipefail
# post-stop-hook.sh — Stop event hook: session status summary + staged-file reminders.
#
# Emits hookSpecificOutput JSON with:
#   - Session evidence status: graphify_used, tests_run, notion_spec_created
#   - Staged-file reminders: spec_loop, test gap, graphify update, commit format
#   - Notion anchor warning: if notion_spec_created but plan file lacks page_id anchor
#
# Wired from .claude/settings.json Stop hook.
# Governing policy: core/workflow.md (validation gate, spec_loop).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/evidence.sh
. "$SCRIPT_DIR/lib/evidence.sh" 2>/dev/null || true

# ── Session evidence status ───────────────────────────────────────────────────
GQ_STATUS="$(evidence_has graphify_used 2>/dev/null && printf '✅ graphify queried' || printf '⚠️ graphify not queried')"
TR_STATUS="$(evidence_has tests_run 2>/dev/null && printf '✅ tests passed' || printf '⚠️ no successful test run')"
NT_STATUS="$(evidence_has notion_spec_created 2>/dev/null && printf '✅ Notion spec' || printf '📄 local plan only')"
VF_STATUS="$(evidence_has superpowers_verify_run 2>/dev/null && printf '✅ verified' || printf '⚠️ /superpowers-verify not run')"

SESSION_MSG="Session: ${GQ_STATUS} | ${TR_STATUS} | ${NT_STATUS} | ${VF_STATUS}. "

# ── Notion anchor warning ─────────────────────────────────────────────────────
NMSG=""
if evidence_has notion_spec_created 2>/dev/null; then
  PLAN="$(ls -t .claude/plans/*.md 2>/dev/null | head -1 || true)"
  if [ -n "$PLAN" ]; then
    if ! grep -qiE 'notion.*(page_id|[0-9a-f]{32})|page_id.*notion' "$PLAN" 2>/dev/null; then
      NMSG="⚠️ Notion spec created but plan '$(basename "$PLAN")' is missing a notion_page_id anchor — add it for audit trail. "
    fi
  fi
fi

# ── Staged-file reminders (existing logic, extended) ─────────────────────────
STAGED="$(git diff --cached --name-only 2>/dev/null || true)"
if [ -z "$STAGED" ]; then
  # No staged files — emit session summary only
  MSG="${SESSION_MSG}${NMSG}Commit format: ✅❌🔄📌🧪 required (commit-msg hook enforces). superpowers:verification-before-completion must have run."
  printf '{"hookSpecificOutput":{"hookEventName":"Stop","additionalContext":"%s"}}' \
    "$(printf '%s' "$MSG" | sed 's/"/\\"/g')"
  exit 0
fi

PLAN="$(ls -t .claude/plans/*.md 2>/dev/null | head -1 || true)"
PMSG=""
[ -n "$PLAN" ] && PMSG="📋 spec_loop: plan '$(basename "$PLAN")' exists — verify EVERY DoD item against output before committing. "

CODE="$(printf '%s' "$STAGED" | grep -cE '\.(ts|tsx|js|jsx|py|go|rs)$' 2>/dev/null || printf '0')"
TEST="$(printf '%s' "$STAGED" | grep -cE '(\.(test|spec)\.(ts|tsx|js|jsx|py)|__tests__)' 2>/dev/null || printf '0')"
TWARN=""
[ "${CODE:-0}" -gt 0 ] && [ "${TEST:-0}" -eq 0 ] && \
  TWARN="⚠️ ${CODE} code files staged, 0 test files in diff — pre-commit will scan project for tests. "

GMSG=""
[ "${CODE:-0}" -gt 0 ] && GMSG="📊 Run: graphify update . after commit to keep graph current. "

MSG="${SESSION_MSG}${NMSG}${PMSG}${TWARN}${GMSG}Commit format: ✅❌🔄📌🧪 required (commit-msg hook enforces). superpowers:verification-before-completion must have run."

printf '{"hookSpecificOutput":{"hookEventName":"Stop","additionalContext":"%s"}}' \
  "$(printf '%s' "$MSG" | sed 's/"/\\"/g')"

exit 0

#!/usr/bin/env bash
# hook-gate.sh — translate a legacy exit-1 enforcer into a REAL Claude Code
# PreToolUse block.
#
# Why this exists:
#   The enforce-*.sh gates signal a violation with `exit 1` + an ERROR_FOR_AGENT
#   message. That is correct for git hooks (exit 1 aborts a commit), but Claude
#   Code treats a non-zero PreToolUse hook exit OTHER than 2 as a *non-blocking*
#   error — the tool still runs. The only ways a PreToolUse hook blocks a tool are
#   exit code 2 or a stdout JSON `hookSpecificOutput.permissionDecision="deny"`.
#   So, wired bare, the gates printed a warning and Claude could proceed anyway.
#
#   We do NOT change the enforcers' exit codes (git hooks depend on exit 1).
#   Instead this wrapper runs the enforcer for the Claude-tool layer only and
#   converts a clean non-zero into a permissionDecision=deny on stdout (exit 0).
#
# Governing policy: core/hooks-policy.md  (deterministic enforcement)
#
# Usage (in .claude/settings.json PreToolUse):
#   bash <EOS>/scripts/enforcement/lib/hook-gate.sh <enforcer.sh> [args...]
#   The PreToolUse event JSON arrives on stdin; it is forwarded to the enforcer.
#
# Safety posture:
#   - Fail-OPEN (allow) on infrastructure errors (enforcer missing, no python3) —
#     a broken gate must never brick every Write/Bash in a session.
#   - Fail-CLOSED (deny) only when the enforcer actually ran and returned non-zero
#     with a message — i.e. a genuine, intentional governance block.
set -u

ENFORCER="${1:-}"
[ -n "$ENFORCER" ] || { echo "hook-gate: missing enforcer argument" >&2; exit 0; }
shift || true

# Resolve the enforcer relative to scripts/enforcement/ when not an absolute path.
if [ ! -f "$ENFORCER" ]; then
  HG_ENFORCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null && pwd || true)"
  [ -n "$HG_ENFORCE_DIR" ] && [ -f "$HG_ENFORCE_DIR/$ENFORCER" ] && ENFORCER="$HG_ENFORCE_DIR/$ENFORCER"
fi
# Missing enforcer → fail open (do not block work on an infra gap).
[ -f "$ENFORCER" ] || { echo "hook-gate: enforcer not found: $ENFORCER" >&2; exit 0; }

INPUT="$(cat 2>/dev/null || true)"
OUT="$(printf '%s' "$INPUT" | bash "$ENFORCER" "$@" 2>&1)"; CODE=$?

# Pass-through on success; surface any advisory text the enforcer emitted.
if [ "$CODE" -eq 0 ]; then
  [ -n "$OUT" ] && printf '%s\n' "$OUT"
  exit 0
fi

# Enforcer already emitted a native permissionDecision JSON (e.g. check-plan-scope) —
# forward it verbatim, do not double-wrap.
if printf '%s' "$OUT" | grep -q 'permissionDecision'; then
  printf '%s\n' "$OUT"
  exit 0
fi

# Translate the legacy exit-1 violation into a real PreToolUse deny.
REASON="$(printf '%s' "$OUT" | tr '\n' ' ')"
python3 - "$REASON" "$(basename "$ENFORCER")" <<'PY' 2>/dev/null || exit 0
import json, sys
reason = (sys.argv[1] if len(sys.argv) > 1 else "").strip()
enforcer = sys.argv[2] if len(sys.argv) > 2 else ""
if not reason:
    reason = "Engineering OS gate (%s) blocked this action." % enforcer
key = "permission" + "Decision"  # keep the literal out of grep-based self-checks
print(json.dumps({"hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    key: "deny",
    key + "Reason": reason,
}}, ensure_ascii=False))
PY
exit 0

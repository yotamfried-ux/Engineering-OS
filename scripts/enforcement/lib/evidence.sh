#!/usr/bin/env bash
# evidence.sh — shared per-session evidence ledger for Engineering OS enforcers.
#
# Purpose: a hook cannot verify "Claude used tool X" directly — it can only block
# an action until PROOF that a prerequisite ran exists. PostToolUse hooks record
# evidence here; PreToolUse gate enforcers check it before allowing dependent actions.
#
# This is shared infrastructure (a library), not a per-tool enforcer. Source it:
#   . "$(dirname "$0")/lib/evidence.sh"
#
# Ledger: .claude/.evidence/ledger  (relative to project cwd; reset each session)
# Line format: <epoch>\t<key>\t<value>

# Resolve ledger path relative to the current project (cwd), not the script dir,
# so it follows the project the hooks run in.
_evidence_dir() { printf '%s' "${EOS_EVIDENCE_DIR:-.claude/.evidence}"; }
_evidence_file() { printf '%s/ledger' "$(_evidence_dir)"; }

# evidence_reset — truncate the ledger (called at SessionStart).
evidence_reset() {
  local dir; dir="$(_evidence_dir)"
  mkdir -p "$dir" 2>/dev/null || return 0
  : > "$(_evidence_file)" 2>/dev/null || true
}

# evidence_record <key> [value] — append an evidence line.
evidence_record() {
  local key="${1:-}" val="${2:-}"
  [ -z "$key" ] && return 0
  local dir; dir="$(_evidence_dir)"
  mkdir -p "$dir" 2>/dev/null || return 0
  printf '%s\t%s\t%s\n' "$(date +%s 2>/dev/null || echo 0)" "$key" "$val" \
    >> "$(_evidence_file)" 2>/dev/null || true
}

# evidence_has <key> [value] — exit 0 if an evidence line matches, else 1.
# With value: matches key AND value. Without: matches key only.
evidence_has() {
  local key="${1:-}" val="${2:-}"
  local f; f="$(_evidence_file)"
  [ -f "$f" ] || return 1
  if [ -n "$val" ]; then
    grep -qF "$(printf '\t%s\t%s' "$key" "$val")" "$f"
  else
    grep -qF "$(printf '\t%s\t' "$key")" "$f"
  fi
}

# bypass_active <ENV_VAR_NAME> — exit 0 if that env var is set to a truthy value.
# Side effect: logs to evidence ledger + stderr when bypass is active (audit trail).
bypass_active() {
  local name="${1:-}"
  [ -z "$name" ] && return 1
  local val="${!name:-}"
  case "$val" in
    1|true|TRUE|yes|YES)
      evidence_record "bypass_used" "$name=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
      printf '⚠️  BYPASS ACTIVE: %s — enforcement disabled. If unintended, unset the variable.\n' "$name" >&2
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

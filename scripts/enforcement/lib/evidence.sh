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
  if ! mkdir -p "$dir" 2>/dev/null; then
    printf 'evidence_reset: WARNING — could not create ledger dir %s\n' "$dir" >&2
    return 1
  fi
  if ! : > "$(_evidence_file)" 2>/dev/null; then
    printf 'evidence_reset: WARNING — could not truncate ledger %s\n' "$(_evidence_file)" >&2
    return 1
  fi
}

# evidence_record <key> [value] — append an evidence line.
# Returns 1 and prints to stderr if the ledger cannot be written (silent failure was
# a systemic bug: gates would pass as if evidence existed when mkdir/write failed).
evidence_record() {
  local key="${1:-}" val="${2:-}"
  [ -z "$key" ] && return 0
  local dir; dir="$(_evidence_dir)"
  if ! mkdir -p "$dir" 2>/dev/null; then
    printf 'evidence_record: WARNING — could not create ledger dir %s (gate may pass without proof)\n' "$dir" >&2
    return 1
  fi
  if ! printf '%s\t%s\t%s\n' "$(date +%s 2>/dev/null || echo 0)" "$key" "$val" \
    >> "$(_evidence_file)" 2>/dev/null; then
    printf 'evidence_record: WARNING — could not write to ledger %s (gate may pass without proof)\n' "$(_evidence_file)" >&2
    return 1
  fi
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

# evidence_get <key> — prints the last value recorded for key (empty if none).
evidence_get() {
  local key="${1:-}"
  local f; f="$(_evidence_file)"
  [ -f "$f" ] || { printf ''; return 1; }
  grep -F "$(printf '\t%s\t' "$key")" "$f" | tail -1 | cut -f3
}

# eos_select_plan [target-hint] — select the active Route Plan deterministically.
# Precedence: (1) EOS_ACTIVE_PLAN when readable; (2) .claude/plans/active.md;
# (3) newest plan whose "Target paths" field matches the target hint;
# (4) newest plan (legacy behavior) when nothing matches or no hint is given.
# Corrective only: a session holding an older matching plan and a newer unrelated
# plan now selects the matching one; with no match, behavior is unchanged.
eos_select_plan() {
  local hint="${1:-}" candidate targets t file prefix newest=""
  if [ -n "${EOS_ACTIVE_PLAN:-}" ] && [ -f "${EOS_ACTIVE_PLAN:-}" ]; then
    printf '%s\n' "$EOS_ACTIVE_PLAN"; return 0
  fi
  if [ -f .claude/plans/active.md ]; then
    printf '%s\n' .claude/plans/active.md; return 0
  fi
  file="$(printf '%s' "$hint" | sed -E 's#^\./##')"
  for candidate in $(ls -t .claude/plans/*.md 2>/dev/null || true); do
    case "$(basename "$candidate")" in README.md|_TEMPLATE.md) continue ;; esac
    [ -n "$newest" ] || newest="$candidate"
    [ -n "$file" ] || continue
    targets="$(awk -F'|' 'NF>1{for(i=1;i<NF;i++){f=tolower($i);gsub(/[*_`]/,"",f);gsub(/^[ \t]+|[ \t]+$/,"",f);if(f ~ /^target paths?$|^target files$|^target scope$/){v=$(i+1);gsub(/^[ \t]+|[ \t]+$/,"",v);print v;exit}}}' "$candidate" 2>/dev/null)"
    [ -n "$targets" ] || continue
    targets_norm="$(printf '%s' "$targets" | tr '[:upper:]' '[:lower:]' | sed -E 's/[[:space:][:punct:]]+$//' | sed -E 's/^[[:space:]]+//')"
    case "$targets_norm" in
      none|n/a|na|not\ required|any) printf '%s\n' "$candidate"; return 0 ;;
    esac
    while IFS= read -r t; do
      [ -n "$t" ] || continue
      prefix="$(printf '%s' "$t" | sed -E 's/<[^>]+>//g; s/`//g; s#^\./##; s#/$##; s/^[-*[:space:]]+//; s/[[:space:]]+$//')"
      [ -n "$prefix" ] || continue
      case "$file" in
        "$prefix"|"$prefix"/*|*/"$prefix"|*/"$prefix"/*) printf '%s\n' "$candidate"; return 0 ;;
      esac
    done <<EOF_TARGETS
$(printf '%s' "$targets" | tr ',;' '\n')
EOF_TARGETS
  done
  [ -n "$newest" ] && printf '%s\n' "$newest"
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

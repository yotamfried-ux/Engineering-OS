#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SESSION_START="$ROOT/scripts/monitoring/eos-telemetry-session-start.sh"
REQUIRE="$ROOT/scripts/monitoring/require-telemetry-session.sh"
PATCHER="$ROOT/scripts/monitoring/patch-settings-telemetry.py"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass() {
  local name="$1"
  shift
  "$@" >/dev/null 2>&1 || { echo "fail: $name"; "$@"; exit 1; }
  echo "ok: $name"
}

blockcase() {
  local name="$1"
  shift
  set +e
  "$@" >/dev/null 2>&1
  local rc=$?
  set -e
  if [ "$rc" -ne 2 ]; then
    echo "fail: $name expected exit 2, got $rc"
    exit 1
  fi
  echo "ok: $name"
}

TARGET="$TMP/target"
mkdir -p "$TARGET/.claude"
git -C "$TARGET" init -q
cp "$ROOT/.claude/settings.json" "$TARGET/.claude/settings.json"

EVENTS="$TARGET/.engineering-os/telemetry/events.jsonl"
RUN_ID="$TARGET/.engineering-os/telemetry/run_id"
SUMMARY="$TARGET/.engineering-os/telemetry/latest-summary.md"

printf '%s' '{"session_id":"fresh-session","hook_event_name":"SessionStart"}' | \
  (cd "$TARGET" && \
    EOS_TELEMETRY_HANDOFF_MODE=disabled \
    EOS_CLAUDE_SETTINGS_FILE="$TARGET/.claude/settings.json" \
    EOS_TELEMETRY_FILE="$EVENTS" \
    EOS_TELEMETRY_RUN_ID_FILE="$RUN_ID" \
    EOS_TELEMETRY_SUMMARY_FILE="$SUMMARY" \
    bash "$SESSION_START") >/dev/null

run_guard() {
  local tool="$1"
  printf '{"tool_name":"%s","tool_input":{}}' "$tool" | \
    (cd "$TARGET" && \
      EOS_TELEMETRY_HANDOFF_MODE=disabled \
      EOS_CLAUDE_SETTINGS_FILE="$TARGET/.claude/settings.json" \
      EOS_TELEMETRY_FILE="$EVENTS" \
      EOS_TELEMETRY_RUN_ID_FILE="$RUN_ID" \
      bash "$REQUIRE")
}

for tool in Bash Read Glob Grep ToolSearch AskUserQuestion mcp__github__get_me; do
  pass "fresh_session_allows_${tool}" run_guard "$tool"
done

blockcase required_mode_rejects_legacy_boundary_wiring bash -c "
  cd '$TARGET'
  EOS_TELEMETRY_HANDOFF_MODE=required \
  EOS_CLAUDE_SETTINGS_FILE='$TARGET/.claude/settings.json' \
  EOS_TELEMETRY_FILE='$EVENTS' \
  EOS_TELEMETRY_RUN_ID_FILE='$RUN_ID' \
  bash '$REQUIRE'
"

MISSING="$TMP/missing-settings.json"
blockcase missing_settings_remains_fail_closed bash -c "
  cd '$TARGET'
  EOS_TELEMETRY_HANDOFF_MODE=disabled \
  EOS_CLAUDE_SETTINGS_FILE='$MISSING' \
  EOS_TELEMETRY_FILE='$EVENTS' \
  EOS_TELEMETRY_RUN_ID_FILE='$RUN_ID' \
  bash '$REQUIRE'
"

PATCHED="$TMP/patched-settings.json"
cp "$ROOT/.claude/settings.json" "$PATCHED"
python3 "$PATCHER" "$PATCHED"
pass patcher_registers_durable_boundaries grep -q 'record-and-sync-telemetry.sh' "$PATCHED"
first_count="$(grep -o 'record-and-sync-telemetry.sh' "$PATCHED" | wc -l | xargs)"
python3 "$PATCHER" "$PATCHED"
second_count="$(grep -o 'record-and-sync-telemetry.sh' "$PATCHED" | wc -l | xargs)"
[ "$first_count" = "$second_count" ] || { echo "fail: telemetry boundary patch is not idempotent"; exit 1; }
echo "ok: telemetry_boundary_patch_idempotent"

echo "fresh-session hook scoping tests passed"

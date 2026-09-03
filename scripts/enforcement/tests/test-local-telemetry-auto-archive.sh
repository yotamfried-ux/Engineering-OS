#!/usr/bin/env bash
set -euo pipefail

# Validates scripts/monitoring/archive-local-telemetry-run.py, wired into
# record-and-sync-telemetry.sh at the Stop/StopFailure/SessionEnd boundary:
# a finished session's telemetry run must land in ENGINEERING_OS_HOME's
# telemetry-archive/ automatically, with matching identity, without any
# manual export/import step and without changing the boundary script's
# existing exit-status contract.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SESSION_START="$ROOT/scripts/monitoring/eos-telemetry-session-start.sh"
RECORDER="$ROOT/scripts/monitoring/eos-telemetry-event.sh"
BOUNDARY="$ROOT/scripts/monitoring/record-and-sync-telemetry.sh"
ARCHIVER="$ROOT/scripts/monitoring/archive-local-telemetry-run.py"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass() { local name="$1"; shift; "$@" >/dev/null 2>&1 || { echo "fail: $name"; "$@"; exit 1; }; echo "ok: $name"; }

pass files_compile python3 -m py_compile "$ARCHIVER"
pass boundary_shell_syntax bash -n "$BOUNDARY"

# Scratch stand-in for a managed target project (like project-8).
TARGET="$TMP/target"
mkdir -p "$TARGET"
git -C "$TARGET" init -q
git -C "$TARGET" config user.email telemetry@example.invalid
git -C "$TARGET" config user.name telemetry
git -C "$TARGET" remote add origin https://github.com/example-org/example-target.git
echo readme > "$TARGET/README.md"
git -C "$TARGET" add README.md
git -C "$TARGET" commit -q -m init

# Scratch stand-in for a local Engineering OS checkout: only scripts/monitoring/
# is needed by the runtime path under test (verified: none of its modules
# reference scripts/enforcement/ at runtime), plus an empty archive skeleton.
EOS_HOME="$TMP/eos-home"
mkdir -p "$EOS_HOME/scripts"
cp -r "$ROOT/scripts/monitoring" "$EOS_HOME/scripts/monitoring"
mkdir -p "$EOS_HOME/telemetry-archive/indexes" "$EOS_HOME/.git-marker-only"
git -C "$EOS_HOME" init -q
git -C "$EOS_HOME" config user.email eos@example.invalid
git -C "$EOS_HOME" config user.name eos
echo marker > "$EOS_HOME/README.md"
git -C "$EOS_HOME" add README.md
git -C "$EOS_HOME" commit -q -m init
EOS_HEAD="$(git -C "$EOS_HOME" rev-parse HEAD)"
TARGET_HEAD="$(git -C "$TARGET" rev-parse HEAD)"

EVENTS="$TARGET/.engineering-os/telemetry/events.jsonl"
RUN_ID_FILE="$TARGET/.engineering-os/telemetry/run_id"
SUMMARY="$TARGET/.engineering-os/telemetry/latest-summary.md"
SEED="stable-local-archive-seed"

env_common=(EOS_TELEMETRY_RUN_ID="$SEED" EOS_TELEMETRY_FILE="$EVENTS" EOS_TELEMETRY_RUN_ID_FILE="$RUN_ID_FILE" EOS_TELEMETRY_SUMMARY_FILE="$SUMMARY" ENGINEERING_OS_HOME="$EOS_HOME")

# 1) A session with zero tool calls still produces two events by the time
#    Stop fires (eos.session_start, then eos.stop itself, appended by the
#    recorder before the archiver runs) -- verified directly, not assumed.
#    Both are pure lifecycle bookkeeping, so this "opened and closed" run
#    must NOT create an archive entry: every managed session reaches at
#    least one boundary event, so archiving unconditionally would fill
#    telemetry-archive/ with noise instead of runs worth analyzing later.
printf '%s' '{"session_id":"minimal-session","hook_event_name":"SessionStart"}' | \
  (cd "$TARGET" && env "${env_common[@]}" bash "$SESSION_START")
run_id_minimal="$(cat "$RUN_ID_FILE")"
out="$(cd "$TARGET" && env "${env_common[@]}" bash "$BOUNDARY" stop 2>&1 </dev/null)"
status=$?
[ "$status" -eq 0 ] || { echo "fail: minimal_session_stop_exit_zero (status=$status)"; echo "$out"; exit 1; }
echo "ok: minimal_session_stop_exit_zero"
[ "$(wc -l < "$EVENTS" | tr -d ' ')" = "2" ] || { echo "fail: minimal session did not have exactly 2 lifecycle events"; cat "$EVENTS"; exit 1; }
echo "ok: minimal_session_has_two_lifecycle_events"
pass lifecycle_only_session_not_archived bash -c "[ ! -d '$EOS_HOME/telemetry-archive/runs' ] || ! find '$EOS_HOME/telemetry-archive/runs' -mindepth 1 -type d | grep -q ."

# A boundary call with literally no events.jsonl on disk at all (SessionStart
# never ran for this run_id) must still be a safe no-op, not an error.
NEVER_STARTED="$TMP/never-started"
mkdir -p "$NEVER_STARTED"
out="$(cd "$TARGET" && env EOS_TELEMETRY_RUN_ID="unused" EOS_TELEMETRY_FILE="$NEVER_STARTED/events.jsonl" EOS_TELEMETRY_RUN_ID_FILE="$NEVER_STARTED/run_id" EOS_TELEMETRY_SUMMARY_FILE="$NEVER_STARTED/latest-summary.md" ENGINEERING_OS_HOME="$EOS_HOME" bash "$BOUNDARY" stop 2>&1 </dev/null)"
status=$?
[ "$status" -eq 0 ] || { echo "fail: no_events_file_stop_exit_zero (status=$status)"; echo "$out"; exit 1; }
echo "ok: no_events_file_stop_exit_zero"

# 2) A session with real tool-call events must be archived automatically.
printf '%s' '{"session_id":"real-session","hook_event_name":"SessionStart"}' | \
  (cd "$TARGET" && env "${env_common[@]}" bash "$SESSION_START")
run_id_real="$(cat "$RUN_ID_FILE")"
[ "$run_id_real" != "$run_id_minimal" ] || { echo "fail: run id did not rotate between sessions"; exit 1; }

printf '%s' '{"session_id":"real-session","tool_name":"Bash","tool_input":{"command":"npm test"}}' | \
  (cd "$TARGET" && env "${env_common[@]}" bash "$RECORDER" pre_tool_use)
printf '%s' '{"session_id":"real-session","tool_name":"Bash","tool_input":{"command":"npm test"}}' | \
  (cd "$TARGET" && env "${env_common[@]}" bash "$RECORDER" post_tool_use)

(cd "$TARGET" && env "${env_common[@]}" bash "$BOUNDARY" stop </dev/null >/dev/null)

ARCHIVED_RUN_DIR="$(find "$EOS_HOME/telemetry-archive/runs" -type d -name "$run_id_real" | head -1)"
[ -n "$ARCHIVED_RUN_DIR" ] || { echo "fail: real session was not archived"; exit 1; }
ARCHIVED_EVENTS="$ARCHIVED_RUN_DIR/events.jsonl"
echo "ok: real_session_archived"

python3 - "$ARCHIVED_EVENTS" "$run_id_real" "$TARGET_HEAD" "$EOS_HEAD" <<'PY'
import json
import sys

events_path, run_id, target_head, eos_head = sys.argv[1:]
manifest_path = events_path.replace("events.jsonl", "manifest.json")
manifest = json.load(open(manifest_path, encoding="utf-8"))
assert manifest["run_id"] == run_id, manifest
assert manifest["head_sha"] == target_head, manifest
assert manifest["engineering_os_head_sha"] == eos_head, manifest
assert manifest["event_count"] >= 2, manifest
assert manifest["privacy_contract"] == "metadata-only", manifest

raw = open(events_path, encoding="utf-8").read()
assert "npm test" not in raw, raw

lines = [json.loads(x) for x in raw.splitlines() if x.strip()]
assert all(item["trace_id"] == run_id for item in lines), lines
PY
echo "ok: archived_identity_and_privacy_match"

# 3) A second boundary call for the same, unchanged run (SessionEnd after Stop)
#    must not fail and must not create a second archive entry.
run_count_before="$(find "$EOS_HOME/telemetry-archive/runs" -mindepth 3 -maxdepth 3 -type d | wc -l | tr -d ' ')"
out="$(cd "$TARGET" && env "${env_common[@]}" bash "$BOUNDARY" session_end 2>&1 </dev/null)"
status=$?
[ "$status" -eq 0 ] || { echo "fail: repeated_boundary_call_exit_zero (status=$status)"; echo "$out"; exit 1; }
echo "ok: repeated_boundary_call_exit_zero"
run_count_after="$(find "$EOS_HOME/telemetry-archive/runs" -mindepth 3 -maxdepth 3 -type d | wc -l | tr -d ' ')"
[ "$run_count_before" = "$run_count_after" ] || { echo "fail: repeated boundary call duplicated the archive entry"; exit 1; }
echo "ok: repeated_boundary_call_did_not_duplicate"

# 4) When ENGINEERING_OS_HOME has no reachable archive, the boundary script
#    must still exit 0 (best-effort, never blocks session teardown).
NO_HOME="$TMP/no-eos-home"
mkdir -p "$NO_HOME"
printf '%s' '{"session_id":"no-home-session","hook_event_name":"SessionStart"}' | \
  (cd "$TARGET" && env EOS_TELEMETRY_RUN_ID="$SEED-2" EOS_TELEMETRY_FILE="$EVENTS" EOS_TELEMETRY_RUN_ID_FILE="$RUN_ID_FILE" EOS_TELEMETRY_SUMMARY_FILE="$SUMMARY" ENGINEERING_OS_HOME="$NO_HOME" bash "$SESSION_START")
printf '%s' '{"session_id":"no-home-session","tool_name":"Bash","tool_input":{"command":"echo hi"}}' | \
  (cd "$TARGET" && env EOS_TELEMETRY_RUN_ID="$SEED-2" EOS_TELEMETRY_FILE="$EVENTS" EOS_TELEMETRY_RUN_ID_FILE="$RUN_ID_FILE" bash "$RECORDER" post_tool_use)
out="$(cd "$TARGET" && env EOS_TELEMETRY_RUN_ID="$SEED-2" EOS_TELEMETRY_FILE="$EVENTS" EOS_TELEMETRY_RUN_ID_FILE="$RUN_ID_FILE" EOS_TELEMETRY_SUMMARY_FILE="$SUMMARY" ENGINEERING_OS_HOME="$NO_HOME" bash "$BOUNDARY" stop 2>&1 </dev/null)"
status=$?
[ "$status" -eq 0 ] || { echo "fail: unreachable_home_exit_zero (status=$status)"; echo "$out"; exit 1; }
echo "ok: unreachable_home_exit_zero"
echo "$out" | grep -q "WARNING_FOR_AGENT: local telemetry archiving" || { echo "fail: unreachable_home_warns"; echo "$out"; exit 1; }
echo "ok: unreachable_home_warns"

echo "local telemetry auto-archive tests passed"

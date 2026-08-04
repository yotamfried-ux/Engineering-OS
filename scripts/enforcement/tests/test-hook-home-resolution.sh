#!/usr/bin/env bash
set -euo pipefail

# An unresolvable Engineering OS home must DENY, not pass.
#
# A real qualification session proved why this matters. project-8's settings wired every
# hook in the bare form `bash "${ENGINEERING_OS_HOME:-$HOME/.engineering-os}/..."`. With
# ENGINEERING_OS_HOME unset and no checkout at $HOME/.engineering-os, every command pointed
# at a missing file. Bash exits 127 there, and per the Claude Code PreToolUse contract only
# exit 2 denies — so the session did all its work with two telemetry events, no
# session_start and no durable bundle, under remote_handoff.mode=required, and reported
# success. The failure was invisible precisely because it was non-blocking.
#
# These cases execute the rendered commands rather than inspecting their text, because the
# defect lives in the exit status the shell produces, not in the string.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
PATCHER="$ROOT/scripts/monitoring/patch-settings-telemetry.py"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# shellcheck disable=SC2016  # deliberate: this is the literal placeholder text that must
# survive into the rendered settings file, not something to expand here.
PORTABLE='${ENGINEERING_OS_HOME:-$HOME/.engineering-os}'
HOOK_INPUT='{"hook_event_name":"PreToolUse","tool_name":"Read","tool_input":{"file_path":"/tmp/x"}}'

# Render a real settings file with the portable root and pull the guard command out of it,
# so the assertions run against what the renderer actually produces.
printf '{}\n' > "$TMP/settings.json"
python3 "$PATCHER" "$TMP/settings.json" --mode direct --home "$PORTABLE" >/dev/null

guard_command() {
  python3 - "$1" <<'PY'
import json, sys
data = json.loads(open(sys.argv[1], encoding="utf-8").read())
for block in data.get("hooks", {}).get("PreToolUse", []):
    for hook in block.get("hooks", []):
        command = hook.get("command", "")
        if "require-telemetry-session.sh" in command:
            print(command)
            raise SystemExit(0)
raise SystemExit("no telemetry guard command found in rendered settings")
PY
}

GATED="$(guard_command "$TMP/settings.json")"
BARE="bash \"$PORTABLE/scripts/monitoring/require-telemetry-session.sh\""

# An empty HOME stand-in: exists, but is not an Engineering OS checkout. This is exactly the
# shape observed in the field — $HOME/.engineering-os existed and held only a telemetry
# directory created by the runtime itself.
FAKE_HOME="$TMP/home"
mkdir -p "$FAKE_HOME/.engineering-os/telemetry"

run_unresolved() {
  set +e
  printf '%s' "$HOOK_INPUT" | env -u ENGINEERING_OS_HOME HOME="$FAKE_HOME" bash -c "$1" >"$TMP/out" 2>"$TMP/err"
  local code=$?
  set -e
  return "$code"
}

# 1. The rendered gate-wrapped command must deny.
run_unresolved "$GATED" && code=0 || code=$?
if [ "$code" -ne 2 ]; then
  echo "fail: gate-wrapped guard returned $code with an unresolvable home; only exit 2 denies at PreToolUse"
  echo "  stderr: $(tr '\n' ' ' < "$TMP/err")"
  exit 1
fi
grep -q 'ERROR_FOR_AGENT' "$TMP/err" || {
  echo "fail: gate-wrapped denial produced no ERROR_FOR_AGENT diagnostic"; exit 1; }
echo "ok: unresolvable_home_denies (exit 2)"

# 2. The bare form is recorded as the defect it is. This case documents the difference the
#    fix protects: if a future change reverts to an ungated command, case 1 fails while this
#    one keeps explaining why 127 is not a denial.
run_unresolved "$BARE" && code=0 || code=$?
if [ "$code" -eq 2 ]; then
  echo "fail: bare command returned 2; this fixture is meant to demonstrate the non-blocking exit"
  exit 1
fi
echo "ok: bare_form_is_non_blocking (exit $code, not a denial)"

# 3. The renderer must not emit a bare hard command for a project surface at all.
if printf '%s' "$GATED" | grep -q '/lib/hook-gate.sh'; then
  echo "ok: rendered_guard_is_gate_wrapped"
else
  echo "fail: rendered guard is not gate-wrapped: $GATED"; exit 1
fi
printf '%s' "$GATED" | grep -q 'exit 2' || {
  echo "fail: rendered guard lacks the missing-wrapper exit-2 bootstrap"; exit 1; }
echo "ok: rendered_guard_has_exit2_bootstrap"

# 4. The portable root must survive rendering, and no machine-specific path may appear.
#    Both are required by the product repository's own settings contract, so a fix that
#    baked an absolute path here would be rejected there.
printf '%s' "$GATED" | grep -qF "$PORTABLE" || {
  echo "fail: portable Engineering OS root did not survive rendering"; exit 1; }
if printf '%s' "$GATED" | grep -Eq '/(home|Users)/[^/$]+/'; then
  echo "fail: rendered guard contains a machine-specific home path"; exit 1
fi
echo "ok: portable_root_preserved_without_machine_specific_path"

# 5. A resolvable home must still allow the gate to run its unit rather than short-circuit.
run_unresolved "${GATED//$PORTABLE/$ROOT}" && code=0 || code=$?
if grep -q 'hard-hook wrapper missing' "$TMP/err"; then
  echo "fail: resolvable home still reported a missing wrapper"; exit 1
fi
echo "ok: resolvable_home_reaches_the_unit (exit $code)"

echo "hook home resolution tests passed"

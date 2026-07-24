#!/usr/bin/env bash
# hook-gate.sh — fail-closed runner for Engineering OS hard Claude Code hooks.
set -u
set -o pipefail

fail_blocking() {
  local reason="${1:-Engineering OS hard hook infrastructure failure.}"
  printf 'ERROR_FOR_AGENT: %s\n' "$reason" >&2
  exit 2
}

EVENT=""
MATCHER=""
UNIT=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --event) EVENT="${2:-}"; shift 2 ;;
    --matcher) MATCHER="${2:-}"; shift 2 ;;
    --unit) UNIT="${2:-}"; shift 2 ;;
    --) shift; break ;;
    *) fail_blocking "hook-gate received an unexpected argument: $1" ;;
  esac
done
UNIT_ARGS=("$@")

[ -n "$EVENT" ] || fail_blocking "hook-gate is missing --event."
[ -n "$MATCHER" ] || fail_blocking "hook-gate is missing --matcher."
[ -n "$UNIT" ] || fail_blocking "hook-gate is missing --unit."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)" || fail_blocking "hook-gate cannot resolve its installation directory."
ROOT="$(cd "$SCRIPT_DIR/../../.." 2>/dev/null && pwd)" || fail_blocking "hook-gate cannot resolve ENGINEERING_OS_HOME."
REGISTRY="${EOS_HOOK_CRITICALITY_FILE:-$ROOT/scripts/enforcement/hook-criticality.tsv}"
PYTHON="${EOS_HOOK_GATE_PYTHON:-python3}"
CONVERTER="${EOS_HOOK_GATE_CONVERTER:-$PYTHON}"

command -v "$PYTHON" >/dev/null 2>&1 || fail_blocking "required hard-hook interpreter is unavailable: $PYTHON"
[ ! -L "$REGISTRY" ] || fail_blocking "hard-hook criticality registry path is a symlink: $REGISTRY"
[ -f "$REGISTRY" ] && [ -r "$REGISTRY" ] || fail_blocking "hard-hook criticality registry is missing or unreadable: $REGISTRY"
[ ! -L "$UNIT" ] || fail_blocking "hard-hook enforcer path is a symlink: $UNIT"
[ -f "$UNIT" ] && [ -r "$UNIT" ] || fail_blocking "hard-hook enforcer is missing or unreadable: $UNIT"

TMP="$(mktemp -d 2>/dev/null)" || fail_blocking "hook-gate cannot create a private temporary directory."
trap 'rm -rf "$TMP"' EXIT HUP INT TERM
INPUT_FILE="$TMP/input.json"
CONTRACT_FILE="$TMP/contract.json"
STDOUT_FILE="$TMP/stdout"
STDERR_FILE="$TMP/stderr"

cat > "$INPUT_FILE" || fail_blocking "hook-gate could not read hook input."
[ -s "$INPUT_FILE" ] || fail_blocking "hard hook received empty JSON input."

if ! "$PYTHON" - "$INPUT_FILE" "$EVENT" <<'PY' >/dev/null 2>"$STDERR_FILE"
import json
import sys
from pathlib import Path
path, expected_event = Path(sys.argv[1]), sys.argv[2]
try:
    data = json.loads(path.read_text(encoding="utf-8"))
except Exception as exc:
    raise SystemExit(f"invalid hook JSON: {exc}")
if not isinstance(data, dict):
    raise SystemExit("hook input must be a JSON object")
actual = data.get("hook_event_name")
if actual != expected_event:
    raise SystemExit(f"hook_event_name mismatch: expected {expected_event!r}, got {actual!r}")
if expected_event == "PreToolUse":
    tool = data.get("tool_name") or data.get("tool")
    if not isinstance(tool, str) or not tool:
        raise SystemExit("PreToolUse input is missing tool_name")
    if not isinstance(data.get("tool_input"), dict):
        raise SystemExit("PreToolUse input is missing object tool_input")
PY
then
  reason="$(tr '\n' ' ' < "$STDERR_FILE" | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//')"
  fail_blocking "hard-hook input validation failed: ${reason:-unknown JSON validation error}"
fi

if ! "$PYTHON" - "$ROOT" "$REGISTRY" "$EVENT" "$MATCHER" "$UNIT" >"$CONTRACT_FILE" 2>"$STDERR_FILE" <<'PY'
import json
import os
import sys
from pathlib import Path
root = Path(sys.argv[1]).resolve()
registry = Path(sys.argv[2])
event, matcher = sys.argv[3:5]
unit_arg_raw = Path(sys.argv[5])
columns = 10
rows = []
for number, raw in enumerate(registry.read_text(encoding="utf-8").splitlines(), 1):
    if not raw.strip() or raw.startswith("#"):
        continue
    parts = raw.split("\t")
    if len(parts) != columns:
        raise SystemExit(f"malformed hook-criticality row {number}: expected {columns} columns, got {len(parts)}")
    e, m, unit, klass, semantics, wiring, parent, surface, requires, deny_mode = parts
    if klass not in {"hard", "advisory", "recorder", "lifecycle"}:
        raise SystemExit(f"invalid class in row {number}: {klass}")
    if wiring not in {"direct", "nested", "inline"}:
        raise SystemExit(f"invalid wiring in row {number}: {wiring}")
    rows.append({"event": e, "matcher": m, "unit": unit, "class": klass,
                 "semantics": semantics, "wiring": wiring, "parent": parent,
                 "surface": surface, "requires": requires, "deny_mode": deny_mode,
                 "line": number})

def trusted_path(rel):
    rel_path = Path(rel)
    if rel_path.is_absolute() or ".." in rel_path.parts:
        raise SystemExit(f"required hard-hook path escapes ENGINEERING_OS_HOME: {rel}")
    unresolved = root
    for part in rel_path.parts:
        unresolved = unresolved / part
        if unresolved.is_symlink():
            raise SystemExit(f"required hard-hook path traverses a symlink: {rel}")
    path = unresolved.resolve()
    try:
        path.relative_to(root)
    except ValueError:
        raise SystemExit(f"required hard-hook path escapes ENGINEERING_OS_HOME: {rel}")
    if not path.is_file() or not os.access(path, os.R_OK):
        raise SystemExit(f"required hard-hook path is missing or unreadable: {rel}")
    return path

try:
    unit_rel = unit_arg_raw.relative_to(root)
except ValueError:
    raise SystemExit(f"hard-hook unit argument escapes ENGINEERING_OS_HOME: {unit_arg_raw}")
unit_arg = trusted_path(str(unit_rel))

matches = [r for r in rows if r["event"] == event and r["matcher"] == matcher and
           r["wiring"] == "direct" and trusted_path(r["unit"]) == unit_arg]
if len(matches) != 1:
    raise SystemExit(f"expected exactly one direct registry row for {event}/{matcher}/{unit_arg}, found {len(matches)}")
row = matches[0]
if row["class"] != "hard" or row["semantics"] != "fail_closed":
    raise SystemExit(f"hook-gate may run only a canonical hard/fail_closed unit, got {row['class']}/{row['semantics']}")
expected_mode = "pretool_json" if event == "PreToolUse" else "stop_json" if event == "Stop" else "exit2"
if row["deny_mode"] != expected_mode:
    raise SystemExit(f"deny mode mismatch: expected {expected_mode}, got {row['deny_mode']}")

by_parent = {}
for item in rows:
    if item["wiring"] == "nested":
        by_parent.setdefault(item["parent"], []).append(item)
required = set()
seen = set()
def add_requirements(item):
    key = item["unit"]
    if key in seen:
        raise SystemExit(f"nested hard-hook cycle detected at {key}")
    seen.add(key)
    required.add(key)
    if item["requires"] != "-":
        for value in item["requires"].split(","):
            value = value.strip()
            if value:
                required.add(value)
    for child in by_parent.get(key, []):
        if child["class"] != "hard" or child["semantics"] != "fail_closed":
            raise SystemExit(f"required nested unit {child['unit']} is not hard/fail_closed")
        add_requirements(child)
    seen.remove(key)
add_requirements(row)

for rel in sorted(required):
    trusted_path(rel)
print(json.dumps({"unit": row["unit"], "deny_mode": row["deny_mode"], "required": sorted(required)}))
PY
then
  reason="$(tr '\n' ' ' < "$STDERR_FILE" | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//')"
  fail_blocking "hard-hook contract validation failed: ${reason:-unknown registry failure}"
fi

set +e
bash "$UNIT" "${UNIT_ARGS[@]}" <"$INPUT_FILE" >"$STDOUT_FILE" 2>"$STDERR_FILE"
CODE=$?

OUT="$(cat "$STDOUT_FILE")"
ERR="$(cat "$STDERR_FILE")"
REASON="$(printf '%s %s' "$OUT" "$ERR" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//' | cut -c1-4000)"

emit_structured() {
  local mode="$1" kind="$2" text="$3" input="$4"
  command -v "$CONVERTER" >/dev/null 2>&1 || return 1
  "$CONVERTER" - "$mode" "$kind" "$text" "$input" <<'PY'
import json
import sys
mode, kind, text, raw = sys.argv[1:5]
if kind == "forward":
    data = json.loads(raw)
    if not isinstance(data, dict):
        raise SystemExit("native hook output is not an object")
    if mode == "pretool_json":
        specific = data.get("hookSpecificOutput")
        if not isinstance(specific, dict) or specific.get("hookEventName") != "PreToolUse":
            raise SystemExit("PreToolUse native JSON lacks matching hookSpecificOutput")
        decision = specific.get("permissionDecision")
        if decision not in {None, "allow", "deny", "ask"}:
            raise SystemExit("invalid PreToolUse permissionDecision")
        if decision == "deny" and not specific.get("permissionDecisionReason"):
            raise SystemExit("PreToolUse deny is missing permissionDecisionReason")
    elif mode == "stop_json":
        decision = data.get("decision")
        if decision not in {None, "block"}:
            raise SystemExit("invalid Stop decision")
        if decision == "block" and not data.get("reason"):
            raise SystemExit("Stop block is missing reason")
    print(json.dumps(data, ensure_ascii=False, separators=(",", ":")))
    raise SystemExit(0)
if not text:
    text = "Engineering OS hard hook blocked because it could not produce a trustworthy policy decision."
if kind == "deny":
    if mode == "pretool_json":
        print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": text}}, ensure_ascii=False, separators=(",", ":")))
    elif mode == "stop_json":
        print(json.dumps({"decision": "block", "reason": text}, ensure_ascii=False, separators=(",", ":")))
    else:
        raise SystemExit("unsupported structured deny mode")
elif kind == "context":
    if mode == "pretool_json":
        print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "additionalContext": text}}, ensure_ascii=False, separators=(",", ":")))
    elif mode == "stop_json":
        print(json.dumps({"systemMessage": text}, ensure_ascii=False, separators=(",", ":")))
    else:
        raise SystemExit("unsupported structured context mode")
else:
    raise SystemExit("unknown output kind")
PY
}

MODE="$("$PYTHON" -c 'import json,sys; print(json.load(open(sys.argv[1]))["deny_mode"])' "$CONTRACT_FILE" 2>/dev/null)" || fail_blocking "hard-hook contract result could not be read."

if [ "$CODE" -eq 0 ]; then
  if [ -z "$OUT" ]; then
    exit 0
  fi
  if printf '%s' "$OUT" | "$PYTHON" -c 'import json,sys; json.load(sys.stdin)' >/dev/null 2>&1; then
    if emit_structured "$MODE" forward "" "$OUT"; then exit 0; fi
    fail_blocking "hard-hook native JSON could not be validated or forwarded."
  fi
  case "$OUT" in
    \{*|\[* ) fail_blocking "hard-hook returned malformed JSON on success." ;;
  esac
  if emit_structured "$MODE" context "$OUT" ""; then exit 0; fi
  fail_blocking "hard-hook success output could not be converted to valid Claude Code JSON."
fi

if [ "$CODE" -gt 128 ]; then
  REASON="hard-hook subprocess terminated by signal $((CODE - 128)): ${REASON:-no diagnostic output}"
elif [ "$CODE" -eq 1 ] || [ "$CODE" -eq 2 ]; then
  REASON="hard-hook policy denial: ${REASON:-the enforcer returned exit $CODE without a reason}"
else
  REASON="hard-hook subprocess returned unexpected exit code $CODE: ${REASON:-no diagnostic output}"
fi

if emit_structured "$MODE" deny "$REASON" ""; then
  exit 0
fi
fail_blocking "$REASON (structured deny conversion failed)"

#!/usr/bin/env bash
set -euo pipefail

# User-level settings lifecycle: creation, exact verification, idempotent update,
# preservation of user hooks, malformed JSON refusal, dry-run, uninstall, and
# actionable runtime-path failure.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
INSTALLER="$ROOT/scripts/monitoring/install-user-level-telemetry-hooks.sh"
PATCHER="$ROOT/scripts/monitoring/patch-settings-telemetry.py"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

HOME_DIR="$TMP/home"
mkdir -p "$HOME_DIR"
SETTINGS="$HOME_DIR/.claude/settings.json"

run_installer() {
  HOME="$HOME_DIR" ENGINEERING_OS_HOME="$ROOT" bash "$INSTALLER" "$@"
}

# 1. New user settings file is valid and uses only dispatcher-mode commands.
run_installer > "$TMP/install.log"
python3 -c "import json; json.load(open('$SETTINGS'))"
grep -q "$ROOT/scripts/monitoring/eos-telemetry-dispatch.sh" "$SETTINGS"
if grep -q 'require-telemetry-session.sh' "$SETTINGS"; then
  echo "ERROR_FOR_AGENT: user-level settings must route the guard through the dispatcher" >&2
  exit 1
fi
if grep -q 'ENGINEERING_OS_HOME' "$SETTINGS"; then
  echo "ERROR_FOR_AGENT: unresolved runtime placeholder leaked into user settings" >&2
  exit 1
fi
python3 - "$SETTINGS" "$ROOT" <<'PY'
import json
import sys
from pathlib import Path

settings = json.loads(Path(sys.argv[1]).read_text())
root = sys.argv[2]
commands = [
    hook["command"]
    for block in settings["hooks"]["PreToolUse"]
    for hook in block.get("hooks", [])
]
expected_guard = f'bash "{root}/scripts/monitoring/eos-telemetry-dispatch.sh" guard'
assert commands.count(expected_guard) == 1, commands
assert sum(command.endswith(" pre_tool_use") for command in commands) == 1, commands
PY

# 2. Exact verification succeeds for a current install.
run_installer --verify

# 3. Verification catches a stale absolute runtime path before reinstall fixes it.
python3 - "$SETTINGS" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
data = json.loads(path.read_text())
for block in data["hooks"]["PostToolUse"]:
    for hook in block.get("hooks", []):
        if "post_tool_use" in hook.get("command", ""):
            hook["command"] = 'bash "/stale/Engineering-OS/scripts/monitoring/eos-telemetry-dispatch.sh" post_tool_use'
path.write_text(json.dumps(data))
PY
if run_installer --verify >"$TMP/stale.out" 2>"$TMP/stale.err"; then
  echo "ERROR_FOR_AGENT: --verify accepted a stale dispatcher path" >&2
  exit 1
fi
grep -q 'stale owned hook' "$TMP/stale.err"
run_installer > /dev/null
run_installer --verify

# 4. A current reinstall is a true no-op and creates no new backup.
rm -f "$HOME_DIR/.claude"/*.backup.*
run_installer > "$TMP/noop.log"
grep -q 'no changes needed' "$TMP/noop.log"
[ -z "$(find "$HOME_DIR/.claude" -maxdepth 1 -name '*.backup.*' -print -quit)" ] || {
  echo "ERROR_FOR_AGENT: no-op reinstall created a backup" >&2
  exit 1
}

# 5. Existing unrelated settings and hooks survive installation.
cat > "$SETTINGS" <<'JSON'
{
  "model": "claude-opus",
  "hooks": {
    "PreToolUse": [{"matcher": ".*", "hooks": [{"type": "command", "command": "echo my-custom-hook"}]}]
  }
}
JSON
run_installer > /dev/null
python3 - "$SETTINGS" <<'PY'
import json
import sys
from pathlib import Path

data = json.loads(Path(sys.argv[1]).read_text())
assert data["model"] == "claude-opus"
commands = [
    hook["command"]
    for block in data["hooks"]["PreToolUse"]
    for hook in block.get("hooks", [])
]
assert "echo my-custom-hook" in commands, commands
PY

# 6. Malformed JSON is rejected without a partial overwrite.
echo '{not valid json' > "$SETTINGS"
cp "$SETTINGS" "$TMP/broken.orig"
if run_installer >"$TMP/broken.out" 2>"$TMP/broken.err"; then
  echo "ERROR_FOR_AGENT: installer accepted malformed settings JSON" >&2
  exit 1
fi
grep -q 'ERROR_FOR_AGENT' "$TMP/broken.err"
diff -q "$SETTINGS" "$TMP/broken.orig" >/dev/null

# 7. Dry-run changes nothing.
rm -f "$SETTINGS"
run_installer > /dev/null
cp "$SETTINGS" "$TMP/before-dry-run.json"
python3 "$PATCHER" "$SETTINGS" --mode dispatcher --home "$ROOT" --uninstall --dry-run > "$TMP/dry.log"
diff -q "$SETTINGS" "$TMP/before-dry-run.json" >/dev/null
grep -q 'dry-run' "$TMP/dry.log"

# 8. Uninstall removes only Engineering-OS-owned entries and retains the file.
python3 - "$SETTINGS" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
data = json.loads(path.read_text())
data.setdefault("hooks", {}).setdefault("PostToolUse", []).append({
    "matcher": ".*",
    "hooks": [{"type": "command", "command": "echo unrelated-user-hook"}],
})
path.write_text(json.dumps(data))
PY
run_installer > /dev/null
run_installer --uninstall > /dev/null
python3 - "$SETTINGS" <<'PY'
import json
import sys
from pathlib import Path

text = Path(sys.argv[1]).read_text()
data = json.loads(text)
assert "eos-telemetry-dispatch.sh" not in text, text
assert "require-telemetry-session.sh" not in text, text
assert "echo unrelated-user-hook" in text, data
PY
[ -f "$SETTINGS" ]

# 9. An invalid runtime path fails with the installer's actionable convention.
if HOME="$HOME_DIR" ENGINEERING_OS_HOME="$TMP/missing-runtime" bash "$INSTALLER" \
  >"$TMP/missing.out" 2>"$TMP/missing.err"; then
  echo "ERROR_FOR_AGENT: missing Engineering OS checkout unexpectedly succeeded" >&2
  exit 1
fi
grep -q 'ERROR_FOR_AGENT: Engineering OS checkout not found' "$TMP/missing.err"
grep -q 'ACTION:' "$TMP/missing.err"

echo 'user-level telemetry installer tests passed: exact dispatcher guard, stale-path detection, idempotency, preservation, refusal, dry-run, uninstall, and actionable path failure'

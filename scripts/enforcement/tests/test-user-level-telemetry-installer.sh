#!/usr/bin/env bash
set -euo pipefail

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

assert_mode() {
  local expected="$1" actual
  actual="$(stat -c '%a' "$SETTINGS")"
  [ "$actual" = "$expected" ] || {
    echo "ERROR_FOR_AGENT: settings mode is $actual, expected $expected" >&2
    exit 1
  }
}

assert_dispatcher_only() {
  python3 - "$SETTINGS" "$ROOT" <<'PY'
import json, sys
from pathlib import Path
settings = json.loads(Path(sys.argv[1]).read_text())
root = sys.argv[2]
all_commands = [
    hook["command"]
    for blocks in settings.get("hooks", {}).values()
    if isinstance(blocks, list)
    for block in blocks
    if isinstance(block, dict)
    for hook in block.get("hooks", [])
    if isinstance(hook, dict) and isinstance(hook.get("command"), str)
]
pretool = [
    hook["command"]
    for block in settings["hooks"]["PreToolUse"]
    for hook in block.get("hooks", [])
]
session_start = [
    hook["command"]
    for block in settings["hooks"]["SessionStart"]
    for hook in block.get("hooks", [])
]
expected = f'bash "{root}/scripts/monitoring/eos-telemetry-dispatch.sh"'
assert pretool.count(f"{expected} guard") == 1, pretool
assert sum(c.endswith(" pre_tool_use") and expected in c for c in pretool) == 1, pretool
assert session_start == [f"{expected} session_start"], session_start
for stale in (
    "require-telemetry-session.sh",
    "eos-telemetry-session-start.sh",
    "eos-telemetry-event.sh",
    "record-and-sync-telemetry.sh",
):
    assert not any(stale in command for command in all_commands), (stale, all_commands)
PY
}

# 1. New settings are exact, dispatcher-only, and private.
run_installer > "$TMP/install.log"
python3 -c "import json; json.load(open('$SETTINGS'))"
grep -q "$ROOT/scripts/monitoring/eos-telemetry-dispatch.sh" "$SETTINGS"
! grep -q 'ENGINEERING_OS_HOME' "$SETTINGS"
assert_dispatcher_only
assert_mode 600

# The temporary file reaches its final restrictive mode before the first byte is written.
python3 - "$PATCHER" "$TMP" <<'PY'
import importlib.util
import os
import stat
import sys
from pathlib import Path

spec = importlib.util.spec_from_file_location("settings_patcher", sys.argv[1])
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)
base = Path(sys.argv[2]) / "atomic-mode"
base.mkdir()
real_fdopen = module.os.fdopen
expected_mode = [0o600]
observed = []

class GuardedStream:
    def __init__(self, inner):
        self.inner = inner
    def __enter__(self):
        return self
    def __exit__(self, exc_type, exc, tb):
        self.inner.close()
        return False
    def write(self, value):
        mode = stat.S_IMODE(os.fstat(self.inner.fileno()).st_mode)
        observed.append(mode)
        assert mode == expected_mode[0], (oct(mode), oct(expected_mode[0]))
        return self.inner.write(value)
    def flush(self):
        return self.inner.flush()
    def fileno(self):
        return self.inner.fileno()

def guarded_fdopen(fd, *args, **kwargs):
    return GuardedStream(real_fdopen(fd, *args, **kwargs))

module.os.fdopen = guarded_fdopen
new_path = base / "new.json"
module.atomic_write(new_path, {"secret": "value"})
assert stat.S_IMODE(new_path.stat().st_mode) == 0o600
existing = base / "existing.json"
existing.write_text("{}")
os.chmod(existing, 0o640)
expected_mode[0] = 0o640
module.atomic_write(existing, {"secret": "updated"})
assert stat.S_IMODE(existing.stat().st_mode) == 0o640
assert observed == [0o600, 0o640], observed
PY

# 2. Exact verification succeeds.
run_installer --verify

# 3. Direct-to-dispatcher conversion removes all direct hooks.
rm -f "$SETTINGS"
mkdir -p "$(dirname "$SETTINGS")"
python3 "$PATCHER" "$SETTINGS" --mode direct --home "$ROOT" --no-backup >/dev/null
grep -q 'eos-telemetry-session-start.sh' "$SETTINGS"
run_installer >/dev/null
assert_dispatcher_only
run_installer --verify

# 4. Verification catches a stale absolute runtime path and reinstall repairs it.
python3 - "$SETTINGS" <<'PY'
import json, sys
from pathlib import Path
path = Path(sys.argv[1]); data = json.loads(path.read_text())
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
run_installer >/dev/null
run_installer --verify

# 5. Verification rejects an additional stale owned hook outside the desired set.
python3 - "$SETTINGS" "$ROOT" <<'PY'
import json, sys
from pathlib import Path
path = Path(sys.argv[1]); root = sys.argv[2]; data = json.loads(path.read_text())
data["hooks"].setdefault("PostToolUse", []).append({
    "matcher": "Read",
    "hooks": [{
        "type": "command",
        "command": f'bash "{root}/scripts/monitoring/eos-telemetry-event.sh" post_tool_use',
    }],
})
path.write_text(json.dumps(data))
PY
if run_installer --verify >"$TMP/extra.out" 2>"$TMP/extra.err"; then
  echo "ERROR_FOR_AGENT: --verify accepted an unexpected owned hook" >&2
  exit 1
fi
grep -q 'unexpected owned hook' "$TMP/extra.err"
run_installer >/dev/null
run_installer --verify
assert_dispatcher_only

# 6. A current reinstall is a no-op and creates no backup.
rm -f "$HOME_DIR/.claude"/*.backup.*
run_installer > "$TMP/noop.log"
grep -q 'no changes needed' "$TMP/noop.log"
[ -z "$(find "$HOME_DIR/.claude" -maxdepth 1 -name '*.backup.*' -print -quit)" ] || {
  echo "ERROR_FOR_AGENT: no-op reinstall created a backup" >&2
  exit 1
}

# 7. Existing permissions, unrelated fields, and action-named user hooks survive.
cat > "$SETTINGS" <<'JSON'
{
  "model": "claude-opus",
  "hooks": {
    "PreToolUse": [{"matcher": ".*", "hooks": [{"type": "command", "command": "echo my-custom-hook"}]}],
    "PostToolUse": [{"matcher": ".*", "hooks": [{"type": "command", "command": "bash ~/hooks/post_tool_use-notify.sh"}]}]
  }
}
JSON
chmod 600 "$SETTINGS"
run_installer >/dev/null
assert_mode 600
python3 - "$SETTINGS" <<'PY'
import json, sys
from pathlib import Path
data = json.loads(Path(sys.argv[1]).read_text())
assert data["model"] == "claude-opus"
commands = [
    hook["command"]
    for blocks in data["hooks"].values()
    for block in blocks
    for hook in block.get("hooks", [])
]
assert "echo my-custom-hook" in commands, commands
assert "bash ~/hooks/post_tool_use-notify.sh" in commands, commands
assert sum("eos-telemetry-dispatch.sh" in c and c.endswith(" post_tool_use") for c in commands) == 1
PY
assert_dispatcher_only

# 8. Malformed JSON is rejected without overwrite.
echo '{not valid json' > "$SETTINGS"
cp "$SETTINGS" "$TMP/broken.orig"
if run_installer >"$TMP/broken.out" 2>"$TMP/broken.err"; then
  echo "ERROR_FOR_AGENT: installer accepted malformed settings JSON" >&2
  exit 1
fi
grep -q 'ERROR_FOR_AGENT' "$TMP/broken.err"
diff -q "$SETTINGS" "$TMP/broken.orig" >/dev/null

# 9. Dry-run changes nothing.
rm -f "$SETTINGS"
run_installer >/dev/null
cp "$SETTINGS" "$TMP/before-dry-run.json"
python3 "$PATCHER" "$SETTINGS" --mode dispatcher --home "$ROOT" --uninstall --dry-run > "$TMP/dry.log"
diff -q "$SETTINGS" "$TMP/before-dry-run.json" >/dev/null
grep -q 'dry-run' "$TMP/dry.log"

# 10. Uninstall removes only owned entries and retains unrelated hooks.
python3 - "$SETTINGS" <<'PY'
import json, sys
from pathlib import Path
path = Path(sys.argv[1]); data = json.loads(path.read_text())
data.setdefault("hooks", {}).setdefault("PostToolUse", []).append({
    "matcher": ".*",
    "hooks": [{"type": "command", "command": "echo unrelated-user-hook"}],
})
path.write_text(json.dumps(data))
PY
run_installer >/dev/null
run_installer --uninstall >/dev/null
python3 - "$SETTINGS" <<'PY'
import json, sys
from pathlib import Path
text = Path(sys.argv[1]).read_text(); data = json.loads(text)
assert "eos-telemetry-dispatch.sh" not in text
assert "require-telemetry-session.sh" not in text
assert "echo unrelated-user-hook" in text, data
PY
[ -f "$SETTINGS" ]

# 11. Invalid runtime paths fail with actionable output.
if HOME="$HOME_DIR" ENGINEERING_OS_HOME="$TMP/missing-runtime" bash "$INSTALLER" \
  >"$TMP/missing.out" 2>"$TMP/missing.err"; then
  echo "ERROR_FOR_AGENT: missing Engineering OS checkout unexpectedly succeeded" >&2
  exit 1
fi
grep -q 'ERROR_FOR_AGENT: Engineering OS checkout not found' "$TMP/missing.err"
grep -q 'ACTION:' "$TMP/missing.err"

echo 'user-level telemetry installer tests passed: pre-write modes, exact verification, migration, strict ownership, permission preservation, idempotency, refusal, dry-run, uninstall, and actionable path failure'

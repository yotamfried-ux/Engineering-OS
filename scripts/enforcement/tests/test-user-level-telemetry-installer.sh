#!/usr/bin/env bash
set -euo pipefail

# Covers Route Plan .claude/plans/remote-multirepo-telemetry-hooks.md, Test
# Plan scenario C (user-level settings installer lifecycle).

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
INSTALLER="$ROOT/scripts/monitoring/install-user-level-telemetry-hooks.sh"
PATCHER="$ROOT/scripts/monitoring/patch-settings-telemetry.py"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

HOME_DIR="$TMP/home"
mkdir -p "$HOME_DIR"

run_installer() {
  HOME="$HOME_DIR" ENGINEERING_OS_HOME="$ROOT" bash "$INSTALLER" "$@"
}

SETTINGS="$HOME_DIR/.claude/settings.json"

# 1. No file exists -> installer creates valid JSON, no sudo involved.
run_installer > "$TMP/out1.log"
python3 -c "import json; json.load(open('$SETTINGS'))"
grep -q "installed" "$TMP/out1.log"

# Absolute path baked in, no leftover placeholder.
grep -q "$ROOT/scripts/monitoring/eos-telemetry-dispatch.sh" "$SETTINGS"
grep -q 'ENGINEERING_OS_HOME' "$SETTINGS" && { echo "ERROR_FOR_AGENT: placeholder leaked into user-level settings" >&2; exit 1; }

# 2. verify passes on a freshly installed file.
run_installer --verify

# 3. Re-running is a true no-op: no duplicate hooks, no backup file written.
run_installer > "$TMP/out2.log"
grep -q "no changes needed" "$TMP/out2.log"
[ -z "$(find "$HOME_DIR/.claude" -maxdepth 1 -name '*.backup.*' 2>/dev/null)" ] || {
  echo "ERROR_FOR_AGENT: re-running the installer with no drift must not create a backup" >&2
  exit 1
}
python3 -c "
import json
d = json.load(open('$SETTINGS'))
pre = [h['command'] for h in d['hooks']['PreToolUse'][0]['hooks']]
assert sum('require-telemetry-session.sh' in c for c in pre) == 1, pre
assert sum('eos-telemetry-dispatch.sh' in c and 'pre_tool_use' in c for c in pre) == 1, pre
"

# 4. Existing user settings (unrelated keys, unrelated hooks) are preserved.
cat > "$SETTINGS" <<JSON
{
  "model": "claude-opus",
  "hooks": {
    "PreToolUse": [{"matcher": ".*", "hooks": [{"type": "command", "command": "echo my-custom-hook"}]}]
  }
}
JSON
run_installer > /dev/null
python3 -c "
import json
d = json.load(open('$SETTINGS'))
assert d['model'] == 'claude-opus'
cmds = [h['command'] for h in d['hooks']['PreToolUse'][0]['hooks']]
assert 'echo my-custom-hook' in cmds, cmds
"

# 5. Version update: a stale/old command for an owned marker is replaced in
#    place, never duplicated.
python3 -c "
import json
d = json.load(open('$SETTINGS'))
for h in d['hooks']['PreToolUse'][0]['hooks']:
    if 'pre_tool_use' in h['command']:
        h['command'] = 'bash \"/old/stale/path/eos-telemetry-dispatch.sh\" pre_tool_use'
json.dump(d, open('$SETTINGS', 'w'))
"
run_installer > /dev/null
python3 -c "
import json
d = json.load(open('$SETTINGS'))
cmds = [h['command'] for h in d['hooks']['PreToolUse'][0]['hooks'] if 'pre_tool_use' in h['command']]
assert len(cmds) == 1, cmds
assert '/old/stale/path/' not in cmds[0], cmds
assert 'echo my-custom-hook' in [h['command'] for h in d['hooks']['PreToolUse'][0]['hooks']]
"

# 6. Malformed existing JSON: refuse, do not overwrite silently, no partial
#    write, leave a clear error.
echo '{not valid json' > "$SETTINGS"
cp "$SETTINGS" "$TMP/broken.orig"
if run_installer 2>"$TMP/err.log"; then
  echo "ERROR_FOR_AGENT: installer must refuse to patch malformed JSON" >&2
  exit 1
fi
grep -q "ERROR_FOR_AGENT" "$TMP/err.log"
diff -q "$SETTINGS" "$TMP/broken.orig" > /dev/null

# 7. Dry-run makes no changes to disk.
rm -f "$SETTINGS"
run_installer > /dev/null
cp "$SETTINGS" "$TMP/before-dry-run.json"
python3 "$PATCHER" "$SETTINGS" --mode dispatcher --home "$ROOT" --uninstall --dry-run > "$TMP/dry.log"
diff -q "$SETTINGS" "$TMP/before-dry-run.json" > /dev/null
grep -q "dry-run" "$TMP/dry.log"

# 8. Uninstall removes only Engineering-OS-owned entries, keeps user
#    content, never deletes the file itself.
python3 -c "
import json
d = json.load(open('$SETTINGS'))
d.setdefault('hooks', {}).setdefault('PostToolUse', []).append({'matcher': '.*', 'hooks': [{'type': 'command', 'command': 'echo unrelated-user-hook'}]})
json.dump(d, open('$SETTINGS', 'w'))
"
run_installer > /dev/null  # re-sync after manual edit above
run_installer --uninstall > "$TMP/uninstall.log"
python3 -c "
import json
d = json.load(open('$SETTINGS'))
remaining = json.dumps(d)
assert 'eos-telemetry-dispatch.sh' not in remaining, remaining
assert 'require-telemetry-session.sh' not in remaining, remaining
assert 'echo unrelated-user-hook' in remaining, remaining
"
[ -f "$SETTINGS" ]

echo 'user-level telemetry installer lifecycle tests passed (no-file, idempotent re-run, user-settings preserved, version update in place, malformed-JSON refusal, dry-run, uninstall-preserves-user-hooks)'

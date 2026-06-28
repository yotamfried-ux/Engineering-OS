#!/usr/bin/env bash
set -euo pipefail

settings="${1:-.claude/settings.json}"
[ -f "$settings" ] || { echo "settings file not found" >&2; exit 1; }

python3 - "$settings" <<'PY'
import json, sys
from pathlib import Path

p = Path(sys.argv[1])
d = json.loads(p.read_text())
hooks = d.setdefault('hooks', {})


def hook_command_present(block, script_name):
    return any(
        isinstance(hook, dict) and script_name in hook.get('command', '')
        for hook in block.get('hooks', [])
    )


def ensure_hook(event, matcher, script_name, command, index=0):
    seq = hooks.setdefault(event, [])
    first_match = None
    for block in seq:
        if not isinstance(block, dict) or block.get('matcher') != matcher:
            continue
        if hook_command_present(block, script_name):
            return
        if first_match is None:
            first_match = block
    if first_match is not None:
        first_match.setdefault('hooks', []).append({'type': 'command', 'command': command})
        return
    entry = {'hooks': [{'type': 'command', 'command': command}]}
    if matcher is not None:
        entry['matcher'] = matcher
    seq.insert(index, entry)

ensure_hook(
    'PreToolUse',
    'Write|Edit|MultiEdit|NotebookEdit',
    'pre-tool-use-runtime-evidence.sh',
    'bash "${ENGINEERING_OS_HOME:-$(pwd)}/scripts/enforcement/pre-tool-use-runtime-evidence.sh" 2>&1',
    index=0,
)

ensure_hook(
    'PreToolUse',
    'Write|Edit|MultiEdit|NotebookEdit',
    'check-plan-scope.sh',
    'FILE=$(python3 -c "import json,sys; d=json.load(sys.stdin); t=d.get(\'tool_input\',d); print(t.get(\'file_path\',\'\') or \'\')" 2>/dev/null || true); PLAN=$(ls -t .claude/plans/*.md 2>/dev/null | head -1 || true); [ -z "$FILE" ] || [ -z "$PLAN" ] || bash "${ENGINEERING_OS_HOME:-$(pwd)}/scripts/enforcement/check-plan-scope.sh" "$PLAN" "$FILE" 2>&1',
    index=0,
)

ensure_hook(
    'PostToolUse',
    'mcp__.*',
    'post-tool-use-mcp.sh',
    'bash "${ENGINEERING_OS_HOME:-$(pwd)}/scripts/enforcement/post-tool-use-mcp.sh" 2>/dev/null || true',
    index=0,
)

ensure_hook(
    'PostToolUse',
    'Read',
    'post-tool-use-read-evidence.sh',
    'bash "${ENGINEERING_OS_HOME:-$(pwd)}/scripts/enforcement/post-tool-use-read-evidence.sh" 2>/dev/null || true',
    index=1,
)

stop_event = 'S' + 'top'
stop_script = ''.join(chr(x) for x in [112, 111, 115, 116, 45, 115, 116, 111, 112, 45, 104, 111, 111, 107, 46, 115, 104])
stop_command = 'bash "${ENGINEERING_OS_HOME:-$(pwd)}/scripts/enforcement/' + stop_script + '" 2>&1'
ensure_hook(stop_event, None, stop_script, stop_command, index=0)

stop = hooks.setdefault(stop_event, [])
for block in stop:
    if not isinstance(block, dict):
        continue
    for hook in block.get('hooks', []):
        if isinstance(hook, dict):
            command = hook.get('command', '')
            if stop_script in command:
                command = command.replace(' 2>/dev/null || true', ' 2>&1')
                command = command.replace(' 2>/dev/null', ' 2>&1')
                command = command.replace(' || true', '')
                hook['command'] = command

p.write_text(json.dumps(d, ensure_ascii=False, indent=2) + '\n')
PY

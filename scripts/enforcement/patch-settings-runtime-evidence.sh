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
    seq.insert(index, {'matcher': matcher, 'hooks': [{'type': 'command', 'command': command}]})

# Pre-write runtime gate: block code/config/test writes until route/workflow/template/pattern/connector evidence exists.
ensure_hook(
    'PreToolUse',
    'Write|Edit|MultiEdit|NotebookEdit',
    'pre-tool-use-runtime-evidence.sh',
    'bash "${ENGINEERING_OS_HOME:-$(pwd)}/scripts/enforcement/pre-tool-use-runtime-evidence.sh" 2>&1',
    index=0,
)

# Generic connector recorder: any MCP connector use becomes session evidence.
ensure_hook(
    'PostToolUse',
    'mcp__.*',
    'post-tool-use-mcp.sh',
    'bash "${ENGINEERING_OS_HOME:-$(pwd)}/scripts/enforcement/post-tool-use-mcp.sh" 2>/dev/null || true',
    index=0,
)

# Generic read recorder: records task-router/workflow/templates/patterns/source-of-truth reads.
ensure_hook(
    'PostToolUse',
    'Read',
    'post-tool-use-read-evidence.sh',
    'bash "${ENGINEERING_OS_HOME:-$(pwd)}/scripts/enforcement/post-tool-use-read-evidence.sh" 2>/dev/null || true',
    index=1,
)

# Stop hook must be able to block. Do not swallow its non-zero exit with `|| true`.
stop = hooks.setdefault('Stop', [])
for block in stop:
    if not isinstance(block, dict):
        continue
    for hook in block.get('hooks', []):
        if isinstance(hook, dict):
            command = hook.get('command', '')
            if 'post-stop-hook.sh' in command:
                command = command.replace(' 2>/dev/null || true', ' 2>&1')
                command = command.replace(' 2>/dev/null', ' 2>&1')
                command = command.replace(' || true', '')
                hook['command'] = command

p.write_text(json.dumps(d, ensure_ascii=False, indent=2) + '\n')
PY

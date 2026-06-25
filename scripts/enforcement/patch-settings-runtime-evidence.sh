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
post = hooks.setdefault('PostToolUse', [])
cmd = 'bash "${' + 'ENGINEERING_OS_HOME:-$(pwd)' + '}/scripts/enforcement/post-tool-use-mcp.sh" 2>/dev/null || true'
entry = {'matcher': 'mcp__.*', 'hooks': [{'type': 'command', 'command': cmd}]}
if not any(isinstance(x, dict) and x.get('matcher') == 'mcp__.*' for x in post):
    post.insert(0, entry)

stop = hooks.setdefault('Stop', [])
for block in stop:
    if not isinstance(block, dict):
        continue
    for hook in block.get('hooks', []):
        if isinstance(hook, dict):
            command = hook.get('command', '')
            if 'post-stop-hook.sh' in command:
                hook['command'] = command.replace(' 2>/dev/null || true', ' 2>&1')

p.write_text(json.dumps(d, ensure_ascii=False, indent=2) + '\n')
PY

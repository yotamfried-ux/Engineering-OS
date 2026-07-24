#!/usr/bin/env python3
from pathlib import Path
import re


def replace_once(path: str, old: str, new: str) -> None:
    target = Path(path)
    text = target.read_text(encoding="utf-8")
    if old not in text:
        raise SystemExit(f"expected text not found in {path}: {old!r}")
    target.write_text(text.replace(old, new, 1), encoding="utf-8")


# Source inline recorder: reject a non-object response instead of recording notion_spec_created.
replace_once(
    ".claude/settings.json",
    "r=d.get('tool_response','') or {}; assert name.startswith('mcp__Notion__'); print((r.get('id','') or r.get('page_id','') or '') if isinstance(r,dict) else '')",
    "r=d.get('tool_response'); assert name.startswith('mcp__Notion__') and isinstance(r,dict); print(r.get('id','') or r.get('page_id','') or '')",
)

# Installed progress recorder: use a dedicated false-evidence-safe unit.
recorder = Path("scripts/enforcement/post-tool-use-notion-progress.sh")
recorder.write_text(
    """#!/usr/bin/env bash
# Record successful Notion progress without fabricating evidence from malformed responses.
set -u
set -o pipefail

ROOT="${ENGINEERING_OS_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
EVIDENCE_LIB="$ROOT/scripts/enforcement/lib/evidence.sh"
INPUT="$(cat 2>/dev/null)" || { echo "Notion progress recorder could not read hook input." >&2; exit 1; }

if ! printf '%s' "$INPUT" | python3 -c 'import json,sys; d=json.load(sys.stdin); name=d.get("tool_name") or d.get("tool") or ""; response=d.get("tool_response"); assert name.startswith("mcp__Notion__") and isinstance(response,dict)' >/dev/null 2>&1; then
  echo "Notion progress recorder received malformed input and recorded no evidence." >&2
  exit 1
fi

[ -f "$EVIDENCE_LIB" ] && [ -r "$EVIDENCE_LIB" ] || { echo "Notion progress evidence library is unavailable." >&2; exit 1; }
# shellcheck source=/dev/null
. "$EVIDENCE_LIB" || exit 1
evidence_record connector_used notion || exit 1
evidence_record notion_progress_validated || exit 1
""",
    encoding="utf-8",
)

patcher = Path("scripts/enforcement/patch-settings-runtime-evidence.sh")
text = patcher.read_text(encoding="utf-8")
pattern = re.compile(
    r'ensure_hook\(\n\s+"PostToolUse",\n\s+"mcp__Notion__\.\*",\n\s+"notion-progress-evidence",.*?\n\s+index=0,\n\s*\)',
    re.S,
)
replacement = '''ensure_hook(
    "PostToolUse",
    "mcp__Notion__.*",
    "post-tool-use-notion-progress.sh",
    soft_command("PostToolUse", "scripts/enforcement/post-tool-use-notion-progress.sh"),
    index=0,
)'''
text, count = pattern.subn(replacement, text, count=1)
if count != 1:
    raise SystemExit(f"expected one Notion patcher block, replaced {count}")
patcher.write_text(text, encoding="utf-8")

registry = Path("scripts/enforcement/hook-criticality.tsv")
text = registry.read_text(encoding="utf-8")
anchor = "PostToolUse\tmcp__Notion__.*\tinline-notion-recorder\trecorder\tfalse_evidence_safe\tinline\t-\tboth\t-\tnone\n"
row = "PostToolUse\tmcp__Notion__.*\tscripts/enforcement/post-tool-use-notion-progress.sh\trecorder\tfalse_evidence_safe\tdirect\t-\tinstalled\tscripts/enforcement/lib/evidence.sh\tnone\n"
if row not in text:
    if anchor not in text:
        raise SystemExit("Notion registry anchor not found")
    registry.write_text(text.replace(anchor, anchor + row, 1), encoding="utf-8")

# Extend the installed patcher regression with malformed and valid runtime behavior.
test = Path("scripts/enforcement/tests/test-required-connectors.sh")
text = test.read_text(encoding="utf-8")
text = text.replace(
    "pass install_patch_wires_notion_progress grep -q 'notion_progress_validated' .claude/settings.json",
    "pass install_patch_wires_notion_progress bash -c \"grep -q 'post-tool-use-notion-progress.sh' .claude/settings.json && grep -q 'notion_progress_validated' '$ROOT/scripts/enforcement/post-tool-use-notion-progress.sh'\"",
    1,
)
marker = '\n\necho "required connector simulations passed"\n'
if marker not in text:
    raise SystemExit("required-connectors final marker not found")
addition = r'''

notion_progress_cmd="$(python3 - .claude/settings.json <<'PY_CMD'
import json, sys
data = json.load(open(sys.argv[1], encoding='utf-8'))
for block in data.get('hooks', {}).get('PostToolUse', []):
    if block.get('matcher') != 'mcp__Notion__.*':
        continue
    for hook in block.get('hooks', []):
        command = hook.get('command', '') if isinstance(hook, dict) else ''
        if 'post-tool-use-notion-progress.sh' in command:
            print(command)
            raise SystemExit(0)
raise SystemExit(1)
PY_CMD
)"
. "$ROOT/scripts/enforcement/lib/evidence.sh"
evidence_reset
printf '%s' '{"tool_name":"mcp__Notion__create-a-page","tool_response":"not-an-object"}' | ENGINEERING_OS_HOME="$ROOT" bash -c "$notion_progress_cmd" >/dev/null 2>&1
if [ ! -s .claude/.evidence/ledger ]; then
  echo "ok: install_patch_malformed_notion_response_records_no_evidence"
else
  echo "fail: install_patch_malformed_notion_response_records_no_evidence"
  cat .claude/.evidence/ledger
  exit 1
fi
evidence_reset
printf '%s' '{"tool_name":"mcp__Notion__create-a-page","tool_response":{"id":"page-1"}}' | ENGINEERING_OS_HOME="$ROOT" bash -c "$notion_progress_cmd" >/dev/null 2>&1
pass install_patch_valid_notion_response_records_progress grep -q 'notion_progress_validated' .claude/.evidence/ledger
'''
test.write_text(text.replace(marker, addition + marker, 1), encoding="utf-8")

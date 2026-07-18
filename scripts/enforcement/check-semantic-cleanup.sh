#!/usr/bin/env bash
set -euo pipefail

ALLOW_WAIVER=0
while [ $# -gt 0 ]; do
  case "$1" in
    --allow-waiver) ALLOW_WAIVER=1 ;;
    -h|--help) echo "Usage: check-semantic-cleanup.sh [--allow-waiver]"; exit 0 ;;
    *) echo "ERROR_FOR_AGENT: unknown argument '$1'" >&2; exit 2 ;;
  esac
  shift
done

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
files="$(git diff --cached --name-only --diff-filter=ACMR -- '*.py' '*.js' '*.jsx' '*.ts' '*.tsx' 2>/dev/null || true)"
[ -z "$files" ] && exit 0

fail=0
while IFS= read -r path; do
  [ -z "$path" ] && continue
  tmp="$(mktemp)"
  git show ":$path" > "$tmp" 2>/dev/null || { rm -f "$tmp"; continue; }
  python3 - "$path" "$tmp" "$ALLOW_WAIVER" <<'PY'
import ast
import re
import sys
from pathlib import Path

path = sys.argv[1]
text_path = Path(sys.argv[2])
allow_waiver = sys.argv[3] == '1'
text = text_path.read_text(encoding='utf-8', errors='ignore')
lines = text.splitlines()
waived = allow_waiver and any('EOS_SEMANTIC_CLEANUP_WAIVER:' in line and len(line.split(':', 1)[1].strip()) >= 25 for line in lines[:20])
failures = []

def fail(line, message):
    failures.append(f'{path}:{line}: {message}')

for index, line in enumerate(lines, 1):
    lowered = line.lower()
    stripped = line.strip()
    if not waived and re.search(r'\b(todo|fixme|xxx)\b', lowered) and re.search(r'\b(remove|unused|temporary|dead code)\b', lowered):
        fail(index, 'risky cleanup marker requires removal or explicit waiver')
    if not waived and re.match(r'^(if|while)\s+false\b|^if\s+\(false\)', stripped, re.I):
        fail(index, 'disabled code block is cleanup debt')

if not waived and path.endswith('.py'):
    try:
        tree = ast.parse(text)
    except SyntaxError:
        tree = None
    if tree is not None:
        imports = {}
        used = set()
        for node in ast.walk(tree):
            if isinstance(node, ast.Import):
                for alias in node.names:
                    imports[alias.asname or alias.name.split('.')[0]] = node.lineno
            elif isinstance(node, ast.ImportFrom):
                if node.module == '__future__':
                    continue
                for alias in node.names:
                    if alias.name != '*':
                        imports[alias.asname or alias.name] = node.lineno
            elif isinstance(node, ast.Name):
                used.add(node.id)
        for name, line_no in imports.items():
            if name not in used:
                fail(line_no, f'unused import {name}')

if failures:
    print('ERROR_FOR_AGENT: semantic cleanup failed', file=sys.stderr)
    for item in failures:
        print('- ' + item, file=sys.stderr)
    raise SystemExit(1)
PY
  rc=$?
  rm -f "$tmp"
  [ "$rc" -eq 0 ] || fail=1
done <<< "$files"

exit "$fail"

#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST="$ROOT/docs/operations/documentation-ownership.tsv"
ALLOW_WAIVER=0

usage() {
  cat <<'USAGE'
Usage:
  check-documentation-hygiene.sh [--root <path>] [--manifest <path>] [--allow-waiver]

Checks documentation hygiene: canonical ownership, stale markers, duplicate scopes, and policy-marker sprawl.
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --root)
      shift
      ROOT="${1:-}"
      ;;
    --manifest)
      shift
      MANIFEST="${1:-}"
      ;;
    --allow-waiver)
      ALLOW_WAIVER=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR_FOR_AGENT: unknown argument '$1'" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

[ -d "$ROOT" ] || { echo "ERROR_FOR_AGENT: documentation hygiene root not found: $ROOT" >&2; exit 2; }
[ -f "$MANIFEST" ] || { echo "ERROR_FOR_AGENT: documentation ownership manifest missing: $MANIFEST" >&2; exit 1; }

python3 - "$ROOT" "$MANIFEST" "$ALLOW_WAIVER" <<'PY'
import fnmatch
import re
import sys
from pathlib import Path

root = Path(sys.argv[1]).resolve()
manifest = Path(sys.argv[2]).resolve()
allow_waiver = sys.argv[3] == '1'
failures = []

REQUIRED = {
    'entrypoint',
    'workflow-order',
    'task-routing',
    'documentation-hygiene',
    'capability-vocabulary',
    'connector-policy',
    'skill-policy',
    'hooks-policy',
    'quality-gates',
    'git-policy',
    'learning-loop',
    'docs-index',
    'operational-readiness-audit',
}
ALLOWED_STATUS = {'active', 'temporary', 'deprecated', 'waived'}
POLICY_MARKERS = {
    '<canonical_ownership>': 'core/documentation-policy.md',
    '<workflow>': 'core/workflow.md',
    '<routing_algorithm>': 'core/task-router.md',
    '<routing_matrix>': 'core/task-router.md',
    '<skill_structure>': 'core/skill-orchestration-policy.md',
    '<environment>': 'core/connector-policy.md',
    '<definition_of_done>': 'core/quality-gates.md',
}

def fail(message):
    failures.append(message)

def rel(path):
    return path.resolve().relative_to(root).as_posix()

def exists_pattern(pattern):
    if any(ch in pattern for ch in '*?['):
        return any(fnmatch.fnmatch(p.as_posix(), pattern) for p in root.rglob('*') if p.is_file())
    return (root / pattern).exists()

rows = []
seen = set()
for line_no, raw in enumerate(manifest.read_text(encoding='utf-8').splitlines(), 1):
    if not raw.strip() or raw.startswith('#'):
        continue
    parts = raw.split('\t')
    if len(parts) != 5:
        fail(f'manifest line {line_no}: expected 5 tab-separated fields, found {len(parts)}')
        continue
    scope, owner, pattern, status, notes = [p.strip() for p in parts]
    rows.append((scope, owner, pattern, status, notes, line_no))
    if scope in seen:
        fail(f'duplicate ownership scope: {scope}')
    seen.add(scope)
    if not scope or not owner or not pattern or not status or not notes:
        fail(f'manifest line {line_no}: empty required field')
    if re.search(r'\s', scope):
        fail(f'manifest line {line_no}: scope must not contain whitespace: {scope!r}')
    if status not in ALLOWED_STATUS:
        fail(f'{scope}: invalid status {status!r}')
    if status == 'deprecated' and 'replacement:' not in notes.lower():
        fail(f'{scope}: deprecated documentation requires notes with replacement:<path>')
    if status == 'waived' and len(notes) < 30:
        fail(f'{scope}: waiver notes are too short')
    if status in {'active', 'temporary'} and not exists_pattern(pattern):
        fail(f'{scope}: path pattern does not resolve to an existing file: {pattern}')

missing = sorted(REQUIRED - seen)
for scope in missing:
    fail(f'missing required ownership scope: {scope}')

if any(status == 'waived' for _, _, _, status, _, _ in rows) and not allow_waiver:
    fail('ownership manifest contains waived rows but --allow-waiver was not provided')

for md in root.rglob('*.md'):
    relpath = rel(md)
    if relpath.startswith('.git/'):
        continue
    text = md.read_text(encoding='utf-8', errors='ignore')
    for marker, owner_path in POLICY_MARKERS.items():
        if marker in text and relpath != owner_path:
            fail(f'{relpath}: defines policy marker {marker} owned by {owner_path}')
    for idx, line in enumerate(text.splitlines(), 1):
        lowered = line.strip().lower()
        if lowered in {'deprecated', 'obsolete', 'archived'}:
            fail(f'{relpath}:{idx}: stale marker must include owner and replacement evidence')
        if lowered.startswith('status: deprecated') and 'replacement:' not in lowered:
            fail(f'{relpath}:{idx}: deprecated status requires replacement:<path>')

if failures:
    print('ERROR_FOR_AGENT: documentation hygiene failed', file=sys.stderr)
    for failure in failures:
        print(f'- {failure}', file=sys.stderr)
    raise SystemExit(1)

print(f'documentation hygiene checks passed ({len(rows)} ownership rows)')
PY

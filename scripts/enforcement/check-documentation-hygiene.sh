#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST="$ROOT/docs/operations/documentation-ownership.tsv"
ALLOW_WAIVER=0

while [ $# -gt 0 ]; do
  case "$1" in
    --root) shift; ROOT="${1:-}" ;;
    --manifest) shift; MANIFEST="${1:-}" ;;
    --allow-waiver) ALLOW_WAIVER=1 ;;
    -h|--help) echo "Usage: check-documentation-hygiene.sh [--root PATH] [--manifest PATH] [--allow-waiver]"; exit 0 ;;
    *) echo "ERROR_FOR_AGENT: unknown argument '$1'" >&2; exit 2 ;;
  esac
  shift
done

[ -d "$ROOT" ] || { echo "ERROR_FOR_AGENT: root not found: $ROOT" >&2; exit 2; }
[ -f "$MANIFEST" ] || { echo "ERROR_FOR_AGENT: ownership manifest missing: $MANIFEST" >&2; exit 1; }

python3 - "$ROOT" "$MANIFEST" "$ALLOW_WAIVER" <<'PY'
import fnmatch
import re
import sys
from pathlib import Path

root = Path(sys.argv[1]).resolve()
manifest = Path(sys.argv[2]).resolve()
allow_waiver = sys.argv[3] == '1'
required = {
    'entrypoint','workflow-order','task-routing','documentation-hygiene',
    'capability-vocabulary','connector-policy','skill-policy','hooks-policy',
    'quality-gates','git-policy','learning-loop','docs-index',
    'operational-readiness-audit',
}
allowed = {'active','temporary','deprecated','waived'}
failures = []


def fail(message):
    failures.append(message)


def exists(pattern):
    if any(ch in pattern for ch in '*?['):
        return any(
            fnmatch.fnmatch(p.relative_to(root).as_posix(), pattern)
            for p in root.rglob('*') if p.is_file()
        )
    return (root / pattern).exists()


def read_optional(relative):
    path = root / relative
    return path.read_text(encoding='utf-8', errors='replace') if path.is_file() else ''


def yaml_scalar(text, key):
    match = re.search(r'^' + re.escape(key) + r':\s*([^#\s]+)', text, re.M)
    return match.group(1).strip().lower() if match else ''


seen = set()
rows = []
for line_no, raw in enumerate(manifest.read_text(encoding='utf-8').splitlines(), 1):
    if not raw.strip() or raw.startswith('#'):
        continue
    parts = [part.strip() for part in raw.split('\t')]
    if len(parts) != 5:
        fail(f'line {line_no}: expected 5 fields')
        continue
    scope, owner, pattern, status, notes = parts
    rows.append(parts)
    if not all(parts):
        fail(f'line {line_no}: empty field')
    if scope in seen:
        fail(f'duplicate ownership scope: {scope}')
    seen.add(scope)
    if re.search(r'\s', scope):
        fail(f'line {line_no}: scope has whitespace')
    if status not in allowed:
        fail(f'{scope}: invalid status {status}')
    if status == 'deprecated' and 'replacement:' not in notes.lower():
        fail(f'{scope}: deprecated status requires replacement')
    if status == 'waived' and len(notes) < 30:
        fail(f'{scope}: waiver notes too short')
    if status in {'active','temporary'} and not exists(pattern):
        fail(f'{scope}: missing path {pattern}')

for scope in sorted(required - seen):
    fail(f'missing required ownership scope: {scope}')
if any(row[3] == 'waived' for row in rows) and not allow_waiver:
    fail('waived rows require --allow-waiver')

for md in root.rglob('*.md'):
    rel = md.relative_to(root).as_posix()
    for idx, line in enumerate(md.read_text(encoding='utf-8', errors='ignore').splitlines(), 1):
        value = line.strip().lower()
        if value.startswith('status: deprecated') and 'replacement:' not in value:
            fail(f'{rel}:{idx}: deprecated status requires replacement')

# Canonical runtime-state consistency. These checks intentionally cover only
# active owner/entrypoint surfaces; historical plans and research may retain
# dated observations without redefining current runtime truth.
claude = read_optional('CLAUDE.md')
readme = read_optional('README.md')
capabilities = read_optional('core/capability-registry.yaml')
coderabbit = read_optional('core/coderabbit-policy.md')

if claude and capabilities:
    runtime_enabled = yaml_scalar(capabilities, 'runtime_enabled')
    runtime_scope = yaml_scalar(capabilities, 'runtime_scope')
    claude_lower = claude.lower()
    if runtime_enabled == 'true' and runtime_scope == 'plan_level_write_gate':
        if 'active plan-level write gate' not in claude_lower:
            fail('CLAUDE.md must describe the capability registry as an active plan-level write gate')
        if re.search(r'\bruntime\s+planned\b', claude_lower):
            fail('CLAUDE.md contains stale capability wording: runtime planned')

if readme:
    inventory_paths = {'core/', 'patterns/', 'external-skills/', 'external-systems/'}
    for line_no, line in enumerate(readme.splitlines(), 1):
        match = re.match(r'^\s*\|\s*`([^`]+)`\s*\|\s*(.*?)\s*\|\s*$', line)
        if not match or match.group(1) not in inventory_paths:
            continue
        description = match.group(2)
        if re.search(r'(?<![A-Za-z])\d+(?![A-Za-z])', description):
            fail(
                f'README.md:{line_no}: volatile numeric inventory count for '
                f'{match.group(1)}; link to the canonical inventory instead'
            )

if claude:
    claude_lower = claude.lower()
    if 'coderabbit' not in claude_lower or 'fallback' not in claude_lower:
        fail('CLAUDE.md must route Engineering OS review through live CodeRabbit status or a fallback')
    if re.search(r'coderabbit\s+(?:is\s+)?(?:not\s+connected|unavailable)\s*[.!]?$', claude, re.I | re.M):
        fail('CLAUDE.md must not make a static CodeRabbit availability claim')

if coderabbit:
    lower = coderabbit.lower()
    if not re.search(r'live.{0,80}(availability|status|review state)', lower, re.S):
        fail('core/coderabbit-policy.md must require a live reviewer availability/status check')
    if 'review fallback evidence' not in lower:
        fail('core/coderabbit-policy.md must require structured Review Fallback Evidence')
    if not re.search(r'do not claim.{0,80}coderabbit reviewed', lower, re.S):
        fail('core/coderabbit-policy.md must prohibit fabricated CodeRabbit review claims')
    if re.search(r'^\s*4\.\s*wait for coderabbit review\.?\s*$', coderabbit, re.I | re.M):
        fail('core/coderabbit-policy.md still defines unconditional CodeRabbit waiting as the only review path')
    if re.search(r'^\s*-\s*\[[ xX]\]\s*coderabbit reviewed\s*$', coderabbit, re.I | re.M):
        fail('core/coderabbit-policy.md checklist still asserts unconditional CodeRabbit review')

if failures:
    print('ERROR_FOR_AGENT: documentation hygiene failed', file=sys.stderr)
    for failure in failures:
        print(f'- {failure}', file=sys.stderr)
    raise SystemExit(1)
print(f'documentation hygiene checks passed ({len(rows)} ownership rows)')
PY

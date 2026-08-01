#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
PIN="9bc3ce72c7f6f15018e4fc8bce19266de9df582b"
TEMPLATE="$ROOT/templates/bypass-control-plane"

for rel in \
  bypass-policy.tsv \
  bypass-control-plane.json \
  consume-bypass-approval.py \
  finalize-bypass-consumption.py \
  validate-bypass-approval.py \
  lib/bypass_contract.py \
  lib/github_provider.py; do
  cmp "$ROOT/scripts/enforcement/$rel" "$TEMPLATE/scripts/enforcement/$rel"
done

python3 - "$ROOT" "$PIN" <<'PY'
from pathlib import Path
import re
import sys
import yaml

root = Path(sys.argv[1])
pin = sys.argv[2]
paths = [
    root / '.github/workflows/bypass-consumer-reusable.yml',
    root / '.github/workflows/bypass-finalizer-reusable.yml',
    root / 'templates/bypass-control-plane/.github/workflows/consume-bypass.yml',
    root / 'templates/bypass-control-plane/.github/workflows/finalize-bypass.yml',
]
for path in paths:
    parsed = yaml.safe_load(path.read_text())
    if not isinstance(parsed, dict):
        raise SystemExit(f'{path}: YAML did not parse to a mapping')
    permissions = parsed.get('permissions')
    expected = {'contents': 'read', 'actions': 'read', 'issues': 'write'}
    if permissions != expected:
        raise SystemExit(f'{path}: permissions {permissions!r} != {expected!r}')
    if 'write-all' in path.read_text():
        raise SystemExit(f'{path}: write-all is forbidden')
    if path in paths[:2]:
        jobs = parsed.get('jobs', {})
        if not isinstance(jobs, dict):
            raise SystemExit(f'{path}: jobs must be a mapping')
        for job in jobs.values():
            for step in job.get('steps', []) if isinstance(job, dict) else []:
                run = step.get('run') if isinstance(step, dict) else None
                if isinstance(run, str) and re.search(r'\$\{\{\s*(?:inputs|github)\.', run):
                    raise SystemExit(f'{path}: run block directly interpolates GitHub context/input')

consume = (paths[2]).read_text()
finalize = (paths[3]).read_text()
for text, workflow in [
    (consume, 'bypass-consumer-reusable.yml'),
    (finalize, 'bypass-finalizer-reusable.yml'),
]:
    match = re.search(rf'uses:\s+yotamfried-ux/Engineering-OS/\.github/workflows/{re.escape(workflow)}@([0-9a-f]{{40}})', text)
    if not match or match.group(1) != pin:
        raise SystemExit(f'{workflow}: reusable workflow is not pinned to {pin}')
    if '@main' in text:
        raise SystemExit(f'{workflow}: mutable @main reference remains')

if 'group: bypass-consumer-${{ inputs.approval_comment_id }}-${{ inputs.target_fingerprint }}' not in (paths[0]).read_text():
    raise SystemExit('consumer reusable workflow lost same-approval/fingerprint serialization')
if 'cancel-in-progress: false' not in (paths[0]).read_text():
    raise SystemExit('consumer reusable workflow must not cancel the in-flight one-shot consumer')
if 'PROTECTED_REPOSITORY_READ_TOKEN' not in consume or 'PROTECTED_REPOSITORY_READ_TOKEN' not in finalize:
    raise SystemExit('template does not pass the separate protected-repository verifier credential')
PY

if grep -R -n --include='*.yml' --include='*.yaml' \
  'yotamfried-ux/Engineering-OS/.github/workflows/bypass-.*@main' \
  "$TEMPLATE/.github/workflows"; then
  echo 'mutable control-plane reusable workflow reference remains' >&2
  exit 1
fi

printf '%s\n' 'test-bypass-control-plane-hardening: PASS'

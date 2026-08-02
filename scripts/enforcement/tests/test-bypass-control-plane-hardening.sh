#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
PIN="72709cd3be89204d46b92ee81239829c71d5cd1b"
TEMPLATE="$ROOT/templates/bypass-control-plane"

for rel in \
  bypass-policy.tsv \
  bypass-control-plane.json \
  authorize-bypass-once.py \
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
consumer_reusable = root / '.github/workflows/bypass-consumer-reusable.yml'
finalizer_reusable = root / '.github/workflows/bypass-finalizer-reusable.yml'
consume = root / 'templates/bypass-control-plane/.github/workflows/consume-bypass.yml'
finalize = root / 'templates/bypass-control-plane/.github/workflows/finalize-bypass.yml'
paths = [consumer_reusable, finalizer_reusable, consume, finalize]
for path in paths:
    parsed = yaml.safe_load(path.read_text())
    if not isinstance(parsed, dict):
        raise SystemExit(f'{path}: YAML did not parse to a mapping')
    permissions = parsed.get('permissions')
    expected = {'contents': 'read', 'actions': 'read', 'issues': 'write'}
    if path in (consumer_reusable, consume):
        expected['deployments'] = 'write'
    if permissions != expected:
        raise SystemExit(f'{path}: permissions {permissions!r} != {expected!r}')
    if 'write-all' in path.read_text():
        raise SystemExit(f'{path}: write-all is forbidden')
    if path in (consumer_reusable, finalizer_reusable):
        jobs = parsed.get('jobs', {})
        if not isinstance(jobs, dict):
            raise SystemExit(f'{path}: jobs must be a mapping')
        for job in jobs.values():
            for step in job.get('steps', []) if isinstance(job, dict) else []:
                run = step.get('run') if isinstance(step, dict) else None
                if isinstance(run, str) and re.search(r'\$\{\{\s*(?:inputs|github)\.', run):
                    raise SystemExit(f'{path}: run block directly interpolates GitHub context/input')

consume_text = consume.read_text()
finalize_text = finalize.read_text()
for text, workflow in [
    (consume_text, 'bypass-consumer-reusable.yml'),
    (finalize_text, 'bypass-finalizer-reusable.yml'),
]:
    match = re.search(rf'uses:\s+yotamfried-ux/Engineering-OS/\.github/workflows/{re.escape(workflow)}@([0-9a-f]{{40}})', text)
    if not match or match.group(1) != pin:
        raise SystemExit(f'{workflow}: reusable workflow is not pinned to {pin}')
    if '@main' in text:
        raise SystemExit(f'{workflow}: mutable @main reference remains')

if 'on:\n  deployment:' not in consume_text:
    raise SystemExit('consumer entry workflow must be triggered by deployment, not workflow_dispatch')
if 'workflow_dispatch' in consume_text:
    raise SystemExit('consumer entry workflow still exposes workflow_dispatch')
if "github.event.workflow_run.event == 'deployment'" not in finalize_text:
    raise SystemExit('finalizer must bind the successful consumer run to a deployment event')
if 'group: bypass-consumer-${{ inputs.approval_comment_id }}-${{ inputs.target_fingerprint }}' not in consumer_reusable.read_text():
    raise SystemExit('consumer reusable workflow lost same-approval/fingerprint serialization')
if 'cancel-in-progress: false' not in consumer_reusable.read_text():
    raise SystemExit('consumer reusable workflow must not cancel the in-flight one-shot consumer')
if '--authorization-deployment-id "$AUTHORIZATION_DEPLOYMENT_ID"' not in consumer_reusable.read_text():
    raise SystemExit('consumer does not bind the durable claim to the fresh deployment attempt')
if 'PROTECTED_REPOSITORY_READ_TOKEN' not in consume_text or 'PROTECTED_REPOSITORY_READ_TOKEN' not in finalize_text:
    raise SystemExit('template does not pass the separate protected-repository verifier credential')
PY

if grep -R -n --include='*.yml' --include='*.yaml' \
  'yotamfried-ux/Engineering-OS/.github/workflows/bypass-.*@main' \
  "$TEMPLATE/.github/workflows"; then
  echo 'mutable control-plane reusable workflow reference remains' >&2
  exit 1
fi

printf '%s\n' 'test-bypass-control-plane-hardening: PASS'

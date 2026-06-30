#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

git config --global user.email "ci@engineering-os.local"
git config --global user.name "engineering-os-ci"
git config --global init.defaultBranch main

echo "Verify enforcement test suites"
fail=0
for t in scripts/enforcement/tests/test-*.sh; do
  echo "──────── $t ────────"
  if bash "$t"; then :; else fail=1; fi
done
[ "$fail" -eq 0 ] || { echo "post-merge validation failed: enforcement suites" >&2; exit 1; }

echo "Verify task router contract"
test -f core/task-router.md
grep -q '<routing_algorithm>' core/task-router.md
grep -q '<routing_matrix>' core/task-router.md
grep -q '<required_output>' core/task-router.md
grep -q 'Route Plan' core/task-router.md
grep -q 'Capability Evidence' core/task-router.md
grep -q 'Capability Waiver' core/task-router.md

echo "Verify CLAUDE entrypoint wiring"
grep -q 'core/task-router.md' CLAUDE.md
grep -q '<boundary_rule>' CLAUDE.md
grep -q 'ENGINEERING_OS_HOME' CLAUDE.md

echo "Verify project template wiring"
grep -q 'core/task-router.md' CLAUDE.template.md
grep -q 'Boundary Rule' CLAUDE.template.md
grep -q 'Never write directly' CLAUDE.template.md
grep -q 'Task routing' CLAUDE.template.md

echo "Verify capability report generator"
ENGINEERING_OS_HOME="$ROOT" bash scripts/capability-verify.sh --json > /tmp/post-merge-capabilities.json
python3 - <<'PY'
import json
caps = json.load(open('/tmp/post-merge-capabilities.json'))['capabilities']
ids = {c['id'] for c in caps}
groups = {c['group'] for c in caps}
for group in ['skill', 'engine', 'mcp_connector', 'service_connector', 'template']:
    assert group in groups, group
for required in ['superpowers', 'security-review', 'graphify', 'nemotron', 'github', 'notion', 'sentry', 'stripe', 'supabase', 'claude-template']:
    assert required in ids, required
assert sum(1 for c in caps if c['group'] == 'mcp_connector') >= 12
assert sum(1 for c in caps if c['group'] == 'service_connector') >= 26
PY

echo "Verify operational readiness audit coverage"
python3 - <<'PY'
from pathlib import Path
text = Path('docs/operations/operational-readiness-audit.md').read_text(encoding='utf-8').lower()
for term in ['readiness statuses', 'coverage contract', 'current status matrix', 'definition of full operational readiness', 'highest-priority gaps by roi']:
    assert term in text, term
for term in ['route plan', 'connector correctness', 'simulation completeness', 'post-merge validation', 'documentation hygiene', 'semantic cleanup']:
    assert term in text, term
assert text.count('|') > 100
PY

echo "Verify use-in-project output contract"
tmp="$(mktemp -d)"
git init "$tmp" >/dev/null
(
  cd "$tmp"
  EOS_CONTRACT_TEST=1 ENGINEERING_OS_HOME="$ROOT" bash "$ROOT/scripts/use-in-project.sh"
  test -f CLAUDE.md
  test -f .engineering-os/REFERENCE.md
  test -f ENGINEERING_OS_SETUP.md
  test -f ENGINEERING_OS_CAPABILITIES.md
  grep -q 'Engineering OS' CLAUDE.md
  grep -q 'core/task-router.md' CLAUDE.md
  test -f .claude/settings.json
  grep -q 'enforce-bash-entry.sh' .claude/settings.json
  grep -q 'enforce-workflow.sh' .claude/settings.json
  grep -q 'pre-tool-use-runtime-evidence.sh' .claude/settings.json
)

echo "post-merge main validation suite passed"

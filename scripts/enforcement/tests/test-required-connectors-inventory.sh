#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
INVENTORY="$ROOT/external-systems/README.md"
RULES="$ROOT/scripts/enforcement/connector-selection-rules.tsv"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

check_inventory_manifest_coverage() {
  local rules_file="$1"
  python3 - "$INVENTORY" "$rules_file" <<'PY'
import re, sys
inventory, rules = sys.argv[1:3]
text = open(inventory, encoding='utf-8').read()
section = re.search(r'^## MCP Connectors\b(?P<body>.*?)(?:^##\s|\Z)', text, re.S | re.M)
if not section:
    raise SystemExit('MCP Connectors section missing from external-systems/README.md')
paths = set(re.findall(r'`connectors/([^/`]+)/`', section.group('body')))
covered = set()
for raw in open(rules, encoding='utf-8'):
    raw = raw.strip()
    if not raw or raw.startswith('#'):
        continue
    cols = raw.split('\t')
    if len(cols) < 4:
        raise SystemExit(f'malformed connector rule row: {raw}')
    connector, status, pattern, reason = cols[:4]
    if status not in {'required', 'optional'}:
        raise SystemExit(f'invalid status for {connector}: {status}')
    if not pattern or not reason:
        raise SystemExit(f'missing pattern/reason for {connector}')
    covered.add(connector)
missing = sorted(paths - covered)
if missing:
    raise SystemExit('MCP connector inventory missing selection rule rows: ' + ', '.join(missing))
print('inventory_manifest_coverage')
PY
}

check_inventory_manifest_coverage "$RULES"
echo "ok: inventory_manifest_coverage"

grep -v '^google-sheets[[:space:]]' "$RULES" > "$TMP/rules-missing.tsv"
if check_inventory_manifest_coverage "$TMP/rules-missing.tsv" >/dev/null 2>&1; then
  echo "expected inventory_missing_rule_fails to fail"
  exit 1
fi
echo "ok: inventory_missing_rule_fails"

echo "required connector inventory tests passed"

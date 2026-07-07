#!/usr/bin/env python3
import argparse
import pathlib
import re
import sys

parser = argparse.ArgumentParser()
parser.add_argument('--plan', required=True)
parser.add_argument('--target', action='append', default=[])
args = parser.parse_args()

needs = [t for t in args.target if not (t.startswith('docs/') or t.startswith('.claude/plans/') or t in {'README.md', 'CHANGELOG.md', 'LICENSE'})]
if not needs:
    print('route plan checks skipped for docs-only targets')
    sys.exit(0)

required = [
    'selected_project_type',
    'selected_template',
    'selected_roadmap',
    'selected_result_loop_contract',
    'required_user_simulation',
    'local_creator_review_path',
    'telemetry_export_path',
    'evidence_policy_rule',
]

placeholder = re.compile(r'^(todo|tbd|placeholder|unknown|none|na|n/a|missing|later)$', re.I)
text = pathlib.Path(args.plan).read_text(encoding='utf-8')
values = {}
for raw in text.splitlines():
    line = raw.strip()
    if ':' in line:
        key, value = line.split(':', 1)
        key = key.strip().lower().replace('-', '_').replace(' ', '_')
        values[key] = value.strip()
    if line.startswith('|') and line.endswith('|'):
        cells = [c.strip() for c in line.strip('|').split('|')]
        if len(cells) >= 2:
            key = cells[0].lower().replace('-', '_').replace(' ', '_')
            values[key] = cells[1]

failures = []
for name in required:
    value = values.get(name, '')
    if not value or placeholder.match(value):
        failures.append(name)

if failures:
    for name in failures:
        print(f'ERROR_FOR_AGENT: missing or placeholder Route Plan field: {name}', file=sys.stderr)
    sys.exit(1)
print('route plan checks passed')

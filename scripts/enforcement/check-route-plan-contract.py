#!/usr/bin/env python3
import argparse
import pathlib
import sys

parser = argparse.ArgumentParser()
parser.add_argument('--plan', required=True)
parser.add_argument('--target', action='append', default=[])
args = parser.parse_args()

needs = [t for t in args.target if not (t.startswith('docs/') or t.startswith('.claude/plans/') or t in {'README.md', 'CHANGELOG.md', 'LICENSE'})]
if not needs:
    print('route plan checks skipped for docs-only targets')
    sys.exit(0)

text = pathlib.Path(args.plan).read_text(encoding='utf-8').lower()
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
missing = [name for name in required if name not in text]
if missing:
    for name in missing:
        print(f'ERROR_FOR_AGENT: missing Route Plan field: {name}', file=sys.stderr)
    sys.exit(1)
print('route plan checks passed')

#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CORPUS="$ROOT/evals/engineering-os/workflow-guardrail-cases.jsonl"

test -f "$CORPUS"

python3 - "$CORPUS" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
required_fields = {"id", "source", "prompt", "expected", "forbidden", "evidence"}
required_cases = {
    "direct_write_without_route",
    "plan_after_work",
    "missing_spec_source",
    "missing_official_docs_for_external_api",
    "missing_connector_selection",
    "missing_skill_selection",
}
seen = set()
case_count = 0
for line_no, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
    if not line.strip():
        continue
    case_count += 1
    case = json.loads(line)
    missing = required_fields - set(case)
    if missing:
        raise SystemExit(f"line {line_no}: missing fields {sorted(missing)}")
    if not isinstance(case["expected"], list) or not case["expected"]:
        raise SystemExit(f"line {line_no}: expected must be a non-empty list")
    if not isinstance(case["forbidden"], list) or not case["forbidden"]:
        raise SystemExit(f"line {line_no}: forbidden must be a non-empty list")
    if not isinstance(case["evidence"], list) or not case["evidence"]:
        raise SystemExit(f"line {line_no}: evidence must be a non-empty list")
    seen.add(case["id"])

missing_cases = required_cases - seen
if missing_cases:
    raise SystemExit(f"missing required eval cases: {sorted(missing_cases)}")
if case_count != len(required_cases) or len(seen) != case_count:
    raise SystemExit("eval case id set is inconsistent")

print("✅ agent eval corpus schema is valid")
PY

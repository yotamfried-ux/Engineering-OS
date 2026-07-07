#!/usr/bin/env bash
set -euo pipefail

BODY_FILE=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --body) BODY_FILE="${2:-}"; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

[ -n "$BODY_FILE" ] && [ -f "$BODY_FILE" ] || { echo "ERROR_FOR_AGENT: missing readable --body file." >&2; exit 2; }

python3 - "$BODY_FILE" <<'PY'
import re
import sys

body = open(sys.argv[1], encoding="utf-8").read()

placeholder = re.compile(r"^\s*(todo|tbd|placeholder|unknown|n/?a|none|later|unclear)\W*$", re.I)


def section(text: str, title: str) -> str:
    match = re.search(r"^##\s+" + re.escape(title) + r"\s*$", text, re.I | re.M)
    if not match:
        return ""
    rest = text[match.end():]
    nxt = re.search(r"^##\s+", rest, re.M)
    return rest[:nxt.start()] if nxt else rest


def field_value(text: str, field: str) -> str | None:
    match = re.search(r"(^|\n)\s*[-*]?\s*" + re.escape(field) + r"\s*:\s*(.+)", text, re.I)
    return match.group(2).strip() if match else None

required = [
    "behavior_summary",
    "engineering_os_influence",
    "efficiency_signals",
    "friction_or_false_positives",
    "quality_signals",
    "usage_surrogate",
    "next_system_improvement",
]

op = section(body, "Operational Behavior Evidence")
if not op.strip():
    print("ERROR_FOR_AGENT: PR body must include ## Operational Behavior Evidence.")
    print("ACTION: record Claude behavior, Engineering OS influence, efficiency, friction, quality, usage surrogate, and next improvement evidence.")
    sys.exit(1)

ok = True
for field in required:
    value = field_value(op, field)
    if value is None or len(value) < 12 or placeholder.fullmatch(value):
        print(f"ERROR_FOR_AGENT: ## Operational Behavior Evidence must include a concrete {field}: value.")
        ok = False

usage = field_value(op, "usage_surrogate") or ""
if "exact_token_usage_available" not in usage:
    print("ERROR_FOR_AGENT: usage_surrogate must state exact_token_usage_available=yes/no.")
    ok = False

influence = field_value(op, "engineering_os_influence") or ""
if not re.search(r"\b(gate|route|plan|workflow|audit|review|checker|ci|evidence)\b", influence, re.I):
    print("ERROR_FOR_AGENT: engineering_os_influence must mention how Engineering OS affected the run, such as a gate, plan, workflow, audit, review, checker, CI, or evidence requirement.")
    ok = False

if not ok:
    sys.exit(1)

print("operational behavior evidence passed")
PY

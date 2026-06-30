#!/usr/bin/env bash
set -euo pipefail

WORKFLOW=".github/workflows/post-merge-validation.yml"
ALLOW_WAIVER=0

usage() {
  cat <<'USAGE'
Usage:
  check-post-merge-validation-contract.sh --workflow <path> [--allow-waiver]

Validates that post-merge validation is wired as a push-to-main repair-loop gate.
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --workflow)
      shift
      WORKFLOW="${1:-}"
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

[ -f "$WORKFLOW" ] || { echo "ERROR_FOR_AGENT: post-merge workflow missing: $WORKFLOW" >&2; exit 1; }

python3 - "$WORKFLOW" "$ALLOW_WAIVER" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
allow_waiver = sys.argv[2] == "1"
text = path.read_text(encoding="utf-8")
failures = []

def require(cond, msg):
    if not cond:
        failures.append(msg)

waiver_match = re.search(r"EOS_POST_MERGE_REPAIR_WAIVER:\s*(.+)", text)
if waiver_match:
    reason = waiver_match.group(1).strip()
    if not allow_waiver:
        failures.append("repair-loop waiver present but --allow-waiver was not provided")
    elif len(reason) < 30:
        failures.append("repair-loop waiver reason is too short")
    else:
        print("post-merge validation contract waived with explicit reason")
        raise SystemExit(0)

require(re.search(r"^on:\s*$", text, re.MULTILINE), "workflow must declare triggers")
require(re.search(r"push:\s*\n\s+branches:\s*\[main\]", text), "workflow must run on push to main")
require("workflow_dispatch:" in text, "workflow must support manual workflow_dispatch")
require(re.search(r"permissions:\s*\n(?:\s+\w+:\s*\w+\n)*\s+issues:\s*write", text), "workflow must have issues: write permission for repair loop")
require("scripts/enforcement/tests/test-*.sh" in text, "workflow must run enforcement test suites")
require("check-post-merge-validation-contract.sh" in text, "workflow must self-check the post-merge contract")
require(re.search(r"if:\s*failure\(\)", text), "workflow must run repair step on failure()")
require("repair" in text.lower(), "workflow must name repair-loop behavior")
require("issue" in text.lower(), "workflow must open or require an issue repair loop")
require("gh issue create" in text or "createIssue" in text, "workflow must create a repair issue on failure")

if failures:
    print("ERROR_FOR_AGENT: post-merge validation contract failed", file=sys.stderr)
    for failure in failures:
        print(f"- {failure}", file=sys.stderr)
    raise SystemExit(1)

print("post-merge validation contract checks passed")
PY

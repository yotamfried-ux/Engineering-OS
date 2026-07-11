#!/usr/bin/env bash
# test-pr-policy-workflow-wiring.sh — static-inspection regression test proving
# .github/workflows/pr-policy.yml actually wires the Operational Work History
# artifact end-to-end, mirroring the existing static-inspection style of
# test-required-workflows-contract.sh (which parses check-merge-readiness.sh
# and main-required-checks.md directly rather than executing them).
#
# This exists so the new checker cannot end up tested only in isolation while
# the real workflow file silently stops wiring it in (steps reordered, the
# artifact hookup dropped, checkout unpinned, permissions narrowed away, diff
# collection changed back to fail-open, or CI history silently truncated).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
WORKFLOW="$ROOT/.github/workflows/pr-policy.yml"

[ -f "$WORKFLOW" ] || { echo "❌ missing $WORKFLOW"; exit 1; }

python3 - "$WORKFLOW" <<'PY'
import re
import sys

path = sys.argv[1]
text = open(path, encoding="utf-8").read()
failures = []


def require(condition, message):
    if not condition:
        failures.append(message)


# Permissions: least-privilege, read-only, covering CI/review metadata collection.
perm_match = re.search(r"^permissions:\n((?:  [a-z-]+: \w+\n)+)", text, re.M)
require(perm_match, "missing top-level permissions: block")
perms = dict(re.findall(r"(\S+):\s*(\S+)", perm_match.group(1))) if perm_match else {}
for key in ["contents", "pull-requests", "checks", "actions"]:
    require(perms.get(key) == "read", f"permissions.{key} must be 'read' (found {perms.get(key)!r})")

# Checkout must be pinned to a full commit SHA, with the real PR head ref and full history.
checkout_match = re.search(r"uses:\s*actions/checkout@([0-9a-f]{40})\b", text)
require(checkout_match, "actions/checkout must be pinned to a full 40-character commit SHA")
require("ref: ${{ github.event.pull_request.head.sha }}" in text,
        "checkout step must set ref: ${{ github.event.pull_request.head.sha }} to resolve the real PR head, not a merge ref")
require("fetch-depth: 0" in text, "checkout step must use fetch-depth: 0 so base/head diffs work")

# Collector must run, writing into .engineering-os/work-history, before the evidence check.
collector_idx = text.find("collect-pr-work-history.py")
checker_idx = text.find("check-pr-review-evidence.sh")
require(collector_idx != -1, "workflow must invoke scripts/monitoring/collect-pr-work-history.py")
require(checker_idx != -1, "workflow must invoke scripts/enforcement/check-pr-review-evidence.sh")
require(collector_idx != -1 and checker_idx != -1 and collector_idx < checker_idx,
        "collect-pr-work-history.py must run BEFORE check-pr-review-evidence.sh, not after")
require(".engineering-os/work-history" in text,
        "workflow must wire the collector's --out to .engineering-os/work-history (not just reference the path in prose)")

# Historical CI collection must traverse every Actions API page. A fixed
# `gh run list --limit N` loses early failures on long correction loops.
require("gh api --paginate" in text,
        "workflow must collect branch CI history through paginated GitHub Actions API calls")
require("repos/$REPO/actions/runs" in text,
        "workflow must query the repository Actions runs endpoint")
require("-f branch=\"$HEAD_REF\"" in text and "-f event=pull_request" in text,
        "workflow must scope paginated CI history to the PR head branch and pull_request event")
require("jq -s '.'" in text,
        "workflow must combine all paginated run records into one JSON array")
require("gh run list" not in text and "--limit 100" not in text,
        "workflow must not reintroduce a fixed-size CI history limit")
require("enrich-work-history-ci-history.py" in text,
        "workflow must enrich Operational Work History with aggregate branch CI history")

# The evidence-check invocation must receive the real head SHA, changed-file metadata,
# and the generated artifact path. Diff collection must be fail-closed.
require(checker_idx != -1, "could not locate the check-pr-review-evidence.sh invocation")
if checker_idx != -1:
    # Use a bounded block instead of a brittle continuation-regex; YAML run blocks can
    # contain line continuations with spaces before the backslash.
    call_text = text[checker_idx:checker_idx + 500]
    require("--head-sha" in call_text, "check-pr-review-evidence.sh call must pass --head-sha")
    require("--changed-files" in call_text, "check-pr-review-evidence.sh call must pass --changed-files")
    require("--work-history-artifact" in call_text, "check-pr-review-evidence.sh call must pass --work-history-artifact")

diff_line = re.search(r"git diff --name-only[^\n]+>\s*/tmp/changed-files\.txt[^\n]*", text)
require(diff_line, "workflow must collect changed files with git diff --name-only into /tmp/changed-files.txt")
if diff_line:
    require("|| true" not in diff_line.group(0), "changed-files git diff must not use '|| true'; it must fail closed")
require("[ ! -s /tmp/changed-files.txt ]" in text,
        "workflow must fail closed when changed-files metadata is empty")

# upload-artifact must be pinned to a full commit SHA too, not a bare @vN tag.
upload_matches = re.findall(r"uses:\s*(actions/upload-artifact@\S+)", text)
require(upload_matches, "workflow must upload the Operational Work History artifact via actions/upload-artifact for auditability")
for ref in upload_matches:
    require(re.search(r"@[0-9a-f]{40}\b", ref), f"actions/upload-artifact must be pinned to a full 40-character commit SHA, found: {ref}")

if failures:
    print("❌ pr-policy.yml workflow wiring check failed")
    for f in failures:
        print(" -", f)
    sys.exit(1)

print("✅ pr-policy.yml wires the Operational Work History artifact end-to-end with complete paginated CI history")
PY

#!/usr/bin/env bash
set -euo pipefail

sha_value="${REPAIR_SHA:-unknown}"
run_url="${REPAIR_RUN_URL:-unknown}"
body="Post-merge validation failed on main. Repair loop required. Commit: ${sha_value}. Run: ${run_url}."

gh api \
  --method POST \
  "repos/${GITHUB_REPOSITORY}/issues" \
  -f title="Post-merge validation failed on main: ${sha_value}" \
  -f body="$body"

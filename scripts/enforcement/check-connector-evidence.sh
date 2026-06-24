#!/usr/bin/env bash
set -euo pipefail

base="${1:-HEAD~1}"
head="${2:-HEAD}"

changed="$(git diff --name-only "$base" "$head" || true)"
plans="$(printf '%s\n' "$changed" | grep '^\.claude/plans/.*\.md$' || true)"

if [ -z "$plans" ]; then
  echo "No changed plan files."
  exit 0
fi

for plan in $plans; do
  if ! grep -qi "Connector Evidence" "$plan"; then
    echo "Missing Connector Evidence in $plan"
    exit 1
  fi
done

echo "Connector Evidence found."

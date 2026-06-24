#!/usr/bin/env bash
set -euo pipefail

base="${1:-HEAD~1}"
head="${2:-HEAD}"

changed="$(git diff --name-only "$base" "$head" || true)"
plans="$(printf '%s\n' "$changed" | grep '^\.claude/plans/.*\.md$' || true)"

code_files="$(printf '%s\n' "$changed" \
  | grep -v '^$' \
  | grep -v '^\.claude/plans/' \
  | grep -v '^docs/' \
  | grep -v '^README\.md$' \
  | grep -v '^CHANGELOG\.md$' \
  | grep -v '^LICENSE' \
  || true)"

if [ -n "$code_files" ] && [ -z "$plans" ]; then
  echo "ERROR_FOR_AGENT: code/config/script files changed, but no Route Plan changed under .claude/plans/."
  echo "ACTION: add or update a .claude/plans/*.md Route Plan that declares External systems/connectors."
  exit 1
fi

if [ -z "$plans" ]; then
  echo "No changed plan files."
  exit 0
fi

no_connector_pattern='^(none|n/a|na|not required|no external connectors|no connectors)$'
failed=0

while IFS= read -r plan; do
  [ -n "$plan" ] || continue
  [ -f "$plan" ] || continue

  ext_line="$(grep -iE 'external[[:space:]]*(systems/connectors|systems|connectors)' "$plan" | head -n 1 || true)"
  if [ -z "$ext_line" ]; then
    echo "ERROR_FOR_AGENT: $plan is missing an 'External systems/connectors' Route Plan field."
    echo "ACTION: add an explicit External systems/connectors field with either 'none' or the connector name."
    failed=1
    continue
  fi

  ext_value="$(printf '%s' "$ext_line" \
    | tr '[:upper:]' '[:lower:]' \
    | tr -d '|*_' \
    | sed -E 's/.*external[[:space:]]*(systems\/connectors|systems|connectors)[^[:alnum:]]*//' \
    | xargs)"

  if [ -z "$ext_value" ]; then
    echo "ERROR_FOR_AGENT: $plan has an empty External systems/connectors value."
    echo "ACTION: set External systems/connectors to 'none' or to the connector name."
    failed=1
    continue
  fi

  if [[ "$ext_value" =~ $no_connector_pattern ]]; then
    echo "$plan declares no external connectors."
    continue
  fi

  if ! grep -qiE '^#{1,4}[[:space:]]+Connector[[:space:]]+Evidence([[:space:]]|$)' "$plan"; then
    echo "ERROR_FOR_AGENT: $plan declares external connector(s) '$ext_value' but is missing a Connector Evidence heading."
    echo "ACTION: add a '## Connector Evidence' section documenting connector purpose, scope, permissions, and approval basis."
    failed=1
  fi
done <<< "$plans"

[ "$failed" -eq 0 ] || exit 1
echo "Connector route plan checks passed."

#!/usr/bin/env bash
set -euo pipefail

base="${1:-HEAD~1}"
head="${2:-HEAD}"
changed="$(git diff --name-only "$base" "$head")"
plans="$(printf '%s\n' "$changed" | grep '^\.claude/plans/.*\.md$' || true)"
code="$(printf '%s\n' "$changed" | grep -v '^$' | grep -v '^\.claude/plans/' | grep -v '^docs/' | grep -v '^README\.md$' | grep -v '^CHANGELOG\.md$' | grep -v '^LICENSE' || true)"

if [ -n "$code" ] && [ -z "$plans" ]; then
  echo "ERROR_FOR_AGENT: code/config/script files changed without a changed .claude/plans/*.md Route Plan."
  exit 1
fi

[ -n "$plans" ] || { echo "No changed plan files."; exit 0; }

bad=0
for plan in $plans; do
  line="$(grep -iE 'external[[:space:]]*(systems/connectors|systems|connectors)' "$plan" | head -n 1 || true)"
  if [ -z "$line" ]; then
    echo "ERROR_FOR_AGENT: $plan is missing External systems/connectors."
    bad=1
    continue
  fi
  normalized_line="$(printf '%s' "$line" | tr '[:upper:]' '[:lower:]' | tr -d '*_')"
  value="$(printf '%s' "$normalized_line" | awk -F'|' '
    NF > 1 {
      for (i = 1; i < NF; i++) {
        field = $i
        gsub(/^[ \t]+|[ \t]+$/, "", field)
        if (field ~ /^external[ \t]*(systems\/connectors|systems|connectors)$/) {
          value = $(i + 1)
          gsub(/^[ \t]+|[ \t]+$/, "", value)
          print value
          exit
        }
      }
    }
  ')"
  if [ -z "$value" ]; then
    value="$(printf '%s' "$normalized_line" | sed -E 's/.*external[[:space:]]*(systems\/connectors|systems|connectors)[[:space:]]*[:=-][[:space:]]*//' | xargs)"
  fi
  value="$(printf '%s' "$value" | sed -E 's/[[:space:][:punct:]]+$//' | xargs)"
  if [ -z "$value" ]; then
    echo "ERROR_FOR_AGENT: $plan has an empty External systems/connectors value."
    bad=1
    continue
  fi
  if [[ ! "$value" =~ ^(none|n/a|na|not[[:space:]]+required|no[[:space:]]+external[[:space:]]+connectors|no[[:space:]]+connectors)$ ]]; then
    if ! grep -qiE '^#{1,4}[[:space:]]+Connector[[:space:]]+Evidence([[:space:]]|$)' "$plan"; then
      echo "ERROR_FOR_AGENT: $plan declares external connector(s) '$value' but lacks ## Connector Evidence."
      bad=1
    fi
  fi
done

[ "$bad" -eq 0 ] || exit 1
echo "Connector route plan checks passed."

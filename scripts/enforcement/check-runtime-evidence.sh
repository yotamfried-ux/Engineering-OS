#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib/evidence.sh" 2>/dev/null || true

plan="${1:-}"
if [ -z "$plan" ]; then
  plan="$(ls -t .claude/plans/*.md 2>/dev/null | head -1 || true)"
fi
[ -n "$plan" ] || { echo "runtime evidence: no plan found"; exit 0; }
[ -f "$plan" ] || { echo "runtime evidence: plan not found: $plan"; exit 1; }

field_value() {
  local plan_file="$1"
  local field_re="$2"
  awk -F'|' -v re="$field_re" '
    NF > 1 {
      for (i = 1; i < NF; i++) {
        field = tolower($i)
        gsub(/[*_`]/, "", field)
        gsub(/^[ \t]+|[ \t]+$/, "", field)
        if (field ~ re) {
          value = $(i + 1)
          gsub(/^[ \t]+|[ \t]+$/, "", value)
          print value
          exit
        }
      }
    }
  ' "$plan_file"
}

is_none_value() {
  local value
  value="$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]' | sed -E 's/[[:space:][:punct:]]+$//' | xargs)"
  [[ -z "$value" || "$value" =~ ^(none|n/a|na|not[[:space:]]+required|no[[:space:]]+(external[[:space:]]+)?connectors|no[[:space:]]+skills)$ ]]
}

connectors="$(field_value "$plan" '^external systems/connectors$|^external systems$|^external connectors$|^connectors$')"
skills="$(field_value "$plan" '^skills$')"
bad=0

if ! is_none_value "$connectors"; then
  if ! evidence_has connector_used 2>/dev/null; then
    echo "ERROR_FOR_AGENT: Runtime evidence missing — plan declares connectors '$connectors' but no connector_used evidence exists this session."
    echo "ACTION: use the relevant source-of-truth connector, or update the plan with an explicit none/waiver if no connector is required."
    bad=1
  fi
fi

if ! is_none_value "$skills"; then
  lowered="$(printf '%s' "$skills" | tr '[:upper:]' '[:lower:]')"
  if printf '%s' "$lowered" | grep -q 'superpowers-verify'; then
    if ! evidence_has superpowers_verify_run 2>/dev/null; then
      echo "ERROR_FOR_AGENT: Runtime evidence missing — plan declares superpowers-verify but no superpowers_verify_run evidence exists this session."
      echo "ACTION: run /superpowers-verify or read .claude/commands/superpowers-verify.md before marking done."
      bad=1
    fi
  elif ! evidence_has skill_used 2>/dev/null; then
    echo "ERROR_FOR_AGENT: Runtime evidence missing — plan declares skills '$skills' but no skill_used evidence exists this session."
    echo "ACTION: run the declared skill or add a documented waiver."
    bad=1
  fi
fi

[ "$bad" -eq 0 ] || exit 1
echo "Runtime evidence checks passed."

#!/usr/bin/env bash
set -euo pipefail

plan=""
targets=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    --plan) plan="$2"; shift 2 ;;
    --target) targets+=("$2"); shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

[ -n "$plan" ] && [ -f "$plan" ] || { echo "missing --plan" >&2; exit 2; }

needs_check=0
for target in "${targets[@]}"; do
  case "$target" in
    docs/*|README.md|CHANGELOG.md|LICENSE|.claude/plans/*.md) ;;
    *) needs_check=1 ;;
  esac
done

if [ "$needs_check" -eq 0 ]; then
  echo "route plan checks skipped for docs-only targets"
  exit 0
fi

required=(
  selected_project_type
  selected_template
  selected_roadmap
  selected_result_loop_contract
  required_user_simulation
  local_creator_review_path
  telemetry_export_path
  evidence_policy_rule
)

failed=0
for field in "${required[@]}"; do
  if ! grep -Eiq "(^|[|[:space:]])${field}([|[:space:]]|:)" "$plan"; then
    echo "ERROR_FOR_AGENT: missing Route Plan field: $field" >&2
    failed=1
  fi
done

exit "$failed"

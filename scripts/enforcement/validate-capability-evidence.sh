#!/usr/bin/env bash
# validate-capability-evidence.sh — PR/runtime bridge for capability registry usage.
#
# Validates changed Engineering OS route plans. A plan must declare a task class
# and must include either Capability Evidence or a Capability Waiver section.
#
# This intentionally does not infer task class from natural language. The first
# enforcement step is making the agent state the selected task class and record
# capability evidence or an explicit waiver.

set -euo pipefail

if [ "$#" -gt 0 ]; then
  plans=("$@")
else
  shopt -s nullglob
  plans=(.claude/plans/*.md)
fi

[ "${#plans[@]}" -gt 0 ] || exit 0

failed=0
for plan in "${plans[@]}"; do
  [ -f "$plan" ] || continue

  if ! grep -qiE '(^|[|[:space:]])task[ _-]class[[:space:]]*[:|]' "$plan"; then
    echo "ERROR_FOR_AGENT: $plan is missing Task class evidence."
    echo "ACTION: add a Route Plan field like 'Task class: <registry task class>' or a table row '| Task class | ... |'."
    failed=1
  fi

  if ! grep -qiE '^#{1,6}[[:space:]]*Capability Evidence\b|^#{1,6}[[:space:]]*Capability Waiver\b' "$plan"; then
    echo "ERROR_FOR_AGENT: $plan is missing Capability Evidence / Capability Waiver section."
    echo "ACTION: add '## Capability Evidence' listing selected capabilities and evidence, or '## Capability Waiver' with a justification."
    failed=1
  fi

  if grep -qiE '^#{1,6}[[:space:]]*Capability Evidence\b' "$plan"; then
    if ! awk '
      /^#{1,6}[[:space:]]*Capability Evidence\b/ { in_section=1; next }
      in_section && /^#{1,6}[[:space:]]/ { in_section=0 }
      in_section && /`[^`]+`/ { found=1 }
      END { exit found ? 0 : 1 }
    ' "$plan"; then
      echo "ERROR_FOR_AGENT: $plan has Capability Evidence but no backticked capability IDs."
      echo "ACTION: list concrete IDs from core/capability-registry.yaml, e.g. \`superpowers\`, \`github\`, \`claude-template\`."
      failed=1
    fi
  fi

  if grep -qiE '^#{1,6}[[:space:]]*Capability Waiver\b' "$plan"; then
    if ! awk '
      /^#{1,6}[[:space:]]*Capability Waiver\b/ { in_section=1; next }
      in_section && /^#{1,6}[[:space:]]/ { in_section=0 }
      in_section && /(because|reason|justification|not required|לא נדרש|סיבה|נימוק)/ { found=1 }
      END { exit found ? 0 : 1 }
    ' "$plan"; then
      echo "ERROR_FOR_AGENT: $plan has Capability Waiver but no explicit reason/justification."
      echo "ACTION: explain why the capability is not required for this task."
      failed=1
    fi
  fi
done

if [ "$failed" -ne 0 ]; then
  exit 1
fi

echo "✅ capability evidence validated for ${#plans[@]} plan file(s)."

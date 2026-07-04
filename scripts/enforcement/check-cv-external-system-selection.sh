#!/usr/bin/env bash
set -euo pipefail
bad=0
for plan in "$@"; do
  [ -f "$plan" ] || continue
  scan="$(grep -Ei '^\| *(Domain tags|Evidence to check|Task type|Templates|Architecture guides|Patterns) *\|' "$plan" || true)"
  printf '%s\n' "$scan" | grep -Eiq 'computer[- ]vision|templates/computer-vision|object detection|tracking|annotation|segmentation|review overlay|frame overlay|video analytics|roboflow|yolo|sports video|drone footage' || continue
  external="$(grep -Ei '^\| *External systems/connectors *\|' "$plan" || true)"
  printf '%s\n' "$external" | grep -Eiq '(^|[^a-z0-9])supervision([^a-z0-9]|$)' && continue
  waiver="$(awk 'BEGIN{on=0} /^#{1,6}[[:space:]]+External System Selection Waiver/{on=1;next} on && /^#{1,6}[[:space:]]+/{exit} on{print}' "$plan")"
  if printf '%s\n' "$waiver" | grep -Eiq 'supervision' && printf '%s\n' "$waiver" | grep -Eiq 'because|reason|justification|not required|unavailable|fallback|scope'; then
    continue
  fi
  echo "ERROR_FOR_AGENT: $plan appears to be a Computer Vision task but does not select or justify skipping supervision."
  bad=1
done
exit "$bad"

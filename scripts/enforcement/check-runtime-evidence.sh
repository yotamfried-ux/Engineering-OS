#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib/evidence.sh" 2>/dev/null || true

select_current_plan() {
  local selected=""
  if [ -n "${EOS_ACTIVE_PLAN:-}" ]; then
    printf '%s\n' "$EOS_ACTIVE_PLAN"
    return 0
  fi
  if [ -f .claude/plans/active.md ]; then
    printf '%s\n' .claude/plans/active.md
    return 0
  fi
  selected="$(evidence_get runtime_active_plan 2>/dev/null || true)"
  [ -z "$selected" ] || printf '%s\n' "$selected"
}

plan="${1:-}"
if [ -z "$plan" ]; then
  plan="$(select_current_plan)"
fi
[ -n "$plan" ] || { echo "runtime evidence: no active plan for this session"; exit 0; }
[ -f "$plan" ] || { echo "runtime evidence: active plan not found: $plan"; exit 1; }

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

normalize_list() {
  printf '%s' "${1:-}" \
    | tr ',;' '\n' \
    | sed -E 's/<[^>]+>//g; s/`//g; s/^[-*[:space:]]+//; s/[[:space:]]+$//' \
    | sed '/^$/d'
}

canon_key() {
  printf '%s' "${1:-}" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/^mcp__//; s/__.*$//; s/^[[:space:]]+|[[:space:]]+$//g; s/[^a-z0-9_-]+/-/g; s/^-+|-+$//g'
}

connector_has_evidence() {
  local item key
  item="$1"
  key="$(canon_key "$item")"
  [ -n "$key" ] || return 0
  evidence_has connector_used "$key" 2>/dev/null || evidence_has "connector_${key}" 2>/dev/null
}

connector_is_waived() {
  python3 - "$plan" "$1" <<'PY'
import re
import sys
from pathlib import Path

plan_path, connector = sys.argv[1:3]
text = Path(plan_path).read_text(encoding="utf-8", errors="replace")

def norm(value: str) -> str:
    value = re.sub(r"[`*_]", "", value or "").lower()
    return re.sub(r"[^a-z0-9]+", " ", value).strip()

def section(title: str) -> str:
    lines = text.splitlines()
    out = []
    active = False
    for line in lines:
        if re.match(r"^#{1,4}\s+" + title + r"(?:\s|$)", line, re.I):
            active = True
            continue
        if active and re.match(r"^#{1,4}\s+", line):
            break
        if active:
            out.append(line)
    return "\n".join(out)

needle = norm(connector)
marker = re.compile(r"\b(unavailable|not available|fallback|waived|waiver|not used)\b", re.I)
for body in (section(r"Connector\s+Evidence"), section(r"Connector\s+Usage\s+Evidence")):
    lines = body.splitlines()
    for index, line in enumerate(lines):
        if needle and not re.search(r"(?<![a-z0-9])" + re.escape(needle) + r"(?![a-z0-9])", norm(line)):
            continue
        block = [line]
        base_indent = len(line) - len(line.lstrip())
        for following in lines[index + 1:]:
            if not following.strip() or re.match(r"^#{1,4}\s+", following):
                break
            indent = len(following) - len(following.lstrip())
            if re.match(r"^\s*[-*]\s+\S", following) and indent <= base_indent:
                break
            if indent > base_indent:
                block.append(following)
                continue
            break
        if marker.search("\n".join(block)):
            raise SystemExit(0)
raise SystemExit(1)
PY
}

skill_has_evidence() {
  local item key
  item="$1"
  key="$(canon_key "$item")"
  [ -n "$key" ] || return 0
  case "$key" in
    superpowers-verify|superpowers_verify)
      evidence_has superpowers_verify_run 2>/dev/null || evidence_has skill_used superpowers-verify 2>/dev/null
      ;;
    *)
      evidence_has skill_used "$key" 2>/dev/null || evidence_has "skill_${key}" 2>/dev/null
      ;;
  esac
}

connectors="$(field_value "$plan" '^external systems/connectors$|^external systems$|^external connectors$|^connectors$')"
skills="$(field_value "$plan" '^skills$')"
bad=0

if ! is_none_value "$connectors"; then
  while IFS= read -r connector; do
    [ -n "$connector" ] || continue
    connector_is_waived "$connector" && continue
    if ! connector_has_evidence "$connector"; then
      echo "ERROR_FOR_AGENT: Runtime evidence missing — active plan declares connector '$connector' but matching connector evidence does not exist this session."
      echo "ACTION: use the declared source-of-truth connector, or update the active plan with a documented connector waiver if no connector is required."
      bad=1
    fi
  done <<EOF_CONNECTORS
$(normalize_list "$connectors")
EOF_CONNECTORS
fi

if ! is_none_value "$skills"; then
  while IFS= read -r skill; do
    [ -n "$skill" ] || continue
    if ! skill_has_evidence "$skill"; then
      key="$(canon_key "$skill")"
      if [ "$key" = "superpowers-verify" ] || [ "$key" = "superpowers_verify" ]; then
        echo "ERROR_FOR_AGENT: Runtime evidence missing — active plan declares superpowers-verify but no superpowers_verify_run evidence exists this session."
        echo "ACTION: run /superpowers-verify or read .claude/commands/superpowers-verify.md before marking done."
      else
        echo "ERROR_FOR_AGENT: Runtime evidence missing — active plan declares skill '$skill' but matching skill evidence does not exist this session."
        echo "ACTION: run the declared skill or add a documented waiver."
      fi
      bad=1
    fi
  done <<EOF_SKILLS
$(normalize_list "$skills")
EOF_SKILLS
fi

[ "$bad" -eq 0 ] || exit 1
echo "Runtime evidence checks passed for active plan: $(basename "$plan")"

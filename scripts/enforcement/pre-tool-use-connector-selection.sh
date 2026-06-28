#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/evidence.sh
. "$SCRIPT_DIR/lib/evidence.sh" 2>/dev/null || true

INPUT="$(cat 2>/dev/null || true)"

json_field() {
  local field="$1"
  printf '%s' "$INPUT" | python3 -c "
import json, sys
try:
    d=json.load(sys.stdin)
except Exception:
    print(''); sys.exit(0)
t=d.get('tool_input', d)
field='$field'
if field == 'tool': print(d.get('tool_name', d.get('tool', '')) or '')
elif field == 'file_path': print(t.get('file_path', '') or '')
" 2>/dev/null || true
}

field_value() {
  local plan_file="$1" field_re="$2"
  awk -F'|' -v re="$field_re" '
    NF > 1 {
      for (i = 1; i < NF; i++) {
        field = tolower($i); gsub(/[*_`]/, "", field); gsub(/^[ \t]+|[ \t]+$/, "", field)
        if (field ~ re) { value = $(i + 1); gsub(/^[ \t]+|[ \t]+$/, "", value); print value; exit }
      }
    }
  ' "$plan_file" 2>/dev/null || true
}

normalize_list() {
  printf '%s' "${1:-}" | tr ',;' '\n' | sed -E 's/<[^>]+>//g; s/`//g; s/^[-*[:space:]]+//; s/[[:space:]]+$//' | sed '/^$/d'
}

canon_key() {
  printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]' | sed -E 's/^mcp__//; s/__.*$//; s/^[[:space:]]+|[[:space:]]+$//g; s/[^a-z0-9_-]+/-/g; s/^-+|-+$//g'
}

connector_has_evidence() {
  local key
  key="$(canon_key "$1")"
  [ -n "$key" ] || return 0
  evidence_has connector_used "$key" 2>/dev/null || evidence_has "connector_${key}" 2>/dev/null
}

select_plan() {
  if [ -n "${EOS_ACTIVE_PLAN:-}" ] && [ -f "${EOS_ACTIVE_PLAN:-}" ]; then printf '%s\n' "$EOS_ACTIVE_PLAN"; return 0; fi
  if [ -f .claude/plans/active.md ]; then printf '%s\n' .claude/plans/active.md; return 0; fi
  ls -t .claude/plans/*.md 2>/dev/null | head -1 || true
}

TOOL="$(json_field tool)"
case "$TOOL" in Write|Edit|MultiEdit|NotebookEdit) ;; *) exit 0 ;; esac
FILE="$(json_field file_path)"
[ -n "$FILE" ] || exit 0
case "$FILE" in .claude/plans/*.md|*/.claude/plans/*.md) exit 0 ;; esac

PLAN="$(select_plan)"
[ -n "$PLAN" ] && [ -f "$PLAN" ] || exit 0
CHECK="$SCRIPT_DIR/check-required-connectors.sh"
[ -f "$CHECK" ] || exit 0

if ! out="$(bash "$CHECK" --plan "$PLAN" --target "$FILE" 2>&1)"; then
  echo "connector selection gate failed: $out" >&2
  exit 1
fi

connectors="$(field_value "$PLAN" '^external systems/connectors$|^external systems$|^external connectors$|^connectors$')"
missing=""
while IFS= read -r connector; do
  [ -n "$connector" ] || continue
  connector_has_evidence "$connector" || missing="${missing}${connector} "
done <<EOF_CONNECTORS
$(normalize_list "$connectors")
EOF_CONNECTORS
[ -z "$missing" ] || { echo "connector evidence missing for: ${missing}" >&2; exit 1; }

if printf '%s' "$connectors" | tr ',;' '\n' | grep -qiE '(^|[[:space:]-])notion([[:space:]-]|$)'; then
  grep -qiE '^#{1,4}[[:space:]]+Notion[[:space:]]+Progress[[:space:]]+Validation([[:space:]]|$)' "$PLAN" || {
    echo "notion progress validation section missing" >&2
    exit 1
  }
  evidence_has notion_progress_validated 2>/dev/null || evidence_has connector_notion_progress_validated 2>/dev/null || {
    echo "notion progress validation evidence missing" >&2
    exit 1
  }
fi

echo "connector selection checks passed"

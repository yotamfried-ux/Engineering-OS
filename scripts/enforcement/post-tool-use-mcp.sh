#!/usr/bin/env bash
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib/evidence.sh" 2>/dev/null || true

INPUT="$(cat 2>/dev/null || true)"
PARSED="$(printf '%s' "$INPUT" | python3 -c 'import json,sys,re
try:
 d=json.load(sys.stdin)
except Exception:
 print(""); sys.exit(0)
name=d.get("tool_name") or d.get("tool") or ""
if not name.startswith("mcp__") or "__" not in name[5:]:
 print(""); sys.exit(0)
connector=name.split("__",2)[1].lower()
connector=re.sub(r"[^a-z0-9_-]", "", connector)
print(connector)' 2>/dev/null || true)"

CONNECTOR="$PARSED"
[ -n "$CONNECTOR" ] || exit 0

evidence_record connector_used "$CONNECTOR" 2>/dev/null || true
evidence_record "connector_${CONNECTOR}" 2>/dev/null || true

case "$CONNECTOR" in
  context7) evidence_record context7 2>/dev/null || true ;;
  notion) evidence_record notion_used 2>/dev/null || true ;;
  github) evidence_record github_used 2>/dev/null || true ;;
  sentry) evidence_record sentry_used 2>/dev/null || true ;;
  supabase) evidence_record supabase_used 2>/dev/null || true ;;
  vercel) evidence_record vercel_used 2>/dev/null || true ;;
  figma) evidence_record figma_used 2>/dev/null || true ;;
esac

exit 0

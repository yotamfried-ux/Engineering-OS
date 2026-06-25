#!/usr/bin/env bash
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib/evidence.sh" 2>/dev/null || true

INPUT="$(cat 2>/dev/null || true)"
TOOL_NAME="$(printf '%s' "$INPUT" | python3 -c 'import json,sys
try:
 d=json.load(sys.stdin)
except Exception:
 print(""); sys.exit(0)
print(d.get("tool_name") or d.get("tool") or "")' 2>/dev/null || true)"

case "$TOOL_NAME" in
  mcp__*__*) ;;
  *) exit 0 ;;
esac

CONNECTOR="$(printf '%s' "$TOOL_NAME" | sed -E 's/^mcp__([^_]+)__.*/\1/' | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9_-')"
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

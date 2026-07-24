#!/usr/bin/env bash
# Record successful Notion progress without fabricating evidence from malformed responses.
set -u
set -o pipefail

ROOT="${ENGINEERING_OS_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
EVIDENCE_LIB="$ROOT/scripts/enforcement/lib/evidence.sh"
INPUT="$(cat 2>/dev/null)" || { echo "Notion progress recorder could not read hook input." >&2; exit 1; }

if ! printf '%s' "$INPUT" | python3 -c 'import json,sys; d=json.load(sys.stdin); name=d.get("tool_name") or d.get("tool") or ""; response=d.get("tool_response"); assert name.startswith("mcp__Notion__") and isinstance(response,dict)' >/dev/null 2>&1; then
  echo "Notion progress recorder received malformed input and recorded no evidence." >&2
  exit 1
fi

[ -f "$EVIDENCE_LIB" ] && [ -r "$EVIDENCE_LIB" ] || { echo "Notion progress evidence library is unavailable." >&2; exit 1; }
# shellcheck source=/dev/null
. "$EVIDENCE_LIB" || exit 1
evidence_record connector_used notion || exit 1
evidence_record notion_progress_validated || exit 1

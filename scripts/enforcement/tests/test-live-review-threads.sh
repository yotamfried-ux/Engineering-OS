#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-live-review-threads.py"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cat > "$TMP/resolved.json" <<'JSON'
[{"id":"a","isResolved":true,"isOutdated":false},{"id":"b","isResolved":true,"isOutdated":true}]
JSON
python3 "$CHECK" --threads-json "$TMP/resolved.json" >/dev/null
cat > "$TMP/current.json" <<'JSON'
[{"id":"a","isResolved":false,"isOutdated":false}]
JSON
if python3 "$CHECK" --threads-json "$TMP/current.json" >/dev/null 2>&1; then echo 'unexpected pass: current unresolved thread'; exit 1; fi
cat > "$TMP/outdated.json" <<'JSON'
[{"id":"a","isResolved":false,"isOutdated":true}]
JSON
if python3 "$CHECK" --threads-json "$TMP/outdated.json" >/dev/null 2>&1; then echo 'unexpected pass: outdated unresolved thread'; exit 1; fi
cat > "$TMP/missing.json" <<'JSON'
[{"id":"a"}]
JSON
if python3 "$CHECK" --threads-json "$TMP/missing.json" >/dev/null 2>&1; then echo 'unexpected pass: missing thread metadata'; exit 1; fi
echo 'live review thread tests passed'

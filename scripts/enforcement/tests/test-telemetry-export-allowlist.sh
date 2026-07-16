#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
EXPORT="$ROOT/scripts/monitoring/export-telemetry-run.py"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
TARGET="$TMP/target"
CUSTOM="$TMP/custom"
OUT="$TMP/export"

git init -q "$TARGET"
git -C "$TARGET" config user.email telemetry@example.invalid
git -C "$TARGET" config user.name telemetry
printf 'base\n' > "$TARGET/README.md"
git -C "$TARGET" add README.md
git -C "$TARGET" commit -qm base

mkdir -p "$CUSTOM"
printf '%s\n' 'allowlist-run' > "$CUSTOM/run_id"
cat > "$CUSTOM/events.jsonl" <<'JSON'
{"schema_version":"eos.telemetry.v1","otel_signal":"span_event","trace_id":"allowlist-run","span_id":"0123456789abcdef","parent_span_id":"","name":"eos.session_start","kind":"INTERNAL","start_time_unix_nano":1,"end_time_unix_nano":1,"timestamp":"2026-07-16T00:00:00+00:00","status":{"code":"OK","detail":"customer-private-status"},"resource":{"service.name":"engineering-os","workspace_path":"/Users/alice/private/client.txt"},"attributes":{"eos.event.name":"session_start","eos.tool.name":"Read","labels":["customer-private-request"],"eos.tool.target_path":{"present":true,"top_dir":"src","extension":".py","path_hash":"abc123","raw":"/Users/alice/private/client.py"}},"events":[{"name":"eos.hook.session_start","time_unix_nano":1,"attributes":{"eos.privacy.raw_payload_stored":false,"labels":["customer-private-event"]}}],"prompt_copy":"customer-private-request"}
JSON

(
  cd "$TARGET"
  EOS_TELEMETRY_FILE="$CUSTOM/events.jsonl" \
  EOS_TELEMETRY_RUN_ID_FILE="$CUSTOM/run_id" \
    python3 "$EXPORT" --out "$OUT" --repo example/allowlist-target \
      --branch feature/allowlist --head-sha "$(git rev-parse HEAD)" >/dev/null
)

python3 - "$OUT/events.jsonl" <<'PY'
import json
import sys
row = json.loads(open(sys.argv[1]).readline())
assert row["name"] == "eos.session_start"
assert row["trace_id"] == "allowlist-run"
assert row["attributes"]["eos.event.name"] == "session_start"
assert row["attributes"]["eos.tool.name"] == "Read"
assert row["attributes"]["eos.tool.target_path"] == {
    "present": True,
    "top_dir": "src",
    "extension": ".py",
    "path_hash": "abc123",
}
assert "prompt_copy" not in row
assert "detail" not in row["status"]
assert "workspace_path" not in row["resource"]
assert "labels" not in row["attributes"]
assert "raw" not in row["attributes"]["eos.tool.target_path"]
assert "labels" not in row["events"][0]["attributes"]
PY

echo 'telemetry export allowlist tests passed'

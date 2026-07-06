#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
RECORDER="$ROOT/scripts/monitoring/eos-telemetry-event.sh"
SUMMARY="$ROOT/scripts/monitoring/eos-telemetry-summary.py"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass() { local name="$1"; shift; "$@" >/dev/null 2>&1 || { echo "fail: $name"; exit 1; }; echo "ok: $name"; }
failcase() { local name="$1"; shift; if "$@" >/dev/null 2>&1; then echo "unexpected pass: $name"; exit 1; else echo "ok: $name"; fi; }

pass recorder_present test -f "$RECORDER"
pass summary_present test -f "$SUMMARY"

cd "$TMP"
git init -q
git config user.email telemetry@example.invalid
git config user.name telemetry
mkdir -p .claude/plans src .engineering-os/telemetry
cat > .claude/plans/active.md <<'EOF'
# Route Plan
EOF
git add .claude/plans/active.md
git commit -qm base

PAYLOAD='{"session_id":"session-alpha-123","transcript_path":"/tmp/eos-transcript.jsonl","cwd":"/tmp/eos-target","tool_name":"Bash","tool_input":{"command":"npm install example-package --audit=false","file_path":"src/customer-file.ts"},"tool_response":{"ok":true}}'
printf '%s' "$PAYLOAD" | ENGINEERING_OS_HOME="$ROOT" EOS_TELEMETRY_FILE="$TMP/.engineering-os/telemetry/events.jsonl" bash "$RECORDER" pre_tool_use_bash

PAYLOAD_TWO='{"session_id":"session-alpha-123","transcript_path":"/tmp/eos-transcript.jsonl","cwd":"/tmp/eos-target","tool_name":"Bash","tool_input":{"command":"pytest tests","file_path":"tests/customer-test.py"},"tool_response":{"ok":true}}'
printf '%s' "$PAYLOAD_TWO" | ENGINEERING_OS_HOME="$ROOT" EOS_TELEMETRY_FILE="$TMP/.engineering-os/telemetry/events.jsonl" bash "$RECORDER" post_tool_use_bash

printf '%s' '{not valid json' | ENGINEERING_OS_HOME="$ROOT" EOS_TELEMETRY_FILE="$TMP/.engineering-os/telemetry/events.jsonl" bash "$RECORDER" invalid_json_event

pass telemetry_file_created test -f "$TMP/.engineering-os/telemetry/events.jsonl"
pass valid_json_lines python3 - "$TMP/.engineering-os/telemetry/events.jsonl" <<'PY'
import json, sys
for line in open(sys.argv[1], encoding='utf-8'):
    json.loads(line)
PY
pass contains_otel_schema grep -q '"schema_version": "eos.telemetry.v1"' "$TMP/.engineering-os/telemetry/events.jsonl"
pass contains_trace_id grep -q '"trace_id"' "$TMP/.engineering-os/telemetry/events.jsonl"
pass contains_span_id grep -q '"span_id"' "$TMP/.engineering-os/telemetry/events.jsonl"
pass contains_resource grep -q '"resource"' "$TMP/.engineering-os/telemetry/events.jsonl"
pass contains_attributes grep -q '"attributes"' "$TMP/.engineering-os/telemetry/events.jsonl"
pass contains_dependency_category grep -q '"dependency.install"' "$TMP/.engineering-os/telemetry/events.jsonl"
pass contains_session_hash_field grep -q '"eos.claude.session.hash"' "$TMP/.engineering-os/telemetry/events.jsonl"
pass contains_transcript_hash_field grep -q '"eos.claude.transcript.hash"' "$TMP/.engineering-os/telemetry/events.jsonl"
pass contains_cwd_hash_field grep -q '"eos.claude.cwd.hash"' "$TMP/.engineering-os/telemetry/events.jsonl"
pass contains_response_presence grep -q '"eos.tool.response.present": true' "$TMP/.engineering-os/telemetry/events.jsonl"

failcase raw_session_not_recorded grep -q 'session-alpha-123' "$TMP/.engineering-os/telemetry/events.jsonl"
failcase raw_transcript_not_recorded grep -q 'eos-transcript.jsonl' "$TMP/.engineering-os/telemetry/events.jsonl"
failcase raw_cwd_not_recorded grep -q '/tmp/eos-target' "$TMP/.engineering-os/telemetry/events.jsonl"
failcase raw_command_not_recorded grep -q 'npm install example-package' "$TMP/.engineering-os/telemetry/events.jsonl"
failcase raw_path_not_recorded grep -q 'src/customer-file.ts' "$TMP/.engineering-os/telemetry/events.jsonl"

python3 "$SUMMARY" "$TMP/.engineering-os/telemetry/events.jsonl" --output "$TMP/summary.md"
pass summary_created test -f "$TMP/summary.md"
pass summary_counts_events grep -q 'Total span events: 3' "$TMP/summary.md"
pass summary_session_correlation grep -q 'Session correlation' "$TMP/summary.md"

EOS_TELEMETRY_DISABLED=1 EOS_TELEMETRY_FILE="$TMP/.engineering-os/telemetry/disabled.jsonl" bash "$RECORDER" disabled_event <<<'{"tool_name":"Bash"}'
failcase disabled_does_not_write test -f "$TMP/.engineering-os/telemetry/disabled.jsonl"

echo "eos telemetry tests passed"

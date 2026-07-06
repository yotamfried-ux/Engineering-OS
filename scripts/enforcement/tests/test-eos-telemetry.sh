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

PAYLOAD='{"tool_name":"Bash","tool_input":{"command":"npm install example-package --token VALUE_SHOULD_NOT_APPEAR","file_path":"src/private/customer-file.ts"}}'
printf '%s' "$PAYLOAD" | ENGINEERING_OS_HOME="$ROOT" EOS_TELEMETRY_FILE="$TMP/.engineering-os/telemetry/events.jsonl" bash "$RECORDER" pre_tool_use_bash

pass telemetry_file_created test -f "$TMP/.engineering-os/telemetry/events.jsonl"
pass valid_json python3 -m json.tool "$TMP/.engineering-os/telemetry/events.jsonl"
pass contains_otel_schema grep -q '"schema_version": "eos.telemetry.v1"' "$TMP/.engineering-os/telemetry/events.jsonl"
pass contains_trace_id grep -q '"trace_id"' "$TMP/.engineering-os/telemetry/events.jsonl"
pass contains_span_id grep -q '"span_id"' "$TMP/.engineering-os/telemetry/events.jsonl"
pass contains_resource grep -q '"resource"' "$TMP/.engineering-os/telemetry/events.jsonl"
pass contains_attributes grep -q '"attributes"' "$TMP/.engineering-os/telemetry/events.jsonl"
pass contains_dependency_category grep -q '"dependency.install"' "$TMP/.engineering-os/telemetry/events.jsonl"

failcase raw_sensitive_value_not_recorded grep -q 'VALUE_SHOULD_NOT_APPEAR' "$TMP/.engineering-os/telemetry/events.jsonl"
failcase raw_command_not_recorded grep -q 'npm install example-package' "$TMP/.engineering-os/telemetry/events.jsonl"
failcase raw_path_not_recorded grep -q 'src/private/customer-file.ts' "$TMP/.engineering-os/telemetry/events.jsonl"

python3 "$SUMMARY" "$TMP/.engineering-os/telemetry/events.jsonl" --output "$TMP/summary.md"
pass summary_created test -f "$TMP/summary.md"
pass summary_counts_events grep -q 'Total span events' "$TMP/summary.md"
pass summary_mentions_privacy grep -q 'does not store prompts' "$TMP/summary.md"

EOS_TELEMETRY_DISABLED=1 EOS_TELEMETRY_FILE="$TMP/.engineering-os/telemetry/disabled.jsonl" bash "$RECORDER" disabled_event <<<'{"tool_name":"Bash"}'
failcase disabled_does_not_write test -f "$TMP/.engineering-os/telemetry/disabled.jsonl"

echo "eos telemetry tests passed"

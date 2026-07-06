#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
EXPORTER="$ROOT/scripts/monitoring/export-telemetry-run.sh"
IMPORTER="$ROOT/scripts/monitoring/import-telemetry-run.py"
ANALYZER="$ROOT/scripts/monitoring/analyze-telemetry-archive.py"
TMP="$(mktemp -d)"
pass() { local n="$1"; shift; "$@" >/dev/null 2>&1 || { echo "fail: $n"; exit 1; }; echo "ok: $n"; }
reject() { local n="$1"; shift; if "$@" >/dev/null 2>&1; then echo "unexpected pass: $n"; exit 1; fi; echo "ok: $n"; }

pass files_compile python3 -m py_compile "$ROOT/scripts/monitoring/export-telemetry-run.py" "$IMPORTER" "$ANALYZER"
pass exporter_shell_syntax bash -n "$EXPORTER"

write_event() {
  cat > "$1" <<'JSON'
{"schema_version":"eos.telemetry.v1","trace_id":"run-001","span_id":"span-001","name":"eos.session_start","timestamp":"2026-07-06T01:00:00+00:00","resource":{"service.name":"engineering-os"},"attributes":{"eos.claude.session.present":true,"eos.claude.prompt.present":true,"eos.claude.transcript.present":true,"eos.claude.cwd.present":true,"eos.tool.name":"Bash","eos.tool.command.category":"test","eos.tool.command.hash":"cmdhash","eos.tool.response.present":false,"eos.tool.error.present":false}}
JSON
}

make_bundle() {
  local dir="$1" run_id="$2"
  mkdir -p "$dir"
  write_event "$dir/events.jsonl"
  printf '# Summary\n' > "$dir/latest-summary.md"
  cat > "$dir/manifest.json" <<JSON
{"schema_version":"eos.telemetry.run.v1","run_id":"$run_id","project":"project-8","project_slug":"project-8","repo":"Video-editing-with-drone","branch":"main","head_sha":"abcdef1234567890","engineering_os_head_sha":"39d8083c9bc49efa1958ae09b0c938ce21dd3f9f","exported_at":"2026-07-06T01:00:00+00:00","source_telemetry_dir":".engineering-os/telemetry","events_file":"events.jsonl","summary_file":"latest-summary.md","event_count":1,"privacy_contract":"metadata-only"}
JSON
}

TARGET="$TMP/project-8"
mkdir -p "$TARGET/.engineering-os/telemetry"
(
  cd "$TARGET"
  git init -q
  git config user.email telemetry@example.invalid
  git config user.name telemetry
  mkdir -p src
  printf 'example\n' > src/example.txt
  git add src/example.txt
  git commit -qm base
)
printf 'run-archive-001\n' > "$TARGET/.engineering-os/telemetry/run_id"
printf '# Engineering OS Telemetry Summary\n' > "$TARGET/.engineering-os/telemetry/latest-summary.md"
write_event "$TARGET/.engineering-os/telemetry/events.jsonl"
cat >> "$TARGET/.engineering-os/telemetry/events.jsonl" <<'JSON'
{"schema_version":"eos.telemetry.v1","trace_id":"run-001","span_id":"span-002","name":"eos.pre_tool_use_bash","timestamp":"2026-07-06T01:00:01+00:00","resource":{"service.name":"engineering-os"},"attributes":{"eos.claude.session.present":true,"eos.claude.prompt.present":true,"eos.claude.transcript.present":true,"eos.claude.cwd.present":true,"eos.tool.name":"Bash","eos.tool.command.category":"build","eos.tool.command.hash":"cmdhash2","eos.tool.response.present":true,"eos.tool.error.present":false}}
JSON

BUNDLE="$TMP/export/project-8"
(cd "$TARGET" && bash "$EXPORTER" --out "$BUNDLE" --project project-8 --repo Video-editing-with-drone --engineering-os-head-sha 39d8083c9bc49efa1958ae09b0c938ce21dd3f9f)
pass export_manifest_created test -f "$BUNDLE/manifest.json"
pass export_events_created test -f "$BUNDLE/events.jsonl"
pass export_summary_created test -f "$BUNDLE/latest-summary.md"
pass export_counts_events python3 -c "import json,pathlib; m=json.loads(pathlib.Path('$BUNDLE/manifest.json').read_text()); assert m['event_count']==2 and m['privacy_contract']=='metadata-only'"
pass export_does_not_copy_run_id test ! -f "$BUNDLE/run_id"

ARCHIVE="$TMP/archive"
python3 "$IMPORTER" "$BUNDLE" --archive "$ARCHIVE"
pass import_manifest_copied test -f "$ARCHIVE/runs/2026-07-06/project-8/run-archive-001/manifest.json"
pass import_findings_created test -f "$ARCHIVE/runs/2026-07-06/project-8/run-archive-001/findings.md"
pass import_index_updated grep -q run-archive-001 "$ARCHIVE/indexes/runs.jsonl"
reject duplicate_import_rejected python3 "$IMPORTER" "$BUNDLE" --archive "$ARCHIVE"
pass duplicate_replace_allowed python3 "$IMPORTER" "$BUNDLE" --archive "$ARCHIVE" --replace

REPORT="$TMP/report.md"
python3 "$ANALYZER" "$ARCHIVE" --project project-8 --output "$REPORT"
pass analyzer_report_created grep -q 'Runs analyzed: 1' "$REPORT"
pass analyzer_mentions_categories grep -q 'Command categories' "$REPORT"
pass analyzer_readiness_note grep -q 'Monitoring sufficiency requires Project 8 evidence' "$REPORT"

MISSING_TARGET="$TMP/missing-events"
mkdir -p "$MISSING_TARGET/.engineering-os/telemetry"
printf '# Summary\n' > "$MISSING_TARGET/.engineering-os/telemetry/latest-summary.md"
reject export_missing_events_fails bash -c "cd '$MISSING_TARGET' && bash '$EXPORTER' --out '$TMP/missing-bundle' --project missing"
pass explicit_empty_run_exports bash -c "cd '$MISSING_TARGET' && bash '$EXPORTER' --out '$TMP/empty-bundle' --project empty --empty-run"
pass empty_run_manifest_marks_empty python3 -c "import json,pathlib; m=json.loads(pathlib.Path('$TMP/empty-bundle/manifest.json').read_text()); assert m['empty_run'] is True and m['event_count']==0"

BAD="$TMP/bad-manifest"; make_bundle "$BAD" bad-manifest-run; printf '{bad json' > "$BAD/manifest.json"; reject invalid_manifest_rejected python3 "$IMPORTER" "$BAD" --archive "$TMP/archive-bad-manifest"
BADJ="$TMP/bad-jsonl"; make_bundle "$BADJ" bad-jsonl-run; printf '{not json}\n' > "$BADJ/events.jsonl"; reject invalid_jsonl_rejected python3 "$IMPORTER" "$BADJ" --archive "$TMP/archive-bad-jsonl"
MISS="$TMP/missing-field"; make_bundle "$MISS" missing-field-run; python3 -c "import json,pathlib; p=pathlib.Path('$MISS/events.jsonl'); e=json.loads(p.read_text()); e.pop('trace_id'); p.write_text(json.dumps(e)+'\n')"; reject missing_event_required_field_rejected python3 "$IMPORTER" "$MISS" --archive "$TMP/archive-missing-field"
BAN="$TMP/banned"; make_bundle "$BAN" banned-run; python3 -c "import json,pathlib; p=pathlib.Path('$BAN/events.jsonl'); e=json.loads(p.read_text()); e['attributes']={'raw_'+'command':'forbidden-fixture-value'}; p.write_text(json.dumps(e)+'\n')"; reject banned_raw_fields_rejected python3 "$IMPORTER" "$BAN" --archive "$TMP/archive-banned"
ART="$TMP/artifact/engineering-os-telemetry-123"; make_bundle "$ART" artifact-run-001; pass artifact_bundle_shape_imports python3 "$IMPORTER" "$ART" --archive "$TMP/artifact-archive"
pass no_sensitive_fixture_leaked bash -c "! grep -R 'forbidden-fixture-value' '$ARCHIVE'"
echo "telemetry archive tests passed"

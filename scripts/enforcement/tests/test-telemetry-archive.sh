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
  local run_id="${2:-run-001}"
  cat > "$1" <<JSON
{"schema_version":"eos.telemetry.v1","trace_id":"$run_id","span_id":"span-001","name":"eos.session_start","timestamp":"2026-07-06T01:00:00+00:00","resource":{"service.name":"engineering-os"},"attributes":{"eos.claude.session.present":true,"eos.claude.prompt.present":true,"eos.claude.transcript.present":true,"eos.claude.cwd.present":true,"eos.tool.name":"Bash","eos.tool.command.category":"test","eos.tool.command.hash":"cmdhash","eos.tool.response.present":false,"eos.tool.error.present":false}}
JSON
}

# Bundles reach the archive after sync-telemetry-run.py has written handoff metadata
# and checksums, so fixtures must be synced too. This calls the real writer rather
# than restating the manifest shape, so a change there fails these tests loudly.
sync_bundle() {
  python3 - "$ROOT" "$1" <<'SYNC'
import importlib.util
import json
import sys
from pathlib import Path

root, bundle = Path(sys.argv[1]), Path(sys.argv[2])
sys.path.insert(0, str(root / "scripts" / "monitoring"))
from telemetry_handoff import latest_boundary_position

spec = importlib.util.spec_from_file_location(
    "sync_telemetry_run", root / "scripts" / "monitoring" / "sync-telemetry-run.py"
)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

manifest = json.loads((bundle / "manifest.json").read_text(encoding="utf-8"))
rows = [
    json.loads(line)
    for line in (bundle / "events.jsonl").read_text(encoding="utf-8").splitlines()
    if line.strip()
]
mod.write_handoff_manifest(
    bundle,
    run_id=manifest["run_id"],
    repo_slug=manifest["repo"],
    pr_number=42,
    branch_hash=manifest.get("branch_hash") or "b" * 32,
    head_sha=manifest["head_sha"],
    event_count=len(rows),
    boundary_position=latest_boundary_position(rows),
)
SYNC
}


make_bundle() {
  local dir="$1" run_id="$2"
  mkdir -p "$dir"
  write_event "$dir/events.jsonl" "$run_id"
  printf '# Summary\n' > "$dir/latest-summary.md"
  cat > "$dir/manifest.json" <<JSON
{"schema_version":"eos.telemetry.run.v1","run_id":"$run_id","project":"project-8","project_slug":"project-8","repo":"yotamfried-ux/Video-editing-with-drone","branch":"sha256:$(printf 'b%.0s' $(seq 32))","branch_hash":"$(printf 'b%.0s' $(seq 32))","head_sha":"$(printf 'a%.0s' $(seq 40))","engineering_os_head_sha":"39d8083c9bc49efa1958ae09b0c938ce21dd3f9f","exported_at":"2026-07-06T01:00:00+00:00","source_telemetry_dir":".engineering-os/telemetry","events_file":"events.jsonl","summary_file":"latest-summary.md","event_count":1,"privacy_contract":"metadata-only"}
JSON
  sync_bundle "$dir"
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
write_event "$TARGET/.engineering-os/telemetry/events.jsonl" run-archive-001
cat >> "$TARGET/.engineering-os/telemetry/events.jsonl" <<'JSON'
{"schema_version":"eos.telemetry.v1","trace_id":"run-archive-001","span_id":"span-002","name":"eos.pre_tool_use_bash","timestamp":"2026-07-06T01:00:01+00:00","resource":{"service.name":"engineering-os"},"attributes":{"eos.claude.session.present":true,"eos.claude.prompt.present":true,"eos.claude.transcript.present":true,"eos.claude.cwd.present":true,"eos.tool.name":"Bash","eos.tool.command.category":"build","eos.tool.command.hash":"cmdhash2","eos.tool.response.present":true,"eos.tool.error.present":false}}
JSON

BUNDLE="$TMP/export/project-8"
(cd "$TARGET" && bash "$EXPORTER" --out "$BUNDLE" --project project-8 --repo yotamfried-ux/Video-editing-with-drone --engineering-os-head-sha 39d8083c9bc49efa1958ae09b0c938ce21dd3f9f)
pass export_manifest_created test -f "$BUNDLE/manifest.json"
pass export_events_created test -f "$BUNDLE/events.jsonl"
pass export_summary_created test -f "$BUNDLE/latest-summary.md"
pass export_counts_events python3 -c "import json,pathlib; m=json.loads(pathlib.Path('$BUNDLE/manifest.json').read_text()); assert m['event_count']==2 and m['privacy_contract']=='metadata-only'"
pass export_does_not_copy_run_id test ! -f "$BUNDLE/run_id"

sync_bundle "$BUNDLE"

ARCHIVE="$TMP/archive"
python3 "$IMPORTER" "$BUNDLE" --archive "$ARCHIVE"
RUN_DATE="$(python3 -c "import json; print(json.load(open('$BUNDLE/manifest.json'))['exported_at'][:10])")"
pass import_manifest_copied test -f "$ARCHIVE/runs/$RUN_DATE/project-8/run-archive-001/manifest.json"
pass import_findings_created test -f "$ARCHIVE/runs/$RUN_DATE/project-8/run-archive-001/findings.md"
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
# --- import integrity: every rejection must leave the archive byte-identical -----------
# The exporter and handoff validator already own checksum and identity verification.
# These cases prove direct archive import now goes through that same shared validator
# before it writes anything, rather than accepting a bundle on schema checks alone.

INTEG="$TMP/integrity"
mkdir -p "$INTEG"
GOOD_ARCHIVE="$TMP/integrity-archive"
GOOD="$INTEG/valid"; make_bundle "$GOOD" integrity-valid-run
pass integrity_valid_bundle_imports python3 "$IMPORTER" "$GOOD" --archive "$GOOD_ARCHIVE"

# Snapshot of every path plus content hash: a rejected import must not change one byte.
archive_fingerprint() {
  find "$1" -type f -print0 2>/dev/null | sort -z | xargs -0 sha256sum 2>/dev/null | sha256sum
}
BASELINE="$(archive_fingerprint "$GOOD_ARCHIVE")"

# reject_unchanged <name> <bundle> [extra importer args...]
# reject_unchanged <name> <bundle> <expected-reason> [extra importer args...]
#
# A negative test that only asserts "it failed" can pass for the wrong reason: the
# shared validator checks checksums before boundary position, so a fixture that
# breaks both reports the checksum and proves nothing about the boundary. Each case
# therefore names the failure it is supposed to provoke, and the reason is matched
# against the importer's real stderr rather than recorded by hand in the PR body.
reject_unchanged() {
  local name="$1" bundle="$2" expected="$3"; shift 3
  local err="$TMP/stderr-$name.txt"
  if python3 "$IMPORTER" "$bundle" --archive "$GOOD_ARCHIVE" "$@" >/dev/null 2>"$err"; then
    echo "unexpected pass: $name"; exit 1
  fi
  if ! grep -qF -- "$expected" "$err"; then
    echo "fail: $name was rejected for the wrong reason"
    echo "  expected to contain: $expected"
    echo "  actual: $(tr '\n' ' ' < "$err")"
    exit 1
  fi
  if [ "$(archive_fingerprint "$GOOD_ARCHIVE")" != "$BASELINE" ]; then
    echo "fail: $name mutated the archive despite being rejected"; exit 1
  fi
  echo "ok: $name (rejected on '$expected', archive unchanged)"
}

B="$INTEG/byte"; make_bundle "$B" integrity-byte-run
printf 'x' >> "$B/events.jsonl"
reject_unchanged byte_mutation_rejected "$B" "telemetry events checksum mismatch"

B="$INTEG/summary"; make_bundle "$B" integrity-summary-run
printf 'tampered\n' >> "$B/latest-summary.md"
reject_unchanged summary_mutation_rejected "$B" "telemetry summary checksum mismatch"

# Manifest replacement: a whole manifest swapped in from a different run.
B="$INTEG/manifest-swap"; make_bundle "$B" integrity-swap-run
OTHER="$INTEG/manifest-source"; make_bundle "$OTHER" integrity-other-run
cp "$OTHER/manifest.json" "$B/manifest.json"
reject_unchanged manifest_replacement_rejected "$B" "telemetry events checksum mismatch"

B="$INTEG/checksum"; make_bundle "$B" integrity-checksum-run
python3 -c "
import json,pathlib,sys
p=pathlib.Path(sys.argv[1])/'manifest.json'
m=json.loads(p.read_text()); m['checksums']['events_sha256']='0'*64
p.write_text(json.dumps(m))" "$B"
reject_unchanged checksum_mismatch_rejected "$B" "telemetry events checksum mismatch"

B="$INTEG/symlink"; make_bundle "$B" integrity-symlink-run
mv "$B/events.jsonl" "$INTEG/events-target.jsonl"
ln -s "$INTEG/events-target.jsonl" "$B/events.jsonl"
reject_unchanged symlink_member_rejected "$B" "bundle member is missing, a symlink, or not a regular file"

B="$INTEG/fifo"; make_bundle "$B" integrity-fifo-run
rm -f "$B/events.jsonl"; mkfifo "$B/events.jsonl"
reject_unchanged non_regular_file_rejected "$B" "bundle member is missing, a symlink, or not a regular file"

B="$INTEG/extra"; make_bundle "$B" integrity-extra-run
printf 'unexpected\n' > "$B/stowaway.txt"
reject_unchanged unexpected_file_rejected "$B" "bundle contains files outside the allowlist"

B="$INTEG/boundary"; make_bundle "$B" integrity-boundary-run
python3 -c "
import json,pathlib,sys
d=pathlib.Path(sys.argv[1])
p=d/'events.jsonl'
e=json.loads(p.read_text().splitlines()[0])
e['name']='eos.pre_tool_use'; e['attributes']['eos.event.name']='pre_tool_use'
p.write_text(json.dumps(e)+'\n')" "$B"
# Re-sync rather than mask a failure: the writer reseals the checksums for the edited
# events, so the bundle reaches the validator internally consistent and can only be
# rejected on the boundary itself. Swallowing this would let a stale checksum stand in
# for the boundary check and the assertion below would prove nothing about boundaries.
sync_bundle "$B"
reject_unchanged missing_terminal_boundary_rejected "$B" "telemetry handoff boundary position is invalid"

B="$INTEG/policy"; make_bundle "$B" integrity-policy-run
python3 -c "
import json,pathlib,sys
p=pathlib.Path(sys.argv[1])/'manifest.json'
m=json.loads(p.read_text()); m['policy']={'schema_version':'eos.telemetry.policy.WRONG'}
p.write_text(json.dumps(m))" "$B"
reject_unchanged invalid_policy_rejected "$B" "bundle declares an invalid telemetry policy identity"

# Identity mismatches: the bundle is internally valid but belongs to another run.
B="$INTEG/identity"; make_bundle "$B" integrity-identity-run
reject_unchanged wrong_repository_rejected "$B" "telemetry bundle repository does not match current repository" --expected-repo other-owner/other-repo
reject_unchanged wrong_branch_rejected "$B" "telemetry bundle branch hash does not match current branch" --expected-branch-hash "$(printf 'c%.0s' $(seq 32))"
reject_unchanged wrong_head_rejected "$B" "telemetry bundle head does not match current head" --expected-head-sha "$(printf 'd%.0s' $(seq 40))"
reject_unchanged wrong_run_rejected "$B" "telemetry bundle run id does not match current run" --expected-run-id some-other-run

# The archive records that validation actually ran, so a later reader can tell.
pass integrity_decision_recorded python3 -c "
import json,pathlib,sys
rows=[json.loads(l) for l in (pathlib.Path(sys.argv[1])/'indexes'/'runs.jsonl').read_text().splitlines() if l.strip()]
row=[r for r in rows if r['run_id']=='integrity-valid-run'][0]
integ=row['integrity']
assert integ['validated_before_mutation'] is True, integ
assert integ['validator']=='telemetry_handoff.validate_bundle', integ
assert 'events_sha256' in integ['checksums_verified'], integ
" "$GOOD_ARCHIVE"

# Engineering OS head is provenance the shared validator does not own, so the importer
# binds it. Without this an otherwise valid bundle attributes evidence to the wrong version.
reject_unchanged wrong_engineering_os_head_rejected "$B" "bundle Engineering OS head does not match the expected version" \
  --expected-engineering-os-head-sha "$(printf 'e%.0s' $(seq 40))"

# The integrity record must not claim coverage the validator does not provide: an extra
# checksum key in the manifest is not verified, so it must not appear as verified.
EXTRA="$INTEG/extra-checksum"; make_bundle "$EXTRA" integrity-extrasum-run
python3 -c "
import json,pathlib,sys
p=pathlib.Path(sys.argv[1])/'manifest.json'
m=json.loads(p.read_text()); m['checksums']['manifest_sha256']='0'*64
p.write_text(json.dumps(m))" "$EXTRA"
pass extra_checksum_key_not_claimed_verified bash -c "
python3 '$IMPORTER' '$EXTRA' --archive '$TMP/integrity-archive-extrasum' >/dev/null &&
python3 -c \"
import json,pathlib,sys
rows=[json.loads(l) for l in (pathlib.Path('$TMP/integrity-archive-extrasum')/'indexes'/'runs.jsonl').read_text().splitlines() if l.strip()]
verified=rows[0]['integrity']['checksums_verified']
assert verified==['events_sha256','summary_sha256'], verified
assert rows[0]['integrity']['snapshot_validated'] is True, rows[0]['integrity']
\""

# A bundle that matches its declared identity still imports when identity is asserted.
B="$INTEG/matched"; make_bundle "$B" integrity-matched-run
pass matching_identity_imports python3 "$IMPORTER" "$B" --archive "$TMP/integrity-archive-matched" \
  --expected-repo yotamfried-ux/Video-editing-with-drone \
  --expected-run-id integrity-matched-run

echo "telemetry archive tests passed"

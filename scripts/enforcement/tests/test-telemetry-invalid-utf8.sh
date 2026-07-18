#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

python3 - "$ROOT" "$TMP" <<'PY'
import hashlib
import json
import shutil
import sys
from pathlib import Path

root = Path(sys.argv[1])
tmp = Path(sys.argv[2])
sys.path.insert(0, str(root / "scripts" / "monitoring"))
from telemetry_handoff import (  # noqa: E402
    HANDOFF_SCHEMA,
    RUN_SCHEMA,
    HandoffError,
    stable_hash,
    validate_bundle,
)

repo = "example/utf8-target"
head = "a" * 40
branch_hash = "b" * 32
run_id = "utf8-run"
row = {
    "schema_version": "eos.telemetry.v1",
    "otel_signal": "span_event",
    "trace_id": run_id,
    "span_id": "0123456789abcdef",
    "parent_span_id": "",
    "name": "eos.stop",
    "kind": "INTERNAL",
    "start_time_unix_nano": 1,
    "end_time_unix_nano": 1,
    "timestamp": "2026-07-16T00:00:00+00:00",
    "status": {"code": "OK"},
    "resource": {"service.name": "engineering-os"},
    "attributes": {"eos.event.name": "stop"},
    "events": [
        {
            "name": "eos.hook.stop",
            "time_unix_nano": 1,
            "attributes": {"eos.privacy.raw_payload_stored": False},
        }
    ],
}


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_bundle(path: Path) -> None:
    path.mkdir(parents=True)
    (path / "events.jsonl").write_text(json.dumps(row) + "\n", encoding="utf-8")
    (path / "latest-summary.md").write_text("# Summary\n", encoding="utf-8")
    manifest = {
        "schema_version": RUN_SCHEMA,
        "run_id": run_id,
        "project": "utf8-target",
        "project_slug": "utf8-target",
        "repo": repo,
        "branch": f"sha256:{branch_hash}",
        "branch_hash": branch_hash,
        "head_sha": head,
        "engineering_os_head_sha": head,
        "exported_at": "2026-07-16T00:00:00+00:00",
        "source_telemetry_dir": ".engineering-os/telemetry",
        "source_events": "events.jsonl",
        "source_run_id": "run_id",
        "events_file": "events.jsonl",
        "summary_file": "latest-summary.md",
        "event_count": 1,
        "privacy_contract": "metadata-only",
        "empty_run": False,
        "bundle_files": {
            "manifest": "manifest.json",
            "events": "events.jsonl",
            "summary": "latest-summary.md",
        },
        "handoff": {
            "schema_version": HANDOFF_SCHEMA,
            "repo": repo,
            "pr_number": 42,
            "pr_binding": "exact",
            "source_branch_hash": branch_hash,
            "head_sha": head,
            "run_id_hash": stable_hash(run_id),
            "event_count": 1,
            "boundary_position": 1,
            "synced_at": "2026-07-16T00:00:00+00:00",
        },
    }
    manifest["checksums"] = {
        "events_sha256": digest(path / "events.jsonl"),
        "summary_sha256": digest(path / "latest-summary.md"),
    }
    (path / "manifest.json").write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def refresh_checksum(path: Path, key: str, payload: Path) -> None:
    manifest_path = path / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    manifest["checksums"][key] = digest(payload)
    manifest_path.write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )

base = tmp / "base"
write_bundle(base)
validate_bundle(base, expected_repo=repo, expected_branch_hash=branch_hash, expected_head_sha=head, expected_run_id=run_id)

invalid_events = tmp / "invalid-events"
shutil.copytree(base, invalid_events)
(invalid_events / "events.jsonl").write_bytes(
    (invalid_events / "events.jsonl").read_bytes().replace(b'"stop"', b'"st\xffop"', 1)
)
refresh_checksum(invalid_events, "events_sha256", invalid_events / "events.jsonl")
try:
    validate_bundle(invalid_events)
except HandoffError:
    pass
else:
    raise AssertionError("invalid UTF-8 events unexpectedly passed")

invalid_summary = tmp / "invalid-summary"
shutil.copytree(base, invalid_summary)
(invalid_summary / "latest-summary.md").write_bytes(b"# Summary\nprivate-\xff-value\n")
refresh_checksum(invalid_summary, "summary_sha256", invalid_summary / "latest-summary.md")
try:
    validate_bundle(invalid_summary)
except HandoffError:
    pass
else:
    raise AssertionError("invalid UTF-8 summary unexpectedly passed")
PY

EXPORT_REPO="$TMP/export-repo"
CUSTOM="$TMP/custom"
git init -q "$EXPORT_REPO"
git -C "$EXPORT_REPO" config user.email telemetry@example.invalid
git -C "$EXPORT_REPO" config user.name telemetry
printf 'base\n' > "$EXPORT_REPO/README.md"
git -C "$EXPORT_REPO" add README.md
git -C "$EXPORT_REPO" commit -qm base
mkdir -p "$CUSTOM"
printf 'utf8-export-run\n' > "$CUSTOM/run_id"
printf '{"trace_id":"utf8-export-run","name":"eos.st\377op","attributes":{"eos.event.name":"stop"}}\n' > "$CUSTOM/events.jsonl"
if (
  cd "$EXPORT_REPO"
  EOS_TELEMETRY_FILE="$CUSTOM/events.jsonl" \
  EOS_TELEMETRY_RUN_ID_FILE="$CUSTOM/run_id" \
    python3 "$ROOT/scripts/monitoring/export-telemetry-run.py" \
      --out "$TMP/export-invalid-events" --repo example/utf8-target \
      --branch feature/utf8 --head-sha "$(git rev-parse HEAD)" >/dev/null 2>&1
); then
  echo 'invalid UTF-8 export events unexpectedly passed'; exit 1
fi

printf '{"trace_id":"utf8-export-run","name":"eos.stop","attributes":{"eos.event.name":"stop"}}\n' > "$CUSTOM/events.jsonl"
printf 'utf8-\377-run\n' > "$CUSTOM/run_id"
if (
  cd "$EXPORT_REPO"
  EOS_TELEMETRY_FILE="$CUSTOM/events.jsonl" \
  EOS_TELEMETRY_RUN_ID_FILE="$CUSTOM/run_id" \
    python3 "$ROOT/scripts/monitoring/export-telemetry-run.py" \
      --out "$TMP/export-invalid-run-id" --repo example/utf8-target \
      --branch feature/utf8 --head-sha "$(git rev-parse HEAD)" >/dev/null 2>&1
); then
  echo 'invalid UTF-8 export run id unexpectedly passed'; exit 1
fi

echo 'telemetry invalid UTF-8 tests passed'

#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

python3 - "$ROOT" "$TMP" <<'PY'
import hashlib
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
tmp = Path(sys.argv[2])
sys.path.insert(0, str(root / "scripts" / "monitoring"))
from telemetry_handoff import HANDOFF_SCHEMA, RUN_SCHEMA, HandoffError, stable_hash, validate_bundle

bundle = tmp / "bundle"
bundle.mkdir()
run_id = "boundary-run"
repo = "example/boundary-target"
head = "a" * 40
branch_hash = "b" * 32
rows = [
    {"trace_id": run_id, "name": "eos.session_start", "attributes": {"eos.event.name": "session_start"}},
    {"trace_id": run_id, "name": "eos.tool", "attributes": {"eos.event.name": "tool"}},
]
(bundle / "events.jsonl").write_text("".join(json.dumps(row) + "\n" for row in rows), encoding="utf-8")
(bundle / "latest-summary.md").write_text("# Summary\n", encoding="utf-8")

def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

manifest = {
    "schema_version": RUN_SCHEMA,
    "run_id": run_id,
    "repo": repo,
    "head_sha": head,
    "event_count": 2,
    "privacy_contract": "metadata-only",
    "checksums": {
        "events_sha256": digest(bundle / "events.jsonl"),
        "summary_sha256": digest(bundle / "latest-summary.md"),
    },
    "handoff": {
        "schema_version": HANDOFF_SCHEMA,
        "repo": repo,
        "pr_number": 42,
        "pr_binding": "exact",
        "source_branch_hash": branch_hash,
        "head_sha": head,
        "run_id_hash": stable_hash(run_id),
        "event_count": 2,
        "boundary_position": 1,
        "synced_at": "2026-07-16T00:00:00+00:00",
    },
}
(bundle / "manifest.json").write_text(json.dumps(manifest), encoding="utf-8")
validate_bundle(bundle)

manifest["handoff"]["boundary_position"] = 2
(bundle / "manifest.json").write_text(json.dumps(manifest), encoding="utf-8")
try:
    validate_bundle(bundle)
except HandoffError:
    pass
else:
    raise AssertionError("overstated boundary position unexpectedly passed")
PY

echo 'telemetry boundary validation tests passed'

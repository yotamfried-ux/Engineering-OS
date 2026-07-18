#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

python3 - "$ROOT" "$TMP" <<'PY'
import json
import sys
import threading
from pathlib import Path

root = Path(sys.argv[1])
tmp = Path(sys.argv[2])
sys.path.insert(0, str(root / "scripts" / "monitoring"))
from telemetry_handoff import atomic_write_json

target = tmp / "handoff-state.json"
wrote_legacy_temp = threading.Event()
release_legacy_writer = threading.Event()
errors = []
original_write_text = Path.write_text


def controlled_write_text(self, data, *args, **kwargs):
    result = original_write_text(self, data, *args, **kwargs)
    if self.name == "handoff-state.json.tmp" and '"writer": "a"' in data:
        wrote_legacy_temp.set()
        if not release_legacy_writer.wait(5):
            raise RuntimeError("timed out coordinating legacy writer")
    return result


def write(value):
    try:
        atomic_write_json(target, value)
    except Exception as exc:
        errors.append(exc)


Path.write_text = controlled_write_text
try:
    first = threading.Thread(target=write, args=({"writer": "a"},))
    first.start()

    if wrote_legacy_temp.wait(1):
        # Legacy implementations share handoff-state.json.tmp. Writer B replaces
        # that file while writer A is paused, so writer A must fail when resumed.
        atomic_write_json(target, {"writer": "b"})
        release_legacy_writer.set()
        first.join(5)
    else:
        # The hardened implementation does not use the shared Path.write_text
        # temp path. Finish the first writer, then exercise concurrent writers.
        first.join(5)
        workers = [
            threading.Thread(target=write, args=({"writer": f"worker-{index}"},))
            for index in range(32)
        ]
        for worker in workers:
            worker.start()
        for worker in workers:
            worker.join(5)
            if worker.is_alive():
                raise RuntimeError("concurrent writer did not finish")
finally:
    release_legacy_writer.set()
    Path.write_text = original_write_text

if first.is_alive():
    raise RuntimeError("first writer did not finish")
if errors:
    raise AssertionError(f"concurrent atomic writer failed: {errors[0]}")
value = json.loads(target.read_text(encoding="utf-8"))
assert str(value["writer"]).startswith(("a", "worker-"))
assert not (tmp / "handoff-state.json.tmp").exists()
PY

echo 'telemetry state atomic write tests passed'

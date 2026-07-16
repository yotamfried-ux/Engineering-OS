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
wrote_a = threading.Event()
allow_a = threading.Event()
errors = []
original_write_text = Path.write_text


def controlled_write_text(self, data, *args, **kwargs):
    result = original_write_text(self, data, *args, **kwargs)
    if self.suffix == ".tmp" and '"writer": "a"' in data:
        wrote_a.set()
        if not allow_a.wait(5):
            raise RuntimeError("timed out coordinating writer a")
    return result


def writer_a():
    try:
        atomic_write_json(target, {"writer": "a"})
    except Exception as exc:
        errors.append(exc)

Path.write_text = controlled_write_text
thread = threading.Thread(target=writer_a)
thread.start()
if not wrote_a.wait(5):
    raise RuntimeError("writer a never reached the temporary file")
atomic_write_json(target, {"writer": "b"})
allow_a.set()
thread.join(5)
Path.write_text = original_write_text
if thread.is_alive():
    raise RuntimeError("writer a did not finish")
if errors:
    raise AssertionError(f"concurrent atomic writer failed: {errors[0]}")
value = json.loads(target.read_text(encoding="utf-8"))
assert value["writer"] in {"a", "b"}
PY

echo 'telemetry state atomic write tests passed'

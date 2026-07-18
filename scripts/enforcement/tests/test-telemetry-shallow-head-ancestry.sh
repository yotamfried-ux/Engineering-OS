#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
SOURCE="$TMP/source"
REMOTE="$TMP/remote.git"
SHALLOW="$TMP/shallow"

mkdir -p "$SOURCE"
git init -q "$SOURCE"
git -C "$SOURCE" config user.email telemetry@example.invalid
git -C "$SOURCE" config user.name telemetry
printf 'one\n' > "$SOURCE/file.txt"
git -C "$SOURCE" add file.txt
git -C "$SOURCE" commit -qm one
OLD_HEAD="$(git -C "$SOURCE" rev-parse HEAD)"
printf 'two\n' > "$SOURCE/file.txt"
git -C "$SOURCE" commit -qam two
NEW_HEAD="$(git -C "$SOURCE" rev-parse HEAD)"
git -C "$SOURCE" branch -M main
git clone -q --bare "$SOURCE" "$REMOTE"
git clone -q --depth=1 --branch main "file://$REMOTE" "$SHALLOW"

if git -C "$SHALLOW" cat-file -e "$OLD_HEAD^{commit}" 2>/dev/null; then
  echo 'fixture error: old head unexpectedly exists in shallow clone'; exit 1
fi

python3 - "$ROOT" "$SHALLOW" "$OLD_HEAD" "$NEW_HEAD" <<'PY'
import importlib.util
import sys
from pathlib import Path

root = Path(sys.argv[1])
workspace = Path(sys.argv[2])
old_head = sys.argv[3]
new_head = sys.argv[4]
sys.path.insert(0, str(root / "scripts" / "monitoring"))
spec = importlib.util.spec_from_file_location(
    "sync_telemetry_run",
    root / "scripts" / "monitoring" / "sync-telemetry-run.py",
)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)
assert module.product_head_relation(workspace, old_head, new_head) == "ancestor"
PY

git -C "$SHALLOW" cat-file -e "$OLD_HEAD^{commit}"
echo 'telemetry shallow head ancestry tests passed'

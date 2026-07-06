#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
python3 "$ROOT/scripts/enforcement/check-scaling-extension.py" --root "$ROOT"
python3 "$ROOT/scripts/enforcement/fixtures/scaling-extension/run-fixtures.py" "$ROOT"
echo "scaling manifest and extension fixture checks passed"

#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
python3 "$ROOT/scripts/enforcement/check-scaling-extension.py" --root "$ROOT"
echo "scaling extension simulations passed"

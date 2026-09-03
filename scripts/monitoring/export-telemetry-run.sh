#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_RUNTIME="$SCRIPT_DIR/../enforcement/lib/python-runtime.sh"
[ -f "$PYTHON_RUNTIME" ] && [ -r "$PYTHON_RUNTIME" ] || {
  echo "ERROR_FOR_AGENT: missing Python runtime resolver: $PYTHON_RUNTIME" >&2
  exit 2
}
# shellcheck source=../enforcement/lib/python-runtime.sh
. "$PYTHON_RUNTIME"
eos_python_preflight || exit 2
export BASH_ENV="$PYTHON_RUNTIME"
python3 "$SCRIPT_DIR/export-telemetry-run.py" "$@"

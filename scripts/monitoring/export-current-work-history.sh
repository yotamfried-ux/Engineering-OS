#!/usr/bin/env bash
set -euo pipefail

# export-current-work-history.sh — same-workspace telemetry handoff helper.
#
# Documented, best-effort, not required. Copies the existing local telemetry
# recorder's output (.engineering-os/telemetry/) into a location
# collect-pr-work-history.py can read via --telemetry-file, for the case
# described in docs/operations/operational-work-history-rollout.md Stage 1.5:
# Claude's working environment and the pr-policy CI runner share a
# filesystem/artifact channel (e.g. a self-hosted runner, or an explicit
# upload-artifact/download-artifact pairing a target project sets up).
#
# This does nothing useful when Claude's session runs in a different
# environment than the CI runner — collect-pr-work-history.py still produces
# a valid artifact in that case, with telemetry_available=false.

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SRC="${EOS_TELEMETRY_DIR:-$ROOT/.engineering-os/telemetry}"
DEST="${1:-$ROOT/.engineering-os/work-history/local-telemetry}"

mkdir -p "$DEST"

copied=0
for name in events.jsonl latest-summary.md run_id; do
  if [ -f "$SRC/$name" ]; then
    cp "$SRC/$name" "$DEST/$name"
    copied=$((copied + 1))
  fi
done

if [ "$copied" -eq 0 ]; then
  echo "no local telemetry found at $SRC — nothing to hand off" >&2
  exit 0
fi

echo "handed off $copied telemetry file(s) from $SRC to $DEST"

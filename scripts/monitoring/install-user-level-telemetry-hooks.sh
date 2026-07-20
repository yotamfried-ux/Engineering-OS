#!/usr/bin/env bash
set -euo pipefail

# Installs Engineering OS telemetry hooks into user-level Claude Code settings
# ($HOME/.claude/settings.json) rather than a single project's settings. The
# installed dispatcher activates only for repositories with a valid
# .engineering-os/telemetry-policy.json marker.
#
# Usage:
#   install-user-level-telemetry-hooks.sh [--dry-run|--verify|--uninstall]
#
# ENGINEERING_OS_HOME must point at the canonical Engineering OS checkout. Its
# absolute path is baked into user-level hook commands, so rerun this installer
# if the checkout moves.

home_dir="${ENGINEERING_OS_HOME:-$HOME/.engineering-os}"
if [ ! -d "$home_dir" ]; then
  echo "ERROR_FOR_AGENT: Engineering OS checkout not found at: $home_dir" >&2
  echo "ACTION: set ENGINEERING_OS_HOME to the canonical checkout path and re-run." >&2
  exit 1
fi
home_dir="$(cd "$home_dir" && pwd)"
target="${EOS_USER_SETTINGS_PATH:-$HOME/.claude/settings.json}"

for runtime in \
  scripts/monitoring/patch-settings-telemetry.py \
  scripts/monitoring/eos-telemetry-dispatch.sh \
  scripts/monitoring/eos-telemetry-dispatch-resolve.py \
  scripts/monitoring/telemetry_repo_discovery.py \
  scripts/monitoring/eos-telemetry-session-start.sh \
  scripts/monitoring/eos-telemetry-event.sh \
  scripts/monitoring/record-and-sync-telemetry.sh \
  scripts/monitoring/require-telemetry-session.sh \
  scripts/monitoring/sync-telemetry-run.py \
  scripts/monitoring/telemetry_handoff.py; do
  if [ ! -f "$home_dir/$runtime" ]; then
    echo "ERROR_FOR_AGENT: missing telemetry runtime dependency: $home_dir/$runtime" >&2
    echo "ACTION: update the Engineering OS checkout before installing user-level hooks." >&2
    exit 1
  fi
done

patcher_args=("$target" --mode dispatcher --home "$home_dir")
case "${1:-}" in
  --dry-run) patcher_args+=(--dry-run) ;;
  --verify) patcher_args+=(--verify) ;;
  --uninstall) patcher_args+=(--uninstall) ;;
  "") ;;
  *)
    echo "ERROR_FOR_AGENT: unknown argument: $1 (expected --dry-run, --verify, or --uninstall)" >&2
    exit 1
    ;;
esac

mkdir -p "$(dirname "$target")"
python3 "$home_dir/scripts/monitoring/patch-settings-telemetry.py" "${patcher_args[@]}"

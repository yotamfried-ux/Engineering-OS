#!/usr/bin/env bash
set -euo pipefail

# Installs Engineering OS telemetry hooks into user-level Claude Code
# settings ($HOME/.claude/settings.json) rather than a single project's
# .claude/settings.json. This is the fix for a Claude Code Remote (or any)
# session whose working directory is not inside any single managed
# repository — project-level settings only load from the session's actual
# starting directory (not inherited like CLAUDE.md), so such a session never
# picks up a project's own hooks at all. User-level settings apply as a
# baseline to every session for this user, regardless of starting directory.
#
# This does NOT turn on machine-wide monitoring: the hooks it installs point
# at scripts/monitoring/eos-telemetry-dispatch.sh, which only ever touches a
# directory that is itself a git repository with a valid, non-symlink
# .engineering-os/telemetry-policy.json at its root (see
# telemetry_repo_discovery.py). A session working only in unmanaged
# repositories collects nothing.
#
# Usage:
#   install-user-level-telemetry-hooks.sh [--dry-run|--verify|--uninstall]
#
# ENGINEERING_OS_HOME must point at the canonical Engineering OS checkout;
# its absolute path is baked into the installed hook commands (a user-level
# settings file has no project cwd for a ${ENGINEERING_OS_HOME:-$(pwd)}
# fallback to resolve against) — re-run this installer if that checkout ever
# moves.

home_dir="${ENGINEERING_OS_HOME:-$HOME/.engineering-os}"
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
  [ -f "$home_dir/$runtime" ] || { echo "ERROR_FOR_AGENT: missing telemetry runtime dependency: $home_dir/$runtime" >&2; exit 1; }
done

patcher_args=("$target" --mode dispatcher --home "$home_dir")
case "${1:-}" in
  --dry-run) patcher_args+=(--dry-run) ;;
  --verify) patcher_args+=(--verify) ;;
  --uninstall) patcher_args+=(--uninstall) ;;
  "") ;;
  *) echo "ERROR_FOR_AGENT: unknown argument: $1 (expected --dry-run, --verify, or --uninstall)" >&2; exit 1 ;;
esac

mkdir -p "$(dirname "$target")"
python3 "$home_dir/scripts/monitoring/patch-settings-telemetry.py" "${patcher_args[@]}"

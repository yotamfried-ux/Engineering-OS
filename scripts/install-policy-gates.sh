#!/usr/bin/env bash
set -euo pipefail

target="${1:-$(pwd)}"
home_dir="${ENGINEERING_OS_HOME:-$HOME/.engineering-os}"
home_dir="$(cd "$home_dir" && pwd)"

mkdir -p "$target/.github/workflows"

for name in pr-policy.yml plan-policy.yml connector-evidence-policy.yml workflow-evidence-policy.yml; do
  src="$home_dir/.github/workflows/$name"
  dst="$target/.github/workflows/$name"
  if [ ! -f "$src" ]; then
    echo "missing source workflow: $src" >&2
    exit 1
  fi
  cp "$src" "$dst"
  echo "installed $name"
done

if [ "${EOS_SKIP_SETTINGS_PATCH:-0}" = "1" ]; then
  echo "settings patch skipped (preserving existing .claude/settings.json)"
  exit 0
fi

settings="$target/.claude/settings.json"
patcher="$home_dir/scripts/enforcement/patch-settings-runtime-evidence.sh"
if [ -f "$settings" ] && [ -f "$patcher" ]; then
  ENGINEERING_OS_HOME="$home_dir" bash "$patcher" "$settings"
fi

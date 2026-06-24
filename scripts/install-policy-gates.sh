#!/usr/bin/env bash
set -euo pipefail

target="${1:-$(pwd)}"
home_dir="${ENGINEERING_OS_HOME:-$HOME/.engineering-os}"

mkdir -p "$target/.github/workflows"

for name in pr-policy.yml plan-policy.yml; do
  src="$home_dir/.github/workflows/$name"
  dst="$target/.github/workflows/$name"
  if [ ! -f "$src" ]; then
    echo "missing source workflow: $src" >&2
    exit 1
  fi
  cp "$src" "$dst"
  echo "installed $name"
done

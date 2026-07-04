#!/usr/bin/env bash
set -euo pipefail

target="${1:-$(pwd)}"
home_dir="${ENGINEERING_OS_HOME:-$HOME/.engineering-os}"
home_dir="$(cd "$home_dir" && pwd)"

mkdir -p "$target/.github/workflows"

for name in pr-policy.yml plan-policy.yml connector-evidence-policy.yml workflow-evidence-policy.yml capability-evidence-policy.yml documentation-asset-policy.yml semantic-cleanup-policy.yml import-cleanup-policy.yml; do
  src="$home_dir/.github/workflows/$name"
  dst="$target/.github/workflows/$name"
  if [ ! -f "$src" ]; then
    echo "missing source workflow: $src" >&2
    exit 1
  fi
  cp "$src" "$dst"
  echo "installed $name"
done

# Several installed workflows call scripts/enforcement/*.sh (and, for
# capability-evidence-policy.yml, a TSV manifest and core/capability-registry.yaml)
# instead of carrying their validation logic inline. Without these dependency
# files, an installed target project's CI checkout is missing them and the
# workflow step exits 127 before validating anything. policy-gate-dependencies.tsv
# is the single source of truth for which files each workflow needs, so a new
# dependency is a manifest row here, not a one-off copy block.
manifest="$home_dir/scripts/enforcement/policy-gate-dependencies.tsv"
if [ ! -f "$manifest" ]; then
  echo "missing policy-gate dependency manifest: $manifest" >&2
  exit 1
fi
while IFS=$'\t' read -r workflow dep; do
  case "${workflow:-}" in ''|'#'*) continue ;; esac
  [ -n "${dep:-}" ] || continue
  dep_src="$home_dir/$dep"
  if [ ! -f "$dep_src" ]; then
    echo "missing policy-gate dependency: $dep_src (declared for $workflow)" >&2
    exit 1
  fi
  dep_dst="$target/$dep"
  mkdir -p "$(dirname "$dep_dst")"
  cp "$dep_src" "$dep_dst"
  case "$dep" in *.sh) chmod +x "$dep_dst" ;; esac
  echo "installed $dep (for $workflow)"
done < "$manifest"

mcp_installer="$home_dir/scripts/install-mcp-servers.sh"
if [ -x "$mcp_installer" ]; then
  ENGINEERING_OS_HOME="$home_dir" bash "$mcp_installer" "$target"
  echo "installed project-scoped MCP profiles"
fi

if [ "${EOS_SKIP_SETTINGS_PATCH:-0}" = "1" ]; then
  echo "settings patch skipped (preserving existing .claude/settings.json)"
  exit 0
fi

settings="$target/.claude/settings.json"
patcher="$home_dir/scripts/enforcement/patch-settings-runtime-evidence.sh"
if [ -f "$settings" ] && [ -f "$patcher" ]; then
  ENGINEERING_OS_HOME="$home_dir" bash "$patcher" "$settings"
fi

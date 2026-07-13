#!/usr/bin/env bash
set -euo pipefail

target="${1:-$(pwd)}"
home_dir="${ENGINEERING_OS_HOME:-$HOME/.engineering-os}"
home_dir="$(cd "$home_dir" && pwd)"

mkdir -p "$target/.github/workflows"
for name in pr-policy.yml plan-policy.yml connector-evidence-policy.yml workflow-evidence-policy.yml capability-evidence-policy.yml documentation-asset-policy.yml semantic-cleanup-policy.yml import-cleanup-policy.yml; do
  src="$home_dir/.github/workflows/$name"
  dst="$target/.github/workflows/$name"
  [ -f "$src" ] || { echo "missing source workflow: $src" >&2; exit 1; }
  cp "$src" "$dst"
  echo "installed $name"
done

manifest="$home_dir/scripts/enforcement/policy-gate-dependencies.tsv"
[ -f "$manifest" ] || { echo "missing policy-gate dependency manifest: $manifest" >&2; exit 1; }
while IFS=$'\t' read -r workflow dep; do
  case "${workflow:-}" in ''|'#'*) continue ;; esac
  [ -n "${dep:-}" ] || continue
  dep_src="$home_dir/$dep"
  [ -f "$dep_src" ] || { echo "missing policy-gate dependency: $dep_src (declared for $workflow)" >&2; exit 1; }
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

for runtime in \
  scripts/monitoring/patch-settings-telemetry.py \
  scripts/monitoring/eos-telemetry-session-start.sh \
  scripts/monitoring/eos-telemetry-event.sh \
  scripts/monitoring/record-and-sync-telemetry.sh \
  scripts/monitoring/sync-telemetry-run.py \
  scripts/monitoring/telemetry_handoff.py \
  scripts/monitoring/export-telemetry-run.py \
  scripts/monitoring/require-telemetry-session.sh \
  scripts/monitoring/eos-telemetry-summary.py; do
  [ -f "$home_dir/$runtime" ] || { echo "missing telemetry runtime dependency: $home_dir/$runtime" >&2; exit 1; }
done

settings="$target/.claude/settings.json"
mkdir -p "$(dirname "$settings")"
if [ ! -f "$settings" ]; then
  template="$home_dir/.claude/settings.json"
  [ -f "$template" ] || { echo "missing canonical Claude settings template: $template" >&2; exit 1; }
  cp "$template" "$settings"
  echo "installed .claude/settings.json"
fi

telemetry_patcher="$home_dir/scripts/monitoring/patch-settings-telemetry.py"
python3 "$telemetry_patcher" "$settings"
echo "installed/verified telemetry hooks, durable handoff, and session preflight"

if [ "${EOS_SKIP_SETTINGS_PATCH:-0}" != "1" ]; then
  runtime_patcher="$home_dir/scripts/enforcement/patch-settings-runtime-evidence.sh"
  if [ -f "$runtime_patcher" ]; then
    ENGINEERING_OS_HOME="$home_dir" bash "$runtime_patcher" "$settings"
  fi
else
  echo "runtime-evidence settings patch skipped; telemetry hooks remain required"
fi

python3 - "$settings" "$home_dir" <<'PY'
import json
import sys
from pathlib import Path
path = Path(sys.argv[1]); home = sys.argv[2]
data = json.loads(path.read_text(encoding="utf-8"))
replacements = {
    "${ENGINEERING_OS_HOME:-$(pwd)}": home,
    "${ENGINEERING_OS_HOME:-$PWD}": home,
    "${ENGINEERING_OS_HOME}": home,
}
def rewrite(value):
    if isinstance(value, dict): return {key: rewrite(item) for key, item in value.items()}
    if isinstance(value, list): return [rewrite(item) for item in value]
    if isinstance(value, str):
        for old, new in replacements.items(): value = value.replace(old, new)
    return value
path.write_text(json.dumps(rewrite(data), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY

policy="$target/.engineering-os/telemetry-policy.json"
mkdir -p "$(dirname "$policy")"
if [ ! -f "$policy" ]; then
  cat > "$policy" <<'JSON'
{
  "schema_version": "eos.telemetry.policy.v1",
  "remote_handoff": {
    "mode": "disabled",
    "remote": "origin",
    "branch": "engineering-os-telemetry"
  }
}
JSON
  echo "installed default telemetry handoff policy (disabled until target opts in)"
fi

echo "rendered .claude/settings.json with Engineering OS reference path"

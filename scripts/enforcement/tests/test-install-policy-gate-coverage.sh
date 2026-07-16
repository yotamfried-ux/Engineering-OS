#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
MANIFEST="$ROOT/scripts/enforcement/policy-gate-dependencies.tsv"
WORKFLOWS_DIR="$ROOT/.github/workflows"
INSTALLER="$ROOT/scripts/install-policy-gates.sh"
installed_workflows() { grep -oE '^for name in [^;]+' "$INSTALLER" | sed -E 's/^for name in //'; }
pass() { echo "ok: $1"; }
fail() { echo "fail: $1"; exit 1; }
manifest_has() { grep -Fqx "$1"$'\t'"$2" "$MANIFEST"; }
[ -f "$MANIFEST" ] || fail manifest_present; pass manifest_present
bad=0
while IFS=$'\t' read -r workflow dep; do
  case "${workflow:-}" in ''|'#'*) continue ;; esac
  [ -n "${dep:-}" ] || { echo "  fail: malformed row for $workflow"; bad=1; continue; }
  [ -f "$ROOT/$dep" ] || { echo "  fail: $workflow declares missing dependency $dep"; bad=1; }
done < "$MANIFEST"
if [ "$bad" -eq 0 ]; then pass all_manifest_dependencies_exist; else fail all_manifest_dependencies_exist; fi
bad=0; INSTALLED="$(installed_workflows)"; [ -n "$INSTALLED" ] || fail installed_workflows_list_non_empty
for wf in "$WORKFLOWS_DIR"/*.yml; do
  name="$(basename "$wf")"; case " $INSTALLED " in *" $name "*) ;; *) continue ;; esac
  while IFS= read -r called; do
    [ -n "$called" ] || continue
    manifest_has "$name" "$called" || { echo "  fail: $name calls $called with no matching manifest row"; bad=1; }
  done < <(grep -oE 'scripts/(enforcement|monitoring)/[A-Za-z0-9_.-]+\.(sh|py)' "$wf" | sort -u)
done
if [ "$bad" -eq 0 ]; then pass every_real_call_site_has_a_manifest_row; else fail every_real_call_site_has_a_manifest_row; fi
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
cat > "$TMP/fake-policy.yml" <<'EOF'
name: fake-policy
jobs:
  x:
    steps:
      - run: bash scripts/monitoring/check-fake-thing.sh
EOF
manifest_has fake-policy.yml scripts/monitoring/check-fake-thing.sh && fail undeclared_dependency_should_not_be_found_in_manifest
pass undeclared_dependency_correctly_absent_from_manifest
FAKE_HOME="$TMP/fake-eos-home"
mkdir -p "$FAKE_HOME/.github/workflows" "$FAKE_HOME/scripts/enforcement" "$FAKE_HOME/scripts/monitoring" "$FAKE_HOME/.claude"
for wf in $INSTALLED; do cp "$WORKFLOWS_DIR/$wf" "$FAKE_HOME/.github/workflows/$wf"; done
while IFS=$'\t' read -r workflow dep; do
  case "${workflow:-}" in ''|'#'*) continue ;; esac
  [ -n "${dep:-}" ] || continue
  mkdir -p "$FAKE_HOME/$(dirname "$dep")"; cp "$ROOT/$dep" "$FAKE_HOME/$dep"
done < "$MANIFEST"
cp "$MANIFEST" "$FAKE_HOME/scripts/enforcement/policy-gate-dependencies.tsv"
cp "$ROOT/.claude/settings.json" "$FAKE_HOME/.claude/settings.json"
for runtime in \
  patch-settings-telemetry.py eos-telemetry-session-start.sh eos-telemetry-event.sh \
  record-and-sync-telemetry.sh sync-telemetry-run.py telemetry_handoff.py \
  export-telemetry-run.py require-telemetry-session.sh eos-telemetry-summary.py; do
  cp "$ROOT/scripts/monitoring/$runtime" "$FAKE_HOME/scripts/monitoring/$runtime"
done
TARGET_OK="$TMP/install-target-ok"; mkdir -p "$TARGET_OK"
printf 'existing-entry\n' > "$TARGET_OK/.gitignore"
if EOS_SKIP_SETTINGS_PATCH=1 ENGINEERING_OS_HOME="$FAKE_HOME" bash "$INSTALLER" "$TARGET_OK" >/dev/null 2>&1; then pass installer_succeeds_with_manifest_present; else fail installer_succeeds_with_manifest_present; fi
bad=0
while IFS=$'\t' read -r workflow dep; do
  case "${workflow:-}" in ''|'#'*) continue ;; esac
  [ -n "${dep:-}" ] || continue
  [ -f "$TARGET_OK/$dep" ] || { echo "  fail: $dep missing from installed target"; bad=1; }
  case "$dep" in *.sh) [ -x "$TARGET_OK/$dep" ] || { echo "  fail: $dep installed without executable bit"; bad=1; } ;; esac
done < "$MANIFEST"
if [ "$bad" -eq 0 ]; then pass installer_copies_every_manifest_dependency; else fail installer_copies_every_manifest_dependency; fi
[ -f "$TARGET_OK/.claude/settings.json" ] || fail installer_creates_claude_settings; pass installer_creates_claude_settings
grep -q 'eos-telemetry-session-start.sh' "$TARGET_OK/.claude/settings.json" || fail installer_settings_include_telemetry
grep -q 'record-and-sync-telemetry.sh' "$TARGET_OK/.claude/settings.json" || fail installer_settings_include_handoff
grep -q 'require-telemetry-session.sh' "$TARGET_OK/.claude/settings.json" || fail installer_settings_include_preflight
pass installer_settings_include_telemetry_handoff
python3 - "$TARGET_OK/.engineering-os/telemetry-policy.json" "$TARGET_OK/.gitignore" <<'PY'
import json,sys
from pathlib import Path
p=json.load(open(sys.argv[1]))
assert p['schema_version']=='eos.telemetry.policy.v1'
assert p['remote_handoff']['mode']=='disabled'
assert p['remote_handoff']['branch']=='engineering-os-telemetry'
lines=Path(sys.argv[2]).read_text().splitlines()
assert 'existing-entry' in lines
for required in (
    '.engineering-os/telemetry/',
    '.engineering-os/work-history/',
    '.engineering-os/remote-telemetry/',
    '.engineering-os/selected-telemetry/',
):
    assert lines.count(required)==1
assert '.engineering-os/' not in lines
assert '.engineering-os/telemetry-policy.json' not in lines
PY
pass installer_creates_safe_policy_and_runtime_ignore_rules
EOS_SKIP_SETTINGS_PATCH=1 ENGINEERING_OS_HOME="$FAKE_HOME" bash "$INSTALLER" "$TARGET_OK" >/dev/null 2>&1
[ "$(grep -Fc '# BEGIN Engineering OS local runtime artifacts' "$TARGET_OK/.gitignore")" -eq 1 ] || fail installer_gitignore_block_is_idempotent
pass installer_gitignore_block_is_idempotent
rm "$FAKE_HOME/scripts/enforcement/policy-gate-dependencies.tsv"
TARGET_MISSING="$TMP/install-target-missing"; mkdir -p "$TARGET_MISSING"; rc=0
install_err="$(EOS_SKIP_SETTINGS_PATCH=1 ENGINEERING_OS_HOME="$FAKE_HOME" bash "$INSTALLER" "$TARGET_MISSING" 2>&1 >/dev/null)" || rc=$?
if [ "$rc" -ne 0 ]; then pass installer_fails_closed_when_manifest_missing; else fail installer_fails_closed_when_manifest_missing; fi
case "$install_err" in *"missing policy-gate dependency manifest:"*) pass missing_manifest_error_is_explicit ;; *) echo "stderr was: $install_err"; fail missing_manifest_error_is_explicit ;; esac
if find "$TARGET_MISSING" -mindepth 1 -type f 2>/dev/null | grep -v '/\.github/workflows/' | grep -q .; then fail no_dependency_copied_after_missing_manifest_failure; else pass no_dependency_copied_after_missing_manifest_failure; fi
echo "install policy-gate coverage simulations passed"

#!/usr/bin/env bash
# Contract and Windows smoke tests for the repository-tracked project installer.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
INSTALLER="$ROOT/scripts/install-engineering-os-project.sh"
POWERSHELL_INSTALLER="$ROOT/scripts/install-engineering-os-project.ps1"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

pass=0
fail=0
ok() { printf '  ✅ %s\n' "$1"; pass=$((pass + 1)); }
bad() { printf '  ❌ %s\n' "$1"; fail=$((fail + 1)); }

INSTALL_PATH="$PATH"
case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    if command -v python3 >/dev/null 2>&1; then
      real_python="$(python3 -c 'import sys; print(sys.executable)')"
    elif command -v python >/dev/null 2>&1; then
      real_python="$(python -c 'import sys; print(sys.executable)')"
    else
      real_python="$(py -3 -c 'import sys; print(sys.executable)')"
    fi
    real_python="$(cygpath -u "$real_python")"
    mkdir -p "$WORK/python-only"
    printf '#!/usr/bin/env bash\nexec %q "$@"\n' "$real_python" >"$WORK/python-only/python"
    chmod +x "$WORK/python-only/python"
    INSTALL_PATH=""
    IFS=: read -r -a path_entries <<<"$PATH"
    for entry in "${path_entries[@]}"; do
      if [ -x "$entry/python3" ] || [ -x "$entry/python3.exe" ]; then
        continue
      fi
      INSTALL_PATH="${INSTALL_PATH:+$INSTALL_PATH:}$entry"
    done
    INSTALL_PATH="$WORK/python-only:$INSTALL_PATH"
    if BASH_ENV= PATH="$INSTALL_PATH" bash -c 'type -P python3' >/dev/null 2>&1; then
      bad "Windows no-shim fixture still exposes python3"
    else
      ok "Windows integration fixture has no python3 executable"
    fi
    ;;
esac

if [ -f "$INSTALLER" ] && [ -f "$POWERSHELL_INSTALLER" ]; then
  ok "Bash and PowerShell installers are tracked together"
else
  bad "repository installer entry points are missing"
fi

if ! grep -Eqi 'outputs|\.local[/\\]bin|python3[^[:alnum:]]+shim' \
    "$INSTALLER" "$POWERSHELL_INSTALLER"; then
  ok "installers do not depend on machine-local helper or shim paths"
else
  bad "installer contains a machine-local helper or shim dependency"
fi

TARGET_MISSING="$WORK/missing runtime target"
mkdir -p "$TARGET_MISSING"
printf 'keep\n' >"$TARGET_MISSING/original.txt"
set +e
HOME="$WORK/missing-home" \
ENGINEERING_OS_HOME="$ROOT" \
EOS_CONTRACT_TEST=1 \
EOS_SKIP_REFERENCE_UPDATE=1 \
EOS_PYTHON_BIN=definitely-missing-python \
bash "$INSTALLER" "$TARGET_MISSING" >"$WORK/missing.out" 2>"$WORK/missing.err"
missing_code=$?
set -e
if [ "$missing_code" -ne 0 ] \
  && [ "$(find "$TARGET_MISSING" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')" = "1" ] \
  && grep -q 'configured Python runtime' "$WORK/missing.err"; then
  ok "runtime preflight fails before target mutation"
else
  bad "missing runtime did not fail cleanly before target mutation (code=$missing_code)"
fi

# Never update a reference that is itself the target or carries unpublished edits.
REFERENCE="$WORK/reference guard"
mkdir -p "$REFERENCE"
git -C "$REFERENCE" init -q
printf 'original\n' >"$REFERENCE/tracked.txt"
git -C "$REFERENCE" add tracked.txt
git -C "$REFERENCE" -c user.email=test@example.invalid -c user.name=test commit -qm init
printf 'local edit\n' >>"$REFERENCE/tracked.txt"
set +e
ENGINEERING_OS_HOME="$REFERENCE" bash "$INSTALLER" "$REFERENCE" >"$WORK/self.out" 2>&1
self_code=$?
ENGINEERING_OS_HOME="$REFERENCE" bash "$INSTALLER" "$TARGET_MISSING" >"$WORK/dirty.out" 2>&1
dirty_code=$?
set -e
if [ "$self_code" -ne 0 ] && grep -q 'must not be the target' "$WORK/self.out" \
  && [ "$dirty_code" -ne 0 ] && grep -q 'tracked local changes' "$WORK/dirty.out" \
  && grep -q 'local edit' "$REFERENCE/tracked.txt"; then
  ok "self-target and dirty reference are rejected before update without losing edits"
else
  bad "reference update guards did not preserve unpublished changes"
fi

TARGET_OK="$WORK/target project with spaces"
HOME_OK="$WORK/home with spaces"
mkdir -p "$TARGET_OK" "$HOME_OK"
git -C "$TARGET_OK" init -q
set +e
HOME="$HOME_OK" \
PATH="$INSTALL_PATH" \
ENGINEERING_OS_HOME="$ROOT" \
EOS_CONTRACT_TEST=1 \
EOS_SKIP_REFERENCE_UPDATE=1 \
bash "$INSTALLER" "$TARGET_OK" >"$WORK/install.out" 2>"$WORK/install.err"
install_code=$?
set -e
if [ "$install_code" -eq 0 ] \
  && grep -q 'Engineering OS installed and verified successfully' "$WORK/install.out" \
  && [ -s "$TARGET_OK/.claude/settings.json" ] \
  && [ -s "$HOME_OK/.claude/settings.json" ]; then
  ok "full install and both hook verifications support paths with spaces"
else
  bad "full installer contract failed (code=$install_code stderr=$(tail -1 "$WORK/install.err"))"
fi

# Exercise an installed inline recorder in a fresh hook shell, not just a wrapper.
inline_command="$(python3 - "$TARGET_OK/.claude/settings.json" <<'PY_INLINE'
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
commands = [hook.get("command", "") for blocks in data["hooks"].values()
            for block in blocks for hook in block.get("hooks", [])]
inline = [command for command in commands if "python3 -c" in command]
assert len(inline) == 5, len(inline)
assert all("eos_python_preflight" in command for command in inline)
print(next(command for command in inline if "evidence_record context7" in command))
PY_INLINE
)"
set +e
(
  cd "$TARGET_OK"
  printf '{"tool_name":"mcp__Context7__query-docs"}' \
    | BASH_ENV= PATH="$INSTALL_PATH" bash -c "$inline_command"
) >"$WORK/inline.out" 2>"$WORK/inline.err"
inline_code=$?
set -e
if [ "$inline_code" -eq 0 ] && grep -q 'context7' "$TARGET_OK/.claude/.evidence/ledger"; then
  ok "installed inline recorder works without a python3 executable"
else
  bad "installed inline recorder failed (code=$inline_code)"
fi

# The user's manual preflight command is a new process, not a child of hook-gate.sh.
# It must initialize the same resolver without relying on an inherited BASH_ENV.
set +e
(
  cd "$TARGET_OK"
  unset BASH_ENV EOS_PYTHON_RUNTIME_LOADED
  export PATH="$INSTALL_PATH"
  printf '{"hook_event_name":"SessionStart","session_id":"installer-fixture"}' \
    | bash "$ROOT/scripts/monitoring/eos-telemetry-session-start.sh"
  bash "$ROOT/scripts/monitoring/require-telemetry-session.sh" </dev/null
) >"$WORK/direct.out" 2>"$WORK/direct.err"
direct_code=$?
set -e
if [ "$direct_code" -eq 0 ] && grep -Eq 'telemetry session ready: events=[1-9][0-9]*' "$WORK/direct.out"; then
  ok "direct telemetry initialization and preflight use the portable runtime"
else
  bad "direct telemetry entry point failed (code=$direct_code err=$(tail -1 "$WORK/direct.err"))"
fi

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    if command -v powershell.exe >/dev/null 2>&1; then
      TARGET_PS="$WORK/powershell target with spaces"
      HOME_PS="$WORK/powershell home with spaces"
      mkdir -p "$TARGET_PS" "$HOME_PS"
      git -C "$TARGET_PS" init -q
      ps_installer="$(cygpath -w "$POWERSHELL_INSTALLER")"
      ps_target="$(cygpath -w "$TARGET_PS")"
      ps_root="$(cygpath -w "$ROOT")"
      ps_installer_b64="$(printf '%s' "$ps_installer" | base64 -w0)"
      ps_target_b64="$(printf '%s' "$ps_target" | base64 -w0)"
      ps_root_b64="$(printf '%s' "$ps_root" | base64 -w0)"
      ps_runner="$WORK/run-installer.ps1"
      cat >"$ps_runner" <<'POWERSHELL'
$decode = { param($value) [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($value)) }
$installer = & $decode $env:EOS_PS_INSTALLER_B64
$target = & $decode $env:EOS_PS_TARGET_B64
$eosHome = & $decode $env:EOS_PS_HOME_B64
& $installer -Target $target -EngineeringOsHome $eosHome
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
POWERSHELL
      ps_runner="$(cygpath -w "$ps_runner")"
      set +e
      HOME="$HOME_PS" \
      PATH="$INSTALL_PATH" \
      EOS_CONTRACT_TEST=1 \
      EOS_SKIP_REFERENCE_UPDATE=1 \
      EOS_PS_INSTALLER_B64="$ps_installer_b64" \
      EOS_PS_TARGET_B64="$ps_target_b64" \
      EOS_PS_HOME_B64="$ps_root_b64" \
      powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$ps_runner" \
        >"$WORK/powershell.out" 2>"$WORK/powershell.err"
      powershell_code=$?
      set -e
      if [ "$powershell_code" -eq 0 ] \
        && grep -q 'Engineering OS installed and verified successfully' "$WORK/powershell.out"; then
        ok "PowerShell launcher executes the tracked installer on Windows"
      else
        bad "PowerShell launcher failed on Windows (code=$powershell_code err=$(head -1 "$WORK/powershell.err"))"
        tail -12 "$WORK/powershell.err"
      fi
    else
      printf '  ➖ PowerShell launcher smoke skipped (powershell.exe unavailable)\n'
    fi
    ;;
  *) printf '  ➖ PowerShell launcher smoke skipped (not Git Bash on Windows)\n' ;;
esac

printf '\nproject installer: %d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]

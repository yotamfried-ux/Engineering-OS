#!/usr/bin/env bash
# Install or refresh Engineering OS in one target project from the canonical GitHub
# checkout, then verify both project-level and user-level Claude Code hooks.
set -euo pipefail

EOS_REPO="${ENGINEERING_OS_REPO:-https://github.com/yotamfried-ux/Engineering-OS.git}"
EOS_REF="${ENGINEERING_OS_REF:-main}"
EOS_HOME="${ENGINEERING_OS_HOME:-$HOME/.engineering-os}"
TARGET_INPUT="${1:-$(pwd)}"

fail() {
  printf 'ERROR_FOR_AGENT: %s\n' "$1" >&2
  exit 1
}

# PowerShell passes Windows paths through environment variables, not a `bash -c`
# command string. This preserves spaces under Windows PowerShell 5.1 as well as pwsh.
if [ -n "${EOS_TARGET_WINDOWS:-}" ] || [ -n "${EOS_HOME_WINDOWS:-}" ]; then
  command -v cygpath >/dev/null 2>&1 || fail "Windows path conversion requires Git Bash"
  [ -z "${EOS_TARGET_WINDOWS:-}" ] || TARGET_INPUT="$(cygpath -u "$EOS_TARGET_WINDOWS")"
  [ -z "${EOS_HOME_WINDOWS:-}" ] || EOS_HOME="$(cygpath -u "$EOS_HOME_WINDOWS")"
fi

[ -d "$TARGET_INPUT" ] || fail "target project directory does not exist: $TARGET_INPUT"
TARGET="$(cd "$TARGET_INPUT" && pwd)"
[ "$(cd "$EOS_HOME" 2>/dev/null && pwd || true)" != "$TARGET" ] \
  || fail "ENGINEERING_OS_HOME must not be the target project"

case "$EOS_REF" in
  ""|/*|*..*) fail "invalid Engineering OS git ref: $EOS_REF" ;;
esac

if [ "${EOS_SKIP_REFERENCE_UPDATE:-0}" = "1" ]; then
  [ "${EOS_CONTRACT_TEST:-0}" = "1" ] \
    || fail "EOS_SKIP_REFERENCE_UPDATE is allowed only with EOS_CONTRACT_TEST=1"
  [ -d "$EOS_HOME/.git" ] \
    || fail "contract-test Engineering OS checkout not found at: $EOS_HOME"
elif [ -d "$EOS_HOME/.git" ]; then
  git -C "$EOS_HOME" diff --quiet && git -C "$EOS_HOME" diff --cached --quiet \
    || fail "Engineering OS reference has tracked local changes; preserve them in GitHub before updating"
  git -C "$EOS_HOME" fetch --quiet origin "$EOS_REF"
  if [ "$EOS_REF" = "main" ]; then
    git -C "$EOS_HOME" switch main --quiet
    git -C "$EOS_HOME" merge --ff-only --quiet FETCH_HEAD
  else
    git -C "$EOS_HOME" switch --detach --quiet FETCH_HEAD
  fi
elif [ -e "$EOS_HOME" ]; then
  fail "Engineering OS home exists but is not a git checkout: $EOS_HOME"
else
  mkdir -p "$(dirname "$EOS_HOME")"
  git clone --depth 1 --branch "$EOS_REF" "$EOS_REPO" "$EOS_HOME"
fi

EOS_HOME="$(cd "$EOS_HOME" && pwd)"
[ "$EOS_HOME" != "$TARGET" ] \
  || fail "ENGINEERING_OS_HOME must not be the target project"

PYTHON_RUNTIME="$EOS_HOME/scripts/enforcement/lib/python-runtime.sh"
[ -f "$PYTHON_RUNTIME" ] && [ -r "$PYTHON_RUNTIME" ] \
  || fail "Engineering OS checkout does not contain the Python runtime resolver: $PYTHON_RUNTIME"

# This is the final preflight before any target or Claude settings mutation. It runs in
# the same Git Bash environment that will execute the installed hook commands.
# shellcheck source=enforcement/lib/python-runtime.sh
. "$PYTHON_RUNTIME"
eos_python_preflight || fail "Engineering OS hooks were not activated"
export BASH_ENV="$PYTHON_RUNTIME"
export ENGINEERING_OS_HOME="$EOS_HOME"

(
  cd "$TARGET"
  EOS_UPDATE_SETTINGS=1 bash "$EOS_HOME/scripts/use-in-project.sh"
)

bash "$EOS_HOME/scripts/monitoring/install-user-level-telemetry-hooks.sh"
bash "$EOS_HOME/scripts/monitoring/install-user-level-telemetry-hooks.sh" --verify

TARGET_SETTINGS="$TARGET/.claude/settings.json"
eos_python "$EOS_HOME/scripts/monitoring/patch-settings-telemetry.py" \
  "$TARGET_SETTINGS" --mode direct --home "$EOS_HOME" --verify
eos_python "$EOS_HOME/scripts/enforcement/check-hard-hook-contract.py" \
  --root "$EOS_HOME" --settings "$TARGET_SETTINGS" --surface installed

REFERENCE_SHA="$(git -C "$EOS_HOME" rev-parse HEAD)"
printf 'Engineering OS installed and verified successfully.\n'
printf 'reference: %s@%s\n' "$EOS_REPO" "$REFERENCE_SHA"
printf 'target: %s\n' "$TARGET"

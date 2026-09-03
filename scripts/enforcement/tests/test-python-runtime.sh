#!/usr/bin/env bash
# Hermetic contract tests for the portable Python 3 resolver.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
RUNTIME="$ROOT/scripts/enforcement/lib/python-runtime.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

pass=0
fail=0
ok() { printf '  ✅ %s\n' "$1"; pass=$((pass + 1)); }
bad() { printf '  ❌ %s\n' "$1"; fail=$((fail + 1)); }

make_fake() {
  local path="$1" label="$2" major="$3"
  mkdir -p "$(dirname "$path")"
  cat > "$path" <<EOF_FAKE
#!/bin/bash
if [ "\${1:-}" = "-3" ]; then shift; fi
if [ "\${1:-}" = "-c" ]; then
  exit $([ "$major" = 3 ] && printf 0 || printf 1)
fi
printf 'RUN %s' '$label'
printf ' <%s>' "\$@"
printf '\n'
EOF_FAKE
  chmod +x "$path"
}

run_with_path() {
  local path="$1"
  shift
  (
    PATH="$path"
    unset EOS_PYTHON_BIN EOS_PYTHON_RUNTIME_LOADED
    # shellcheck source=../lib/python-runtime.sh
    . "$RUNTIME"
    eos_python "$@"
  )
}

# Candidate order is deterministic and accepts the two common Windows names.
dir="$WORK/all"
make_fake "$dir/python3" python3 3
make_fake "$dir/python" python 3
make_fake "$dir/py" py 3
out="$(run_with_path "$dir" payload)"
[ "$out" = 'RUN python3 <payload>' ] && ok "python3 has first priority" || bad "python3 priority (out=$out)"

dir="$WORK/python-only"
make_fake "$dir/python" python 3
out="$(run_with_path "$dir" payload)"
[ "$out" = 'RUN python <payload>' ] && ok "python fallback works" || bad "python fallback (out=$out)"

dir="$WORK/py-only"
make_fake "$dir/py" py 3
out="$(run_with_path "$dir" payload)"
[ "$out" = 'RUN py <payload>' ] && ok "Windows py -3 fallback works" || bad "py -3 fallback (out=$out)"

# A non-Python-3 executable is rejected and discovery continues.
dir="$WORK/version-fallback"
make_fake "$dir/python3" python2 2
make_fake "$dir/python" python3 3
out="$(run_with_path "$dir" payload)"
[ "$out" = 'RUN python3 <payload>' ] && ok "non-Python-3 candidate is rejected" || bad "version fallback (out=$out)"

# Overrides are one executable argv token, including paths with spaces.
spaced="$WORK/runtime with spaces/custom python"
make_fake "$spaced" spaced 3
out="$(
(
  PATH="$WORK/empty"
  EOS_PYTHON_BIN="$spaced"
  unset EOS_PYTHON_RUNTIME_LOADED
  . "$RUNTIME"
  eos_python payload
) 2>&1
)"
[ "$out" = 'RUN spaced <payload>' ] && ok "explicit runtime path with spaces is argv-safe" || bad "spaced override (out=$out)"

# A command-shaped override is never evaluated as shell source.
marker="$WORK/must-not-exist"
set +e
err="$(
(
  PATH="$WORK/empty"
  EOS_PYTHON_BIN="missing-python; touch $marker"
  unset EOS_PYTHON_RUNTIME_LOADED
  . "$RUNTIME"
  eos_python_preflight
) 2>&1
)"
code=$?
set -e
if [ "$code" -ne 0 ] && [ ! -e "$marker" ] && printf '%s' "$err" | grep -q 'configured Python runtime'; then
  ok "override strings are not evaluated"
else
  bad "command-shaped override was not rejected safely (code=$code err=$err)"
fi

# No candidate is an explicit, actionable failure.
mkdir -p "$WORK/empty"
set +e
err="$(
(
  PATH="$WORK/empty"
  unset EOS_PYTHON_BIN EOS_PYTHON_RUNTIME_LOADED
  . "$RUNTIME"
  eos_python_preflight
) 2>&1
)"
code=$?
set -e
if [ "$code" -ne 0 ] && printf '%s' "$err" | grep -q 'tried python3, python, and py -3' && printf '%s' "$err" | grep -q 'ACTION:'; then
  ok "missing runtime fails with actionable diagnostics"
else
  bad "missing runtime contract (code=$code err=$err)"
fi

printf '\npython-runtime: %d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]

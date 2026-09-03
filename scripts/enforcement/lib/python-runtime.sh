#!/usr/bin/env bash
# python-runtime.sh — one argv-safe Python 3 contract for Engineering OS shell runtime.
#
# Source this file and call eos_python, or set BASH_ENV to this path before starting a
# child Bash process whose existing code invokes `python3`. Discovery never evaluates a
# command string: the Windows `py -3` launcher is stored as two argv entries.

if [ "${EOS_PYTHON_RUNTIME_LOADED:-0}" = "1" ] \
  && [ "${BASH_SOURCE[0]}" != "$0" ]; then
  return 0 2>/dev/null || exit 0
fi
EOS_PYTHON_RUNTIME_LOADED=1

EOS_PYTHON_ERROR=""
EOS_PYTHON_ARGV=()

_eos_python_candidate_is_v3() {
  "$@" -c 'import sys; raise SystemExit(0 if sys.version_info.major == 3 else 1)' \
    >/dev/null 2>&1
}

_eos_python_select() {
  local executable="$1" resolved=""
  shift
  [ -n "$executable" ] || return 1
  case "$executable" in
    */*) [ -x "$executable" ] || return 1; resolved="$executable" ;;
    *) resolved="$(type -P "$executable" 2>/dev/null || true)" ;;
  esac
  [ -n "$resolved" ] || return 1
  _eos_python_candidate_is_v3 "$resolved" "$@" || return 1
  EOS_PYTHON_ARGV=("$resolved" "$@")
  return 0
}

eos_python_resolve() {
  [ "${#EOS_PYTHON_ARGV[@]}" -gt 0 ] && return 0
  EOS_PYTHON_ERROR=""

  # An override is one executable token, quoted as one argv entry. It may be an
  # absolute path containing spaces, but it is never eval'd and cannot smuggle args.
  if [ -n "${EOS_PYTHON_BIN:-}" ]; then
    if _eos_python_select "$EOS_PYTHON_BIN"; then
      return 0
    fi
    EOS_PYTHON_ERROR="configured Python runtime is unavailable or is not Python 3: $EOS_PYTHON_BIN"
    return 1
  fi

  if _eos_python_select python3; then
    return 0
  fi
  if _eos_python_select python; then
    return 0
  fi
  if _eos_python_select py -3; then
    return 0
  fi

  EOS_PYTHON_ERROR="no usable Python 3 runtime found (tried python3, python, and py -3)"
  return 1
}

eos_python() {
  if ! eos_python_resolve; then
    printf 'ERROR_FOR_AGENT: %s\n' "$EOS_PYTHON_ERROR" >&2
    return 127
  fi
  "${EOS_PYTHON_ARGV[@]}" "$@"
}

eos_python_preflight() {
  if eos_python_resolve; then
    return 0
  fi
  printf 'ERROR_FOR_AGENT: %s\n' "$EOS_PYTHON_ERROR" >&2
  printf 'ACTION: install Python 3 or expose python3, python, or the Windows py launcher before activating Engineering OS hooks.\n' >&2
  return 1
}

# Compatibility for existing hook and telemetry units. Because this function delegates
# to a resolved argv array rather than a command string, `py -3` stays injection-safe.
python3() {
  eos_python "$@"
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  case "${1:-}" in
    --check)
      shift
      eos_python_preflight
      ;;
    --)
      shift
      eos_python "$@"
      ;;
    *)
      eos_python "$@"
      ;;
  esac
fi

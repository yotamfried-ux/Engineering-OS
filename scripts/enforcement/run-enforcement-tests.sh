#!/usr/bin/env bash
# run-enforcement-tests.sh — canonical failure-propagating runner for EOS Bash suites.
#
# With no arguments, runs every scripts/enforcement/tests/test-*.sh suite.
# Optional explicit paths are supported for deterministic regression fixtures.
# The process exits non-zero if any suite fails, so a successful PostToolUse event
# for a direct invocation of this runner is trustworthy `tests_run` evidence.
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if [ "$#" -gt 0 ]; then
  TESTS=("$@")
else
  shopt -s nullglob
  TESTS=("$ROOT"/scripts/enforcement/tests/test-*.sh)
  shopt -u nullglob
fi

if [ "${#TESTS[@]}" -eq 0 ]; then
  echo "❌ no enforcement test suites found" >&2
  exit 1
fi

fail=0
count=0
for test_path in "${TESTS[@]}"; do
  count=$((count + 1))
  echo "──────── $test_path ────────"
  if bash "$test_path"; then
    :
  else
    fail=1
  fi
done

echo
if [ "$fail" -ne 0 ]; then
  echo "❌ one or more enforcement suites failed"
  exit 1
fi

echo "✅ all $count enforcement suites passed"

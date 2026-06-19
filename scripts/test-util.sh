#!/usr/bin/env bash

# run_test <test-name> <exit-code>
# Prints "PASS: <name>" or "FAIL: <name>" based on exit code.
# Usage: run_test "my test" $?
run_test() {
  local name="$1"
  local exit_code="${2:-$?}"

  if [[ "$exit_code" -eq 0 ]]; then
    echo "PASS: $name"
  else
    echo "FAIL: $name"
  fi
}

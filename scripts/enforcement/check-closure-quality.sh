#!/usr/bin/env bash
set -euo pipefail
file="${1:-}"
[ -n "$file" ] || exit 1
echo ok

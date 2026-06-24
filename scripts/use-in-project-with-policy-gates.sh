#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target="${1:-$(pwd)}"

cd "$target"
"$script_dir/use-in-project.sh"
"$script_dir/install-policy-gates.sh" "$target"

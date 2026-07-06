#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECKER="$ROOT/scripts/enforcement/check-result-loop-contract.py"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

python3 "$CHECKER" --root "$ROOT"

copy_repo() {
  local name="$1"
  local repo="$TMPDIR/$name"
  mkdir -p "$repo"
  tar --exclude='.git' -C "$ROOT" -cf - . | tar -C "$repo" -xf -
  printf '%s\n' "$repo"
}

expect_reject() {
  local name="$1"
  local repo="$2"
  if python3 "$repo/scripts/enforcement/check-result-loop-contract.py" --root "$repo" >/tmp/result-loop-$name.out 2>&1; then
    echo "ERROR_FOR_AGENT: result-loop checker accepted incomplete fixture $name" >&2
    cat /tmp/result-loop-$name.out >&2
    exit 1
  fi
  echo "rejected incomplete result-loop fixture: $name"
}

repo="$(copy_repo missing-contract-row)"
awk 'BEGIN{FS=OFS="\t"} !/^web-application\t/' "$repo/scripts/enforcement/result-loop-requirements.tsv" > "$repo/result-loop.tmp"
mv "$repo/result-loop.tmp" "$repo/scripts/enforcement/result-loop-requirements.tsv"
expect_reject missing-contract-row "$repo"

repo="$(copy_repo placeholder-field)"
awk 'BEGIN{FS=OFS="\t"} $1=="web-application"{$5="required"} {print}' "$repo/scripts/enforcement/result-loop-requirements.tsv" > "$repo/result-loop.tmp"
mv "$repo/result-loop.tmp" "$repo/scripts/enforcement/result-loop-requirements.tsv"
expect_reject placeholder-field "$repo"

repo="$(copy_repo mobile-no-local-review)"
awk 'BEGIN{FS=OFS="\t"} $1=="mobile-application"{$8="local unit test output only"} {print}' "$repo/scripts/enforcement/result-loop-requirements.tsv" > "$repo/result-loop.tmp"
mv "$repo/result-loop.tmp" "$repo/scripts/enforcement/result-loop-requirements.tsv"
expect_reject mobile-no-local-review "$repo"

repo="$(copy_repo api-no-performance)"
awk 'BEGIN{FS=OFS="\t"} $1=="api-service"{$12="NONE"} {print}' "$repo/scripts/enforcement/result-loop-requirements.tsv" > "$repo/result-loop.tmp"
mv "$repo/result-loop.tmp" "$repo/scripts/enforcement/result-loop-requirements.tsv"
expect_reject api-no-performance "$repo"

repo="$(copy_repo missing-telemetry-export)"
awk 'BEGIN{FS=OFS="\t"} $1=="ai-agent"{$15="manual note only"} {print}' "$repo/scripts/enforcement/result-loop-requirements.tsv" > "$repo/result-loop.tmp"
mv "$repo/result-loop.tmp" "$repo/scripts/enforcement/result-loop-requirements.tsv"
expect_reject missing-telemetry-export "$repo"

repo="$(copy_repo game-no-playable)"
awk 'BEGIN{FS=OFS="\t"} $1=="game-development"{$7="log report only"} {print}' "$repo/scripts/enforcement/result-loop-requirements.tsv" > "$repo/result-loop.tmp"
mv "$repo/result-loop.tmp" "$repo/scripts/enforcement/result-loop-requirements.tsv"
expect_reject game-no-playable "$repo"

echo "result loop contract checker tests passed"
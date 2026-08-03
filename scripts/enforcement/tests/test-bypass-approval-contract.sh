#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-bypass-approval-contract.py"

python3 "$CHECK" --strict-runtime

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
cp -a "$ROOT/." "$tmp/repo"

expect_fail() {
  local name="$1"; shift
  if "$@" >"$tmp/$name.out" 2>&1; then
    echo "FAIL: $name unexpectedly passed" >&2
    cat "$tmp/$name.out" >&2
    exit 1
  fi
}

cp -a "$tmp/repo" "$tmp/duplicate"
sed -n '2p' "$tmp/duplicate/scripts/enforcement/bypass-policy.tsv" >> "$tmp/duplicate/scripts/enforcement/bypass-policy.tsv"
expect_fail duplicate python3 "$CHECK" --root "$tmp/duplicate"

cp -a "$tmp/repo" "$tmp/missing"
sed -i '/^EOS_BYPASS_ENTRY\t/d' "$tmp/missing/scripts/enforcement/bypass-policy.tsv"
expect_fail missing python3 "$CHECK" --root "$tmp/missing"

cp -a "$tmp/repo" "$tmp/master"
sed -i 's/^EOS_BYPASS_WORKFLOW\(.*\)master-disabled$/EOS_BYPASS_WORKFLOW\1action-specific/' "$tmp/master/scripts/enforcement/bypass-policy.tsv"
expect_fail master python3 "$CHECK" --root "$tmp/master"

cp -a "$tmp/repo" "$tmp/fallback"
printf '\nbypass_active() { case "${EOS_BYPASS_ENTRY:-}" in 1) return 0;; esac; }\n' >> "$tmp/fallback/scripts/enforcement/enforce-bash-entry.sh"
expect_fail fallback python3 "$CHECK" --strict-runtime --root "$tmp/fallback"

cp -a "$tmp/repo" "$tmp/fallback-function"
printf '\nfunction bypass_active { case "${EOS_BYPASS_ENTRY:-}" in 1) return 0;; esac; }\n' >> "$tmp/fallback-function/scripts/enforcement/enforce-bash-entry.sh"
expect_fail fallback_function python3 "$CHECK" --strict-runtime --root "$tmp/fallback-function"

cp -a "$tmp/repo" "$tmp/direct-bracket"
printf '\nif [[ "${EOS_BYPASS_ENTRY:-}" == "1" ]]; then exit 0; fi\n' >> "$tmp/direct-bracket/scripts/enforcement/enforce-bash-entry.sh"
expect_fail direct_bracket python3 "$CHECK" --strict-runtime --root "$tmp/direct-bracket"

cp -a "$tmp/repo" "$tmp/direct-test"
printf '\nif test "${EOS_BYPASS_ENTRY:-}" = "1"; then exit 0; fi\n' >> "$tmp/direct-test/scripts/enforcement/enforce-bash-entry.sh"
expect_fail direct_test python3 "$CHECK" --strict-runtime --root "$tmp/direct-test"

cp -a "$tmp/repo" "$tmp/tag"
printf '\n# bypass consumption: git tag eos-bypass-used\n' >> "$tmp/tag/scripts/enforcement/enforce-bash-entry.sh"
expect_fail tag python3 "$CHECK" --strict-runtime --root "$tmp/tag"

echo "test-bypass-approval-contract: PASS"

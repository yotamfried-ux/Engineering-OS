#!/usr/bin/env bash
# test-documentation-ownership.sh — static regression checks for documentation boundaries.
# Run: bash scripts/enforcement/tests/test-documentation-ownership.sh
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ✅ %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  ❌ %s\n' "$1"; }

contains() {
  local file="$1" pattern="$2"
  grep -Eq "$pattern" "$ROOT/$file"
}

not_contains() {
  local file="$1" pattern="$2"
  ! grep -Eq "$pattern" "$ROOT/$file"
}

echo "── ownership map ──"
contains "core/documentation-policy.md" '^## <canonical_ownership>' \
  && ok "documentation policy defines canonical ownership" \
  || bad "documentation policy missing <canonical_ownership>"
contains "core/documentation-policy.md" 'external-systems/README\.md.*אינו|external-systems/README\.md` \| חובה' \
  && ok "external-systems ownership appears in policy" \
  || bad "external-systems ownership missing from policy"
contains "core/documentation-policy.md" '\.claude/plans/\*' \
  && ok "plan lifecycle ownership appears in policy" \
  || bad "plan lifecycle ownership missing from policy"

echo "── inventory boundaries ──"
contains "external-systems/README.md" 'index-only' \
  && ok "external systems README declares index-only role" \
  || bad "external systems README missing index-only boundary"
contains "external-skills/README.md" 'index-only' \
  && ok "external skills README declares index-only role" \
  || bad "external skills README missing index-only boundary"
contains "external-skills/README.md" '^## Active SIP-managed skills' \
  && ok "external skills active table is explicit" \
  || bad "external skills active section missing"
contains "external-skills/README.md" '^## Replaced / deprecated wrappers' \
  && ok "deprecated skills section exists" \
  || bad "deprecated skills section missing"
contains "external-skills/README.md" '^## Adjacent accelerators' \
  && ok "adjacent accelerators section exists" \
  || bad "adjacent accelerators section missing"

echo "── known classification decisions ──"
not_contains "external-skills/README.md" '^\| \[frontend-design\].*\| .*Active' \
  && ok "frontend-design is not classified active" \
  || bad "frontend-design appears active"
contains "external-skills/README.md" '\| \[frontend-design\].*replaced.*ui-ux-pro-max' \
  && ok "frontend-design is marked replaced by ui-ux-pro-max" \
  || bad "frontend-design replacement not documented"
contains "external-skills/README.md" '\| \[nemotron\].*adjacent accelerator' \
  && ok "nemotron is classified as adjacent accelerator" \
  || bad "nemotron adjacent classification missing"
not_contains "external-skills/README.md" '^\| \[nemotron\].*\| L[012]' \
  && ok "nemotron is not in active SIP level table" \
  || bad "nemotron appears in active SIP level table"

echo
printf '════════ %s passed, %s failed ════════\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]

#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
PASS=0
FAIL=0

ok() { PASS=$((PASS+1)); printf '  ✅ %s\n' "$1"; }
no() { FAIL=$((FAIL+1)); printf '  ❌ %s\n' "$1"; }

has() {
  local file="$1" pattern="$2"
  grep -Eq "$pattern" "$ROOT/$file"
}

lacks() {
  local file="$1" pattern="$2"
  ! grep -Eq "$pattern" "$ROOT/$file"
}

echo "doc ownership"
has "core/documentation-policy.md" '^## <canonical_ownership>' && ok "canonical ownership exists" || no "canonical ownership missing"
has "core/documentation-policy.md" 'external-systems/README\.md' && ok "external systems owner listed" || no "external systems owner missing"
has "core/documentation-policy.md" 'external-skills/README\.md' && ok "external skills owner listed" || no "external skills owner missing"
has "core/documentation-policy.md" '\.claude/plans/\*' && ok "plan lifecycle listed" || no "plan lifecycle missing"

echo "inventory boundaries"
has "external-systems/README.md" 'index-only' && ok "systems inventory role exists" || no "systems inventory role missing"
has "external-skills/README.md" 'index-only' && ok "skills inventory role exists" || no "skills inventory role missing"
has "external-systems/README.md" 'Connector selection and fallback.*connector-policy\.md' && ok "systems points to connector policy" || no "systems connector policy pointer missing"
has "external-skills/README.md" 'Skill Integration Protocol.*skill-orchestration-policy\.md' && ok "skills points to skill policy" || no "skills policy pointer missing"

echo "current decisions"
has "external-skills/README.md" 'frontend-design.*DEPRECATED.*ui-ux-pro-max' && ok "frontend replacement documented" || no "frontend replacement missing"
has "external-skills/README.md" 'Nemotron is an engine, not a skill' && ok "nemotron engine note exists" || no "nemotron engine note missing"
lacks "external-skills/README.md" '^\| .*\[nemotron\]' && ok "nemotron absent from skill rows" || no "nemotron appears in skill rows"

echo
printf 'passed=%s failed=%s\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]

#!/usr/bin/env bash
# test-ops-branch-protection.sh — regression tests for the ops scripts that apply
# main branch protection and prune merged branches.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
APPLY="$ROOT/scripts/ops/apply-main-branch-protection.sh"
PRUNE="$ROOT/scripts/ops/prune-merged-branches.sh"
MERGE_CHECK="$ROOT/scripts/enforcement/check-merge-readiness.sh"
chmod +x "$APPLY" "$PRUNE" 2>/dev/null || true

pass=0; fail=0
ok()  { echo "  ✅ $1"; pass=$((pass+1)); }
bad() { echo "  ❌ $1"; fail=$((fail+1)); }

# --- apply-main-branch-protection.sh dry-run: one context per required workflow ---
required_count="$(awk -F'"' '/^REQUIRED_WORKFLOWS_DEFAULT=/ { print $2; exit }' "$MERGE_CHECK" | tr ' ' '\n' | sed '/^$/d' | wc -l | xargs)"
apply_out="$(bash "$APPLY" 2>&1)"
apply_rc=$?

[ "$apply_rc" -eq 0 ] && ok "apply dry-run exits 0" || bad "apply dry-run should exit 0"

# Count contexts listed in the "Required check contexts (N):" header.
ctx_n="$(printf '%s\n' "$apply_out" | sed -n 's/^Required check contexts (\([0-9]\+\)):/\1/p')"
if [ "$ctx_n" = "$required_count" ] && [ "$required_count" -gt 0 ]; then
  ok "apply derives one context per required workflow ($ctx_n == $required_count)"
else
  bad "apply context count ($ctx_n) != required workflows ($required_count)"
fi

# Each required workflow's resolved context must be non-empty and present in the body.
for c in "enforcement-tests" "Require ready-for-review PR" "Require connector route plan evidence" \
         "Require Engineering OS workflow evidence" "Require capability evidence in changed plans" \
         "Require completed plan checklists" "Require documentation/reference asset evidence" \
         "semantic-cleanup-policy" "import-cleanup-policy"; do
  printf '%s\n' "$apply_out" | grep -qF "$c" \
    && ok "apply lists context: $c" \
    || bad "apply missing expected context: $c"
done

# Dry-run must not perform a network call (no HTTP/✅ applied lines).
if printf '%s\n' "$apply_out" | grep -qiE 'applied via|HTTP [0-9]'; then
  bad "apply dry-run must not hit the network"
else
  ok "apply dry-run performs no network call"
fi

# --- prune-merged-branches.sh: hermetic temp repo with known topology ---
tmp="$(mktemp -d)"
(
  cd "$tmp"
  git init -q --bare remote.git
  git clone -q remote.git work >/dev/null 2>&1
  cd work
  git config user.email ci@eos.local; git config user.name ci
  echo base > f; git add f; git commit -qm base
  git push -q origin HEAD:main >/dev/null 2>&1

  # merged-branch: ancestor of main (fast-forwarded in).
  git checkout -q -b merged-branch; echo m > g; git add g; git commit -qm m
  git checkout -q main; git merge -q --ff-only merged-branch >/dev/null 2>&1
  git push -q origin main >/dev/null 2>&1
  git push -q origin merged-branch >/dev/null 2>&1

  # unmerged-branch: has a commit not on main, NOT in any allowlist.
  git checkout -q -b unmerged-branch; echo u > h; git add h; git commit -qm u
  git push -q origin unmerged-branch >/dev/null 2>&1

  # superseded-x: a commit not on main, but allowlisted via --allow.
  git checkout -q main
  git checkout -q -b superseded-x; echo s > i; git add i; git commit -qm s
  git push -q origin superseded-x >/dev/null 2>&1
  git checkout -q main
) >/dev/null 2>&1

# The script resolves ROOT as <its dir>/../.., so place it at scripts/ops/ depth inside
# the temp work repo — then its git ops target the temp topology, not the real repo.
mkdir -p "$tmp/work/scripts/ops"
cp "$PRUNE" "$tmp/work/scripts/ops/prune.sh"
prune_out="$(cd "$tmp/work" && bash scripts/ops/prune.sh --allow=superseded-x 2>&1)"

printf '%s\n' "$prune_out" | grep -qE '✓ merged-branch' \
  && ok "prune lists ancestor-merged branch as deletable" \
  || bad "prune should list merged-branch as deletable"

printf '%s\n' "$prune_out" | grep -qE '✓ superseded-x' \
  && ok "prune honors --allow for a superseded branch" \
  || bad "prune should allow superseded-x via --allow"

if printf '%s\n' "$prune_out" | grep -qE '• unmerged-branch'; then
  ok "prune refuses (skips) an unmerged, non-allowlisted branch"
else
  bad "prune must skip unmerged-branch"
fi

# unmerged-branch must never appear in the deletion command.
if printf '%s\n' "$prune_out" | grep 'Would run:' | grep -qw 'unmerged-branch'; then
  bad "unmerged-branch must not be in the delete set"
else
  ok "unmerged-branch excluded from delete set"
fi

# current branch (main here) must never be deleted.
if printf '%s\n' "$prune_out" | grep 'Would run:' | grep -qw 'main'; then
  bad "main must never be in the delete set"
else
  ok "main excluded from delete set"
fi

rm -rf "$tmp"

echo
if [ "$fail" -ne 0 ]; then
  echo "❌ ops branch-protection tests: $fail failed, $pass passed"
  exit 1
fi
echo "✅ ops branch-protection tests passed ($pass checks)"

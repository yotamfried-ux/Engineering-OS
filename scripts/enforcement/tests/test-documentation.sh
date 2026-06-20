#!/usr/bin/env bash
# test-documentation.sh — regression tests for the documentation-policy.md enforcer.
# Run: bash scripts/enforcement/tests/test-documentation.sh
set -u

ENFORCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENFORCER="$ENFORCE_DIR/enforce-documentation.sh"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  ✅ %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  ❌ %s\n' "$1"; }
expect() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (expected exit $2, got $3)"; fi; }

REPO="$(mktemp -d)"; REPO2="$(mktemp -d)"
trap 'rm -rf "$REPO" "$REPO2" 2>/dev/null' EXIT

run() { bash "$ENFORCER" >/dev/null 2>&1; echo $?; }
reset_idx() { git reset -q >/dev/null 2>&1; }

# ── Main repo: has a committed root README (isolates D1/D3 from D2) ───────────
cd "$REPO" || exit 1
git init -q 2>/dev/null; git config user.email t@t.t; git config user.name t
echo '# Root' > README.md; git add README.md; git commit -qm init 2>/dev/null

echo "── D1: content dirs need README ──"
mkdir -p patterns/api; echo r > patterns/api/README.md; echo y > patterns/api/p.md; git add patterns/api
expect "patterns/<domain> with README allowed" 0 "$(run)"; reset_idx; rm -rf patterns
mkdir -p patterns/db; echo y > patterns/db/p.md; git add patterns/db/p.md
expect "patterns/<domain> without README blocked" 1 "$(run)"; reset_idx; rm -rf patterns
mkdir -p external-systems/foo; echo y > external-systems/foo/s.md; git add external-systems/foo/s.md
expect "external-systems/<svc> without README blocked" 1 "$(run)"; reset_idx; rm -rf external-systems
mkdir -p patterns; echo x > patterns/README.md; git add patterns/README.md
expect "patterns/ top-level README allowed" 0 "$(run)"; reset_idx; rm -rf patterns
mkdir -p patterns/db; echo y > patterns/db/p.md; git add patterns/db/p.md
expect "EOS_BYPASS_DOCREADME skips D1" 0 "$(EOS_BYPASS_DOCREADME=1 run)"; reset_idx; rm -rf patterns

echo "── D3: no standalone placeholders in .md ──"
printf 'TBD\n' > doc.md; git add doc.md
expect "standalone TBD blocked"            1 "$(run)"; reset_idx; rm -f doc.md
printf '## TBD\n' > doc.md; git add doc.md
expect "heading-only TBD blocked"          1 "$(run)"; reset_idx; rm -f doc.md
printf -- '- TBD\n' > doc.md; git add doc.md
expect "list-item TBD blocked"             1 "$(run)"; reset_idx; rm -f doc.md
printf '> XXX\n' > doc.md; git add doc.md
expect "blockquote XXX blocked"            1 "$(run)"; reset_idx; rm -f doc.md
printf 'status: TBD\n' > doc.md; git add doc.md
expect "key-value TBD blocked"             1 "$(run)"; reset_idx; rm -f doc.md
printf '???\n' > doc.md; git add doc.md
expect "standalone ??? blocked"            1 "$(run)"; reset_idx; rm -f doc.md
printf 'see the `TBD` list inline here\n' > doc.md; git add doc.md
expect "inline TBD prose allowed"          0 "$(run)"; reset_idx; rm -f doc.md
printf 'is this ??? unclear in prose\n' > doc.md; git add doc.md
expect "inline ??? prose allowed"          0 "$(run)"; reset_idx; rm -f doc.md
printf 'TBD\n' > note.txt; git add note.txt
expect "non-.md TBD allowed"               0 "$(run)"; reset_idx; rm -f note.txt
printf 'TBD\n' > doc.md; git add doc.md
expect "EOS_BYPASS_TBD skips D3"           0 "$(EOS_BYPASS_TBD=1 run)"; reset_idx; rm -f doc.md

echo "── general ──"
echo x > src.txt; git add src.txt
expect "unrelated file allowed"            0 "$(run)"; reset_idx; rm -f src.txt
expect "no staged files → pass"            0 "$(run)"

# ── D2: fresh repo WITHOUT a root README ─────────────────────────────────────
echo "── D2: root README required ──"
cd "$REPO2" || exit 1
git init -q 2>/dev/null; git config user.email t@t.t; git config user.name t
echo x > foo.txt; git add foo.txt
expect "missing root README blocked"       1 "$(run)"
expect "EOS_BYPASS_ROOTREADME skips D2"    0 "$(EOS_BYPASS_ROOTREADME=1 run)"
expect "EOS_BYPASS_DOC (master) skips all" 0 "$(EOS_BYPASS_DOC=1 run)"
echo '# r' > README.md; git add README.md
expect "root README present allowed"       0 "$(run)"

echo
echo "════════ $PASS passed, $FAIL failed ════════"
[ "$FAIL" -eq 0 ]

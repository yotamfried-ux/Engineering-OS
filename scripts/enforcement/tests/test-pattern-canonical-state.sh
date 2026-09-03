#!/usr/bin/env bash
# test-pattern-canonical-state.sh — fixtures for the canonical pattern-state gate.
#
# Covers the six drift classes named in the closure criterion of
# gap:pattern-registry-canonical-drift, plus the positive agreement case and the
# real repository state.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-pattern-canonical-state.sh"
chmod +x "$CHECK"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

ok(){ local n="$1"; shift; "$@" >"$TMP/$n.out" 2>&1 || { echo "fail: $n"; cat "$TMP/$n.out"; exit 1; }; echo "ok: $n"; }
no(){ local n="$1"; shift; if "$@" >"$TMP/$n.out" 2>&1; then echo "unexpected pass: $n"; cat "$TMP/$n.out"; exit 1; else echo "ok: $n"; fi; }

# no_msg <name> <expected-substring> <cmd...> — must fail *and* explain why.
no_msg(){
  local n="$1" want="$2"; shift 2
  if "$@" >"$TMP/$n.out" 2>&1; then
    echo "unexpected pass: $n"; cat "$TMP/$n.out"; exit 1
  fi
  grep -qF "$want" "$TMP/$n.out" || {
    echo "fail: $n did not report '$want'"; cat "$TMP/$n.out"; exit 1
  }
  echo "ok: $n"
}

RATINGS_HEAD='# asset_id	type	path	status	score	confidence	used_count	success_count	failure_count	last_used	use_when	avoid_when	evidence	notes'

# write_registry <out> <status> <score> <used_in> <evidence-literal>
write_registry(){
  local out="$1" status="$2" score="$3" used="$4" evidence="$5"
  cat > "$out" <<EOF
patterns:

  - id: fixture-pattern
    domain: fixture
    subdomain: null
    name: "Fixture Pattern"
    status: $status
    score: $score
    version: "1.0.0"
    used_in: $used
    scored_by: null
    scored_at: null
    code_path: patterns/fixture/README.md
    test_path: null
    source_url: null
    evidence: $evidence
    deprecated_reason: null
    successor: null
EOF
}

# write_ratings <out> <asset_id> <type> <status> <score> <used_count> <evidence>
write_ratings(){
  local out="$1" asset="$2"
  printf '%s\n' "$RATINGS_HEAD" > "$out"
  [ "$asset" = "NONE" ] && return 0
  local typ="$3" status="$4" score="$5" used="$6" evidence="$7"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$asset" "$typ" "patterns/fixture/README.md" "$status" "$score" "medium" \
    "$used" "0" "0" "2026-09-03" \
    "Use when the fixture domain is in scope for the change." \
    "Avoid when the fixture domain has no bearing on the change." \
    "$evidence" "fixture row" >> "$out"
}

EMPTY_PATTERNS="$TMP/empty-patterns"
mkdir -p "$EMPTY_PATTERNS"

run(){ bash "$CHECK" --registry "$1" --ratings "$2" --patterns-dir "$EMPTY_PATTERNS"; }

# ── positive: registry alone, no competing surface ──────────────────────────────
write_registry "$TMP/reg-candidate.yaml" candidate null 0 '[]'
write_ratings "$TMP/rat-empty.tsv" NONE
ok candidate_registry_without_competing_rows_passes run "$TMP/reg-candidate.yaml" "$TMP/rat-empty.tsv"

# positive: a legitimately promoted pattern meeting every canonical threshold
write_registry "$TMP/reg-active.yaml" active 72 2 '["two real project outcomes recorded"]'
ok active_meeting_thresholds_passes run "$TMP/reg-active.yaml" "$TMP/rat-empty.tsv"

# positive: an agreeing pattern row is accepted (score 4 * 20 == 80)
write_registry "$TMP/reg-agree.yaml" active 80 3 '["agreeing evidence"]'
write_ratings "$TMP/rat-agree.tsv" pattern-fixture-pattern pattern active 4 3 "agreeing evidence"
ok agreeing_pattern_row_passes run "$TMP/reg-agree.yaml" "$TMP/rat-agree.tsv"

# positive: template rows are not pattern state and are ignored by this gate
write_ratings "$TMP/rat-template.tsv" template-fixture template active 4 1 "templates/fixture/README.md"
ok template_row_is_ignored run "$TMP/reg-candidate.yaml" "$TMP/rat-template.tsv"

# ── negative 1: conflicting status ──────────────────────────────────────────────
write_ratings "$TMP/rat-status.tsv" pattern-fixture-pattern pattern active 4 3 "agreeing evidence"
no_msg conflicting_status_fails "conflicting status" \
  run "$TMP/reg-candidate.yaml" "$TMP/rat-status.tsv"

# ── negative 2: conflicting score ───────────────────────────────────────────────
write_ratings "$TMP/rat-score.tsv" pattern-fixture-pattern pattern active 2 3 "agreeing evidence"
no_msg conflicting_score_fails "conflicting score" \
  run "$TMP/reg-agree.yaml" "$TMP/rat-score.tsv"

# ── negative 3: conflicting usage ───────────────────────────────────────────────
write_ratings "$TMP/rat-usage.tsv" pattern-fixture-pattern pattern active 4 9 "agreeing evidence"
no_msg conflicting_usage_fails "conflicting usage" \
  run "$TMP/reg-agree.yaml" "$TMP/rat-usage.tsv"

# ── negative 4: conflicting evidence ────────────────────────────────────────────
write_ratings "$TMP/rat-evidence.tsv" pattern-fixture-pattern pattern active 4 3 "evidence the registry never recorded"
no_msg conflicting_evidence_fails "conflicting evidence" \
  run "$TMP/reg-agree.yaml" "$TMP/rat-evidence.tsv"

# ── negative 5: unknown row ─────────────────────────────────────────────────────
write_ratings "$TMP/rat-unknown.tsv" pattern-not-in-registry pattern candidate 3 0 "patterns/fixture/README.md"
no_msg unknown_row_fails "unknown row" \
  run "$TMP/reg-candidate.yaml" "$TMP/rat-unknown.tsv"

# ── negative 6: active below the canonical promotion thresholds ─────────────────
write_registry "$TMP/reg-low-score.yaml" active 41 2 '["one outcome"]'
no_msg active_below_score_threshold_fails "active-below-threshold" \
  run "$TMP/reg-low-score.yaml" "$TMP/rat-empty.tsv"

write_registry "$TMP/reg-low-uses.yaml" active 72 1 '["one outcome"]'
no_msg active_below_use_threshold_fails "active-below-threshold" \
  run "$TMP/reg-low-uses.yaml" "$TMP/rat-empty.tsv"

write_registry "$TMP/reg-no-evidence.yaml" active 72 2 '[]'
no_msg active_without_evidence_fails "active-below-threshold" \
  run "$TMP/reg-no-evidence.yaml" "$TMP/rat-empty.tsv"

write_registry "$TMP/reg-unscored-active.yaml" active null 2 '["one outcome"]'
no_msg active_without_score_fails "active-below-threshold" \
  run "$TMP/reg-unscored-active.yaml" "$TMP/rat-empty.tsv"

# ── registry integrity ──────────────────────────────────────────────────────────
write_registry "$TMP/reg-bad-status.yaml" promoted null 0 '[]'
no_msg invalid_status_fails "invalid status" \
  run "$TMP/reg-bad-status.yaml" "$TMP/rat-empty.tsv"

write_registry "$TMP/reg-out-of-range.yaml" candidate 140 0 '[]'
no_msg score_out_of_range_fails "outside the canonical 0-100 range" \
  run "$TMP/reg-out-of-range.yaml" "$TMP/rat-empty.tsv"

printf 'patterns:\n' > "$TMP/reg-empty.yaml"
no empty_registry_fails run "$TMP/reg-empty.yaml" "$TMP/rat-empty.tsv"

# ── README competing surface ────────────────────────────────────────────────────
README_DIR="$TMP/patterns-with-state"
mkdir -p "$README_DIR/fixture"
printf '# Fixture\n\n**Score:** TBD (see pattern-lifecycle.md)\n' > "$README_DIR/fixture/README.md"
no_msg readme_declaring_state_fails "conflicting status" \
  bash "$CHECK" --registry "$TMP/reg-candidate.yaml" --ratings "$TMP/rat-empty.tsv" --patterns-dir "$README_DIR"

printf '# Fixture\n\n**Registry:** see patterns/registry.yaml for canonical status, score, and usage.\n' \
  > "$README_DIR/fixture/README.md"
ok readme_pointing_at_registry_passes \
  bash "$CHECK" --registry "$TMP/reg-candidate.yaml" --ratings "$TMP/rat-empty.tsv" --patterns-dir "$README_DIR"

# ── the real repository must satisfy its own gate ───────────────────────────────
ok real_repository_state_passes bash "$CHECK"

echo "pattern canonical state tests passed"

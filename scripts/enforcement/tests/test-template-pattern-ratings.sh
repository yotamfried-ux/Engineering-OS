#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-template-pattern-ratings.sh"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
ok(){ local n="$1"; shift; "$@" >/dev/null || { echo "fail: $n"; exit 1; }; echo "ok: $n"; }
no(){ local n="$1"; shift; if "$@" >/dev/null 2>&1; then echo "unexpected pass: $n"; exit 1; else echo "ok: $n"; fi; }
row(){ printf '%s\tpattern\tNONE\t%s\t%s\tmedium\t%s\t%s\t%s\t2026-06-30\tUse when this fixture pattern matches the task.\tAvoid when this fixture pattern is irrelevant.\tNONE\t%s\n' "$1" "$2" "$3" "$4" "$5" "$6" "$7"; }
row asset-one active 4 2 1 1 current_ratings_manifest_passes > "$TMP/good.tsv"
printf 'asset-one\tpattern\tNONE\tactive\t9\tmedium\t2\t1\t1\t2026-06-30\tUse when this fixture pattern matches the task.\tAvoid when this fixture pattern is irrelevant.\tNONE\tinvalid_rating_score_fails\n' > "$TMP/badscore.tsv"
row asset-one active 4 1 1 1 inconsistent_rating_counts_fails > "$TMP/badcounts.tsv"
printf 'asset-one\tpattern\tNONE\tactive\t4\tmedium\t2\t1\t1\t2026-06-30\tUse when this fixture pattern matches the task.\t\tNONE\tmissing_rating_field_fails\n' > "$TMP/missing.tsv"
row asset-one waived 1 0 0 0 waived_rating_row_passes > "$TMP/waived.tsv"
ok current_ratings_manifest_passes bash "$CHECK"
ok good_fixture_passes env EOS_TEMPLATE_PATTERN_RATINGS_MIN_ROWS=1 bash "$CHECK" "$TMP/good.tsv"
no invalid_rating_score_fails env EOS_TEMPLATE_PATTERN_RATINGS_MIN_ROWS=1 bash "$CHECK" "$TMP/badscore.tsv"
no inconsistent_rating_counts_fails env EOS_TEMPLATE_PATTERN_RATINGS_MIN_ROWS=1 bash "$CHECK" "$TMP/badcounts.tsv"
no missing_rating_field_fails env EOS_TEMPLATE_PATTERN_RATINGS_MIN_ROWS=1 bash "$CHECK" "$TMP/missing.tsv"
ok waived_rating_row_passes env EOS_TEMPLATE_PATTERN_RATINGS_MIN_ROWS=1 bash "$CHECK" "$TMP/waived.tsv"

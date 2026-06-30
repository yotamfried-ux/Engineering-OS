#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-template-pattern-ratings.sh"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
bash "$CHECK" >/dev/null
echo current_ratings_manifest_passes
printf 'asset\tpattern\tNONE\tactive\t9\tmedium\t1\t0\t0\t2026-06-30\tUse this fixture when the pattern matches.\tAvoid this fixture when it does not match.\tNONE\tinvalid_rating_score_fails\n' > "$TMP/score.tsv"
if env EOS_TEMPLATE_PATTERN_RATINGS_MIN_ROWS=1 bash "$CHECK" "$TMP/score.tsv" >/dev/null 2>&1; then exit 1; fi
echo invalid_rating_score_fails
printf 'asset\tpattern\tNONE\tactive\t4\tmedium\t1\t1\t1\t2026-06-30\tUse this fixture when the pattern matches.\tAvoid this fixture when it does not match.\tNONE\tinconsistent_rating_counts_fails\n' > "$TMP/counts.tsv"
if env EOS_TEMPLATE_PATTERN_RATINGS_MIN_ROWS=1 bash "$CHECK" "$TMP/counts.tsv" >/dev/null 2>&1; then exit 1; fi
echo inconsistent_rating_counts_fails
printf 'asset\tpattern\tNONE\twaived\t1\tlow\t0\t0\t0\t2026-06-30\tUse this fixture only for waiver tests.\tAvoid this fixture unless a waiver is required.\tNONE\twaived_rating_row_passes\n' > "$TMP/waived.tsv"
env EOS_TEMPLATE_PATTERN_RATINGS_MIN_ROWS=1 bash "$CHECK" "$TMP/waived.tsv" >/dev/null
echo waived_rating_row_passes

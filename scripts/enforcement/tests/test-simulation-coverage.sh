#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="${EOS_SIM_CHECK:-$ROOT/scripts/enforcement/check-simulation-coverage.sh}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
HEAD="1111111111111111111111111111111111111111"
if [[ "$CHECK" == *.py ]]; then CHECK_CMD=(python3 "$CHECK"); else CHECK_CMD=(bash "$CHECK"); fi

pass() { local name="$1"; shift; "$@" >"$TMP/$name.out" 2>&1 || { echo "fail: $name"; cat "$TMP/$name.out"; exit 1; }; echo "ok: $name"; }
failcase() { local name="$1"; shift; if "$@" >"$TMP/$name.out" 2>&1; then echo "unexpected pass: $name"; cat "$TMP/$name.out"; exit 1; else echo "ok: $name"; fi; }

fixture_test="$TMP/fixture-test.sh"
cat > "$fixture_test" <<'EOF'
#!/usr/bin/env bash
# positive-case-token exists only in source here and must not count by itself.
# negative-case-token
# invalid-case-token
EOF

write_row() {
  local file="$1" gate="$2" test_file="$3" positive="$4" negative="$5" invalid="$6" waiver="$7" notes="$8"
  printf '# gate_id\towner\tenforcer\ttest_file\tpositive\tnegative\tinvalid\twaiver\tnotes\n' > "$file"
  printf '%s\tvalidation-governance\tNONE\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$gate" "$test_file" "$positive" "$negative" "$invalid" "$waiver" "$notes" >> "$file"
}

make_receipt() {
  local receipt="$1" test_path="$2" result="$3" content="$4" head="${5:-$HEAD}"
  local log="$TMP/log-$(printf '%s-%s-%s' "$test_path" "$result" "$RANDOM" | sha256sum | cut -c1-16).txt"
  printf '%s\n' "$content" > "$log"
  local sha
  sha="$(sha256sum "$log" | awk '{print $1}')"
  python3 - "$receipt" "$test_path" "$result" "$log" "$sha" "$head" <<'PY'
import json, sys
receipt, test_path, result, log, sha, head = sys.argv[1:]
with open(receipt, "a", encoding="utf-8") as f:
    f.write(json.dumps({
        "schema_version": 1,
        "test_id": "fixture:" + test_path,
        "path": test_path,
        "runner": "fixture-runner",
        "head_sha": head,
        "attempt": 1,
        "result": result,
        "evidence_level": "fixture",
        "log_path": log,
        "log_sha256": sha,
    }) + "\n")
PY
}

good_manifest="$TMP/good.tsv"
write_row "$good_manifest" fixture-gate "$fixture_test" \
  covered:positive-case-token covered:negative-case-token covered:invalid-case-token \
  'none-by-design:This fixture gate deliberately exposes no waiver path.' 'Fixture gate.'

good_receipts="$TMP/good.jsonl"
make_receipt "$good_receipts" "$fixture_test" pass "positive-case-token
negative-case-token
invalid-case-token"

pass executed-scenarios-pass env EOS_SIM_COVERAGE_REQUIRED_GATES=fixture-gate EOS_SIM_COVERAGE_MIN_ROWS=1 "${CHECK_CMD[@]}" "$good_manifest" --receipts "$good_receipts" --head-sha "$HEAD"

comment_only_receipts="$TMP/comment-only.jsonl"
make_receipt "$comment_only_receipts" "$fixture_test" pass "test process passed without emitting scenario ids"
failcase comment-only-source-does-not-count env EOS_SIM_COVERAGE_REQUIRED_GATES=fixture-gate EOS_SIM_COVERAGE_MIN_ROWS=1 "${CHECK_CMD[@]}" "$good_manifest" --receipts "$comment_only_receipts" --head-sha "$HEAD"

failed_receipts="$TMP/failed.jsonl"
make_receipt "$failed_receipts" "$fixture_test" fail "positive-case-token
negative-case-token
invalid-case-token"
failcase failed-test-cannot-satisfy-coverage env EOS_SIM_COVERAGE_REQUIRED_GATES=fixture-gate EOS_SIM_COVERAGE_MIN_ROWS=1 "${CHECK_CMD[@]}" "$good_manifest" --receipts "$failed_receipts" --head-sha "$HEAD"

other_test="$TMP/other-test.sh"
printf '#!/usr/bin/env bash\n' > "$other_test"
wrong_test_receipts="$TMP/wrong-test.jsonl"
make_receipt "$wrong_test_receipts" "$other_test" pass "positive-case-token
negative-case-token
invalid-case-token"
failcase wrong-test-receipt-does-not-count env EOS_SIM_COVERAGE_REQUIRED_GATES=fixture-gate EOS_SIM_COVERAGE_MIN_ROWS=1 "${CHECK_CMD[@]}" "$good_manifest" --receipts "$wrong_test_receipts" --head-sha "$HEAD"

stale_receipts="$TMP/stale.jsonl"
make_receipt "$stale_receipts" "$fixture_test" pass "positive-case-token
negative-case-token
invalid-case-token" 2222222222222222222222222222222222222222
failcase stale-head-receipt-fails env EOS_SIM_COVERAGE_REQUIRED_GATES=fixture-gate EOS_SIM_COVERAGE_MIN_ROWS=1 "${CHECK_CMD[@]}" "$good_manifest" --receipts "$stale_receipts" --head-sha "$HEAD"

missing_token_manifest="$TMP/missing-token.tsv"
write_row "$missing_token_manifest" fixture-gate "$fixture_test" \
  covered:positive-case-token covered:missing-token-fails covered:invalid-case-token \
  'none-by-design:This fixture gate deliberately exposes no waiver path.' 'Fixture gate.'
failcase missing-executed-token-fails env EOS_SIM_COVERAGE_REQUIRED_GATES=fixture-gate EOS_SIM_COVERAGE_MIN_ROWS=1 "${CHECK_CMD[@]}" "$missing_token_manifest" --receipts "$good_receipts" --head-sha "$HEAD"

malformed_manifest="$TMP/malformed.tsv"
printf 'fixture-gate\tvalidation-governance\tNONE\n' > "$malformed_manifest"
failcase malformed-row-fails env EOS_SIM_COVERAGE_REQUIRED_GATES=fixture-gate EOS_SIM_COVERAGE_MIN_ROWS=1 "${CHECK_CMD[@]}" "$malformed_manifest" --receipts "$good_receipts" --head-sha "$HEAD"

waiver_manifest="$TMP/waiver.tsv"
write_row "$waiver_manifest" waiver-gate NONE \
  'waived:Positive simulation is temporarily unavailable for this manual-only fixture gate.' \
  'waived:Negative simulation is temporarily unavailable for this manual-only fixture gate.' \
  'waived:Invalid simulation is temporarily unavailable for this manual-only fixture gate.' \
  'waived:Waiver simulation is temporarily unavailable because this row validates explicit waiver text.' \
  'Fixture waiver row.'
: > "$TMP/empty.jsonl"
pass waiver-row-passes env EOS_SIM_COVERAGE_REQUIRED_GATES=waiver-gate EOS_SIM_COVERAGE_MIN_ROWS=1 "${CHECK_CMD[@]}" "$waiver_manifest" --receipts "$TMP/empty.jsonl" --head-sha "$HEAD"

stale_manifest="$TMP/stale-manifest.tsv"
write_row "$stale_manifest" stale-gate "$fixture_test" \
  covered:positive-case-token covered:negative-case-token covered:invalid-case-token \
  'waived:This fixture intentionally keeps old pending coverage text for validation.' \
  'Fixture still says future loop should add a direct test.'
failcase deferred-language-fails env EOS_SIM_COVERAGE_REQUIRED_GATES=stale-gate EOS_SIM_COVERAGE_MIN_ROWS=1 "${CHECK_CMD[@]}" "$stale_manifest" --receipts "$good_receipts" --head-sha "$HEAD"

tamper_receipts="$TMP/tamper.jsonl"
make_receipt "$tamper_receipts" "$fixture_test" pass "positive-case-token
negative-case-token
invalid-case-token"
tamper_log="$(python3 - "$tamper_receipts" <<'PY'
import json, sys
print(json.loads(open(sys.argv[1]).readline())["log_path"])
PY
)"
printf 'tamper\n' >> "$tamper_log"
failcase log-checksum-tamper-fails env EOS_SIM_COVERAGE_REQUIRED_GATES=fixture-gate EOS_SIM_COVERAGE_MIN_ROWS=1 "${CHECK_CMD[@]}" "$good_manifest" --receipts "$tamper_receipts" --head-sha "$HEAD"

echo "simulation coverage validator tests passed"

#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
TOOL="${EOS_TEST_EVIDENCE_TOOL:-$ROOT/scripts/enforcement/test_evidence.py}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
FIX="$TMP/root"
HEAD="1111111111111111111111111111111111111111"

pass() { local name="$1"; shift; "$@" >"$TMP/$name.out" 2>&1 || { echo "fail: $name"; cat "$TMP/$name.out"; exit 1; }; echo "ok: $name"; }
failcase() { local name="$1"; shift; if "$@" >"$TMP/$name.out" 2>&1; then echo "unexpected pass: $name"; cat "$TMP/$name.out"; exit 1; else echo "ok: $name"; fi; }

mkdir -p "$FIX/scripts/enforcement/tests" "$FIX/.github/workflows" "$FIX/.engineering-os/test-evidence/logs"
cat > "$FIX/scripts/enforcement/tests/test-one.sh" <<'EOF'
#!/usr/bin/env bash
echo shell-ok
EOF
cat > "$FIX/scripts/enforcement/tests/test-two.py" <<'EOF'
def main():
    print("python-ok")
    return 0
if __name__ == "__main__":
    raise SystemExit(main())
EOF
cat > "$FIX/scripts/enforcement/tests/test-helper.py" <<'EOF'
# EOS_TEST_ROLE: helper
def helper():
    return "support"
EOF
cat > "$FIX/scripts/enforcement/run-enforcement-tests.sh" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
cat > "$FIX/scripts/enforcement/run-python-enforcement-tests.py" <<'EOF'
raise SystemExit(0)
EOF
cat > "$FIX/.github/workflows/enforcement-tests.yml" <<'EOF'
steps:
  - run: bash scripts/enforcement/run-enforcement-tests.sh
  - run: python3 scripts/enforcement/run-python-enforcement-tests.py
EOF

pass inventory-owned python3 "$TOOL" check-inventory --root "$FIX"

cp "$FIX/.github/workflows/enforcement-tests.yml" "$TMP/good-workflow.yml"
cat > "$FIX/.github/workflows/enforcement-tests.yml" <<'EOF'
steps:
  - run: bash scripts/enforcement/run-enforcement-tests.sh
EOF
failcase missing-python-runner-wiring python3 "$TOOL" check-inventory --root "$FIX"
cp "$TMP/good-workflow.yml" "$FIX/.github/workflows/enforcement-tests.yml"

cat > "$FIX/scripts/enforcement/tests/test-pytest-style.py" <<'EOF'
def test_something():
    assert True
EOF
failcase undeclared-python-style-fails python3 "$TOOL" check-inventory --root "$FIX"
rm "$FIX/scripts/enforcement/tests/test-pytest-style.py"

printf 'shell scenario passed\n' > "$FIX/.engineering-os/test-evidence/logs/shell.log"
printf 'python scenario passed\n' > "$FIX/.engineering-os/test-evidence/logs/python.log"
RECEIPTS="$FIX/.engineering-os/test-evidence/receipts.jsonl"
python3 "$TOOL" record --root "$FIX" --receipt-file "$RECEIPTS" \
  --test-path scripts/enforcement/tests/test-one.sh \
  --runner scripts/enforcement/run-enforcement-tests.sh --result pass \
  --log-path "$FIX/.engineering-os/test-evidence/logs/shell.log" --head-sha "$HEAD" --attempt 1 --duration-ms 10 >/dev/null
python3 "$TOOL" record --root "$FIX" --receipt-file "$RECEIPTS" \
  --test-path scripts/enforcement/tests/test-two.py \
  --runner scripts/enforcement/run-python-enforcement-tests.py --result pass \
  --log-path "$FIX/.engineering-os/test-evidence/logs/python.log" --head-sha "$HEAD" --attempt 1 --duration-ms 20 >/dev/null
pass exact-receipts-complete python3 "$TOOL" check-receipts --root "$FIX" --receipt-file "$RECEIPTS" --head-sha "$HEAD"
failcase stale-head-fails python3 "$TOOL" check-receipts --root "$FIX" --receipt-file "$RECEIPTS" --head-sha 2222222222222222222222222222222222222222

cp "$RECEIPTS" "$TMP/complete.jsonl"
head -1 "$RECEIPTS" > "$TMP/missing.jsonl"
failcase missing-python-receipt-fails python3 "$TOOL" check-receipts --root "$FIX" --receipt-file "$TMP/missing.jsonl" --head-sha "$HEAD"

printf 'tampered\n' >> "$FIX/.engineering-os/test-evidence/logs/shell.log"
failcase tampered-log-fails python3 "$TOOL" check-receipts --root "$FIX" --receipt-file "$RECEIPTS" --head-sha "$HEAD"
printf 'shell scenario passed\n' > "$FIX/.engineering-os/test-evidence/logs/shell.log"
cp "$TMP/complete.jsonl" "$RECEIPTS"

python3 "$TOOL" record --root "$FIX" --receipt-file "$RECEIPTS" \
  --test-path scripts/enforcement/tests/test-one.sh \
  --runner scripts/enforcement/run-enforcement-tests.sh --result pass \
  --log-path "$FIX/.engineering-os/test-evidence/logs/shell.log" --head-sha "$HEAD" --attempt 2 --duration-ms 11 >/dev/null
pass duplicate-attempts-valid python3 "$TOOL" check-receipts --root "$FIX" --receipt-file "$RECEIPTS" --head-sha "$HEAD"
python3 "$TOOL" summary --root "$FIX" --receipt-file "$RECEIPTS" --head-sha "$HEAD" --output "$TMP/summary.json" >/dev/null
python3 - "$TMP/summary.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
assert d["discovered_standalone_tests"] == 2, d
assert d["declared_helpers"] == 1, d
assert d["execution_attempts"] == 3, d
assert d["duplicate_attempts"] == 1, d
assert d["unique_status"]["passed"] == 2, d
assert d["passed_evidence_levels"]["static"] == 2, d
PY
echo "ok: duplicate-attempts-count-once"

echo "test evidence trust tests passed"

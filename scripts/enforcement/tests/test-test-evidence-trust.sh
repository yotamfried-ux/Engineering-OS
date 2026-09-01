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

python3 - "$RECEIPTS" <<'PY'
import json, sys
p = sys.argv[1]
rows = [json.loads(line) for line in open(p) if line.strip()]
rows[0]["log_content_b64"] = rows[0]["log_content_b64"][:-4] + "AAAA"
open(p, "w").write("".join(json.dumps(row, sort_keys=True) + "\n" for row in rows))
PY
failcase tampered-embedded-log-fails python3 "$TOOL" check-receipts --root "$FIX" --receipt-file "$RECEIPTS" --head-sha "$HEAD"
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

cp "$RECEIPTS" "$TMP/passing-retries.jsonl"
python3 "$TOOL" record --root "$FIX" --receipt-file "$RECEIPTS" \
  --test-path scripts/enforcement/tests/test-one.sh \
  --runner scripts/enforcement/run-enforcement-tests.sh --result fail \
  --log-path "$FIX/.engineering-os/test-evidence/logs/shell.log" --head-sha "$HEAD" --attempt 3 --duration-ms 12 >/dev/null
failcase pass-plus-fail-rejected python3 "$TOOL" check-receipts --root "$FIX" --receipt-file "$RECEIPTS" --head-sha "$HEAD"
cp "$TMP/passing-retries.jsonl" "$RECEIPTS"

# Default local evidence is isolated by exact HEAD, so receipts from an older
# commit cannot poison a new commit's otherwise complete run.
grep -Fq '.engineering-os/test-evidence/$safe_head' "$ROOT/scripts/enforcement/run-enforcement-tests.sh"
grep -Fq '.engineering-os/test-evidence" / safe_head' "$ROOT/scripts/enforcement/run-python-enforcement-tests.py"
grep -Fq 'EOS_TEST_EVIDENCE_DIR: .engineering-os/test-evidence' "$ROOT/.github/workflows/enforcement-tests.yml"
echo "ok: default-evidence-is-head-scoped"

# Two isolated runner processes may both allocate attempt 1 before either
# appends a receipt. Their immutable log names must still remain distinct and
# both receipts must survive checksum validation.
CONCURRENT="$TMP/concurrent"
mkdir -p "$CONCURRENT"
EOS_TEST_EVIDENCE_DIR="$CONCURRENT" bash "$ROOT/scripts/enforcement/run-enforcement-tests.sh" \
  scripts/enforcement/tests/test-active-mcp-verification.sh >"$TMP/concurrent-a.out" 2>&1 &
pid_a=$!
EOS_TEST_EVIDENCE_DIR="$CONCURRENT" bash "$ROOT/scripts/enforcement/run-enforcement-tests.sh" \
  scripts/enforcement/tests/test-active-mcp-verification.sh >"$TMP/concurrent-b.out" 2>&1 &
pid_b=$!
wait "$pid_a"
wait "$pid_b"
python3 - "$ROOT" "$CONCURRENT/receipts.jsonl" <<'PY'
import sys
from pathlib import Path
root = Path(sys.argv[1])
sys.path.insert(0, str(root / "scripts/enforcement"))
import test_evidence
rows = test_evidence.load_receipts(root, Path(sys.argv[2]), test_evidence.git_head(root))
assert len(rows) == 2, rows
assert len({row["log_path"] for row in rows}) == 2, rows
PY
echo "ok: concurrent-receipts-validate"
echo "ok: concurrent-runner-logs-are-immutable"

echo "test evidence trust tests passed"

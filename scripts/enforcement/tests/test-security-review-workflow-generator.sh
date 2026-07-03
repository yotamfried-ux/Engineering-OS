#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
GENERATOR="$ROOT/scripts/skill-bootstrap.sh"

pass() { echo "ok: $1"; }
fail() { echo "fail: $1"; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Extract the security-review-nemotron.yml heredoc the generator emits into
# installed targets, then the python payload of its `python3 -c "..."` step.
# This is the artifact every downstream project's PR security gate runs, so
# its review must cover the WHOLE diff (Codex finding on Expiriens-saas-0.9
# PR #2: a single `diff[:12000]` slice silently dropped everything past 12000
# characters while the gate stayed green).
awk '/<< .WORKFLOW.$/{on=1; next} /^WORKFLOW$/{on=0} on' "$GENERATOR" > "$TMP/workflow.yml"
[ -s "$TMP/workflow.yml" ] || fail "workflow_heredoc_extracted"
pass workflow_heredoc_extracted

python3 - "$TMP/workflow.yml" <<'PY'
import sys

text = open(sys.argv[1]).read()
start = text.index('python3 -c "') + len('python3 -c "')
end = text.rindex('"')
code = text[start:end]

# The payload must be valid python before anything else.
compile(code, "security-review-nemotron.yml embedded python", "exec")
print("ok: embedded_python_compiles")

# Regression (fails on the pre-fix generator): the diff must not be reviewed
# through a single truncating slice.
if "diff[:12000]" in code:
    print("fail: diff reviewed via single truncating slice diff[:12000]")
    sys.exit(1)
print("ok: no_single_slice_truncation")

# The fix contract: chunked full-diff review with a fail-closed cap, and
# (CodeRabbit nitpick on this PR) a bounded client timeout/retry policy with
# a per-chunk try/except so one stalled or failed call can't hang the CI step
# indefinitely or silently abort the rest of the review.
for needle, name in (
    ("MAX_CHUNKS", "fail_closed_chunk_cap_present"),
    ("for idx, chunk in enumerate(chunks", "chunk_loop_reviews_every_part"),
    ("sys.exit(1)", "over_cap_exits_nonzero"),
    ("timeout=", "client_has_bounded_timeout"),
    ("max_retries=", "client_has_bounded_retries"),
    ("except Exception as exc", "per_chunk_call_is_exception_guarded"),
):
    if needle not in code:
        print(f"fail: {name}")
        sys.exit(1)
    print(f"ok: {name}")

# Behavioral check of the chunking expression itself, executed exactly as
# written in the payload: every byte of an oversized diff must land in some
# chunk, in order.
import re
m = re.search(r"chunks = (\[diff\[i:i \+ CHUNK\] for i in range\(0, len\(diff\), CHUNK\)\] or \[diff\])", code)
if not m:
    print("fail: chunk_expression_found")
    sys.exit(1)
diff = "x" * 12000 * 3 + "TAIL-MARKER"
CHUNK = 12000
chunks = eval(m.group(1))
assert "".join(chunks) == diff, "chunks must reassemble the full diff"
assert "TAIL-MARKER" in chunks[-1], "content past 12000 chars must be reviewed"
print("ok: chunks_cover_entire_diff_including_tail")
PY

echo "security-review workflow generator checks passed"

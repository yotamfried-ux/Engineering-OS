#!/usr/bin/env bash
set -euo pipefail

# Covers Route Plan .claude/plans/remote-multirepo-telemetry-hooks.md, Test
# Plan scenario G (downstream compatibility): dispatcher-produced per-repo
# telemetry state feeds into the EXISTING, unmodified export/select
# pipeline (export-telemetry-run.py, select-pr-telemetry.py) exactly like a
# normal single-repo install would, and a bundle from one repo can never
# satisfy a PR-match query for a different repo.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
DISPATCH="$ROOT/scripts/monitoring/eos-telemetry-dispatch.sh"
EXPORT="$ROOT/scripts/monitoring/export-telemetry-run.py"
SELECT="$ROOT/scripts/monitoring/select-pr-telemetry.py"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

HOME_DIR="$TMP/home"
mkdir -p "$HOME_DIR"

init_managed_repo() {
  local dir="$1"
  mkdir -p "$dir/.engineering-os"
  git init -q "$dir"
  git -C "$dir" config user.email test@example.com
  git -C "$dir" config user.name test
  # A distinguishing file, not --allow-empty: two --allow-empty commits with
  # identical author/message/timestamp-second produce byte-identical (and
  # therefore identically-hashed) commit objects, which would make this
  # test's "different repos have different head SHAs" premise false by
  # accident rather than by design.
  echo "$dir" > "$dir/.repo-identity"
  git -C "$dir" add .repo-identity
  git -C "$dir" commit -q -m "init $(basename "$dir")"
  cat > "$dir/.engineering-os/telemetry-policy.json" <<'JSON'
{"schema_version":"eos.telemetry.policy.v1","remote_handoff":{"mode":"required","remote":"origin","branch":"engineering-os-telemetry"}}
JSON
}

init_managed_repo "$HOME_DIR/repo-alpha"
init_managed_repo "$HOME_DIR/repo-beta"

SESSION_ID="downstream-pr-match-$$"
PAYLOAD=$(python3 -c "import json; print(json.dumps({'session_id': '$SESSION_ID', 'cwd': '$HOME_DIR', 'hook_event_name': 'SessionStart'}))")
printf '%s' "$PAYLOAD" | HOME="$HOME_DIR" EOS_DISPATCH_HOME="$HOME_DIR" bash "$DISPATCH" session_start > /dev/null

HANDOFF_ROOT="$TMP/handoff-runs"
mkdir -p "$HANDOFF_ROOT/runs"

export_repo() {
  local repo="$1" slug="$2" head="$3"
  local bundle_dir="$HANDOFF_ROOT/runs/$repo"
  mkdir -p "$bundle_dir"
  python3 "$EXPORT" \
    --out "$bundle_dir" \
    --telemetry-dir "$HOME_DIR/$repo/.engineering-os/telemetry" \
    --repo "$slug" \
    --branch "main" \
    --head-sha "$head" \
    --engineering-os-head-sha "$(git -C "$ROOT" rev-parse HEAD)"
  python3 - "$bundle_dir" "$slug" "main" "$head" <<'PY'
import json
import sys
from pathlib import Path

bundle_dir, slug, branch, head = Path(sys.argv[1]), sys.argv[2], sys.argv[3], sys.argv[4]
manifest_path = bundle_dir / "manifest.json"
manifest = json.loads(manifest_path.read_text())
rows = [json.loads(l) for l in (bundle_dir / "events.jsonl").read_text().splitlines() if l.strip()]
boundary_events = {"eos.session_start", "eos.stop", "eos.stop_failure", "eos.session_end"}
boundary_position = 0
for index, row in enumerate(rows, start=1):
    name = row.get("name") or ""
    attr_name = (row.get("attributes") or {}).get("eos.event.name") or ""
    canonical = name if str(name).startswith("eos.") else f"eos.{attr_name}"
    if canonical in boundary_events:
        boundary_position = index
manifest["handoff"] = {
    "schema_version": "eos.telemetry.handoff.v1",
    "repo": slug,
    "pr_number": 0,
    "pr_binding": "provisional",
    "source_branch_hash": __import__("hashlib").sha256(branch.encode()).hexdigest()[:32],
    "head_sha": head,
    "run_id_hash": __import__("hashlib").sha256(manifest["run_id"].encode()).hexdigest()[:32],
    "event_count": len(rows),
    "boundary_position": boundary_position,
    "synced_at": "2026-01-01T00:00:00+00:00",
}
manifest_path.write_text(json.dumps(manifest))
PY
}

export_repo "repo-alpha" "example-org/repo-alpha" "$(git -C "$HOME_DIR/repo-alpha" rev-parse HEAD)"
export_repo "repo-beta" "example-org/repo-beta" "$(git -C "$HOME_DIR/repo-beta" rev-parse HEAD)"

ALPHA_HEAD="$(git -C "$HOME_DIR/repo-alpha" rev-parse HEAD)"
BETA_HEAD="$(git -C "$HOME_DIR/repo-beta" rev-parse HEAD)"

# Querying with repo-alpha's own identity must select its own bundle.
OUT_ALPHA="$TMP/selected-alpha"
python3 "$SELECT" \
  --root "$HOME_DIR/repo-alpha" \
  --handoff-root "$HANDOFF_ROOT" \
  --repo "example-org/repo-alpha" \
  --pr-number 0 \
  --head-ref "main" \
  --head-sha "$ALPHA_HEAD" \
  --out "$OUT_ALPHA" > "$TMP/select-alpha.log"
grep -q "selected telemetry bundle" "$TMP/select-alpha.log"

# Querying with repo-alpha's identity but repo-beta's head SHA must select
# NOTHING — a bundle from one repo must never satisfy another repo's
# (or the wrong head's) PR match, even under a required policy.
OUT_CROSS="$TMP/selected-cross"
if python3 "$SELECT" \
  --root "$HOME_DIR/repo-alpha" \
  --handoff-root "$HANDOFF_ROOT" \
  --repo "example-org/repo-alpha" \
  --pr-number 0 \
  --head-ref "main" \
  --head-sha "$BETA_HEAD" \
  --out "$OUT_CROSS" > "$TMP/select-cross.log" 2>&1; then
  echo "ERROR_FOR_AGENT: cross-repo/cross-head bundle selection unexpectedly succeeded" >&2
  cat "$TMP/select-cross.log" >&2
  exit 1
fi
grep -q "no non-empty telemetry bundle matches" "$TMP/select-cross.log"

# Querying repo-beta's own identity+head must select ITS bundle, not
# repo-alpha's.
OUT_BETA="$TMP/selected-beta"
python3 "$SELECT" \
  --root "$HOME_DIR/repo-beta" \
  --handoff-root "$HANDOFF_ROOT" \
  --repo "example-org/repo-beta" \
  --pr-number 0 \
  --head-ref "main" \
  --head-sha "$BETA_HEAD" \
  --out "$OUT_BETA" > "$TMP/select-beta.log"
grep -q "selected telemetry bundle" "$TMP/select-beta.log"

python3 -c "
import json
a = json.load(open('$OUT_ALPHA/manifest.json'))
b = json.load(open('$OUT_BETA/manifest.json'))
assert a['handoff']['repo'] == 'example-org/repo-alpha', a
assert b['handoff']['repo'] == 'example-org/repo-beta', b
assert a['run_id'] != b['run_id'], (a['run_id'], b['run_id'])
print('repo identity checked before selection; independent run_ids preserved through export/select')
"

echo 'downstream PR-matching compatibility test passed: dispatcher-produced state exports and selects correctly through the unmodified existing pipeline, cross-repo matching is rejected'

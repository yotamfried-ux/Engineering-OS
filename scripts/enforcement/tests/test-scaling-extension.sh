#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GATE="$ROOT/scripts/enforcement/check-scaling-extension.py"

echo "[scaling-extension] positive repository check"
python3 "$GATE" --root "$ROOT"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

copy_repo() {
  local target="$1"
  rm -rf "$target"
  mkdir -p "$target"
  tar --exclude='.git' -C "$ROOT" -cf - . | tar -C "$target" -xf -
}

expect_rejects() {
  local name="$1"
  local action="$2"
  local repo="$TMPDIR/$name"
  copy_repo "$repo"
  bash -c "$action" _ "$repo"
  if python3 "$repo/scripts/enforcement/check-scaling-extension.py" --root "$repo" >/tmp/scaling-$name.out 2>&1; then
    echo "ERROR_FOR_AGENT: scaling gate accepted negative fixture: $name" >&2
    cat /tmp/scaling-$name.out >&2
    exit 1
  fi
  echo "[scaling-extension] rejected negative fixture: $name"
}

expect_rejects missing_template_row 'repo="$1"; mkdir -p "$repo/templates/unregistered-app"'
expect_rejects missing_roadmap_row 'repo="$1"; python3 - "$repo" <<"PY"
from pathlib import Path
root = Path(__import__("sys").argv[1])
path = root / "scripts/enforcement/project-type-roadmaps.tsv"
lines = path.read_text().splitlines()
path.write_text("\n".join(line for line in lines if not line.startswith("web-application\t")) + "\n")
PY'
expect_rejects docs_missing_freshness 'repo="$1"; python3 - "$repo" <<"PY"
from pathlib import Path
root = Path(__import__("sys").argv[1])
path = root / "scripts/enforcement/documentation-sources.tsv"
lines = path.read_text().splitlines()
header = lines[0]
rows = []
for line in lines[1:]:
    cells = line.split("\t")
    if cells and cells[0].startswith("web-"):
        cells[6] = "NONE"
    rows.append("\t".join(cells))
path.write_text("\n".join([header] + rows) + "\n")
PY'
expect_rejects bad_reference_repo 'repo="$1"; cat >> "$repo/scripts/enforcement/reference-repositories.tsv" <<"EOF"
bad-reference	active	web-application	https://example.com/repo.git	NONE	NONE	NONE	NONE	NONE	NONE	NONE	not_exempt	docs/operations/result-loop-contract-audit-checklist.md#scaling-gate-implementation	docs/operations/known-gaps.tsv
EOF'
expect_rejects bad_code_example 'repo="$1"; cat >> "$repo/scripts/enforcement/code-example-requirements.tsv" <<"EOF"
bad-example	active	web-application	web-application	NONE	NONE	NONE	NONE	NONE	NONE	not_exempt	docs/operations/result-loop-contract-audit-checklist.md#scaling-gate-implementation	docs/operations/known-gaps.tsv
EOF'
expect_rejects missing_pattern_skill 'repo="$1"; python3 - "$repo" <<"PY"
from pathlib import Path
root = Path(__import__("sys").argv[1])
for rel in ["scripts/enforcement/pattern-requirements.tsv", "scripts/enforcement/skill-requirements.tsv"]:
    path = root / rel
    lines = path.read_text().splitlines()
    path.write_text("\n".join(line for line in lines if "\tweb-application\t" not in line) + "\n")
PY'
expect_rejects bad_connector_rule 'repo="$1"; cat >> "$repo/scripts/enforcement/connector-workflow-requirements.tsv" <<"EOF"
bad-connector	active	github	NONE	NONE	software work	NONE	NONE	not_exempt	docs/operations/result-loop-contract-audit-checklist.md#scaling-gate-implementation	docs/operations/known-gaps.tsv
EOF'
expect_rejects bad_waiver 'repo="$1"; cat >> "$repo/scripts/enforcement/waiver-requirements.tsv" <<"EOF"
bad-waiver	active	missing-rule	NONE	NONE	NONE	NONE	NONE	NONE
EOF'
expect_rejects game_missing_evidence 'repo="$1"; python3 - "$repo" <<"PY"
from pathlib import Path
root = Path(__import__("sys").argv[1])
path = root / "scripts/enforcement/project-type-roadmaps.tsv"
lines = path.read_text().splitlines()
out = [lines[0]]
for line in lines[1:]:
    cells = line.split("\t")
    if cells and cells[0] == "game-development":
        cells[6] = "telemetry export"
    out.append("\t".join(cells))
path.write_text("\n".join(out) + "\n")
PY'

echo "✅ scaling extension gate tests passed"

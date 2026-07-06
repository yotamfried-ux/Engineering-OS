#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
MANIFESTS=(
  scripts/enforcement/project-type-roadmaps.tsv
  scripts/enforcement/result-loop-requirements.tsv
  scripts/enforcement/documentation-sources.tsv
  scripts/enforcement/reference-repositories.tsv
  scripts/enforcement/code-example-requirements.tsv
  scripts/enforcement/pattern-requirements.tsv
  scripts/enforcement/skill-requirements.tsv
  scripts/enforcement/connector-workflow-requirements.tsv
)

python3 - "$ROOT" "${MANIFESTS[@]}" <<'PY'
import csv
import sys
from pathlib import Path

root = Path(sys.argv[1])
manifest_paths = [Path(p) for p in sys.argv[2:]]
allowed_status = {"active", "required", "planned", "deferred", "exempt"}
allowed_exemptions = {"not_exempt", "exempt", "waiver_required", "waived", "not_applicable"}
skip_values = {"NONE", "none", "planned", "TBD", "tbd", "n/a", "NA"}


def read_manifest(rel):
    path = root / rel
    if not path.is_file():
        raise SystemExit(f"missing manifest: {rel}")
    lines = path.read_text(encoding="utf-8").splitlines()
    header_line = next((line for line in lines if line.startswith("# ") and "\t" in line), None)
    if not header_line:
        raise SystemExit(f"{rel}: missing commented TSV header")
    header = header_line[2:].split("\t")
    if len(header) < 4:
        raise SystemExit(f"{rel}: expected at least 4 columns")
    if "status" not in header:
        raise SystemExit(f"{rel}: missing status column")
    if "exemption_state" not in header:
        raise SystemExit(f"{rel}: missing exemption_state column")
    rows = []
    for raw in lines:
        if not raw or raw.startswith("#"):
            continue
        cells = next(csv.reader([raw], delimiter="\t"))
        if len(cells) != len(header):
            raise SystemExit(f"{rel}: expected {len(header)} columns, got {len(cells)} in row: {raw}")
        if any(not cell.strip() for cell in cells):
            raise SystemExit(f"{rel}: empty cell in row: {raw}")
        rows.append(dict(zip(header, [cell.strip() for cell in cells])))
    if not rows:
        raise SystemExit(f"{rel}: no data rows")
    return header, rows


def path_values(row, header):
    for name in header:
        if name.endswith("_path") or name in {"source_path", "target_path", "source_doc_path", "template_path", "example_path", "run_path", "validation_path"}:
            yield name, row[name]


for rel in manifest_paths:
    header, rows = read_manifest(rel)
    for row in rows:
        status = row["status"]
        exemption = row["exemption_state"]
        if status not in allowed_status:
            raise SystemExit(f"{rel}: invalid status {status}")
        if exemption not in allowed_exemptions:
            raise SystemExit(f"{rel}: invalid exemption_state {exemption}")
        if status in {"planned", "deferred"}:
            continue
        for name, value in path_values(row, header):
            for item in [part.strip() for part in value.split(";") if part.strip()]:
                if item in skip_values or item.startswith("http://") or item.startswith("https://"):
                    continue
                if not (root / item).exists():
                    raise SystemExit(f"{rel}: {name} path does not exist for active row: {item}")
    print(f"ok: {rel}")

print("scaling manifest parsing checks passed")
PY

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

EXPECTED_HEADERS = {
    "scripts/enforcement/project-type-roadmaps.tsv": [
        "project_type_id", "status", "roadmap_label", "source_doc_path", "template_path",
        "target_manifest_path", "required_evidence", "exemption_state", "audit_link", "gap_link",
    ],
    "scripts/enforcement/result-loop-requirements.tsv": [
        "project_type_id", "status", "source_doc_path", "target_manifest_path", "setup_command",
        "run_command", "visible_result", "creator_local_review", "required_tests", "user_simulation",
        "feedback_surfaces", "performance_monitoring", "acceptance_metrics",
        "change_impact_measurement", "telemetry_export", "failure_repair_loop",
        "evidence_artifacts", "exemption_state", "audit_link", "gap_link",
    ],
    "scripts/enforcement/documentation-sources.tsv": [
        "source_id", "status", "project_type_id", "source_type", "source_url", "freshness_note",
        "target_path", "consult_rule", "fallback_or_waiver", "required_evidence",
        "exemption_state", "audit_link", "gap_link",
    ],
    "scripts/enforcement/reference-repositories.tsv": [
        "reference_id", "status", "project_type_id", "repository_url", "owner_type", "usage_scope",
        "license_usage_note", "validation_status", "validation_evidence", "target_path",
        "exemption_state", "audit_link", "gap_link",
    ],
    "scripts/enforcement/code-example-requirements.tsv": [
        "example_id", "status", "project_type_id", "example_path", "run_path", "validation_path",
        "owner", "source_reference", "required_evidence", "exemption_state", "audit_link", "gap_link",
    ],
    "scripts/enforcement/pattern-requirements.tsv": [
        "pattern_requirement_id", "status", "project_type_id", "source_path", "target_path",
        "usage_rule", "enforcement_rule", "required_evidence", "exemption_state", "audit_link", "gap_link",
    ],
    "scripts/enforcement/skill-requirements.tsv": [
        "skill_requirement_id", "status", "project_type_id", "source_path", "target_path",
        "trigger_rule", "evidence_rule", "exemption_state", "audit_link", "gap_link",
    ],
    "scripts/enforcement/connector-workflow-requirements.tsv": [
        "connector_requirement_id", "status", "connector_id", "source_path", "target_path",
        "workflow_scope", "required_evidence", "fallback_rule", "exemption_state", "audit_link", "gap_link",
    ],
}


def read_manifest(rel):
    key = rel.as_posix()
    expected_header = EXPECTED_HEADERS.get(key)
    if expected_header is None:
        raise SystemExit(f"{rel}: no expected schema registered")

    path = root / rel
    if not path.is_file():
        raise SystemExit(f"missing manifest: {rel}")
    lines = path.read_text(encoding="utf-8").splitlines()
    header_line = next((line for line in lines if line.startswith("# ") and "\t" in line), None)
    if not header_line:
        raise SystemExit(f"{rel}: missing commented TSV header")
    header = header_line[2:].split("\t")
    if header != expected_header:
        missing = [col for col in expected_header if col not in header]
        unknown = [col for col in header if col not in expected_header]
        detail = []
        if missing:
            detail.append("missing columns: " + ", ".join(missing))
        if unknown:
            detail.append("unknown columns: " + ", ".join(unknown))
        if not detail:
            detail.append("column order does not match documented schema")
        raise SystemExit(f"{rel}: schema mismatch; {'; '.join(detail)}")

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

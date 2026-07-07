#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import re
import sys
from pathlib import Path

ACTIVE = {"active", "required"}
STATUS = ACTIVE | {"planned", "deferred", "exempt"}
EXEMPT = {"not_exempt", "exempt", "waiver_required", "waived", "not_applicable"}
SKIP = {"", "NONE", "none", "planned", "deferred", "n/a", "NA", "TBD", "tbd"}
MANIFESTS = [
    "scripts/enforcement/project-type-roadmaps.tsv",
    "scripts/enforcement/result-loop-requirements.tsv",
    "scripts/enforcement/documentation-sources.tsv",
    "scripts/enforcement/reference-repositories.tsv",
    "scripts/enforcement/code-example-requirements.tsv",
    "scripts/enforcement/pattern-requirements.tsv",
    "scripts/enforcement/skill-requirements.tsv",
    "scripts/enforcement/connector-workflow-requirements.tsv",
    "scripts/enforcement/waiver-requirements.tsv",
]


def split_cell(value: str) -> list[str]:
    return [part.strip() for part in re.split(r"[;,]", value or "") if part.strip()]


def noneish(value: str) -> bool:
    return value.strip() in SKIP


def read_tsv(root: Path, rel: str, errors: list[str]) -> list[dict[str, str]]:
    path = root / rel
    if not path.is_file():
        errors.append(f"missing manifest: {rel}")
        return []
    lines = path.read_text(encoding="utf-8").splitlines()
    header_line = next((line for line in lines if line.startswith("# ") and "\t" in line), "")
    header = header_line[2:].split("\t") if header_line else []
    if not header:
        errors.append(f"missing header: {rel}")
        return []
    rows = []
    for raw in lines:
        if not raw or raw.startswith("#"):
            continue
        cells = next(csv.reader([raw], delimiter="\t"))
        if len(cells) != len(header):
            errors.append(f"wrong column count: {rel}")
            continue
        row = dict(zip(header, [cell.strip() for cell in cells]))
        if row.get("status") not in STATUS:
            errors.append(f"invalid status: {rel}")
        if row.get("exemption_state") and row["exemption_state"] not in EXEMPT:
            errors.append(f"invalid exemption: {rel}")
        if any(value == "" for value in row.values()):
            errors.append(f"empty cell: {rel}")
        rows.append(row)
    return rows


def template_ids(root: Path, errors: list[str]) -> dict[str, str]:
    path = root / "scripts/enforcement/template-requirements.tsv"
    if not path.is_file():
        errors.append("missing template-requirements.tsv")
        return {}
    found = {}
    for raw in path.read_text(encoding="utf-8").splitlines():
        if raw and not raw.startswith("#"):
            parts = raw.split("\t")
            if len(parts) != 4:
                errors.append("bad template-requirements.tsv row")
            else:
                found[parts[0].strip()] = parts[1].strip()
    return found


def check(root: Path) -> list[str]:
    errors: list[str] = []
    rows = {rel: read_tsv(root, rel, errors) for rel in MANIFESTS}
    templates = template_ids(root, errors)
    template_root = root / "templates"
    if template_root.is_dir():
        for child in template_root.iterdir():
            if child.is_dir() and child.name not in templates:
                errors.append(f"unregistered template directory: templates/{child.name}")

    roadmaps = {row["project_type_id"]: row for row in rows["scripts/enforcement/project-type-roadmaps.tsv"]}
    roadmap_covered_templates = set(roadmaps)
    for row in roadmaps.values():
        for template_path in split_cell(row.get("template_path", "")):
            if not noneish(template_path):
                roadmap_covered_templates.add(Path(template_path).name)
    for template_id, kind in templates.items():
        if kind == "project" and template_id not in roadmap_covered_templates:
            errors.append(f"kind=project template lacks project-type-roadmap row: {template_id}")

    result = {row["project_type_id"] for row in rows["scripts/enforcement/result-loop-requirements.tsv"]}
    docs = {row["project_type_id"] for row in rows["scripts/enforcement/documentation-sources.tsv"]}
    patterns = {row["project_type_id"] for row in rows["scripts/enforcement/pattern-requirements.tsv"] if row["status"] in ACTIVE}
    skills = {row["project_type_id"] for row in rows["scripts/enforcement/skill-requirements.tsv"] if row["status"] in ACTIVE}
    for project in (result | docs | patterns | skills) - set(roadmaps):
        errors.append(f"project type referenced without roadmap: {project}")
    for project, row in roadmaps.items():
        if row["status"] not in ACTIVE:
            continue
        for label, collection in [("result loop", result), ("documentation", docs), ("pattern", patterns), ("skill", skills)]:
            if project not in collection:
                errors.append(f"project type {project} lacks {label} coverage")
        for template_path in split_cell(row.get("template_path", "")):
            if not noneish(template_path) and Path(template_path).name not in templates:
                errors.append(f"template path lacks requirement row: {template_path}")

    for row in rows["scripts/enforcement/documentation-sources.tsv"]:
        if row["status"] in ACTIVE:
            for field in ["source_url", "freshness_note", "consult_rule", "fallback_or_waiver"]:
                if noneish(row[field]) or len(row[field]) < 4:
                    errors.append(f"documentation source {row['source_id']} lacks {field}")

    for row in rows["scripts/enforcement/project-type-roadmaps.tsv"]:
        if row["project_type_id"] == "game-development" and row["status"] in ACTIVE:
            evidence = row["required_evidence"].lower()
            for token in ["playable", "gameplay", "visual", "performance", "telemetry"]:
                if token not in evidence:
                    errors.append(f"game-development evidence lacks {token}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=".")
    errors = check(Path(parser.parse_args().root).resolve())
    if errors:
        for error in errors:
            print(f"SCALING_GATE_ERROR: {error}")
        return 1
    print("scaling extension gate passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())

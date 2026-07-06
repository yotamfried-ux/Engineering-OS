#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import re
import sys
from pathlib import Path

ACTIVE = {"active", "required"}
STATUS = ACTIVE | {"planned", "deferred", "exempt"}
EXEMPTION = {"not_exempt", "exempt", "waiver_required", "waived", "not_applicable"}
SKIP = {"", "NONE", "none", "planned", "deferred", "n/a", "NA", "TBD", "tbd"}

SCHEMAS = {
    "scripts/enforcement/project-type-roadmaps.tsv": "project_type_id status roadmap_label source_doc_path template_path target_manifest_path required_evidence exemption_state audit_link gap_link".split(),
    "scripts/enforcement/result-loop-requirements.tsv": "project_type_id status source_doc_path target_manifest_path setup_command run_command visible_result creator_local_review required_tests user_simulation feedback_surfaces performance_monitoring acceptance_metrics change_impact_measurement telemetry_export failure_repair_loop evidence_artifacts exemption_state audit_link gap_link".split(),
    "scripts/enforcement/documentation-sources.tsv": "source_id status project_type_id source_type source_url freshness_note target_path consult_rule fallback_or_waiver required_evidence exemption_state audit_link gap_link".split(),
    "scripts/enforcement/reference-repositories.tsv": "reference_id status project_type_id repository_url owner_type usage_scope license_usage_note freshness_status validation_status validation_evidence target_path exemption_state audit_link gap_link".split(),
    "scripts/enforcement/code-example-requirements.tsv": "example_id status project_type_id supported_template example_path run_path validation_path owner source_reference required_evidence exemption_state audit_link gap_link".split(),
    "scripts/enforcement/pattern-requirements.tsv": "pattern_requirement_id status project_type_id source_path target_path usage_rule enforcement_rule required_evidence exemption_state audit_link gap_link".split(),
    "scripts/enforcement/skill-requirements.tsv": "skill_requirement_id status project_type_id source_path target_path trigger_rule evidence_rule exemption_state audit_link gap_link".split(),
    "scripts/enforcement/connector-workflow-requirements.tsv": "connector_requirement_id status connector_id source_path target_path workflow_scope required_evidence fallback_rule exemption_state audit_link gap_link".split(),
    "scripts/enforcement/waiver-requirements.tsv": "waiver_id status linked_requirement_id reason scope owner_context expiry_or_revisit_trigger audit_link gap_link".split(),
}


def split_items(value: str) -> list[str]:
    return [part.strip() for part in re.split(r"[;,]", value or "") if part.strip()]


def skipped(value: str) -> bool:
    return value.strip() in SKIP


class ScalingGate:
    def __init__(self, root: Path) -> None:
        self.root = root
        self.rows: dict[str, list[dict[str, str]]] = {}
        self.errors: list[str] = []

    def fail(self, message: str) -> None:
        self.errors.append(message)

    def read_tsv(self, rel: str) -> list[dict[str, str]]:
        path = self.root / rel
        expected = SCHEMAS[rel]
        if not path.is_file():
            self.fail(f"missing manifest: {rel}")
            self.rows[rel] = []
            return []
        lines = path.read_text(encoding="utf-8").splitlines()
        header_line = next((line for line in lines if line.startswith("# ") and "\t" in line), "")
        header = header_line[2:].split("\t") if header_line else []
        if header != expected:
            self.fail(f"{rel}: schema mismatch")
            self.rows[rel] = []
            return []
        parsed: list[dict[str, str]] = []
        for raw in lines:
            if not raw or raw.startswith("#"):
                continue
            cells = next(csv.reader([raw], delimiter="\t"))
            if len(cells) != len(header):
                self.fail(f"{rel}: wrong column count")
                continue
            row = dict(zip(header, [cell.strip() for cell in cells]))
            if any(value == "" for value in row.values()):
                self.fail(f"{rel}: empty cell")
            if row.get("status") not in STATUS:
                self.fail(f"{rel}: invalid status {row.get('status', '')}")
            if row.get("exemption_state") and row["exemption_state"] not in EXEMPTION:
                self.fail(f"{rel}: invalid exemption_state {row['exemption_state']}")
            parsed.append(row)
        self.rows[rel] = parsed
        return parsed

    def template_ids(self) -> set[str]:
        path = self.root / "scripts/enforcement/template-requirements.tsv"
        if not path.is_file():
            self.fail("missing template requirements manifest")
            return set()
        found: set[str] = set()
        for raw in path.read_text(encoding="utf-8").splitlines():
            if raw and not raw.startswith("#"):
                cells = raw.split("\t")
                if len(cells) != 4:
                    self.fail("template-requirements.tsv: wrong column count")
                    continue
                found.add(cells[0].strip())
        return found

    def validate_template_coverage(self, template_ids: set[str]) -> None:
        templates = self.root / "templates"
        if not templates.is_dir():
            return
        for child in templates.iterdir():
            if child.is_dir() and child.name not in template_ids:
                self.fail(f"template directory templates/{child.name} lacks template-requirements.tsv row")

    def validate_paths(self) -> None:
        path_columns = {"source_doc_path", "target_manifest_path", "template_path", "target_path", "example_path", "run_path", "validation_path", "source_path", "audit_link", "gap_link"}
        for rel, rows in self.rows.items():
            for row in rows:
                if row.get("status") not in ACTIVE | {"exempt"}:
                    continue
                for column in path_columns & set(row):
                    for value in split_items(row[column]):
                        value = value.split("#", 1)[0]
                        if skipped(value) or value.startswith("http"):
                            continue
                        if not (self.root / value).exists():
                            self.fail(f"{rel}: {column} path does not exist: {value}")

    def validate_project_coverage(self, template_ids: set[str]) -> None:
        roadmaps = {row["project_type_id"]: row for row in self.rows["scripts/enforcement/project-type-roadmaps.tsv"]}
        result_loop = {row["project_type_id"] for row in self.rows["scripts/enforcement/result-loop-requirements.tsv"]}
        docs: dict[str, int] = {}
        for row in self.rows["scripts/enforcement/documentation-sources.tsv"]:
            docs[row["project_type_id"]] = docs.get(row["project_type_id"], 0) + 1
        patterns = {row["project_type_id"] for row in self.rows["scripts/enforcement/pattern-requirements.tsv"] if row["status"] in ACTIVE}
        skills = {row["project_type_id"] for row in self.rows["scripts/enforcement/skill-requirements.tsv"] if row["status"] in ACTIVE}
        for project in (result_loop | set(docs) | patterns | skills) - set(roadmaps):
            self.fail(f"project type {project} referenced without roadmap row")
        for project, row in roadmaps.items():
            if row["status"] not in ACTIVE:
                continue
            if project not in result_loop:
                self.fail(f"project type {project} lacks result-loop-requirements row")
            if not docs.get(project):
                self.fail(f"project type {project} lacks documentation-sources row")
            if project not in patterns:
                self.fail(f"project type {project} lacks active pattern requirement")
            if project not in skills:
                self.fail(f"project type {project} lacks active skill requirement")
            for template_path in split_items(row.get("template_path", "")):
                if not skipped(template_path) and Path(template_path).name not in template_ids:
                    self.fail(f"project type {project} template {template_path} lacks template requirement row")

    def validate_metadata(self) -> None:
        checks = [
            ("scripts/enforcement/documentation-sources.tsv", "source_id", ["source_url", "freshness_note", "consult_rule", "fallback_or_waiver"]),
            ("scripts/enforcement/reference-repositories.tsv", "reference_id", ["repository_url", "owner_type", "license_usage_note", "freshness_status", "validation_status"]),
            ("scripts/enforcement/code-example-requirements.tsv", "example_id", ["supported_template", "run_path", "validation_path", "owner", "source_reference"]),
            ("scripts/enforcement/pattern-requirements.tsv", "pattern_requirement_id", ["usage_rule", "enforcement_rule", "required_evidence"]),
            ("scripts/enforcement/skill-requirements.tsv", "skill_requirement_id", ["trigger_rule", "evidence_rule"]),
            ("scripts/enforcement/connector-workflow-requirements.tsv", "connector_requirement_id", ["required_evidence", "fallback_rule"]),
            ("scripts/enforcement/waiver-requirements.tsv", "waiver_id", ["reason", "scope", "owner_context", "expiry_or_revisit_trigger", "audit_link", "gap_link"]),
        ]
        for rel, key, fields in checks:
            for row in self.rows[rel]:
                if row["status"] in ACTIVE:
                    for field in fields:
                        if skipped(row[field]) or len(row[field]) < 4:
                            self.fail(f"{rel}: {row[key]} missing {field}")

    def validate_game_evidence(self) -> None:
        for row in self.rows["scripts/enforcement/project-type-roadmaps.tsv"]:
            if row["project_type_id"] == "game-development" and row["status"] in ACTIVE:
                evidence = row["required_evidence"].lower()
                for token in ["playable", "gameplay", "visual", "performance", "telemetry"]:
                    if token not in evidence:
                        self.fail(f"game-development required_evidence must include {token}")

    def run(self) -> int:
        for rel in SCHEMAS:
            self.read_tsv(rel)
        templates = self.template_ids()
        self.validate_template_coverage(templates)
        self.validate_paths()
        self.validate_project_coverage(templates)
        self.validate_metadata()
        self.validate_game_evidence()
        if self.errors:
            for error in self.errors:
                print(f"ERROR_FOR_AGENT: {error}")
            return 1
        print("scaling extension gate passed")
        return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=".")
    args = parser.parse_args()
    return ScalingGate(Path(args.root).resolve()).run()


if __name__ == "__main__":
    sys.exit(main())

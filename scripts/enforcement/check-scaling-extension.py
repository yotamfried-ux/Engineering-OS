#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import re
import sys
from pathlib import Path

ALLOWED_STATUS = {"active", "required", "planned", "deferred", "exempt"}
ALLOWED_EXEMPTIONS = {"not_exempt", "exempt", "waiver_required", "waived", "not_applicable"}
CONCRETE = {"active", "required"}
SKIP = {"", "NONE", "none", "planned", "deferred", "n/a", "NA", "TBD", "tbd"}

SCHEMAS = {
    "scripts/enforcement/project-type-roadmaps.tsv": ["project_type_id", "status", "roadmap_label", "source_doc_path", "template_path", "target_manifest_path", "required_evidence", "exemption_state", "audit_link", "gap_link"],
    "scripts/enforcement/result-loop-requirements.tsv": ["project_type_id", "status", "source_doc_path", "target_manifest_path", "setup_command", "run_command", "visible_result", "creator_local_review", "required_tests", "user_simulation", "feedback_surfaces", "performance_monitoring", "acceptance_metrics", "change_impact_measurement", "telemetry_export", "failure_repair_loop", "evidence_artifacts", "exemption_state", "audit_link", "gap_link"],
    "scripts/enforcement/documentation-sources.tsv": ["source_id", "status", "project_type_id", "source_type", "source_url", "reason", "freshness_note", "target_path", "consult_rule", "fallback_or_waiver", "required_evidence", "exemption_state", "audit_link", "gap_link"],
    "scripts/enforcement/reference-repositories.tsv": ["reference_id", "status", "project_type_id", "repository_url", "owner_type", "usage_scope", "license_usage_note", "freshness_status", "validation_status", "validation_evidence", "target_path", "exemption_state", "audit_link", "gap_link"],
    "scripts/enforcement/code-example-requirements.tsv": ["example_id", "status", "project_type_id", "supported_template", "example_path", "run_path", "validation_path", "owner", "source_reference", "required_evidence", "exemption_state", "audit_link", "gap_link"],
    "scripts/enforcement/pattern-requirements.tsv": ["pattern_requirement_id", "status", "project_type_id", "source_path", "target_path", "usage_rule", "enforcement_rule", "required_evidence", "exemption_state", "audit_link", "gap_link"],
    "scripts/enforcement/skill-requirements.tsv": ["skill_requirement_id", "status", "project_type_id", "source_path", "target_path", "trigger_rule", "evidence_rule", "exemption_state", "audit_link", "gap_link"],
    "scripts/enforcement/connector-workflow-requirements.tsv": ["connector_requirement_id", "status", "connector_id", "source_path", "target_path", "workflow_scope", "required_evidence", "fallback_rule", "exemption_state", "audit_link", "gap_link"],
    "scripts/enforcement/waiver-requirements.tsv": ["waiver_id", "status", "linked_requirement_id", "reason", "scope", "owner_context", "expiry_or_revisit_trigger", "audit_link", "gap_link"],
}


def skip(value: str) -> bool:
    return value.strip() in SKIP


def items(value: str) -> list[str]:
    return [part.strip() for part in re.split(r"[;,]", value) if part.strip()]


class Gate:
    def __init__(self, root: Path) -> None:
        self.root = root
        self.rows: dict[str, list[dict[str, str]]] = {}
        self.errors: list[str] = []

    def fail(self, message: str) -> None:
        self.errors.append(message)

    def read(self, rel: str) -> list[dict[str, str]]:
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
        parsed = []
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
            if "status" in row and row["status"] not in ALLOWED_STATUS:
                self.fail(f"{rel}: invalid status {row['status']}")
            if "exemption_state" in row and row["exemption_state"] not in ALLOWED_EXEMPTIONS:
                self.fail(f"{rel}: invalid exemption_state {row['exemption_state']}")
            parsed.append(row)
        self.rows[rel] = parsed
        return parsed

    def template_ids(self) -> set[str]:
        path = self.root / "scripts/enforcement/template-requirements.tsv"
        found = set()
        if not path.is_file():
            self.fail("missing template requirements manifest")
            return found
        for raw in path.read_text(encoding="utf-8").splitlines():
            if raw and not raw.startswith("#"):
                parts = raw.split("\t")
                if len(parts) != 4:
                    self.fail("template-requirements.tsv: wrong column count")
                    continue
                found.add(parts[0].strip())
        return found

    def validate_templates(self, mapped: set[str]) -> None:
        templates = self.root / "templates"
        if not templates.is_dir():
            return
        for child in templates.iterdir():
            if child.is_dir() and child.name not in mapped:
                self.fail(f"template directory templates/{child.name} lacks template-requirements.tsv row")

    def validate_paths(self) -> None:
        path_cols = {"source_doc_path", "target_manifest_path", "template_path", "target_path", "example_path", "run_path", "validation_path", "source_path", "audit_link", "gap_link"}
        for rel, rows in self.rows.items():
            for row in rows:
                if row.get("status") not in CONCRETE | {"exempt"}:
                    continue
                for col in path_cols:
                    if col not in row:
                        continue
                    for value in items(row[col]):
                        value = value.split("#", 1)[0]
                        if skip(value) or value.startswith(("http://", "https://")):
                            continue
                        if not (self.root / value).exists():
                            self.fail(f"{rel}: {col} path does not exist: {value}")

    def validate_coverage(self, templates: set[str]) -> None:
        roadmaps = {r["project_type_id"]: r for r in self.rows["scripts/enforcement/project-type-roadmaps.tsv"]}
        result = {r["project_type_id"] for r in self.rows["scripts/enforcement/result-loop-requirements.tsv"]}
        docs: dict[str, int] = {}
        for row in self.rows["scripts/enforcement/documentation-sources.tsv"]:
            docs[row["project_type_id"]] = docs.get(row["project_type_id"], 0) + 1
        patterns = {r["project_type_id"] for r in self.rows["scripts/enforcement/pattern-requirements.tsv"] if r["status"] in CONCRETE}
        skills = {r["project_type_id"] for r in self.rows["scripts/enforcement/skill-requirements.tsv"] if r["status"] in CONCRETE}
        referenced = set(roadmaps) | result | set(docs) | patterns | skills
        for project in referenced - set(roadmaps):
            self.fail(f"project type {project} referenced without roadmap row")
        for project, row in roadmaps.items():
            if row["status"] not in CONCRETE:
                continue
            if project not in result:
                self.fail(f"project type {project} lacks result-loop-requirements row")
            if not docs.get(project):
                self.fail(f"project type {project} lacks documentation-sources row")
            if project not in patterns:
                self.fail(f"project type {project} lacks active pattern requirement")
            if project not in skills:
                self.fail(f"project type {project} lacks active skill requirement")
            for template_path in items(row.get("template_path", "")):
                if skip(template_path):
                    continue
                if Path(template_path).name not in templates:
                    self.fail(f"project type {project} template {template_path} lacks template requirement row")

    def validate_metadata(self) -> None:
        for row in self.rows["scripts/enforcement/documentation-sources.tsv"]:
            if row["status"] in CONCRETE:
                for field in ["source_url", "reason", "freshness_note", "consult_rule", "fallback_or_waiver"]:
                    if skip(row[field]) or len(row[field]) < 5:
                        self.fail(f"documentation source {row['source_id']} missing {field}")
        for row in self.rows["scripts/enforcement/reference-repositories.tsv"]:
            if row["status"] in CONCRETE:
                for field in ["repository_url", "owner_type", "license_usage_note", "freshness_status", "validation_status"]:
                    if skip(row[field]) or len(row[field]) < 4:
                        self.fail(f"reference repo {row['reference_id']} missing {field}")
        for row in self.rows["scripts/enforcement/code-example-requirements.tsv"]:
            if row["status"] in CONCRETE:
                for field in ["supported_template", "run_path", "validation_path", "owner", "source_reference"]:
                    if skip(row[field]) or len(row[field]) < 3:
                        self.fail(f"code example {row['example_id']} missing {field}")
        for rel, key, fields in [
            ("scripts/enforcement/pattern-requirements.tsv", "pattern_requirement_id", ["usage_rule", "enforcement_rule", "required_evidence"]),
            ("scripts/enforcement/skill-requirements.tsv", "skill_requirement_id", ["trigger_rule", "evidence_rule"]),
            ("scripts/enforcement/connector-workflow-requirements.tsv", "connector_requirement_id", ["required_evidence", "fallback_rule"]),
        ]:
            for row in self.rows[rel]:
                if row["status"] in CONCRETE:
                    for field in fields:
                        if skip(row[field]) or len(row[field]) < 5:
                            self.fail(f"{rel}: {row[key]} missing {field}")
        for row in self.rows["scripts/enforcement/waiver-requirements.tsv"]:
            if row["status"] in CONCRETE:
                for field in ["reason", "scope", "owner_context", "expiry_or_revisit_trigger", "audit_link", "gap_link"]:
                    if skip(row[field]) or len(row[field]) < 5:
                        self.fail(f"waiver {row['waiver_id']} missing {field}")

    def validate_game(self) -> None:
        for row in self.rows["scripts/enforcement/project-type-roadmaps.tsv"]:
            if row["project_type_id"] == "game-development" and row["status"] in CONCRETE:
                evidence = row["required_evidence"].lower()
                for token in ["playable", "gameplay", "visual", "performance", "telemetry"]:
                    if token not in evidence:
                        self.fail(f"game-development required_evidence must include {token}")

    def run(self) -> int:
        for rel in SCHEMAS:
            self.read(rel)
        mapped = self.template_ids()
        self.validate_templates(mapped)
        self.validate_paths()
        self.validate_coverage(mapped)
        self.validate_metadata()
        self.validate_game()
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
    return Gate(Path(args.root).resolve()).run()


if __name__ == "__main__":
    sys.exit(main())

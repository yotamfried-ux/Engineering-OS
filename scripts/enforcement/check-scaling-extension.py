#!/usr/bin/env python3
"""Deterministic scaling-extension gate for Engineering OS.

The gate validates the registry-backed scaling manifests introduced by the
Scaling Manifest Foundation. It intentionally checks structure and coverage; it
does not claim real-run readiness.
"""
from __future__ import annotations

import argparse
import csv
import re
import sys
from pathlib import Path

ALLOWED_STATUS = {"active", "required", "planned", "deferred", "exempt"}
ALLOWED_EXEMPTIONS = {"not_exempt", "exempt", "waiver_required", "waived", "not_applicable"}
CONCRETE_STATUS = {"active", "required"}
SKIP = {"", "NONE", "none", "planned", "deferred", "n/a", "NA", "TBD", "tbd"}

SCHEMAS = {
    "scripts/enforcement/project-type-roadmaps.tsv": [
        "project_type_id", "status", "roadmap_label", "source_doc_path", "template_path",
        "target_manifest_path", "required_evidence", "exemption_state", "audit_link", "gap_link",
    ],
    "scripts/enforcement/result-loop-requirements.tsv": [
        "project_type_id", "status", "source_doc_path", "target_manifest_path", "setup_command",
        "run_command", "visible_result", "creator_local_review", "required_tests", "user_simulation",
        "feedback_surfaces", "performance_monitoring", "acceptance_metrics", "change_impact_measurement",
        "telemetry_export", "failure_repair_loop", "evidence_artifacts", "exemption_state", "audit_link", "gap_link",
    ],
    "scripts/enforcement/documentation-sources.tsv": [
        "source_id", "status", "project_type_id", "source_type", "source_url", "reason",
        "freshness_note", "target_path", "consult_rule", "fallback_or_waiver", "required_evidence",
        "exemption_state", "audit_link", "gap_link",
    ],
    "scripts/enforcement/reference-repositories.tsv": [
        "reference_id", "status", "project_type_id", "repository_url", "owner_type", "usage_scope",
        "license_usage_note", "freshness_status", "validation_status", "validation_evidence", "target_path",
        "exemption_state", "audit_link", "gap_link",
    ],
    "scripts/enforcement/code-example-requirements.tsv": [
        "example_id", "status", "project_type_id", "supported_template", "example_path", "run_path",
        "validation_path", "owner", "source_reference", "required_evidence", "exemption_state", "audit_link", "gap_link",
    ],
    "scripts/enforcement/pattern-requirements.tsv": [
        "pattern_requirement_id", "status", "project_type_id", "source_path", "target_path", "usage_rule",
        "enforcement_rule", "required_evidence", "exemption_state", "audit_link", "gap_link",
    ],
    "scripts/enforcement/skill-requirements.tsv": [
        "skill_requirement_id", "status", "project_type_id", "source_path", "target_path", "trigger_rule",
        "evidence_rule", "exemption_state", "audit_link", "gap_link",
    ],
    "scripts/enforcement/connector-workflow-requirements.tsv": [
        "connector_requirement_id", "status", "connector_id", "source_path", "target_path", "workflow_scope",
        "required_evidence", "fallback_rule", "exemption_state", "audit_link", "gap_link",
    ],
    "scripts/enforcement/waiver-requirements.tsv": [
        "waiver_id", "status", "linked_requirement_id", "reason", "scope", "owner_context",
        "expiry_or_revisit_trigger", "audit_link", "gap_link",
    ],
}

PATH_COLUMNS = {
    "source_doc_path", "target_manifest_path", "template_path", "target_path", "example_path", "run_path",
    "validation_path", "source_path", "audit_link", "gap_link",
}


def is_skip(value: str) -> bool:
    return value.strip() in SKIP


def is_url(value: str) -> bool:
    return value.startswith("http://") or value.startswith("https://")


def split_items(value: str) -> list[str]:
    return [part.strip() for part in re.split(r"[;,]", value) if part.strip()]


def strip_anchor(value: str) -> str:
    return value.split("#", 1)[0]


class Gate:
    def __init__(self, root: Path) -> None:
        self.root = root
        self.errors: list[str] = []
        self.rows: dict[str, list[dict[str, str]]] = {}

    def fail(self, message: str) -> None:
        self.errors.append(message)

    def require(self, condition: bool, message: str) -> None:
        if not condition:
            self.fail(message)

    def read_manifest(self, rel: str) -> list[dict[str, str]]:
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
            self.fail(f"{rel}: schema mismatch; expected exact header {expected}, got {header}")
            self.rows[rel] = []
            return []
        parsed: list[dict[str, str]] = []
        for raw in lines:
            if not raw or raw.startswith("#"):
                continue
            cells = next(csv.reader([raw], delimiter="\t"))
            if len(cells) != len(header):
                self.fail(f"{rel}: wrong column count in row: {raw}")
                continue
            row = dict(zip(header, [cell.strip() for cell in cells]))
            if any(value == "" for value in row.values()):
                self.fail(f"{rel}: empty cell in row: {raw}")
            if "status" in row and row["status"] not in ALLOWED_STATUS:
                self.fail(f"{rel}: invalid status {row['status']}")
            if "exemption_state" in row and row["exemption_state"] not in ALLOWED_EXEMPTIONS:
                self.fail(f"{rel}: invalid exemption_state {row['exemption_state']}")
            parsed.append(row)
        self.rows[rel] = parsed
        return parsed

    def validate_paths(self) -> None:
        for rel, rows in self.rows.items():
            for row in rows:
                if row.get("status") not in CONCRETE_STATUS | {"exempt"}:
                    continue
                for col in PATH_COLUMNS:
                    if col not in row:
                        continue
                    for item in split_items(row[col]):
                        if is_skip(item) or is_url(item):
                            continue
                        item_path = strip_anchor(item)
                        if is_skip(item_path):
                            continue
                        if not (self.root / item_path).exists():
                            self.fail(f"{rel}: {col} path does not exist: {item}")

    def template_requirements(self) -> set[str]:
        path = self.root / "scripts/enforcement/template-requirements.tsv"
        mapped: set[str] = set()
        if not path.is_file():
            self.fail("missing scripts/enforcement/template-requirements.tsv")
            return mapped
        for raw in path.read_text(encoding="utf-8").splitlines():
            if not raw or raw.startswith("#"):
                continue
            parts = raw.split("\t")
            if len(parts) != 4:
                self.fail(f"template-requirements.tsv: expected 4 columns: {raw}")
                continue
            mapped.add(parts[0].strip())
        return mapped

    def validate_templates(self, mapped: set[str]) -> None:
        templates_dir = self.root / "templates"
        if not templates_dir.is_dir():
            return
        for child in templates_dir.iterdir():
            if child.is_dir() and child.name not in mapped:
                self.fail(f"template directory templates/{child.name} lacks template-requirements.tsv row")

    def validate_project_type_coverage(self, template_ids: set[str]) -> None:
        roadmaps = {r["project_type_id"]: r for r in self.rows["scripts/enforcement/project-type-roadmaps.tsv"]}
        result = {r["project_type_id"]: r for r in self.rows["scripts/enforcement/result-loop-requirements.tsv"]}
        docs: dict[str, list[dict[str, str]]] = {}
        for row in self.rows["scripts/enforcement/documentation-sources.tsv"]:
            docs.setdefault(row["project_type_id"], []).append(row)
        patterns = {r["project_type_id"] for r in self.rows["scripts/enforcement/pattern-requirements.tsv"] if r.get("status") in CONCRETE_STATUS}
        skills = {r["project_type_id"] for r in self.rows["scripts/enforcement/skill-requirements.tsv"] if r.get("status") in CONCRETE_STATUS}

        referenced = set(roadmaps) | set(result) | set(docs) | patterns | skills
        for project in sorted(referenced - set(roadmaps)):
            self.fail(f"project type {project} referenced without roadmap row")
        for project, row in roadmaps.items():
            if row["status"] not in CONCRETE_STATUS:
                continue
            if project not in result:
                self.fail(f"project type {project} lacks result-loop-requirements row")
            if project not in docs:
                self.fail(f"project type {project} lacks documentation-sources row")
            if project not in patterns:
                self.fail(f"project type {project} lacks active pattern requirement")
            if project not in skills:
                self.fail(f"project type {project} lacks active skill requirement")
            for template_path in split_items(row.get("template_path", "")):
                if is_skip(template_path):
                    continue
                template_id = Path(template_path).name
                if template_id not in template_ids:
                    self.fail(f"project type {project} template {template_path} lacks template requirement row")

    def validate_metadata(self) -> None:
        for row in self.rows["scripts/enforcement/documentation-sources.tsv"]:
            if row["status"] not in CONCRETE_STATUS:
                continue
            self.require(is_url(row["source_url"]), f"documentation source {row['source_id']} lacks http(s) source_url")
            for field in ["reason", "freshness_note", "consult_rule", "fallback_or_waiver"]:
                self.require(len(row[field]) >= 8 and not is_skip(row[field]), f"documentation source {row['source_id']} missing {field}")
        for row in self.rows["scripts/enforcement/reference-repositories.tsv"]:
            if row["status"] not in CONCRETE_STATUS:
                continue
            for field in ["repository_url", "owner_type", "usage_scope", "license_usage_note", "freshness_status", "validation_status"]:
                self.require(not is_skip(row[field]) and len(row[field]) >= 4, f"reference repo {row['reference_id']} missing {field}")
        for row in self.rows["scripts/enforcement/code-example-requirements.tsv"]:
            if row["status"] not in CONCRETE_STATUS:
                continue
            for field in ["supported_template", "run_path", "validation_path", "owner", "source_reference"]:
                self.require(not is_skip(row[field]) and len(row[field]) >= 3, f"code example {row['example_id']} missing {field}")
        for rel, id_field, required in [
            ("scripts/enforcement/pattern-requirements.tsv", "pattern_requirement_id", ["usage_rule", "enforcement_rule", "required_evidence"]),
            ("scripts/enforcement/skill-requirements.tsv", "skill_requirement_id", ["trigger_rule", "evidence_rule"]),
            ("scripts/enforcement/connector-workflow-requirements.tsv", "connector_requirement_id", ["required_evidence", "fallback_rule"]),
        ]:
            for row in self.rows[rel]:
                if row["status"] not in CONCRETE_STATUS:
                    continue
                for field in required:
                    self.require(not is_skip(row[field]) and len(row[field]) >= 5, f"{rel}: {row[id_field]} missing {field}")
        for row in self.rows["scripts/enforcement/waiver-requirements.tsv"]:
            if row["status"] not in CONCRETE_STATUS:
                continue
            for field in ["reason", "scope", "owner_context", "expiry_or_revisit_trigger", "audit_link", "gap_link"]:
                self.require(not is_skip(row[field]) and len(row[field]) >= 5, f"waiver {row['waiver_id']} missing {field}")

    def validate_game_development(self) -> None:
        row = next((r for r in self.rows["scripts/enforcement/project-type-roadmaps.tsv"] if r["project_type_id"] == "game-development"), None)
        if not row or row["status"] not in CONCRETE_STATUS:
            return
        evidence = row["required_evidence"].lower()
        for token in ["playable", "gameplay", "visual", "performance", "telemetry"]:
            self.require(token in evidence, f"game-development required_evidence must include {token}")

    def validate_audit_claims(self) -> None:
        audit = self.root / "docs/operations/result-loop-contract-audit-checklist.md"
        if not audit.is_file():
            self.fail("missing result-loop audit checklist")
            return
        text = audit.read_text(encoding="utf-8")
        if "- [x] Implement deterministic scaling gate" in text:
            self.require((self.root / "scripts/enforcement/check-scaling-extension.py").is_file(), "audit marks scaling gate done but gate script is missing")
        if "- [x] Add positive fixture: a fully registered project type passes scaling enforcement." in text:
            self.require((self.root / "scripts/enforcement/fixtures/scaling-extension/cases.tsv").is_file(), "audit marks fixtures done but fixture catalog is missing")
            self.require((self.root / "scripts/enforcement/tests/test-scaling-extension.sh").is_file(), "audit marks fixtures done but test wrapper is missing")

    def run(self) -> int:
        for rel in SCHEMAS:
            self.read_manifest(rel)
        template_ids = self.template_requirements()
        self.validate_paths()
        self.validate_templates(template_ids)
        self.validate_project_type_coverage(template_ids)
        self.validate_metadata()
        self.validate_game_development()
        self.validate_audit_claims()
        if self.errors:
            for error in self.errors:
                print(f"ERROR_FOR_AGENT: {error}")
            return 1
        print("✅ scaling extension gate passed")
        return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=".", help="repository root to validate")
    args = parser.parse_args()
    return Gate(Path(args.root).resolve()).run()


if __name__ == "__main__":
    sys.exit(main())

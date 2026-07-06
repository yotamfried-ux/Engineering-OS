#!/usr/bin/env python3
"""Deterministic scaling-extension gate for Engineering OS.

The gate validates that scalable extension assets are registered in manifests,
that active rows include the metadata needed by the scaling procedure, and that
fixtures/audit cannot claim completion without enforcement artifacts.
"""
from __future__ import annotations

import argparse
import csv
import re
import sys
from pathlib import Path
from typing import Iterable

ALLOWED_STATUS = {"active", "required", "planned", "deferred", "exempt"}
ALLOWED_EXEMPTIONS = {"not_exempt", "exempt", "waiver_required", "waived", "not_applicable"}
SKIP_VALUES = {"", "NONE", "none", "planned", "TBD", "tbd", "n/a", "NA"}
REQUIRE_CONCRETE = {"active", "required"}
PATH_COLUMNS = {
    "source_path",
    "target_path",
    "source_doc_path",
    "template_path",
    "target_manifest_path",
    "example_path",
    "run_path",
    "validation_path",
    "audit_link",
    "gap_link",
}

MANIFEST_SCHEMAS: dict[str, list[str]] = {
    "scripts/enforcement/project-type-roadmaps.tsv": [
        "project_type_id", "status", "roadmap_label", "source_doc_path", "template_path",
        "target_manifest_path", "required_evidence", "exemption_state", "audit_link", "gap_link",
    ],
    "scripts/enforcement/result-loop-requirements.tsv": [
        "project_type_id", "status", "source_doc_path", "target_manifest_path", "setup_command",
        "run_command", "visible_result", "creator_local_review", "required_tests", "user_simulation",
        "feedback_surfaces", "performance_monitoring", "acceptance_metrics",
        "change_impact_measurement", "telemetry_export", "failure_repair_loop", "evidence_artifacts",
        "exemption_state", "audit_link", "gap_link",
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
        "validation_path", "owner", "source_reference", "required_evidence", "exemption_state",
        "audit_link", "gap_link",
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
    "scripts/enforcement/waiver-requirements.tsv": [
        "waiver_id", "status", "linked_requirement_id", "reason", "scope", "owner_context",
        "expiry_or_revisit_trigger", "audit_link", "gap_link",
    ],
}


def is_skip(value: str) -> bool:
    return value.strip() in SKIP_VALUES


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
        self.manifests: dict[str, list[dict[str, str]]] = {}

    def fail(self, message: str) -> None:
        self.errors.append(message)

    def require(self, condition: bool, message: str) -> None:
        if not condition:
            self.fail(message)

    def read_manifest(self, rel: str) -> list[dict[str, str]]:
        expected = MANIFEST_SCHEMAS[rel]
        path = self.root / rel
        if not path.is_file():
            self.fail(f"missing manifest: {rel}")
            self.manifests[rel] = []
            return []
        lines = path.read_text(encoding="utf-8").splitlines()
        header_line = next((line for line in lines if line.startswith("# ") and "\t" in line), None)
        if not header_line:
            self.fail(f"{rel}: missing commented TSV header")
            self.manifests[rel] = []
            return []
        header = header_line[2:].split("\t")
        if header != expected:
            missing = [col for col in expected if col not in header]
            unknown = [col for col in header if col not in expected]
            detail = []
            if missing:
                detail.append("missing columns: " + ", ".join(missing))
            if unknown:
                detail.append("unknown columns: " + ", ".join(unknown))
            if not detail:
                detail.append("column order does not match documented schema")
            self.fail(f"{rel}: schema mismatch; {'; '.join(detail)}")
            self.manifests[rel] = []
            return []

        rows: list[dict[str, str]] = []
        for raw in lines:
            if not raw or raw.startswith("#"):
                continue
            cells = next(csv.reader([raw], delimiter="\t"))
            if len(cells) != len(header):
                self.fail(f"{rel}: expected {len(header)} columns, got {len(cells)} in row: {raw}")
                continue
            row = dict(zip(header, [cell.strip() for cell in cells]))
            if any(not cell for cell in row.values()):
                self.fail(f"{rel}: empty cell in row: {raw}")
            status = row.get("status", "")
            exemption = row.get("exemption_state", "not_exempt")
            if "status" in header and status not in ALLOWED_STATUS:
                self.fail(f"{rel}: invalid status {status}")
            if "exemption_state" in header and exemption not in ALLOWED_EXEMPTIONS:
                self.fail(f"{rel}: invalid exemption_state {exemption}")
            rows.append(row)
        self.manifests[rel] = rows
        return rows

    def load_all_manifests(self) -> None:
        for rel in MANIFEST_SCHEMAS:
            self.read_manifest(rel)

    def validate_paths(self) -> None:
        for rel, rows in self.manifests.items():
            header = MANIFEST_SCHEMAS[rel]
            for row in rows:
                if row.get("status") not in {"active", "required", "exempt"}:
                    continue
                for name in header:
                    if name not in PATH_COLUMNS and not name.endswith("_path"):
                        continue
                    for item in split_items(row.get(name, "")):
                        if is_skip(item) or is_url(item):
                            continue
                        path_item = strip_anchor(item)
                        if is_skip(path_item):
                            continue
                        if not (self.root / path_item).exists():
                            self.fail(f"{rel}: {name} path does not exist for {row.get('status')} row: {item}")

    def load_template_requirements(self) -> dict[str, dict[str, str]]:
        rel = "scripts/enforcement/template-requirements.tsv"
        path = self.root / rel
        rows: dict[str, dict[str, str]] = {}
        if not path.is_file():
            self.fail(f"missing template requirements manifest: {rel}")
            return rows
        for raw in path.read_text(encoding="utf-8").splitlines():
            if not raw or raw.startswith("#"):
                continue
            parts = raw.split("\t")
            if len(parts) != 4:
                self.fail(f"{rel}: expected 4 columns, got {len(parts)} in row: {raw}")
                continue
            template_id, kind, keyword_ere, reason = [p.strip() for p in parts]
            if kind not in {"project", "exempt"}:
                self.fail(f"{rel}: {template_id} invalid kind {kind}")
            if kind == "project" and (not keyword_ere or keyword_ere == "NONE"):
                self.fail(f"{rel}: project template {template_id} requires a keyword ERE")
            if len(reason) < 20:
                self.fail(f"{rel}: {template_id} reason is too short")
            rows[template_id] = {"kind": kind, "keyword_ere": keyword_ere, "reason": reason}
        return rows

    def validate_template_directory_coverage(self, template_rows: dict[str, dict[str, str]]) -> None:
        templates_dir = self.root / "templates"
        if not templates_dir.is_dir():
            return
        mapped = set(template_rows)
        for child in sorted(templates_dir.iterdir()):
            if child.is_dir() and child.name not in mapped:
                self.fail(f"template inventory coverage failed: templates/{child.name}/ has no template-requirements.tsv row")

    def validate_project_type_mapping(self, template_rows: dict[str, dict[str, str]]) -> None:
        roadmaps = self.manifests["scripts/enforcement/project-type-roadmaps.tsv"]
        result_loop = self.manifests["scripts/enforcement/result-loop-requirements.tsv"]
        docs = self.manifests["scripts/enforcement/documentation-sources.tsv"]
        patterns = self.manifests["scripts/enforcement/pattern-requirements.tsv"]
        skills = self.manifests["scripts/enforcement/skill-requirements.tsv"]

        roadmap_by_project = {r["project_type_id"]: r for r in roadmaps}
        result_by_project = {r["project_type_id"]: r for r in result_loop}
        docs_by_project: dict[str, list[dict[str, str]]] = {}
        for row in docs:
            docs_by_project.setdefault(row["project_type_id"], []).append(row)
        pattern_projects = {r["project_type_id"] for r in patterns if r.get("status") in REQUIRE_CONCRETE}
        skill_projects = {r["project_type_id"] for r in skills if r.get("status") in REQUIRE_CONCRETE}

        referenced_projects: set[str] = set()
        for rel in [
            "scripts/enforcement/result-loop-requirements.tsv",
            "scripts/enforcement/documentation-sources.tsv",
            "scripts/enforcement/reference-repositories.tsv",
            "scripts/enforcement/code-example-requirements.tsv",
            "scripts/enforcement/pattern-requirements.tsv",
            "scripts/enforcement/skill-requirements.tsv",
        ]:
            for row in self.manifests[rel]:
                project = row.get("project_type_id")
                if project and not is_skip(project):
                    referenced_projects.add(project)

        for project in sorted(referenced_projects - set(roadmap_by_project)):
            self.fail(f"project type mapping failed: {project} is referenced by a manifest but has no project-type-roadmaps.tsv row")

        for project, row in sorted(roadmap_by_project.items()):
            if row["status"] not in REQUIRE_CONCRETE:
                continue
            if project not in result_by_project:
                self.fail(f"project type mapping failed: {project} has no result-loop-requirements.tsv row")
            if not docs_by_project.get(project):
                self.fail(f"project type mapping failed: {project} has no documentation-sources.tsv row")
            if project not in pattern_projects:
                self.fail(f"project type mapping failed: {project} has no active pattern-requirements.tsv row")
            if project not in skill_projects:
                self.fail(f"project type mapping failed: {project} has no active skill-requirements.tsv row")
            for template_path in split_items(row.get("template_path", "")):
                if is_skip(template_path):
                    continue
                template_id = Path(template_path).name
                if template_id not in template_rows:
                    self.fail(f"project type mapping failed: {project} template {template_path} has no template-requirements.tsv row")

    def validate_documentation_sources(self) -> None:
        for row in self.manifests["scripts/enforcement/documentation-sources.tsv"]:
            if row["status"] not in REQUIRE_CONCRETE:
                continue
            prefix = f"documentation source {row['source_id']}"
            self.require(is_url(row["source_url"]), f"{prefix}: source_url must be an http(s) URL")
            for field in ["reason", "freshness_note", "consult_rule", "fallback_or_waiver"]:
                self.require(not is_skip(row[field]) and len(row[field]) >= 8, f"{prefix}: missing {field}")
            self.require(row["source_type"] in {"official_docs", "trusted_docs", "trusted_internal_catalog"}, f"{prefix}: source_type must be official_docs/trusted_docs/trusted_internal_catalog")

    def validate_roadmap_official_sources(self) -> None:
        docs_by_project: dict[str, list[dict[str, str]]] = {}
        for row in self.manifests["scripts/enforcement/documentation-sources.tsv"]:
            docs_by_project.setdefault(row["project_type_id"], []).append(row)
        for row in self.manifests["scripts/enforcement/project-type-roadmaps.tsv"]:
            if row["status"] not in REQUIRE_CONCRETE:
                continue
            project = row["project_type_id"]
            official = [
                source for source in docs_by_project.get(project, [])
                if source.get("status") in REQUIRE_CONCRETE
                and source.get("source_type") in {"official_docs", "trusted_docs", "trusted_internal_catalog"}
                and is_url(source.get("source_url", ""))
            ]
            self.require(bool(official), f"roadmap official sources failed: {project} has no active official/trusted documentation source URL")

    def validate_reference_repositories(self) -> None:
        allowed_validation = {"validated", "stale", "unverified"}
        for row in self.manifests["scripts/enforcement/reference-repositories.tsv"]:
            if row["status"] not in REQUIRE_CONCRETE:
                continue
            prefix = f"reference repository {row['reference_id']}"
            self.require(is_url(row["repository_url"]), f"{prefix}: repository_url must be an http(s) URL")
            for field in ["owner_type", "usage_scope", "license_usage_note", "freshness_status"]:
                self.require(not is_skip(row[field]) and len(row[field]) >= 4, f"{prefix}: missing {field}")
            validation = row["validation_status"]
            self.require(validation in allowed_validation, f"{prefix}: validation_status must be validated/stale/unverified")
            if validation == "validated":
                self.require(not is_skip(row["validation_evidence"]), f"{prefix}: validated rows require validation_evidence")

    def validate_code_examples(self, template_rows: dict[str, dict[str, str]]) -> None:
        for row in self.manifests["scripts/enforcement/code-example-requirements.tsv"]:
            if row["status"] not in REQUIRE_CONCRETE:
                continue
            prefix = f"code example {row['example_id']}"
            for field in ["supported_template", "run_path", "validation_path", "owner"]:
                self.require(not is_skip(row[field]), f"{prefix}: missing {field}")
            template = row["supported_template"]
            if not is_skip(template):
                self.require(template in template_rows or template == row["project_type_id"], f"{prefix}: supported_template {template} has no template-requirements.tsv row")

    def validate_patterns_and_skills(self) -> None:
        for row in self.manifests["scripts/enforcement/pattern-requirements.tsv"]:
            if row["status"] not in REQUIRE_CONCRETE:
                continue
            prefix = f"pattern requirement {row['pattern_requirement_id']}"
            for field in ["usage_rule", "enforcement_rule", "required_evidence"]:
                self.require(not is_skip(row[field]), f"{prefix}: missing {field}")
        for row in self.manifests["scripts/enforcement/skill-requirements.tsv"]:
            if row["status"] not in REQUIRE_CONCRETE:
                continue
            prefix = f"skill requirement {row['skill_requirement_id']}"
            for field in ["trigger_rule", "evidence_rule"]:
                self.require(not is_skip(row[field]), f"{prefix}: missing {field}")

    def validate_connector_workflows(self) -> None:
        for row in self.manifests["scripts/enforcement/connector-workflow-requirements.tsv"]:
            if row["status"] not in REQUIRE_CONCRETE:
                continue
            prefix = f"connector workflow {row['connector_requirement_id']}"
            for field in ["workflow_scope", "required_evidence", "fallback_rule"]:
                self.require(not is_skip(row[field]) and len(row[field]) >= 8, f"{prefix}: missing {field}")

    def validate_waivers(self) -> None:
        waiver_rows = self.manifests["scripts/enforcement/waiver-requirements.tsv"]
        waiver_ids = {row["linked_requirement_id"] for row in waiver_rows if row["status"] in REQUIRE_CONCRETE}
        for row in waiver_rows:
            if row["status"] not in REQUIRE_CONCRETE:
                continue
            prefix = f"waiver {row['waiver_id']}"
            for field in ["reason", "scope", "owner_context", "expiry_or_revisit_trigger", "audit_link", "gap_link"]:
                self.require(not is_skip(row[field]) and len(row[field]) >= 4, f"{prefix}: missing {field}")
        for rel, rows in self.manifests.items():
            if rel == "scripts/enforcement/waiver-requirements.tsv":
                continue
            id_field = MANIFEST_SCHEMAS[rel][0]
            for row in rows:
                if row.get("exemption_state") in {"waived", "waiver_required"}:
                    linked = row.get(id_field, "")
                    self.require(linked in waiver_ids, f"waiver linkage failed: {rel} row {linked} has {row.get('exemption_state')} without waiver-requirements.tsv coverage")

    def validate_game_development(self) -> None:
        row = next((r for r in self.manifests["scripts/enforcement/project-type-roadmaps.tsv"] if r["project_type_id"] == "game-development"), None)
        if not row or row["status"] not in REQUIRE_CONCRETE:
            return
        evidence = row["required_evidence"].lower()
        requirements = {
            "playable surface": ["playable", "local"],
            "gameplay simulation": ["gameplay", "simulation"],
            "visual/gameplay evidence": ["screenshot", "video", "replay", "log", "profiler"],
            "performance metrics": ["performance", "fps", "frame", "memory", "load", "crash"],
            "telemetry export": ["telemetry"],
        }
        for label, tokens in requirements.items():
            if not any(token in evidence for token in tokens):
                self.fail(f"game-development roadmap missing {label}")

    def validate_audit_claims(self) -> None:
        audit = self.root / "docs/operations/result-loop-contract-audit-checklist.md"
        if not audit.is_file():
            self.fail("missing audit checklist: docs/operations/result-loop-contract-audit-checklist.md")
            return
        text = audit.read_text(encoding="utf-8")
        script_exists = (self.root / "scripts/enforcement/check-scaling-extension.py").is_file()
        test_exists = (self.root / "scripts/enforcement/tests/test-scaling-extension.sh").is_file()
        fixture_catalog_exists = (self.root / "scripts/enforcement/fixtures/scaling-extension/cases.tsv").is_file()
        guarded_phrases = [
            "Implement deterministic scaling gate",
            "Reuse or extend existing template coverage checks",
            "Fail CI when a new project type appears",
            "Fail CI when roadmap rows lack official source references",
            "Fail CI when documentation sources lack reason",
            "Fail CI when reference repositories lack license/usage note",
            "Fail CI when code examples lack a run path or validation path",
            "Fail CI when patterns or skills are referenced",
            "Fail CI when connector-dependent workflows lack connector evidence",
            "Fail CI when telemetry export is missing",
            "Fail CI when a waiver/exemption is malformed",
            "Fail CI when audit marks a scaling item complete",
        ]
        for phrase in guarded_phrases:
            if re.search(rf"- \[x\] {re.escape(phrase)}", text) and not script_exists:
                self.fail(f"audit claim blocked: '{phrase}' is checked before check-scaling-extension.py exists")
        if re.search(r"- \[x\] Add positive fixture: a fully registered project type passes scaling enforcement\.", text) and not (test_exists and fixture_catalog_exists):
            self.fail("audit claim blocked: scaling fixtures checked before test and fixture catalog exist")
        premature_complete = [
            "Every extension type has a fixed add/update path and enforcement rule or explicit exemption.",
            "CI fails when scaling additions bypass registries/manifests.",
            "CI fails when docs, reference repos, examples, patterns, skills, or connectors are added without required metadata and enforcement coverage.",
            "Scaling simulations prove both complete additions and rejected incomplete additions.",
        ]
        for phrase in premature_complete:
            if re.search(rf"- \[x\] {re.escape(phrase)}", text) and not script_exists:
                self.fail(f"audit completion claim blocked before enforcement artifact: {phrase}")

    def run(self) -> int:
        self.load_all_manifests()
        template_rows = self.load_template_requirements()
        self.validate_template_directory_coverage(template_rows)
        self.validate_paths()
        self.validate_project_type_mapping(template_rows)
        self.validate_documentation_sources()
        self.validate_roadmap_official_sources()
        self.validate_reference_repositories()
        self.validate_code_examples(template_rows)
        self.validate_patterns_and_skills()
        self.validate_connector_workflows()
        self.validate_waivers()
        self.validate_game_development()
        self.validate_audit_claims()
        if self.errors:
            for error in self.errors:
                print(error, file=sys.stderr)
            return 1
        print("scaling extension gate passed")
        return 0


def main(argv: Iterable[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=str(Path(__file__).resolve().parents[2]), help="repository root to validate")
    args = parser.parse_args(list(argv) if argv is not None else None)
    return Gate(Path(args.root).resolve()).run()


if __name__ == "__main__":
    raise SystemExit(main())

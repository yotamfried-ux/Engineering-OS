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
PLACEHOLDER = {"", "NONE", "none", "required", "planned", "deferred", "TBD", "tbd", "n/a", "NA"}
RESULT_LOOP = "scripts/enforcement/result-loop-requirements.tsv"
ROADMAPS = "scripts/enforcement/project-type-roadmaps.tsv"
REQUIRED_FIELDS = [
    "setup_command",
    "run_command",
    "visible_result",
    "creator_local_review",
    "required_tests",
    "user_simulation",
    "feedback_surfaces",
    "performance_monitoring",
    "acceptance_metrics",
    "change_impact_measurement",
    "telemetry_export",
    "failure_repair_loop",
    "evidence_artifacts",
]


def words(value: str) -> str:
    return re.sub(r"[^a-z0-9./_-]+", " ", value.lower())


def has_any(value: str, tokens: list[str]) -> bool:
    text = words(value)
    return any(re.search(r"(?<![a-z0-9])" + re.escape(token.lower()) + r"(?![a-z0-9])", text) for token in tokens)


def has_phrase(value: str, phrase: str) -> bool:
    return phrase.lower() in value.lower()


def concrete(value: str) -> bool:
    clean = value.strip()
    return clean not in PLACEHOLDER and len(clean) >= 8


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
            errors.append(f"invalid status in {rel}: {row.get('status')}")
        if row.get("exemption_state") not in EXEMPT:
            errors.append(f"invalid exemption_state in {rel}: {row.get('exemption_state')}")
        rows.append(row)
    return rows


def require_field(row: dict[str, str], field: str, errors: list[str]) -> None:
    if not concrete(row.get(field, "")):
        errors.append(f"result-loop {row.get('project_type_id', '<unknown>')} lacks concrete {field}")


def require_any(row: dict[str, str], field: str, tokens: list[str], label: str, errors: list[str]) -> None:
    if not has_any(row.get(field, ""), tokens):
        errors.append(f"result-loop {row['project_type_id']} lacks {label} in {field}")


def require_phrase(row: dict[str, str], field: str, phrase: str, label: str, errors: list[str]) -> None:
    if not has_phrase(row.get(field, ""), phrase):
        errors.append(f"result-loop {row['project_type_id']} lacks {label} in {field}")


def check_project(row: dict[str, str], errors: list[str]) -> None:
    project = row["project_type_id"]
    for field in REQUIRED_FIELDS:
        require_field(row, field, errors)

    require_any(row, "creator_local_review", ["local", "url", "device", "simulator", "emulator", "window", "output", "build"], "creator-visible local review", errors)
    require_any(row, "user_simulation", ["e2e", "flow", "simulation", "playwright", "appium", "test", "bot", "eval"], "user simulation", errors)
    require_any(row, "feedback_surfaces", ["screenshot", "video", "trace", "log", "console", "network", "report", "artifact", "replay"], "feedback artifact surface", errors)
    require_any(row, "performance_monitoring", ["metric", "performance", "latency", "memory", "runtime", "fps", "frame", "cost", "throughput", "error"], "performance monitoring", errors)
    require_any(row, "acceptance_metrics", ["threshold", "budget", "pass", "fail", "metric", "criteria"], "measurable acceptance criteria", errors)
    require_any(row, "change_impact_measurement", ["before/after", "comparison", "diff", "baseline", "compare"], "change-impact comparison", errors)
    require_phrase(row, "telemetry_export", "scripts/monitoring/export-telemetry-run.sh", "telemetry export script", errors)
    require_any(row, "telemetry_export", ["telemetry", "archive", "metadata"], "metadata telemetry archive", errors)
    require_any(row, "failure_repair_loop", ["stop", "failing", "fix", "rerun", "repair"], "failure repair loop", errors)
    require_any(row, "evidence_artifacts", ["artifact", "report", "screenshot", "video", "trace", "log", "telemetry", "bundle"], "evidence artifacts", errors)

    if project in {"web-application", "full-stack"}:
        require_any(row, "visible_result", ["url", "browser", "web"], "browser-visible result", errors)
        require_any(row, "user_simulation", ["playwright", "browser", "e2e"], "browser automation", errors)
        require_any(row, "feedback_surfaces", ["screenshot", "trace", "console", "network", "video"], "visual/browser feedback", errors)
    if project == "mobile-application":
        require_any(row, "creator_local_review", ["device", "simulator", "emulator", "development", "build"], "mobile device/simulator review", errors)
        require_any(row, "user_simulation", ["appium", "native", "flow"], "mobile user-flow automation", errors)
        require_any(row, "feedback_surfaces", ["screenshot", "video", "crash", "log"], "mobile runtime feedback", errors)
    if project == "desktop-application":
        require_any(row, "creator_local_review", ["window", "desktop", "packaged", "dev-run"], "desktop app-window review", errors)
        require_any(row, "user_simulation", ["electron", "tauri", "webdriver", "appium", "ui"], "desktop UI automation", errors)
        require_any(row, "feedback_surfaces", ["screenshot", "video", "console", "log", "crash"], "desktop runtime feedback", errors)
    if project == "game-development":
        require_any(row, "visible_result", ["playable", "editor", "build"], "playable local surface", errors)
        require_any(row, "user_simulation", ["gameplay", "input", "bot", "automation", "simulation"], "gameplay simulation", errors)
        require_any(row, "feedback_surfaces", ["screenshot", "video", "replay", "profiler", "log"], "game visual/profiler evidence", errors)
        require_any(row, "performance_monitoring", ["fps", "frame", "memory", "load", "crash"], "game performance metrics", errors)
    if project == "api-service":
        require_any(row, "visible_result", ["health", "endpoint", "response"], "service health/response surface", errors)
        require_any(row, "required_tests", ["contract", "integration"], "API contract/integration tests", errors)
        require_any(row, "performance_monitoring", ["latency", "throughput", "error", "metrics", "trace"], "service metrics", errors)
    if project == "data-pipeline":
        require_any(row, "visible_result", ["dataset", "output", "report"], "data output surface", errors)
        require_any(row, "acceptance_metrics", ["row", "quality", "threshold", "pass", "fail"], "data quality criteria", errors)
    if project == "machine-learning":
        require_any(row, "required_tests", ["evaluation", "inference", "training", "mlflow"], "ML evaluation path", errors)
        require_any(row, "acceptance_metrics", ["metric", "threshold", "score", "pass", "fail"], "ML metric threshold", errors)
    if project == "ai-agent":
        require_any(row, "required_tests", ["eval", "retrieval", "trace"], "agent eval path", errors)
        require_any(row, "performance_monitoring", ["latency", "cost", "error", "metric"], "agent runtime metrics", errors)
    if project == "computer-vision":
        require_any(row, "visible_result", ["media", "output", "artifact", "video", "image"], "vision output artifact", errors)
        require_any(row, "feedback_surfaces", ["visual", "screenshot", "video", "review"], "visual review evidence", errors)
    if project == "browser-extension":
        require_any(row, "visible_result", ["extension", "browser"], "local extension surface", errors)
        require_any(row, "user_simulation", ["browser", "playwright", "automation"], "browser-extension automation", errors)


def check(root: Path) -> list[str]:
    errors: list[str] = []
    result_rows = read_tsv(root, RESULT_LOOP, errors)
    roadmap_rows = read_tsv(root, ROADMAPS, errors)
    if errors:
        return errors

    result_by_project = {row["project_type_id"]: row for row in result_rows}
    active_roadmaps = {row["project_type_id"] for row in roadmap_rows if row.get("status") in ACTIVE}
    for project in sorted(active_roadmaps):
        row = result_by_project.get(project)
        if not row:
            errors.append(f"project type {project} lacks result-loop contract row")
            continue
        if row.get("status") not in ACTIVE:
            errors.append(f"project type {project} result-loop contract is not active or required")
            continue
        if row.get("exemption_state") != "not_exempt":
            errors.append(f"project type {project} result-loop contract must be not_exempt while required")
            continue
        check_project(row, errors)

    for project, row in sorted(result_by_project.items()):
        if row.get("status") in ACTIVE and project not in active_roadmaps:
            errors.append(f"result-loop contract references project without active roadmap: {project}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=".")
    errors = check(Path(parser.parse_args().root).resolve())
    if errors:
        for error in errors:
            print(f"RESULT_LOOP_GATE_ERROR: {error}")
        return 1
    print("result loop contract gate passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
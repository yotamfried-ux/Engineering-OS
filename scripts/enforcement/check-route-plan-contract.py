#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

REQUIRED_FIELDS = [
    ("selected_project_type", ["selected_project_type", "selected project type", "project type"]),
    ("selected_template", ["selected_template", "selected template", "templates", "template"]),
    ("selected_roadmap", ["selected_roadmap", "selected roadmap", "roadmap"]),
    ("selected_result_loop_contract", ["selected_result_loop_contract", "selected result loop contract", "selected result-loop contract", "result loop contract", "result-loop contract"]),
    ("required_user_simulation", ["required_user_simulation", "required user simulation", "user simulation"]),
    ("local_creator_review_path", ["local_creator_review_path", "local creator review path", "creator local review"]),
    ("telemetry_export_path", ["telemetry_export_path", "telemetry export path", "telemetry export"]),
    ("evidence_redaction_rule", ["evidence_redaction_rule", "evidence redaction rule", "redaction rule"]),
]

WAIVER_RE = re.compile(r"\b(waiver|known[ -]?gap|gap:|explicit exemption|planned requirement|requirement via)\b", re.I)
PLACEHOLDER_RE = re.compile(r"\b(todo|tbd|placeholder|unknown|later|to decide|not sure|unclear)\b", re.I)
MISSING_RE = re.compile(r"^(none|n/a|na|missing|not available|not applicable|no template|no roadmap|no contract)$", re.I)
DOC_ONLY_RE = re.compile(r"^(docs/|README\.md$|CHANGELOG\.md$|LICENSE$)")
PLAN_RE = re.compile(r"^\.claude/plans/.*\.md$")


def normalize_label(value: str) -> str:
    value = re.sub(r"[`*_]", "", value or "").strip().lower()
    value = value.replace("-", " ").replace("_", " ")
    value = re.sub(r"\s+", " ", value)
    return value


def strip_md_value(value: str) -> str:
    return re.sub(r"[`*_]", "", value or "").strip()


def field_value(text: str, names: list[str]) -> str:
    wanted = {normalize_label(name) for name in names}
    for line in text.splitlines():
        raw = line.strip()
        if not raw:
            continue
        if "|" in raw:
            cells = [cell.strip() for cell in raw.strip("|").split("|")]
            labels = [normalize_label(cell) for cell in cells]
            for index, label in enumerate(labels[:-1]):
                if label in wanted:
                    return strip_md_value(cells[index + 1])
        match = re.match(r"^\s*(?:[-*]\s*)?([^:|]+?)\s*:\s*(.+?)\s*$", line)
        if match and normalize_label(match.group(1)) in wanted:
            return strip_md_value(match.group(2))
    return ""


def is_code_config_or_test_target(path: str) -> bool:
    normalized = path.replace("\\", "/").lstrip("./")
    if not normalized:
        return False
    if PLAN_RE.match(normalized) or DOC_ONLY_RE.match(normalized):
        return False
    return True


def weak_value(value: str) -> bool:
    cleaned = strip_md_value(value)
    if not cleaned or len(cleaned) < 6:
        return True
    return bool(PLACEHOLDER_RE.search(cleaned))


def missing_without_waiver(value: str) -> bool:
    cleaned = strip_md_value(value)
    if not cleaned:
        return True
    if WAIVER_RE.search(cleaned):
        return False
    return bool(MISSING_RE.search(cleaned))


def validate_plan(plan_path: Path, targets: list[str]) -> list[str]:
    text = plan_path.read_text(encoding="utf-8")
    failures: list[str] = []
    active_targets = [target for target in targets if is_code_config_or_test_target(target)]
    if not active_targets:
        return []

    values: dict[str, str] = {}
    for field_id, names in REQUIRED_FIELDS:
        value = field_value(text, names)
        values[field_id] = value
        if weak_value(value):
            failures.append(f"{plan_path}: Route Plan field '{field_id}' is missing or placeholder.")

    for field_id in ("selected_template", "selected_roadmap", "selected_result_loop_contract", "selected_project_type"):
        if missing_without_waiver(values.get(field_id, "")):
            failures.append(f"{plan_path}: Route Plan field '{field_id}' is missing without an explicit waiver or known gap.")

    telemetry = values.get("telemetry_export_path", "")
    if telemetry and not re.search(r"telemetry|export", telemetry, re.I):
        failures.append(f"{plan_path}: telemetry_export_path must name a telemetry/export path or waiver.")

    redaction = values.get("evidence_redaction_rule", "")
    if redaction and not re.search(r"redact|metadata|sensitive|exclude", redaction, re.I):
        failures.append(f"{plan_path}: evidence_redaction_rule must state how evidence is handled.")

    return failures


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--plan", required=True)
    parser.add_argument("--target", action="append", default=[])
    args = parser.parse_args()

    plan_path = Path(args.plan)
    if not plan_path.is_file():
        print(f"missing readable --plan: {plan_path}", file=sys.stderr)
        return 2

    failures = validate_plan(plan_path, args.target)
    if failures:
        for failure in failures:
            print(f"ERROR_FOR_AGENT: {failure}", file=sys.stderr)
        print("ACTION: update the Route Plan result-loop integration fields, or name an explicit waiver/known gap.", file=sys.stderr)
        return 1

    print("route plan result-loop integration checks passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
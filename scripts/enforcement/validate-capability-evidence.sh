#!/usr/bin/env bash
# validate-capability-evidence.sh — PR/runtime bridge for capability registry usage.
#
# Validates changed Engineering OS route plans. A plan must declare a task class
# and must include either Capability Evidence or Capability Waiver. For known
# task classes, every required capability from core/capability-registry.yaml must
# appear in Capability Evidence or be explicitly listed in Capability Waiver.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REGISTRY="$ROOT/core/capability-registry.yaml"

if [ "$#" -gt 0 ]; then
  plans=("$@")
else
  shopt -s nullglob
  plans=(.claude/plans/*.md)
fi

[ "${#plans[@]}" -gt 0 ] || exit 0

python3 - "$REGISTRY" "${plans[@]}" <<'PY'
import re
import sys
from pathlib import Path

registry_path = Path(sys.argv[1])
plan_paths = [Path(p) for p in sys.argv[2:]]
registry = registry_path.read_text(encoding="utf-8")
failures: list[str] = []


def registry_task_classes(text: str) -> dict[str, list[str]]:
    start = re.search(r"(?m)^task_classes:\s*$", text)
    if not start:
        return {}
    end = re.search(r"(?m)^capabilities:\s*$", text[start.end():])
    block = text[start.end(): start.end() + end.start()] if end else text[start.end():]
    classes: dict[str, list[str]] = {}
    matches = list(re.finditer(r"(?m)^  ([A-Za-z0-9_-]+):\s*$", block))
    for index, match in enumerate(matches):
        name = match.group(1)
        section_start = match.end()
        section_end = matches[index + 1].start() if index + 1 < len(matches) else len(block)
        section = block[section_start:section_end]
        caps_match = re.search(r"(?ms)^    required_capabilities:\s*\n(.*?)(?=^    [A-Za-z0-9_-]+:|\Z)", section)
        caps: list[str] = []
        if caps_match:
            caps = [m.group(1).strip() for m in re.finditer(r"(?m)^      -\s*([^\s#]+)\s*$", caps_match.group(1))]
        classes[name] = caps
    return classes


def extract_task_class(text: str) -> str | None:
    table = re.search(r"(?im)^\|\s*Task[ _-]class\s*\|\s*([^|`]+|`[^`]+`)\s*\|", text)
    if table:
        return table.group(1).strip().strip("`")
    line = re.search(r"(?im)^\s*Task[ _-]class\s*:\s*([^\n#]+)", text)
    if line:
        return line.group(1).strip().strip("`")
    return None


def section(text: str, title: str) -> str:
    pattern = re.compile(rf"(?ims)^#{{1,6}}\s*{re.escape(title)}(?:\s|$)(.*?)(?=^#{{1,6}}\s|\Z)")
    match = pattern.search(text)
    return match.group(1) if match else ""


def ids_in(text: str) -> set[str]:
    return set(re.findall(r"`([^`]+)`", text))


def has_reason(text: str) -> bool:
    return bool(re.search(r"(?i)\b(because|reason|justification|not required)\b|לא נדרש|סיבה|נימוק", text))

classes = registry_task_classes(registry)

for plan in plan_paths:
    if not plan.exists():
        continue
    text = plan.read_text(encoding="utf-8")
    label = str(plan)

    task_class = extract_task_class(text)
    evidence = section(text, "Capability Evidence")
    waiver = section(text, "Capability Waiver")
    evidence_ids = ids_in(evidence)
    waiver_ids = ids_in(waiver)
    all_ids = evidence_ids | waiver_ids

    if not task_class:
        failures.append(f"ERROR_FOR_AGENT: {label} is missing Task class evidence.\nACTION: add 'Task class: <registry task class>' or a table row '| Task class | ... |'.")
        continue

    if not evidence and not waiver:
        failures.append(f"ERROR_FOR_AGENT: {label} is missing Capability Evidence / Capability Waiver section.\nACTION: add capability IDs from core/capability-registry.yaml, or focused waivers.")
        continue

    if evidence and not evidence_ids:
        failures.append(f"ERROR_FOR_AGENT: {label} has Capability Evidence but no backticked capability IDs.\nACTION: list concrete registry IDs, e.g. `routing.task-router-read`, `source.github-repo-read`.")

    if waiver and not has_reason(waiver):
        failures.append(f"ERROR_FOR_AGENT: {label} has Capability Waiver but no explicit reason/justification.\nACTION: explain why each waived capability is not required for this task.")

    if task_class in {"unclassified", "unknown"} or task_class not in classes:
        if not waiver or not has_reason(waiver):
            failures.append(f"ERROR_FOR_AGENT: {label} uses unknown/unclassified task class `{task_class}` without a Capability Waiver reason.\nACTION: choose a task class from core/capability-registry.yaml or add a waiver explaining why none applies.")
        continue

    required = classes.get(task_class, [])
    missing = [cap for cap in required if cap not in all_ids]
    if missing:
        lines = "\n".join(f" - `{cap}`" for cap in missing)
        failures.append(
            f"ERROR_FOR_AGENT: {label} selected task class `{task_class}` but is missing required capability evidence/waiver:\n"
            f"{lines}\n"
            f"ACTION: add each missing capability ID to `Capability Evidence`, or list it in `Capability Waiver` with a focused reason."
        )

if failures:
    print("❌ capability evidence validation failed:")
    for failure in failures:
        print(failure)
    sys.exit(1)

print(f"✅ capability evidence validated for {len(plan_paths)} plan file(s).")
PY

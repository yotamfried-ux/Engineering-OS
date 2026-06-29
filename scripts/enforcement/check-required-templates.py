#!/usr/bin/env python3
import argparse
import re
import sys
from pathlib import Path


def field_value(text: str, names: list[str]) -> str:
    wanted = {n.lower() for n in names}
    for line in text.splitlines():
        if "|" not in line:
            continue
        cells = [c.strip().strip("*_`").lower() for c in line.strip().strip("|").split("|")]
        raw = [c.strip() for c in line.strip().strip("|").split("|")]
        for i, cell in enumerate(cells[:-1]):
            if cell in wanted:
                return raw[i + 1].strip()
    return ""


def has_heading(text: str, heading_regex: str) -> bool:
    return re.search(rf"(?im)^#{{1,4}}\s+{heading_regex}(\s|$)", text) is not None


def section_text(text: str, heading_regex: str) -> str:
    lines = text.splitlines()
    found = False
    out: list[str] = []
    for line in lines:
        if re.match(r"^#{1,4}\s+", line):
            if re.search(heading_regex, line, re.I):
                found = True
                continue
            if found:
                break
        elif found:
            out.append(line)
    return "\n".join(out)


def canon(value: str) -> str:
    value = value.strip().lower().strip("`*")
    value = re.sub(r"^templates/", "", value)
    value = re.sub(r"/readme\.md$|\.md$", "", value)
    value = re.sub(r"[^a-z0-9_-]+", "-", value)
    return value.strip("-")


def selected_templates(value: str) -> set[str]:
    return {canon(x) for x in re.split(r"[,;\n]+", value) if canon(x)}


def has_word(text: str, words: str) -> bool:
    return re.search(rf"(^|[^a-z0-9])({words})([^a-z0-9]|$)", text) is not None


def valid_waiver(plan_text: str) -> bool:
    if not has_heading(plan_text, r"Template\s+Selection\s+Waiver"):
        return False
    body = section_text(plan_text, r"Template\s+Selection\s+Waiver")
    body = "\n".join(line for line in body.splitlines() if line.strip() and not line.strip().startswith("<!--"))
    if len(body) < 20:
        return False
    return re.search(r"reason|because|fallback|custom|manual|unsupported|environment|availability", body, re.I) is not None


def required_templates(task: str, tags: str, target: str) -> set[str]:
    text = f"{task} {tags} {target}".lower()
    req: set[str] = set()
    if re.search(r"saas|multi-tenant|subscription|billing", text):
        req.add("saas-platform")
    if re.search(r"booking|appointment|scheduler|calendar", text):
        req.add("booking-system")
    if has_word(text, r"api|rest|endpoint|microservice|server"):
        req.add("api-service")
    if has_word(text, r"web|frontend|ui|ux|component|screen|page|react|next"):
        req.add("web-application")
    if re.search(r"admin|dashboard|backoffice|control panel", text):
        req.add("admin-dashboard")
    if re.search(r"mobile|android|ios|expo|react native", text):
        req.add("mobile-application")
    if re.search(r"agent|ai-agent|multi-agent|llm|tool-calling", text):
        req.add("ai-agent")
    if re.search(r"data pipeline|etl|elt|analytics|warehouse|reporting", text):
        req.add("data-pipeline")
    if re.search(r"automation|workflow|zapier|make|n8n", text):
        req.add("automation-system")
    if re.search(r"extension|browser extension|chrome", text):
        req.add("browser-extension")
    if re.search(r"cli|command line|terminal tool", text):
        req.add("cli-tool")
    return req


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--plan", required=True)
    parser.add_argument("--target", required=True)
    args = parser.parse_args()

    plan_path = Path(args.plan)
    if not plan_path.is_file():
        print("missing readable --plan", file=sys.stderr)
        return 2

    text = plan_path.read_text(encoding="utf-8")
    task = field_value(text, ["Task class", "Task-class", "Type"])
    tags = field_value(text, ["Domain tags", "Domains", "Tags"])
    templates = field_value(text, ["Templates", "Template"])

    required = required_templates(task, tags, args.target)
    if not required:
        print("required template checks passed")
        return 0

    if has_heading(text, r"Template\s+Selection\s+Waiver"):
        if valid_waiver(text):
            print("required template checks passed via Template Selection Waiver")
            return 0
        print("template selection waiver invalid: add a specific reason/fallback.", file=sys.stderr)
        return 1

    selected = selected_templates(templates)
    missing = sorted(required - selected)
    if missing:
        print("required templates missing: " + " ".join(missing), file=sys.stderr)
        return 1

    print("required template checks passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

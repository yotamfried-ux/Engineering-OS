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


def valid_waiver(plan_text: str) -> bool:
    if not has_heading(plan_text, r"Template\s+Selection\s+Waiver"):
        return False
    body = section_text(plan_text, r"Template\s+Selection\s+Waiver")
    body = "\n".join(line for line in body.splitlines() if line.strip() and not line.strip().startswith("<!--"))
    if len(body) < 20:
        return False
    return re.search(r"reason|because|fallback|custom|manual|unsupported|environment|availability", body, re.I) is not None


DEFAULT_MANIFEST = Path(__file__).resolve().parent / "template-requirements.tsv"
DEFAULT_TEMPLATES_DIR = Path(__file__).resolve().parent.parent.parent / "templates"


def load_manifest(manifest_path: Path) -> list[tuple[str, str, str, str]]:
    """Parse the template requirements manifest; malformed rows abort (exit 2)."""
    rows: list[tuple[str, str, str, str]] = []
    for raw in manifest_path.read_text(encoding="utf-8").splitlines():
        if not raw or raw.startswith("#"):
            continue
        parts = raw.split("\t")
        if len(parts) != 4:
            print(f"template manifest malformed: expected 4 columns, got {len(parts)}: {raw[:60]}", file=sys.stderr)
            raise SystemExit(2)
        template_id, kind, ere, reason = (p.strip() for p in parts)
        if kind not in {"project", "exempt"}:
            print(f"template manifest malformed: {template_id} has invalid kind '{kind}'", file=sys.stderr)
            raise SystemExit(2)
        if kind == "project" and (not ere or ere == "NONE"):
            print(f"template manifest malformed: {template_id} is a project row without a keyword ERE", file=sys.stderr)
            raise SystemExit(2)
        if len(reason) < 20:
            print(f"template manifest malformed: {template_id} reason is too short", file=sys.stderr)
            raise SystemExit(2)
        rows.append((template_id, kind, ere, reason))
    return rows


def check_coverage(rows: list[tuple[str, str, str, str]], templates_dir: Path) -> int:
    """Every templates/<dir>/ must have a manifest row so new templates cannot be silently unselectable."""
    if not templates_dir.is_dir():
        print(f"templates directory not found: {templates_dir}", file=sys.stderr)
        return 1
    mapped = {template_id for template_id, _, _, _ in rows}
    missing = sorted(d.name for d in templates_dir.iterdir() if d.is_dir() and d.name not in mapped)
    if missing:
        for name in missing:
            print(f"template inventory coverage failed: templates/{name}/ has no manifest row", file=sys.stderr)
        return 1
    print(f"template requirements coverage passed ({len(mapped)} rows)")
    return 0


def required_templates(rows: list[tuple[str, str, str, str]], task: str, tags: str, target: str) -> set[str]:
    text = f"{task} {tags} {target}".lower()
    req: set[str] = set()
    for template_id, kind, ere, _reason in rows:
        if kind != "project":
            continue
        if re.search(ere, text):
            req.add(template_id)
    return req


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--plan")
    parser.add_argument("--target")
    parser.add_argument("--manifest", default=str(DEFAULT_MANIFEST))
    parser.add_argument("--templates-dir", default=str(DEFAULT_TEMPLATES_DIR))
    parser.add_argument("--check-coverage", action="store_true")
    args = parser.parse_args()

    manifest_path = Path(args.manifest)
    if not manifest_path.is_file():
        print(f"missing template requirements manifest: {manifest_path}", file=sys.stderr)
        return 2
    rows = load_manifest(manifest_path)

    if args.check_coverage:
        return check_coverage(rows, Path(args.templates_dir))

    if not args.plan or not args.target:
        print("missing --plan/--target", file=sys.stderr)
        return 2
    plan_path = Path(args.plan)
    if not plan_path.is_file():
        print("missing readable --plan", file=sys.stderr)
        return 2

    text = plan_path.read_text(encoding="utf-8")
    task = field_value(text, ["Task class", "Task-class", "Type"])
    tags = field_value(text, ["Domain tags", "Domains", "Tags"])
    templates = field_value(text, ["Templates", "Template"])

    required = required_templates(rows, task, tags, args.target)
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

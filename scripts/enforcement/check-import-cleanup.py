#!/usr/bin/env python3
"""Fail when changed JS/TS files contain unused static imports.

This intentionally stays lightweight: it handles default, named, namespace,
multiline, side-effect, semicolon-terminated, and semicolonless ES imports.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

SUPPORTED_SUFFIXES = {".js", ".jsx", ".ts", ".tsx"}
IDENT = re.compile(r"^[A-Za-z_$][\w$]*$")
FROM_END = re.compile(r"\bfrom\s+(['\"])[^'\"\n]+\1\s*;?\s*(?://[^\n]*)?$", re.S)
SIDE_EFFECT_END = re.compile(r"^\s*import\s+(['\"])[^'\"\n]+\1\s*;?\s*(?://[^\n]*)?$", re.S)


def changed_files(root: Path, base: str, head: str) -> list[Path]:
    output = subprocess.check_output(
        [
            "git",
            "-C",
            str(root),
            "diff",
            "--name-only",
            "--diff-filter=ACMR",
            f"{base}...{head}",
            "--",
            "*.js",
            "*.jsx",
            "*.ts",
            "*.tsx",
        ],
        text=True,
    )
    return [root / line for line in output.splitlines() if line.strip()]


def import_spans(text: str) -> list[tuple[int, int, str, int]]:
    """Return (start, end, statement, line) for complete static imports."""
    lines = text.splitlines(keepends=True)
    spans: list[tuple[int, int, str, int]] = []
    offset = 0
    index = 0

    while index < len(lines):
        line = lines[index]
        if not re.match(r"^[ \t]*import\s+", line) or re.match(r"^[ \t]*import\s*\(", line):
            offset += len(line)
            index += 1
            continue

        start = offset
        start_line = index + 1
        statement = line
        end = offset + len(line)
        cursor = index

        while not (FROM_END.search(statement.rstrip("\r\n")) or SIDE_EFFECT_END.search(statement.rstrip("\r\n"))):
            cursor += 1
            if cursor >= len(lines):
                break
            statement += lines[cursor]
            end += len(lines[cursor])
            if len(statement) > 10000:
                break

        if FROM_END.search(statement.rstrip("\r\n")) or SIDE_EFFECT_END.search(statement.rstrip("\r\n")):
            spans.append((start, end, statement, start_line))
            for consumed in range(index, cursor + 1):
                if consumed > index:
                    offset += len(lines[consumed])
            index = cursor + 1
            offset = end
        else:
            offset += len(line)
            index += 1

    return spans


def imported_names(statement: str) -> list[str]:
    if SIDE_EFFECT_END.match(statement.strip()):
        return []

    match = re.match(r"^\s*import\s+(.+?)\s+from\s+['\"]", statement, re.S)
    if not match:
        return []

    clause = match.group(1).strip()
    if clause.startswith("type "):
        clause = clause[5:].strip()

    names: list[str] = []

    namespace = re.search(r"\*\s+as\s+([A-Za-z_$][\w$]*)", clause)
    if namespace:
        names.append(namespace.group(1))

    named = re.search(r"\{([^}]*)\}", clause, re.S)
    if named:
        for part in named.group(1).split(","):
            part = re.sub(r"/\*.*?\*/", "", part, flags=re.S).strip()
            if not part:
                continue
            if part.startswith("type "):
                part = part[5:].strip()
            alias = re.split(r"\s+as\s+", part)
            names.append(alias[-1].strip())

    prefix = re.sub(r"\{[^}]*\}", "", clause, flags=re.S)
    prefix = re.sub(r"\*\s+as\s+[A-Za-z_$][\w$]*", "", prefix)
    prefix = prefix.strip().strip(",").strip()
    if prefix:
        default = prefix.split(",", 1)[0].strip()
        if default:
            names.append(default)

    return [name for name in names if IDENT.match(name)]


def check_file(path: Path) -> list[str]:
    try:
        text = path.read_text(encoding="utf-8", errors="ignore")
    except FileNotFoundError:
        return []

    if any(
        "EOS_SEMANTIC_CLEANUP_WAIVER:" in line
        and len(line.split(":", 1)[1].strip()) >= 25
        for line in text.splitlines()[:20]
    ):
        return []

    spans = import_spans(text)
    body = text
    for start, end, _, _ in reversed(spans):
        body = body[:start] + (" " * (end - start)) + body[end:]

    failures: list[str] = []
    for _, _, statement, line in spans:
        for name in imported_names(statement):
            if not re.search(r"(?<![\w$])" + re.escape(name) + r"(?![\w$])", body):
                failures.append(f"{path}:{line}: unused import {name}")
    return failures


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=".")
    parser.add_argument("--base")
    parser.add_argument("--head", default="HEAD")
    parser.add_argument("--files-from")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    if args.files_from:
        files = [root / line for line in Path(args.files_from).read_text().splitlines() if line.strip()]
    else:
        if not args.base:
            parser.error("--base is required unless --files-from is supplied")
        files = changed_files(root, args.base, args.head)

    failures: list[str] = []
    for path in files:
        if path.suffix.lower() in SUPPORTED_SUFFIXES:
            failures.extend(check_file(path))

    if failures:
        print("ERROR_FOR_AGENT: import cleanup failed")
        print("\n".join(f"- {failure}" for failure in failures))
        return 1

    print("Import cleanup passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

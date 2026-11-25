#!/usr/bin/env python3
"""Project-scoped React Bits component installer using the upstream jsrepo registry."""
from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
from pathlib import Path

EXAMPLES = ("SplitText", "ShinyText", "Magnet", "BlurText", "ScrollReveal")
VARIANTS = {"TS-TW", "TS-CSS", "JS-TW", "JS-CSS"}


def command(component: str, variant: str) -> list[str]:
    if not re.fullmatch(r"[A-Za-z][A-Za-z0-9]*", component):
        raise ValueError("Invalid component name; use an exact React Bits component name")
    if variant not in VARIANTS:
        raise ValueError("Invalid React Bits variant")
    return ["npx", "--yes", "jsrepo@latest", "add",
            f"https://reactbits.dev/r/{component}-{variant}"]


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description="Add a React Bits component to an existing web project.")
    p.add_argument("component", nargs="?", help="e.g. SplitText")
    p.add_argument("--project", default=".", help="Existing React/Next.js project directory")
    p.add_argument("--variant", choices=sorted(VARIANTS), default="TS-TW")
    p.add_argument("--dry-run", action="store_true", help="Print the exact command without installing")
    p.add_argument("--examples", action="store_true", help="Show sample upstream component names")
    args = p.parse_args(argv)
    if args.examples:
        print(json.dumps({"examples": EXAMPLES, "canonical_source": "https://reactbits.dev/"}))
        return 0
    if not args.component:
        p.error("component is required unless --examples is used")
    cmd = command(args.component, args.variant)
    project = Path(args.project).expanduser().resolve()
    if not (project / "package.json").is_file():
        p.error(f"Missing package.json: {project}")
    if not shutil.which("npx"):
        p.error("Node/npm/npx is required")
    if args.dry_run:
        print(json.dumps({"cwd": str(project), "argv": cmd}))
        return 0
    print("Installing official React Bits component; review upstream code/dependencies after installation.")
    return subprocess.run(cmd, cwd=project, check=False).returncode


if __name__ == "__main__":
    raise SystemExit(main())

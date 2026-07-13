#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(description="Fail when GitHub reports unresolved PR review threads.")
    parser.add_argument("--threads-json", type=Path, required=True)
    args = parser.parse_args()
    if not args.threads_json.is_file():
        print("ERROR_FOR_AGENT: live review-thread metadata is unavailable.", file=sys.stderr)
        return 1
    try:
        rows = json.loads(args.threads_json.read_text(encoding="utf-8"))
    except Exception as exc:
        print(f"ERROR_FOR_AGENT: invalid live review-thread metadata: {exc}", file=sys.stderr)
        return 1
    if not isinstance(rows, list):
        print("ERROR_FOR_AGENT: live review-thread metadata must be an array.", file=sys.stderr)
        return 1
    unresolved = [row for row in rows if isinstance(row, dict) and not bool(row.get("isResolved"))]
    if unresolved:
        current = sum(1 for row in unresolved if not bool(row.get("isOutdated")))
        outdated = len(unresolved) - current
        print(
            "ERROR_FOR_AGENT: GitHub has unresolved review threads: "
            f"total={len(unresolved)}, current={current}, outdated={outdated}. "
            "Resolve every thread explicitly before merge readiness.",
            file=sys.stderr,
        )
        return 1
    print(f"live review-thread check passed: total={len(rows)}, unresolved=0")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

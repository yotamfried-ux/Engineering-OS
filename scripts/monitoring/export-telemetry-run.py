#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
import uuid
from datetime import datetime, timezone
from pathlib import Path


def fail(message: str) -> None:
    print(f"error: {message}", file=sys.stderr)
    raise SystemExit(1)


def git_value(root: Path, args: list[str]) -> str:
    try:
        return subprocess.check_output(["git", "-C", str(root), *args], text=True, stderr=subprocess.DEVNULL).strip()
    except Exception:
        return "unknown"


def slugify(value: str) -> str:
    value = re.sub(r"[^a-zA-Z0-9_.-]+", "-", str(value or "").strip().lower())
    value = re.sub(r"-+", "-", value).strip("-._")
    return value[:96] or "unknown-project"


def count_events(path: Path) -> int:
    return sum(1 for line in path.read_text(encoding="utf-8", errors="replace").splitlines() if line.strip())


def digest(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def repo_root() -> Path:
    try:
        out = subprocess.check_output(["git", "rev-parse", "--show-toplevel"], text=True, stderr=subprocess.DEVNULL).strip()
        return Path(out)
    except Exception:
        return Path.cwd()


def main() -> int:
    parser = argparse.ArgumentParser(description="Export local Engineering OS telemetry into a metadata-only bundle.")
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--telemetry-dir", default=".engineering-os/telemetry")
    parser.add_argument("--project")
    parser.add_argument("--project-slug")
    parser.add_argument("--repo")
    parser.add_argument("--branch")
    parser.add_argument("--head-sha")
    parser.add_argument("--engineering-os-head-sha")
    parser.add_argument("--empty-run", action="store_true")
    args = parser.parse_args()

    root = repo_root()
    telemetry_root = Path(args.telemetry_dir)
    if not telemetry_root.is_absolute():
        telemetry_root = root / telemetry_root
    events_src = telemetry_root / "events.jsonl"
    summary_src = telemetry_root / "latest-summary.md"
    run_id_file = telemetry_root / "run_id"

    if not events_src.exists() and not args.empty_run:
        fail(f"missing telemetry events file: {events_src} (pass --empty-run to export an explicit empty run)")
    event_count = count_events(events_src) if events_src.exists() else 0
    if event_count == 0 and not args.empty_run:
        fail(f"telemetry events file has no events: {events_src} (pass --empty-run to export an explicit empty run)")
    if not summary_src.exists() and not args.empty_run:
        fail(f"missing telemetry summary file: {summary_src}")

    project = args.project or root.name
    project_slug = slugify(args.project_slug or project)
    repo = args.repo or project
    run_id = run_id_file.read_text(encoding="utf-8", errors="replace").splitlines()[0].strip() if run_id_file.exists() else ""
    run_id = re.sub(r"[^a-zA-Z0-9_.:-]", "", run_id) or uuid.uuid4().hex
    branch = args.branch or git_value(root, ["rev-parse", "--abbrev-ref", "HEAD"])
    head_sha = args.head_sha or git_value(root, ["rev-parse", "HEAD"])
    engineering_os_head_sha = args.engineering_os_head_sha or "unknown"

    args.out.mkdir(parents=True, exist_ok=True)
    events_dest = args.out / "events.jsonl"
    summary_dest = args.out / "latest-summary.md"
    events_dest.write_text(events_src.read_text(encoding="utf-8", errors="replace") if events_src.exists() else "", encoding="utf-8")
    if summary_src.exists():
        summary_dest.write_text(summary_src.read_text(encoding="utf-8", errors="replace"), encoding="utf-8")
    else:
        summary_dest.write_text("# Engineering OS Telemetry Summary\n\nExplicit empty run.\n", encoding="utf-8")

    manifest = {
        "schema_version": "eos.telemetry.run.v1",
        "run_id": run_id,
        "project": project,
        "project_slug": project_slug,
        "repo": repo,
        "branch": branch,
        "head_sha": head_sha,
        "engineering_os_head_sha": engineering_os_head_sha,
        "exported_at": datetime.now(timezone.utc).replace(microsecond=0).isoformat(),
        "source_telemetry_dir": args.telemetry_dir,
        "events_file": "events.jsonl",
        "summary_file": "latest-summary.md",
        "event_count": event_count,
        "privacy_contract": "metadata-only",
        "empty_run": bool(args.empty_run),
        "bundle_files": {"manifest": "manifest.json", "events": "events.jsonl", "summary": "latest-summary.md"},
        "checksums": {"events_sha256": digest(events_dest), "summary_sha256": digest(summary_dest)},
    }
    (args.out / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"exported telemetry bundle: {args.out}")
    print(f"events: {event_count}")
    print(f"run_id: {run_id}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

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
from typing import Any

from telemetry_handoff import validate_metadata_only


def fail(message: str) -> None:
    print(f"error: {message}", file=sys.stderr)
    raise SystemExit(1)


def git_value(root: Path, args: list[str]) -> str:
    try:
        return subprocess.check_output(
            ["git", "-C", str(root), *args], text=True, stderr=subprocess.DEVNULL
        ).strip()
    except Exception:
        return "unknown"


def slugify(value: str) -> str:
    value = re.sub(r"[^a-zA-Z0-9_.-]+", "-", str(value or "").strip().lower())
    value = re.sub(r"-+", "-", value).strip("-._")
    return value[:96] or "unknown-project"


def stable_hash(value: str, size: int = 32) -> str:
    return hashlib.sha256(str(value or "").encode("utf-8", errors="replace")).hexdigest()[:size]


def digest(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def repo_root() -> Path:
    try:
        out = subprocess.check_output(
            ["git", "rev-parse", "--show-toplevel"], text=True, stderr=subprocess.DEVNULL
        ).strip()
        return Path(out)
    except Exception:
        return Path.cwd()


def safe_source_descriptor(configured: str, resolved: Path) -> str:
    raw = str(configured or "")
    candidate = Path(raw)
    if raw and not candidate.is_absolute() and ".." not in candidate.parts:
        return raw.replace("\\", "/")
    return f"sha256:{stable_hash(str(resolved))}"


def sanitize_event(record: dict[str, Any]) -> dict[str, Any]:
    attrs = record.get("attributes")
    if isinstance(attrs, dict):
        raw_branch = str(attrs.pop("eos.git.branch", "") or "")
        if raw_branch and not attrs.get("eos.git.branch.hash"):
            attrs["eos.git.branch.hash"] = stable_hash(raw_branch)
        attrs["eos.git.branch.present"] = bool(attrs.get("eos.git.branch.hash"))
    return record


def write_sanitized_events(source: Path, destination: Path) -> int:
    count = 0
    destination.parent.mkdir(parents=True, exist_ok=True)
    with destination.open("w", encoding="utf-8") as out:
        if not source.is_file():
            return 0
        for line_number, raw in enumerate(
            source.read_text(encoding="utf-8", errors="replace").splitlines(), start=1
        ):
            if not raw.strip():
                continue
            try:
                item = json.loads(raw)
            except Exception as exc:
                fail(f"invalid telemetry JSONL at {source}:{line_number}: {exc}")
            if not isinstance(item, dict):
                fail(f"telemetry event at {source}:{line_number} must be an object")
            sanitized = sanitize_event(item)
            validate_metadata_only(sanitized)
            out.write(json.dumps(sanitized, ensure_ascii=False, sort_keys=True) + "\n")
            count += 1
    return count


def build_summary(events_dest: Path, summary_dest: Path) -> None:
    summary_tool = Path(__file__).resolve().parent / "eos-telemetry-summary.py"
    if not summary_tool.is_file():
        fail(f"missing telemetry summary tool: {summary_tool}")
    subprocess.run(
        [sys.executable, str(summary_tool), str(events_dest), "--output", str(summary_dest)],
        check=True,
    )


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Export local Engineering OS telemetry into a metadata-only bundle."
    )
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
    run_id_file = telemetry_root / "run_id"

    if not events_src.exists() and not args.empty_run:
        fail(
            f"missing telemetry events file: {events_src} "
            "(pass --empty-run to export an explicit empty run)"
        )

    project = args.project or root.name
    project_slug = slugify(args.project_slug or project)
    repo = args.repo or project
    run_id = (
        run_id_file.read_text(encoding="utf-8", errors="replace").splitlines()[0].strip()
        if run_id_file.exists()
        else ""
    )
    run_id = re.sub(r"[^a-zA-Z0-9_.:-]", "", run_id) or uuid.uuid4().hex
    raw_branch = args.branch or git_value(root, ["rev-parse", "--abbrev-ref", "HEAD"])
    branch_hash = stable_hash(raw_branch)
    head_sha = args.head_sha or git_value(root, ["rev-parse", "HEAD"])
    engineering_os_head_sha = args.engineering_os_head_sha or "unknown"

    args.out.mkdir(parents=True, exist_ok=True)
    events_dest = args.out / "events.jsonl"
    summary_dest = args.out / "latest-summary.md"
    event_count = write_sanitized_events(events_src, events_dest)
    if event_count == 0 and not args.empty_run:
        fail(
            f"telemetry events file has no events: {events_src} "
            "(pass --empty-run to export an explicit empty run)"
        )

    if event_count:
        build_summary(events_dest, summary_dest)
    else:
        summary_dest.write_text(
            "# Engineering OS Telemetry Summary\n\nExplicit empty run.\n", encoding="utf-8"
        )

    manifest = {
        "schema_version": "eos.telemetry.run.v1",
        "run_id": run_id,
        "project": project,
        "project_slug": project_slug,
        "repo": repo,
        "branch": f"sha256:{branch_hash}",
        "branch_hash": branch_hash,
        "head_sha": head_sha,
        "engineering_os_head_sha": engineering_os_head_sha,
        "exported_at": datetime.now(timezone.utc).replace(microsecond=0).isoformat(),
        "source_telemetry_dir": safe_source_descriptor(args.telemetry_dir, telemetry_root),
        "events_file": "events.jsonl",
        "summary_file": "latest-summary.md",
        "event_count": event_count,
        "privacy_contract": "metadata-only",
        "empty_run": bool(args.empty_run),
        "bundle_files": {
            "manifest": "manifest.json",
            "events": "events.jsonl",
            "summary": "latest-summary.md",
        },
        "checksums": {
            "events_sha256": digest(events_dest),
            "summary_sha256": digest(summary_dest),
        },
    }
    validate_metadata_only(manifest)
    (args.out / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    print(f"exported telemetry bundle: {args.out}")
    print(f"events: {event_count}")
    print(f"run_id: {run_id}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

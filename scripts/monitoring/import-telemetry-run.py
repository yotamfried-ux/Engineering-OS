#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

MANIFEST_SCHEMA = "eos.telemetry.run.v1"
EVENT_REQUIRED = {"schema_version", "trace_id", "span_id", "name", "timestamp", "resource", "attributes"}
MANIFEST_REQUIRED = {"schema_version", "run_id", "project", "project_slug", "repo", "branch", "head_sha", "engineering_os_head_sha", "exported_at", "source_telemetry_dir", "events_file", "summary_file", "event_count", "privacy_contract"}
BANNED_KEYS = {"prompt", "user_prompt", "model_text", "user_text", "raw_model_text", "raw_user_text", "command", "raw_command", "raw_shell_command", "file_path", "raw_file_path", "path", "transcript_path", "private_transcript_path", "content", "contents", "file_contents", "raw_connector_payload", "connector_payload", "tool_input", "tool_response", "raw_tool_response", "environment", "env", "environment_values", "credential", "credentials", "secret", "secrets", "api_key", "access_token", "refresh_token", "password"}
BANNED_PATTERNS = [re.compile("-" * 5 + r"BEGIN [A-Z ]*" + "PRIVATE KEY" + "-" * 5), re.compile(r"\b" + "gh" + r"[pousr]_[A-Za-z0-9_]{20,}\b"), re.compile(r"\b" + "sk" + r"-[A-Za-z0-9][A-Za-z0-9_-]{16,}\b"), re.compile("VALUE_SHOULD_NOT_APPEAR")]


class TelemetryImportError(ValueError):
    pass


def fail(message: str) -> None:
    raise TelemetryImportError(message)


def read_json(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        fail(f"invalid JSON in {path}: {exc}")
    if not isinstance(data, dict):
        fail(f"{path} must contain a JSON object")
    return data


def slug(value: str) -> str:
    value = re.sub(r"[^a-zA-Z0-9_.:-]+", "-", str(value or "").strip())
    return re.sub(r"-+", "-", value).strip("-._:")[:96] or "unknown"


def iter_paths(value: Any, prefix: str = ""):
    if isinstance(value, dict):
        for key, child in value.items():
            path = f"{prefix}.{key}" if prefix else str(key)
            yield path, child
            yield from iter_paths(child, path)
    elif isinstance(value, list):
        for index, child in enumerate(value):
            yield from iter_paths(child, f"{prefix}[{index}]")


def validate_metadata_only(value: Any) -> None:
    for path, child in iter_paths(value):
        key = re.sub(r"\[\d+\]", "", path.split(".")[-1]).lower().replace("-", "_")
        if key in BANNED_KEYS or (key.startswith("raw_") and not key.endswith("_stored")):
            fail(f"banned raw field present: {path}")
        if isinstance(child, str) and any(pattern.search(child) for pattern in BANNED_PATTERNS):
            fail(f"banned sensitive value pattern present at: {path}")


def validate_manifest(manifest: dict[str, Any]) -> None:
    missing = sorted(MANIFEST_REQUIRED - manifest.keys())
    if missing:
        fail(f"manifest missing required fields: {', '.join(missing)}")
    if manifest.get("schema_version") != MANIFEST_SCHEMA:
        fail(f"manifest schema_version must be {MANIFEST_SCHEMA}")
    if manifest.get("privacy_contract") != "metadata-only":
        fail("manifest privacy_contract must be metadata-only")
    if manifest.get("events_file") != "events.jsonl" or manifest.get("summary_file") != "latest-summary.md":
        fail("manifest must reference events.jsonl and latest-summary.md")
    if not isinstance(manifest.get("event_count"), int) or manifest["event_count"] < 0:
        fail("manifest event_count must be a non-negative integer")
    for field in ("run_id", "project", "project_slug"):
        if not str(manifest.get(field) or "").strip():
            fail(f"manifest {field} must be non-empty")
    validate_metadata_only(manifest)


def load_events(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        fail(f"missing events.jsonl: {path}")
    events: list[dict[str, Any]] = []
    for line_number, line in enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), start=1):
        if not line.strip():
            continue
        try:
            event = json.loads(line)
        except Exception as exc:
            fail(f"invalid JSONL at {path}:{line_number}: {exc}")
        if not isinstance(event, dict):
            fail(f"event at {path}:{line_number} must be an object")
        missing = sorted(EVENT_REQUIRED - event.keys())
        if missing:
            fail(f"event at {path}:{line_number} missing required fields: {', '.join(missing)}")
        if not isinstance(event.get("resource"), dict) or not isinstance(event.get("attributes"), dict):
            fail(f"event at {path}:{line_number} resource and attributes must be objects")
        validate_metadata_only(event)
        events.append(event)
    return events


def read_jsonl(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        return []
    rows = []
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        if line.strip():
            rows.append(json.loads(line))
    return [row for row in rows if isinstance(row, dict)]


def write_jsonl(path: Path, rows: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("".join(json.dumps(row, ensure_ascii=False, sort_keys=True) + "\n" for row in rows), encoding="utf-8")


def export_date(value: str) -> str:
    try:
        parsed = datetime.fromisoformat(str(value).replace("Z", "+00:00"))
        if parsed.tzinfo is None:
            parsed = parsed.replace(tzinfo=timezone.utc)
        return parsed.astimezone(timezone.utc).date().isoformat()
    except Exception:
        return datetime.now(timezone.utc).date().isoformat()


def coverage(events: list[dict[str, Any]]) -> dict[str, int]:
    def attrs(e: dict[str, Any]) -> dict[str, Any]:
        return e.get("attributes") if isinstance(e.get("attributes"), dict) else {}
    return {
        "missing_session": sum(1 for e in events if not attrs(e).get("eos.claude.session.present")),
        "missing_turn": sum(1 for e in events if not (attrs(e).get("eos.claude.turn.present") or attrs(e).get("eos.claude.prompt.present"))),
        "missing_transcript": sum(1 for e in events if not attrs(e).get("eos.claude.transcript.present")),
        "missing_cwd": sum(1 for e in events if not attrs(e).get("eos.claude.cwd.present")),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Import an Engineering OS telemetry bundle into the central archive.")
    parser.add_argument("bundle", type=Path)
    parser.add_argument("--archive", type=Path, default=Path("telemetry-archive"))
    parser.add_argument("--replace", action="store_true")
    args = parser.parse_args()

    bundle = args.bundle
    manifest_path = bundle / "manifest.json"
    events_path = bundle / "events.jsonl"
    summary_path = bundle / "latest-summary.md"
    if not bundle.is_dir() or not manifest_path.exists() or not summary_path.exists():
        fail("bundle must contain manifest.json, events.jsonl, and latest-summary.md")
    manifest = read_json(manifest_path)
    validate_manifest(manifest)
    events = load_events(events_path)
    if len(events) != manifest["event_count"]:
        fail(f"manifest event_count={manifest['event_count']} does not match events.jsonl count={len(events)}")
    if not events and not manifest.get("empty_run"):
        fail("zero-event import requires manifest empty_run=true")

    run_date = export_date(str(manifest.get("exported_at") or ""))
    project_slug = slug(str(manifest.get("project_slug") or manifest.get("project")))
    run_id = slug(str(manifest.get("run_id")))
    archive_key = f"{run_date}/{project_slug}/{run_id}"
    dest = args.archive / "runs" / run_date / project_slug / run_id
    index_path = args.archive / "indexes" / "runs.jsonl"
    projects_path = args.archive / "indexes" / "projects.json"
    gaps_path = args.archive / "indexes" / "gaps.jsonl"
    rows = read_jsonl(index_path)
    duplicate = dest.exists() or any(str(row.get("archive_key")) == archive_key for row in rows)
    if duplicate and not args.replace:
        fail(f"duplicate telemetry import for {archive_key}; pass --replace to overwrite")
    if args.replace:
        if dest.exists():
            shutil.rmtree(dest)
        rows = [row for row in rows if str(row.get("archive_key")) != archive_key]

    dest.mkdir(parents=True, exist_ok=False)
    shutil.copy2(manifest_path, dest / "manifest.json")
    shutil.copy2(events_path, dest / "events.jsonl")
    shutil.copy2(summary_path, dest / "latest-summary.md")
    findings = dest / "findings.md"
    findings.write_text("# Telemetry Findings\n\nStatus: pending-review\n", encoding="utf-8")
    rows.append({"schema_version": "eos.telemetry.archive.index.v1", "archive_key": archive_key, "archive_path": str(dest), "project": manifest.get("project"), "project_slug": project_slug, "run_id": run_id, "run_date": run_date, "repo": manifest.get("repo"), "branch": manifest.get("branch"), "head_sha": manifest.get("head_sha"), "engineering_os_head_sha": manifest.get("engineering_os_head_sha"), "exported_at": manifest.get("exported_at"), "imported_at": datetime.now(timezone.utc).replace(microsecond=0).isoformat(), "event_count": len(events), "summary_path": str(dest / "latest-summary.md"), "findings_path": str(findings), "privacy_contract": "metadata-only", "coverage": coverage(events)})
    write_jsonl(index_path, rows)
    projects = read_json(projects_path) if projects_path.exists() else {}
    entry = projects.setdefault(project_slug, {"project_slug": project_slug, "project": manifest.get("project"), "runs": 0})
    entry.update({"project": manifest.get("project"), "latest_run_id": run_id, "latest_run_date": run_date, "runs": sum(1 for row in rows if row.get("project_slug") == project_slug)})
    projects_path.parent.mkdir(parents=True, exist_ok=True)
    projects_path.write_text(json.dumps(projects, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    gaps_path.parent.mkdir(parents=True, exist_ok=True)
    gaps_path.touch(exist_ok=True)
    print(f"imported telemetry run: {archive_key}")
    print(f"events: {len(events)}")
    print(f"archive_path: {dest}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except TelemetryImportError as exc:
        print(f"error: {exc}", file=sys.stderr)
        raise SystemExit(1)

#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import shutil
import sys
from pathlib import Path
from typing import Any

from telemetry_handoff import (
    HANDOFF_SCHEMA,
    HandoffError,
    file_digest,
    load_policy,
    stable_hash,
    validate_metadata_only,
)


def fail(message: str) -> None:
    raise HandoffError(message)


def load_json(path: Path) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        fail(f"invalid JSON in {path}: {exc}")
    if not isinstance(value, dict):
        fail(f"{path} must contain a JSON object")
    return value


def validate_bundle(bundle: Path) -> dict[str, Any]:
    manifest_path = bundle / "manifest.json"
    events_path = bundle / "events.jsonl"
    summary_path = bundle / "latest-summary.md"
    if not (manifest_path.is_file() and events_path.is_file() and summary_path.is_file()):
        fail(f"incomplete telemetry bundle: {bundle}")
    manifest = load_json(manifest_path)
    if manifest.get("schema_version") != "eos.telemetry.run.v1":
        fail(f"unsupported telemetry manifest schema in {bundle}")
    if manifest.get("privacy_contract") != "metadata-only":
        fail(f"telemetry bundle privacy contract is not metadata-only: {bundle}")
    handoff = manifest.get("handoff")
    if not isinstance(handoff, dict) or handoff.get("schema_version") != HANDOFF_SCHEMA:
        fail(f"telemetry bundle has no valid handoff metadata: {bundle}")
    pr_number = int(handoff.get("pr_number") or 0)
    binding = str(handoff.get("pr_binding") or ("exact" if pr_number > 0 else "provisional"))
    if binding not in {"exact", "provisional"}:
        fail(f"telemetry handoff PR binding is invalid: {bundle}")
    if (binding == "exact") != (pr_number > 0):
        fail(f"telemetry handoff PR binding contradicts pr_number: {bundle}")
    handoff["pr_binding"] = binding
    manifest["handoff"] = handoff

    checksums = manifest.get("checksums") if isinstance(manifest.get("checksums"), dict) else {}
    if checksums.get("events_sha256") != file_digest(events_path):
        fail(f"telemetry events checksum mismatch: {bundle}")
    if checksums.get("summary_sha256") != file_digest(summary_path):
        fail(f"telemetry summary checksum mismatch: {bundle}")
    rows: list[dict[str, Any]] = []
    for line_number, raw in enumerate(events_path.read_text(encoding="utf-8", errors="replace").splitlines(), start=1):
        if not raw.strip():
            continue
        try:
            row = json.loads(raw)
        except Exception as exc:
            fail(f"invalid JSONL at {events_path}:{line_number}: {exc}")
        if not isinstance(row, dict):
            fail(f"telemetry event must be an object at {events_path}:{line_number}")
        rows.append(row)
    if len(rows) != int(manifest.get("event_count") or -1):
        fail(f"telemetry event_count mismatch: {bundle}")
    if not rows:
        fail(f"zero-event telemetry bundle is not valid for a required experiment: {bundle}")
    run_id = str(manifest.get("run_id") or "")
    if not run_id or any(str(row.get("trace_id") or "") != run_id for row in rows):
        fail(f"telemetry bundle run correlation is invalid: {bundle}")
    if int(handoff.get("event_count") or -1) != len(rows):
        fail(f"telemetry handoff event count mismatch: {bundle}")
    if int(handoff.get("boundary_position") or 0) <= 0 or int(handoff.get("boundary_position") or 0) > len(rows):
        fail(f"telemetry handoff boundary position is invalid: {bundle}")
    validate_metadata_only(manifest)
    validate_metadata_only(rows)
    return manifest


def synced_sort_key(manifest: dict[str, Any]) -> tuple[int, str, int]:
    handoff = manifest.get("handoff") if isinstance(manifest.get("handoff"), dict) else {}
    exact_rank = 1 if int(handoff.get("pr_number") or 0) > 0 else 0
    return (exact_rank, str(handoff.get("synced_at") or ""), int(manifest.get("event_count") or 0))


def safe_observed_descriptor(manifest: dict[str, Any]) -> str:
    handoff = manifest.get("handoff") if isinstance(manifest.get("handoff"), dict) else {}
    return ",".join([
        f"repo={str(handoff.get('repo') or manifest.get('repo') or '')}",
        f"pr={int(handoff.get('pr_number') or 0)}",
        f"binding={str(handoff.get('pr_binding') or '')}",
        f"branch_hash={str(handoff.get('source_branch_hash') or '')}",
        f"head={str(handoff.get('head_sha') or manifest.get('head_sha') or '')}",
        f"events={int(manifest.get('event_count') or 0)}",
    ])


def main() -> int:
    parser = argparse.ArgumentParser(description="Select an exact PR/head-matched remote telemetry bundle.")
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument("--handoff-root", type=Path, required=True)
    parser.add_argument("--policy-file", type=Path)
    parser.add_argument("--repo", required=True)
    parser.add_argument("--pr-number", required=True, type=int)
    parser.add_argument("--head-ref", required=True)
    parser.add_argument("--head-sha", required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()

    policy = load_policy(args.root.resolve(), args.policy_file)
    if policy["mode"] == "disabled":
        print("telemetry handoff disabled by target policy")
        return 0

    runs_root = args.handoff_root / "runs"
    candidates: list[tuple[dict[str, Any], Path]] = []
    observed: list[str] = []
    invalid: list[str] = []
    if runs_root.is_dir():
        for manifest_path in sorted(runs_root.glob("*/manifest.json")):
            bundle = manifest_path.parent
            try:
                manifest = validate_bundle(bundle)
            except Exception as exc:
                invalid.append(str(exc))
                continue
            observed.append(safe_observed_descriptor(manifest))
            handoff = manifest["handoff"]
            if str(handoff.get("repo") or manifest.get("repo") or "") != args.repo:
                continue
            bundle_pr = int(handoff.get("pr_number") or 0)
            if bundle_pr not in (0, args.pr_number):
                continue
            if str(handoff.get("source_branch_hash") or "") != stable_hash(args.head_ref):
                continue
            if str(handoff.get("head_sha") or manifest.get("head_sha") or "") != args.head_sha:
                continue
            candidates.append((manifest, bundle))

    if not candidates:
        expected = (
            f"repo={args.repo},pr={args.pr_number},branch_hash={stable_hash(args.head_ref)},"
            f"head={args.head_sha}"
        )
        details = [f"expected[{expected}]", f"valid_bundles={len(observed)}", f"invalid_bundles={len(invalid)}"]
        if observed:
            details.append("observed[" + ";".join(observed[:5]) + "]")
        message = "no non-empty telemetry bundle matches exact branch/head metadata and compatible PR binding; " + "; ".join(details)
        if policy["mode"] == "required":
            fail(message)
        print(f"WARNING_FOR_AGENT: {message}", file=sys.stderr)
        return 0

    manifest, selected = max(candidates, key=lambda item: synced_sort_key(item[0]))
    if args.out.exists():
        shutil.rmtree(args.out)
    shutil.copytree(selected, args.out)
    binding = manifest["handoff"].get("pr_binding")
    print(f"selected telemetry bundle: {selected}")
    print(f"events: {manifest['event_count']}")
    print(f"pr_binding: {binding}")
    print(f"run_id_hash: {manifest['handoff']['run_id_hash']}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except HandoffError as exc:
        print(f"ERROR_FOR_AGENT: {exc}", file=sys.stderr)
        raise SystemExit(1)

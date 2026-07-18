#!/usr/bin/env python3
from __future__ import annotations

import argparse
import shutil
import sys
from pathlib import Path
from typing import Any

from telemetry_handoff import (
    HandoffError,
    load_policy,
    stable_hash,
    validate_bundle,
    validate_repo_slug,
)


def fail(message: str) -> None:
    raise HandoffError(message)


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

    expected_repo = validate_repo_slug(args.repo)
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
            if str(handoff.get("repo") or manifest.get("repo") or "") != expected_repo:
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
            f"repo={expected_repo},pr={args.pr_number},branch_hash={stable_hash(args.head_ref)},"
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

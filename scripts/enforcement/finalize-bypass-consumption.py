#!/usr/bin/env python3
"""Trusted finalizer: after a successful consumer run, write one durable marker."""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import importlib.util
import json
from pathlib import Path
import sys

BASE = Path(__file__).resolve().parent
LIB = BASE / "lib"
sys.path.insert(0, str(LIB))
from bypass_contract import (  # noqa: E402
    CLAIM_SCHEMA,
    ContractError,
    digest_json,
    load_json,
    load_policy,
    marker_from_claim,
    parse_timestamp,
    validate_control_config,
    validate_marker_shape,
)
from github_provider import ProviderError  # noqa: E402

spec = importlib.util.spec_from_file_location("eos_bypass_validator", BASE / "validate-bypass-approval.py")
if spec is None or spec.loader is None:
    raise RuntimeError("cannot load pinned bypass validator")
validator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validator)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    parser.add_argument("--consumer-run-id", required=True, type=int)
    parser.add_argument("--finalizer-default-branch-sha", required=True)
    parser.add_argument("--finalizer-run-id", required=True, type=int)
    parser.add_argument("--finalizer-run-attempt", required=True, type=int)
    parser.add_argument("--finalizer-actor", required=True)
    parser.add_argument("--finalizer-triggering-actor", required=True)
    parser.add_argument("--finalizer-event", required=True)
    parser.add_argument("--provider-fixture", help=argparse.SUPPRESS)
    parser.add_argument("--now", help=argparse.SUPPRESS)
    parser.add_argument("--timeout", type=float, default=10.0)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        validator.require_test_overrides(args)
        config = load_json(BASE / "bypass-control-plane.json")
        validate_control_config(config)
        policy = load_policy(BASE / "bypass-policy.tsv")
        provider = validator.make_provider(args, config)
        now = parse_timestamp(args.now, "now") if args.now else datetime.now(timezone.utc)

        candidates = []
        comments = provider.issue_comments(config["control_repository"]["full_name"], config["issues"]["approval"])
        for claim, comment in validator.iter_schema_comments(comments, CLAIM_SCHEMA, "claim"):
            if claim.get("run_id") == args.consumer_run_id:
                candidates.append((claim, comment))
        if len(candidates) != 1:
            raise ContractError(f"expected exactly one claim for consumer run, found {len(candidates)}")
        claim, claim_comment = candidates[0]

        approval_id = claim.get("approval_comment_id")
        if not isinstance(approval_id, int):
            raise ContractError("claim approval comment ID is invalid")
        expected = {key: claim[key] for key in ("bypass", "gate", "action", "surface", "target", "target_fingerprint", "target_commit")}
        approval = validator.verify_approval(
            provider, config, policy,
            approval_comment_id=approval_id,
            expected=expected,
            now=now,
        )
        validator.verify_claim(provider, config, policy, approval, claim, claim_comment)
        existing = validator.matching_markers(provider, config, policy, approval, claim, claim_comment)
        if existing:
            raise ContractError("approval replay denied: durable marker already exists")
        marker = marker_from_claim(
            approval,
            claim,
            claim_comment_id=claim_comment["id"],
            claim_created_at=claim_comment["created_at"],
            finalizer_default_branch_sha=args.finalizer_default_branch_sha,
            finalizer_run_id=args.finalizer_run_id,
            finalizer_run_attempt=args.finalizer_run_attempt,
            finalizer_actor=args.finalizer_actor,
            finalizer_triggering_actor=args.finalizer_triggering_actor,
            finalizer_event=args.finalizer_event,
        )
        validate_marker_shape(marker, policy)
        body = json.dumps(marker, sort_keys=True, separators=(",", ":"))
        created = provider.create_issue_comment(
            config["control_repository"]["full_name"],
            config["issues"]["consumption"],
            body,
        )
        if not isinstance(created, dict) or not isinstance(created.get("id"), int):
            raise ContractError("provider did not return one created marker comment")
        print(json.dumps({
            "consumed": True,
            "approval_digest": digest_json(approval),
            "claim_digest": digest_json(claim),
            "marker_digest": digest_json(marker),
            "marker_comment_id": created["id"],
        }, sort_keys=True, separators=(",", ":")))
        return 0
    except (ContractError, ProviderError, OSError, KeyError, TypeError, ValueError) as exc:
        print(json.dumps({"consumed": False, "error": str(exc)}, sort_keys=True), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())

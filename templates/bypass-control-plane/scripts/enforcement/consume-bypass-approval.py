#!/usr/bin/env python3
"""Trusted consumer: validate approval and write one durable claim."""
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
    ContractError,
    claim_from_approval,
    digest_json,
    load_json,
    load_policy,
    parse_timestamp,
    validate_claim_shape,
    validate_control_config,
)
from github_provider import ProviderError  # noqa: E402

spec = importlib.util.spec_from_file_location("eos_bypass_validator", BASE / "validate-bypass-approval.py")
if spec is None or spec.loader is None:
    raise RuntimeError("cannot load pinned bypass validator")
validator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validator)


def build_parser() -> argparse.ArgumentParser:
    parser = validator.build_parser()
    parser.set_defaults(stage="approval")
    parser.add_argument("--consumer-default-branch-sha", required=True)
    parser.add_argument("--run-id", required=True, type=int)
    parser.add_argument("--run-attempt", required=True, type=int)
    parser.add_argument("--actor", required=True)
    parser.add_argument("--triggering-actor", required=True)
    parser.add_argument("--event", required=True)
    return parser


def main() -> int:
    args = build_parser().parse_args()
    try:
        config, policy, provider, now, expected = validator.load_runtime(args)
        approval = validator.verify_approval(
            provider, config, policy,
            approval_comment_id=args.approval_comment_id,
            expected=expected,
            now=now,
        )
        existing_claims = validator.matching_claims(provider, config, policy, approval)
        if existing_claims:
            raise ContractError("approval replay denied: durable claim already exists")
        # A matching marker without a matching claim is conflicting/tampered state.
        for marker, _comment in validator.iter_schema_comments(
            provider.issue_comments(config["control_repository"]["full_name"], config["issues"]["consumption"]),
            __import__("bypass_contract").MARKER_SCHEMA,
            "marker",
        ):
            if marker.get("approval_digest") == digest_json(approval):
                raise ContractError("approval replay denied: durable marker already exists")
        claim = claim_from_approval(
            approval,
            consumption_issue_id=config["issues"]["consumption"],
            consumer_default_branch_sha=args.consumer_default_branch_sha,
            run_id=args.run_id,
            run_attempt=args.run_attempt,
            actor=args.actor,
            triggering_actor=args.triggering_actor,
            event=args.event,
        )
        validate_claim_shape(claim, policy)
        if claim["consumer_default_branch_sha"] != approval["control_default_branch_sha"]:
            raise ContractError("consumer run does not match approved default-branch SHA")
        body = json.dumps(claim, sort_keys=True, separators=(",", ":"))
        created = provider.create_issue_comment(
            config["control_repository"]["full_name"],
            config["issues"]["consumption"],
            body,
        )
        if not isinstance(created, dict) or not isinstance(created.get("id"), int):
            raise ContractError("provider did not return one created claim comment")
        print(json.dumps({
            "claimed": True,
            "approval_digest": digest_json(approval),
            "claim_digest": digest_json(claim),
            "claim_comment_id": created["id"],
        }, sort_keys=True, separators=(",", ":")))
        return 0
    except (ContractError, ProviderError, OSError, KeyError, TypeError, ValueError) as exc:
        print(json.dumps({"claimed": False, "error": str(exc)}, sort_keys=True), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())

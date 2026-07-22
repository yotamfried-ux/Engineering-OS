#!/usr/bin/env python3
"""Validate canonical known-gap live-state claims against a normalized GitHub snapshot."""

from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable

CLAIMS_SCHEMA = "eos.known-gaps-live-claims.v1"
SNAPSHOT_SCHEMA = "eos.known-gaps-live-snapshot.v1"
GAP_STATUSES = {"open", "mitigated", "closed", "accepted-manual", "blocked"}
SHA_RE = re.compile(r"^[0-9a-f]{40}$")
ID_RE = re.compile(r"^[a-z0-9][a-z0-9._-]*$")
REPO_RE = re.compile(r"^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")


class ValidationError(Exception):
    """Raised for malformed input before semantic reconciliation."""


def _load_json(path: Path) -> Any:
    try:
        with path.open(encoding="utf-8") as handle:
            return json.load(handle)
    except FileNotFoundError as exc:
        raise ValidationError(f"missing JSON file: {path}") from exc
    except json.JSONDecodeError as exc:
        raise ValidationError(f"invalid JSON in {path}: {exc.msg} at line {exc.lineno}") from exc


def _expect_dict(value: Any, label: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise ValidationError(f"{label} must be an object")
    return value


def _expect_list(value: Any, label: str) -> list[Any]:
    if not isinstance(value, list):
        raise ValidationError(f"{label} must be an array")
    return value


def _expect_text(value: Any, label: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise ValidationError(f"{label} must be a non-empty string")
    return value.strip()


def _expect_sha(value: Any, label: str) -> str:
    text = _expect_text(value, label)
    if not SHA_RE.fullmatch(text):
        raise ValidationError(f"{label} must be a lowercase 40-character SHA")
    return text


def _expect_positive_int(value: Any, label: str) -> int:
    if isinstance(value, bool) or not isinstance(value, int) or value <= 0:
        raise ValidationError(f"{label} must be a positive integer")
    return value


def _text_list(value: Any, label: str, *, allow_empty: bool = False) -> list[str]:
    raw = _expect_list(value, label)
    result: list[str] = []
    for index, item in enumerate(raw):
        text = _expect_text(item, f"{label}[{index}]")
        if text in result:
            raise ValidationError(f"{label} contains duplicate value: {text}")
        result.append(text)
    if not allow_empty and not result:
        raise ValidationError(f"{label} must contain at least one value")
    return result


def load_gap_statuses(path: Path) -> dict[str, str]:
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except FileNotFoundError as exc:
        raise ValidationError(f"missing known-gaps file: {path}") from exc
    result: dict[str, str] = {}
    for line_number, raw in enumerate(lines, 1):
        if not raw or raw.startswith("#"):
            continue
        parts = raw.split("\t")
        if len(parts) != 10:
            raise ValidationError(
                f"{path}:{line_number}: expected 10 tab-separated columns, found {len(parts)}"
            )
        gap_id, _, status, *_ = parts
        if gap_id in result:
            raise ValidationError(f"{path}:{line_number}: duplicate gap_id {gap_id}")
        if status not in GAP_STATUSES:
            raise ValidationError(f"{path}:{line_number}: invalid status {status}")
        result[gap_id] = status
    return result


def load_claims(path: Path, gap_statuses: dict[str, str]) -> list[dict[str, Any]]:
    root = _expect_dict(_load_json(path), str(path))
    if root.get("schema_version") != CLAIMS_SCHEMA:
        raise ValidationError(f"{path}: schema_version must be {CLAIMS_SCHEMA!r}")
    raw_claims = _expect_list(root.get("claims"), f"{path}: claims")
    if not raw_claims:
        raise ValidationError(f"{path}: claims must not be empty")

    claims: list[dict[str, Any]] = []
    seen_ids: set[str] = set()
    seen_targets: set[tuple[str, int]] = set()
    for index, raw in enumerate(raw_claims):
        label = f"{path}: claims[{index}]"
        claim = _expect_dict(raw, label)
        claim_id = _expect_text(claim.get("claim_id"), f"{label}.claim_id")
        if not ID_RE.fullmatch(claim_id):
            raise ValidationError(f"{label}.claim_id has invalid format: {claim_id}")
        if claim_id in seen_ids:
            raise ValidationError(f"{path}: duplicate claim_id {claim_id}")
        seen_ids.add(claim_id)

        gap_id = _expect_text(claim.get("gap_id"), f"{label}.gap_id")
        if gap_id not in gap_statuses:
            raise ValidationError(f"{label}.gap_id references unknown gap {gap_id}")
        if gap_statuses[gap_id] != "closed":
            raise ValidationError(
                f"{label}.gap_id {gap_id} must be closed before it can own a live closure claim "
                f"(current status: {gap_statuses[gap_id]})"
            )

        repository = _expect_text(claim.get("repository"), f"{label}.repository")
        if not REPO_RE.fullmatch(repository):
            raise ValidationError(f"{label}.repository must use owner/repo form")
        pull_number = _expect_positive_int(claim.get("pull_number"), f"{label}.pull_number")
        target = (repository.lower(), pull_number)
        if target in seen_targets:
            raise ValidationError(f"{path}: duplicate live target {repository}#{pull_number}")
        seen_targets.add(target)

        base_branch = _expect_text(claim.get("base_branch"), f"{label}.base_branch")
        if any(ch.isspace() for ch in base_branch):
            raise ValidationError(f"{label}.base_branch must not contain whitespace")

        required_pr = _text_list(
            claim.get("required_pull_request_workflows"),
            f"{label}.required_pull_request_workflows",
        )
        if all(name.lower() == "pr-policy" for name in required_pr):
            raise ValidationError(
                f"{label}.required_pull_request_workflows must include a non-self workflow"
            )
        required_push = _text_list(
            claim.get("required_push_workflows"),
            f"{label}.required_push_workflows",
        )
        required_checks = _text_list(
            claim.get("required_check_runs", []),
            f"{label}.required_check_runs",
            allow_empty=True,
        )
        claims.append(
            {
                "claim_id": claim_id,
                "gap_id": gap_id,
                "repository": repository,
                "pull_number": pull_number,
                "base_branch": base_branch,
                "expected_head_sha": _expect_sha(
                    claim.get("expected_head_sha"), f"{label}.expected_head_sha"
                ),
                "expected_merge_commit_sha": _expect_sha(
                    claim.get("expected_merge_commit_sha"),
                    f"{label}.expected_merge_commit_sha",
                ),
                "required_pull_request_workflows": required_pr,
                "required_push_workflows": required_push,
                "required_check_runs": required_checks,
            }
        )
    return claims


def load_snapshot(path: Path) -> dict[str, dict[str, Any]]:
    root = _expect_dict(_load_json(path), str(path))
    if root.get("schema_version") != SNAPSHOT_SCHEMA:
        raise ValidationError(f"{path}: schema_version must be {SNAPSHOT_SCHEMA!r}")
    generated_at = _expect_text(root.get("generated_at"), f"{path}.generated_at")
    if "T" not in generated_at:
        raise ValidationError(f"{path}.generated_at must be an ISO-8601 timestamp")
    raw_entries = _expect_list(root.get("claims"), f"{path}.claims")
    entries: dict[str, dict[str, Any]] = {}
    for index, raw in enumerate(raw_entries):
        label = f"{path}: claims[{index}]"
        entry = _expect_dict(raw, label)
        claim_id = _expect_text(entry.get("claim_id"), f"{label}.claim_id")
        if claim_id in entries:
            raise ValidationError(f"{path}: duplicate snapshot claim_id {claim_id}")
        entries[claim_id] = entry
    return entries


def _workflow_timestamp(run: dict[str, Any], label: str) -> tuple[datetime, str | None]:
    raw = run.get("run_started_at") or run.get("updated_at") or run.get("created_at")
    if not isinstance(raw, str) or not raw.strip():
        return (
            datetime.min.replace(tzinfo=timezone.utc),
            f"{label} lacks a chronological workflow timestamp",
        )
    try:
        value = datetime.fromisoformat(raw.replace("Z", "+00:00"))
    except ValueError:
        return (
            datetime.min.replace(tzinfo=timezone.utc),
            f"{label} has invalid workflow timestamp {raw!r}",
        )
    if value.tzinfo is None:
        value = value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc), None


def _run_key(run: dict[str, Any], label: str) -> tuple[datetime, int, int]:
    timestamp, _ = _workflow_timestamp(run, label)

    def number(name: str) -> int:
        value = run.get(name, 0)
        return value if isinstance(value, int) and not isinstance(value, bool) else 0

    return timestamp, number("run_attempt"), number("id")


def _latest_workflow(
    runs: Iterable[Any], *, name: str, event: str, head_sha: str, label: str
) -> tuple[dict[str, Any] | None, list[str]]:
    failures: list[str] = []
    candidates: list[dict[str, Any]] = []
    for index, raw in enumerate(runs):
        if not isinstance(raw, dict):
            failures.append(f"{label}[{index}] must be an object")
            continue
        if raw.get("name") == name and raw.get("event") == event and raw.get("head_sha") == head_sha:
            _, timestamp_failure = _workflow_timestamp(raw, f"{label}[{index}]")
            if timestamp_failure:
                failures.append(timestamp_failure)
            candidates.append(raw)
    if not candidates:
        return None, failures
    return max(candidates, key=lambda run: _run_key(run, label)), failures


def _check_key(run: dict[str, Any]) -> tuple[str, int]:
    timestamp = run.get("completed_at") or run.get("started_at") or ""
    ident = run.get("id", 0)
    return str(timestamp), ident if isinstance(ident, int) and not isinstance(ident, bool) else 0


def _latest_check(
    checks: Iterable[Any], *, name: str, head_sha: str, label: str
) -> tuple[dict[str, Any] | None, list[str]]:
    failures: list[str] = []
    candidates: list[dict[str, Any]] = []
    for index, raw in enumerate(checks):
        if not isinstance(raw, dict):
            failures.append(f"{label}[{index}] must be an object")
            continue
        if raw.get("name") == name and raw.get("head_sha") == head_sha:
            candidates.append(raw)
    if not candidates:
        return None, failures
    return max(candidates, key=_check_key), failures


def validate_claim(claim: dict[str, Any], entry: dict[str, Any]) -> list[str]:
    claim_id = claim["claim_id"]
    failures: list[str] = []

    for field in ("repository", "pull_number"):
        if entry.get(field) != claim[field]:
            failures.append(
                f"{claim_id}: snapshot {field}={entry.get(field)!r} does not match claim {claim[field]!r}"
            )

    pull = entry.get("pull")
    if not isinstance(pull, dict):
        return failures + [f"{claim_id}: snapshot pull must be an object"]

    expected_pull = {
        "state": "closed",
        "merged": True,
        "head_sha": claim["expected_head_sha"],
        "merge_commit_sha": claim["expected_merge_commit_sha"],
        "base_ref": claim["base_branch"],
    }
    for field, expected in expected_pull.items():
        if pull.get(field) != expected:
            failures.append(f"{claim_id}: pull.{field}={pull.get(field)!r}; expected {expected!r}")
    if not pull.get("merged_at"):
        failures.append(f"{claim_id}: pull.merged_at is missing")

    containment = entry.get("base_containment")
    if not isinstance(containment, dict):
        failures.append(f"{claim_id}: base_containment must be an object")
    else:
        status = containment.get("status")
        if status not in {"ahead", "identical"}:
            failures.append(
                f"{claim_id}: base branch does not contain the merge commit "
                f"(compare status {status!r})"
            )
        if containment.get("behind_by") != 0:
            failures.append(
                f"{claim_id}: base containment behind_by must be 0, found "
                f"{containment.get('behind_by')!r}"
            )
        if containment.get("merge_base_sha") != claim["expected_merge_commit_sha"]:
            failures.append(
                f"{claim_id}: compare merge_base_sha={containment.get('merge_base_sha')!r}; "
                f"expected {claim['expected_merge_commit_sha']!r}"
            )
        if containment.get("base_branch") != claim["base_branch"]:
            failures.append(
                f"{claim_id}: containment base_branch={containment.get('base_branch')!r}; "
                f"expected {claim['base_branch']!r}"
            )

    pr_runs = entry.get("pull_request_workflow_runs")
    if not isinstance(pr_runs, list):
        failures.append(f"{claim_id}: pull_request_workflow_runs must be an array")
        pr_runs = []
    push_runs = entry.get("push_workflow_runs")
    if not isinstance(push_runs, list):
        failures.append(f"{claim_id}: push_workflow_runs must be an array")
        push_runs = []
    checks = entry.get("check_runs")
    if not isinstance(checks, list):
        failures.append(f"{claim_id}: check_runs must be an array")
        checks = []

    successful_non_self = False
    for name in claim["required_pull_request_workflows"]:
        run, shape_failures = _latest_workflow(
            pr_runs,
            name=name,
            event="pull_request",
            head_sha=claim["expected_head_sha"],
            label=f"{claim_id}.pull_request_workflow_runs",
        )
        failures.extend(shape_failures)
        if run is None:
            failures.append(
                f"{claim_id}: missing required pull_request workflow {name!r} "
                f"on {claim['expected_head_sha']}"
            )
            continue
        if run.get("status") != "completed" or run.get("conclusion") != "success":
            failures.append(
                f"{claim_id}: latest pull_request workflow {name!r} is "
                f"{run.get('status')}/{run.get('conclusion')}, not completed/success"
            )
            continue
        if name.lower() != "pr-policy":
            successful_non_self = True
    if not successful_non_self:
        failures.append(f"{claim_id}: no successful required non-self pull_request workflow was proven")

    for name in claim["required_push_workflows"]:
        run, shape_failures = _latest_workflow(
            push_runs,
            name=name,
            event="push",
            head_sha=claim["expected_merge_commit_sha"],
            label=f"{claim_id}.push_workflow_runs",
        )
        failures.extend(shape_failures)
        if run is None:
            failures.append(
                f"{claim_id}: missing required push workflow {name!r} "
                f"on {claim['expected_merge_commit_sha']}"
            )
            continue
        if run.get("status") != "completed" or run.get("conclusion") != "success":
            failures.append(
                f"{claim_id}: latest push workflow {name!r} is "
                f"{run.get('status')}/{run.get('conclusion')}, not completed/success"
            )

    for name in claim["required_check_runs"]:
        check, shape_failures = _latest_check(
            checks,
            name=name,
            head_sha=claim["expected_head_sha"],
            label=f"{claim_id}.check_runs",
        )
        failures.extend(shape_failures)
        if check is None:
            failures.append(
                f"{claim_id}: missing required check run {name!r} "
                f"on {claim['expected_head_sha']}"
            )
            continue
        if check.get("status") != "completed" or check.get("conclusion") != "success":
            failures.append(
                f"{claim_id}: latest check run {name!r} is "
                f"{check.get('status')}/{check.get('conclusion')}, not completed/success"
            )

    return failures


def validate(
    claims_path: Path, snapshot_path: Path, known_gaps_path: Path
) -> tuple[list[str], int]:
    gap_statuses = load_gap_statuses(known_gaps_path)
    claims = load_claims(claims_path, gap_statuses)
    entries = load_snapshot(snapshot_path)

    failures: list[str] = []
    expected_ids = {claim["claim_id"] for claim in claims}
    actual_ids = set(entries)
    for missing in sorted(expected_ids - actual_ids):
        failures.append(f"snapshot missing claim_id {missing}")
    for extra in sorted(actual_ids - expected_ids):
        failures.append(f"snapshot contains unknown claim_id {extra}")

    for claim in claims:
        entry = entries.get(claim["claim_id"])
        if entry is not None:
            failures.extend(validate_claim(claim, entry))
    return failures, len(claims)


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Validate known-gap live-state claims against a normalized GitHub snapshot."
    )
    parser.add_argument("--claims", required=True, type=Path)
    parser.add_argument("--snapshot", required=True, type=Path)
    parser.add_argument("--known-gaps", required=True, type=Path)
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv or sys.argv[1:])
    try:
        failures, count = validate(args.claims, args.snapshot, args.known_gaps)
    except ValidationError as exc:
        print(f"known gaps live-state failed: {exc}", file=sys.stderr)
        return 1
    if failures:
        for failure in failures:
            print(f"known gaps live-state failed: {failure}", file=sys.stderr)
        return 1
    print(f"known gaps live-state checks passed ({count} claim(s))")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

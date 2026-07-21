#!/usr/bin/env python3
"""Focused regressions for canonical telemetry policy and bundle trust boundaries."""
from __future__ import annotations

import hashlib
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[3]
MONITORING = ROOT / "scripts" / "monitoring"
sys.path.insert(0, str(MONITORING))

from telemetry_handoff import (  # noqa: E402
    HANDOFF_SCHEMA,
    POLICY_SCHEMA,
    REQUIRED_BUNDLE_FILES,
    RUN_SCHEMA,
    HandoffError,
    load_policy,
    stable_hash,
    validate_bundle,
)

SELECTOR = MONITORING / "select-pr-telemetry.py"


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write_policy(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(
            {
                "schema_version": POLICY_SCHEMA,
                "remote_handoff": {
                    "mode": "required",
                    "remote": "origin",
                    "branch": "engineering-os-telemetry",
                },
            }
        ),
        encoding="utf-8",
    )


def write_disabled_policy(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(
            {
                "schema_version": POLICY_SCHEMA,
                "remote_handoff": {"mode": "disabled"},
            }
        ),
        encoding="utf-8",
    )


def create_bundle(root: Path, *, run_id: str = "hardening-run") -> tuple[Path, str, str, int]:
    repo = "example/project"
    head_ref = "chore/test"
    head_sha = "a" * 40
    pr_number = 7
    bundle = root / "runs" / run_id
    bundle.mkdir(parents=True)

    row = {
        "trace_id": run_id,
        "name": "eos.session_start",
        "attributes": {"eos.event.name": "session_start"},
    }
    (bundle / "events.jsonl").write_text(json.dumps(row) + "\n", encoding="utf-8")
    (bundle / "latest-summary.md").write_text("# Summary\n", encoding="utf-8")
    manifest = {
        "schema_version": RUN_SCHEMA,
        "run_id": run_id,
        "repo": repo,
        "head_sha": head_sha,
        "event_count": 1,
        "privacy_contract": "metadata-only",
        "checksums": {
            "events_sha256": digest(bundle / "events.jsonl"),
            "summary_sha256": digest(bundle / "latest-summary.md"),
        },
        "handoff": {
            "schema_version": HANDOFF_SCHEMA,
            "repo": repo,
            "pr_number": pr_number,
            "pr_binding": "exact",
            "source_branch_hash": stable_hash(head_ref),
            "head_sha": head_sha,
            "run_id_hash": stable_hash(run_id),
            "event_count": 1,
            "boundary_position": 1,
            "synced_at": "2026-07-20T00:00:00+00:00",
        },
    }
    (bundle / "manifest.json").write_text(json.dumps(manifest), encoding="utf-8")
    validate_bundle(bundle)
    return bundle, repo, head_ref, pr_number


def run_selector(
    *,
    handoff: Path,
    policy: Path,
    repo: str = "example/project",
    head_ref: str = "chore/test",
    pr_number: int = 7,
    out: Path,
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [
            sys.executable,
            str(SELECTOR),
            "--root",
            str(ROOT),
            "--handoff-root",
            str(handoff),
            "--policy-file",
            str(policy),
            "--repo",
            repo,
            "--pr-number",
            str(pr_number),
            "--head-ref",
            head_ref,
            "--head-sha",
            "a" * 40,
            "--out",
            str(out),
        ],
        text=True,
        capture_output=True,
        check=False,
    )


class TelemetryTrustBoundaryTests(unittest.TestCase):
    def test_explicit_missing_policy_fails_closed(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            missing = Path(tmp) / "trusted-policy.json"
            with self.assertRaises(HandoffError):
                load_policy(ROOT, missing)

    def test_explicit_policy_ignores_environment_overrides(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            policy_path = Path(tmp) / "trusted-policy.json"
            write_policy(policy_path)
            with patch.dict(
                os.environ,
                {
                    "EOS_TELEMETRY_HANDOFF_MODE": "disabled",
                    "EOS_TELEMETRY_HANDOFF_REMOTE": "untrusted",
                    "EOS_TELEMETRY_HANDOFF_BRANCH": "untrusted-branch",
                },
                clear=False,
            ):
                policy = load_policy(ROOT, policy_path)
            self.assertEqual(policy["mode"], "required")
            self.assertEqual(policy["remote"], "origin")
            self.assertEqual(policy["branch"], "engineering-os-telemetry")

    def test_explicit_disabled_policy_ignores_pr_checkout_policy(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            pr_root = tmp_path / "pr-checkout"
            write_policy(pr_root / ".engineering-os" / "telemetry-policy.json")
            trusted_policy = tmp_path / "trusted-base-policy.json"
            write_disabled_policy(trusted_policy)
            with patch.dict(
                os.environ,
                {"EOS_TELEMETRY_HANDOFF_MODE": "required"},
                clear=False,
            ):
                policy = load_policy(pr_root, trusted_policy)
            self.assertEqual(policy["mode"], "disabled")
            self.assertEqual(policy["remote"], "origin")
            self.assertEqual(policy["branch"], "engineering-os-telemetry")

    def test_required_bundle_file_symlink_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            bundle, _, _, _ = create_bundle(tmp_path / "handoff")
            summary = bundle / "latest-summary.md"
            target = tmp_path / "outside-summary.md"
            target.write_bytes(summary.read_bytes())
            summary.unlink()
            summary.symlink_to(target)
            with self.assertRaises(HandoffError):
                validate_bundle(bundle)

    def test_selector_rejects_symlinked_run_directory(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            outside_bundle, repo, head_ref, pr_number = create_bundle(tmp_path / "outside")
            handoff = tmp_path / "handoff"
            (handoff / "runs").mkdir(parents=True)
            (handoff / "runs" / outside_bundle.name).symlink_to(
                outside_bundle,
                target_is_directory=True,
            )
            policy = tmp_path / "trusted-policy.json"
            write_policy(policy)
            result = run_selector(
                handoff=handoff,
                policy=policy,
                repo=repo,
                head_ref=head_ref,
                pr_number=pr_number,
                out=tmp_path / "selected",
            )
            self.assertEqual(result.returncode, 1)
            self.assertIn("symlink", result.stderr.lower())

    def test_selector_rejects_symlinked_runs_root(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            _, repo, head_ref, pr_number = create_bundle(tmp_path / "outside")
            handoff = tmp_path / "handoff"
            handoff.mkdir()
            (handoff / "runs").symlink_to(
                tmp_path / "outside" / "runs",
                target_is_directory=True,
            )
            policy = tmp_path / "trusted-policy.json"
            write_policy(policy)
            result = run_selector(
                handoff=handoff,
                policy=policy,
                repo=repo,
                head_ref=head_ref,
                pr_number=pr_number,
                out=tmp_path / "selected",
            )
            self.assertEqual(result.returncode, 1)
            self.assertIn("symlink", result.stderr.lower())

    def test_selector_copies_only_validated_allowlist(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            handoff = tmp_path / "handoff"
            bundle, repo, head_ref, pr_number = create_bundle(handoff)
            (bundle / "unvalidated.txt").write_text("VALUE_SHOULD_NOT_APPEAR\n", encoding="utf-8")
            outside = tmp_path / "outside-secret.txt"
            outside.write_text("VALUE_SHOULD_NOT_APPEAR\n", encoding="utf-8")
            (bundle / "unvalidated-link.txt").symlink_to(outside)

            policy = tmp_path / "trusted-policy.json"
            write_policy(policy)
            out = tmp_path / "selected"
            result = run_selector(
                handoff=handoff,
                policy=policy,
                repo=repo,
                head_ref=head_ref,
                pr_number=pr_number,
                out=out,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual({path.name for path in out.iterdir()}, set(REQUIRED_BUNDLE_FILES))
            serialized = b"".join(path.read_bytes() for path in out.iterdir())
            self.assertNotIn(b"VALUE_SHOULD_NOT_APPEAR", serialized)


if __name__ == "__main__":
    unittest.main(verbosity=2)

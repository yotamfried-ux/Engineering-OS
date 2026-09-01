#!/usr/bin/env python3
"""Canonical runner for standalone Python enforcement tests."""
from __future__ import annotations

import os
import subprocess
import sys
import tempfile
import time
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))
import test_evidence  # noqa: E402


def main() -> int:
    root = SCRIPT_DIR.parent.parent
    evidence_dir = Path(os.environ.get("EOS_TEST_EVIDENCE_DIR", root / ".engineering-os/test-evidence"))
    receipt_file = Path(os.environ.get("EOS_TEST_RECEIPT_FILE", evidence_dir / "receipts.jsonl"))
    head_sha = os.environ.get("EOS_TEST_HEAD_SHA") or os.environ.get("GITHUB_SHA") or test_evidence.git_head(root)
    evidence_dir.mkdir(parents=True, exist_ok=True)
    (evidence_dir / "logs").mkdir(parents=True, exist_ok=True)

    inventory = test_evidence.discover(root)
    standalone = [r for r in inventory if r["language"] == "python" and r["role"] == "standalone"]
    if len(sys.argv) > 1:
        requested = {str(Path(x).as_posix()) for x in sys.argv[1:]}
        by_path = {r["path"]: r for r in standalone}
        missing = sorted(requested - set(by_path))
        if missing:
            print("❌ unknown/non-standalone Python tests: " + ", ".join(missing), file=sys.stderr)
            return 1
        standalone = [by_path[p] for p in sorted(requested)]

    if not standalone:
        print("✅ no standalone Python enforcement tests discovered")
        return 0

    failed = False
    for item in standalone:
        test_path = item["path"]
        test_id = item["id"]
        attempt = test_evidence.next_attempt(receipt_file, test_id)
        safe = test_path.replace("/", "_").replace(":", "_").replace(" ", "_")
        # Use atomic exclusive creation rather than clocks/PIDs: isolated
        # runners may share both, but the filesystem cannot allocate the same
        # path twice.
        fd, log_name = tempfile.mkstemp(
            dir=evidence_dir / "logs",
            prefix=f"{safe}.attempt-{attempt}.run-",
            suffix=".log",
        )
        os.close(fd)
        log = Path(log_name)
        start = time.monotonic()
        proc = subprocess.run(
            [sys.executable, str(root / test_path)],
            cwd=root,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            errors="replace",
            env=os.environ.copy(),
        )
        duration_ms = int((time.monotonic() - start) * 1000)
        log.write_text(proc.stdout or "", encoding="utf-8")
        print(f"──────── {test_path} ────────")
        if proc.stdout:
            print(proc.stdout, end="" if proc.stdout.endswith("\n") else "\n")
        result = "pass" if proc.returncode == 0 else "fail"
        if proc.returncode != 0:
            failed = True
        try:
            test_evidence.append_receipt(
                root=root,
                receipt_file=receipt_file,
                test_path=test_path,
                runner=test_evidence.PYTHON_RUNNER,
                result=result,
                log_path=log,
                head_sha=head_sha,
                attempt=attempt,
                duration_ms=duration_ms,
            )
        except ValueError as exc:
            print(f"❌ failed to record execution receipt for {test_path}: {exc}", file=sys.stderr)
            failed = True

    if failed:
        print("❌ one or more Python enforcement tests failed or lacked trustworthy receipts")
        return 1
    print(f"✅ all {len(standalone)} Python enforcement tests passed with execution receipts")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

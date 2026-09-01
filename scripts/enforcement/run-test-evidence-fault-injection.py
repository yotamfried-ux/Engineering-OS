#!/usr/bin/env python3
"""Mutate temporary copies of evidence controls and require focused regressions to detect each weakening."""
from __future__ import annotations

import os
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SIM = ROOT / "scripts/enforcement/check-simulation-coverage.py"
EVIDENCE = ROOT / "scripts/enforcement/test_evidence.py"
SIM_TEST = ROOT / "scripts/enforcement/tests/test-simulation-coverage.sh"
EVIDENCE_TEST = ROOT / "scripts/enforcement/tests/test-test-evidence-trust.sh"


def mutated_copy(source: Path, old: str, new: str, target: Path) -> None:
    text = source.read_text(encoding="utf-8")
    if old not in text:
        raise RuntimeError(f"mutation anchor missing in {source}: {old}")
    target.write_text(text.replace(old, new, 1), encoding="utf-8")


def require_detected(name: str, command: list[str], env: dict[str, str]) -> None:
    proc = subprocess.run(command, cwd=ROOT, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, errors="replace")
    if proc.returncode == 0:
        print(proc.stdout)
        raise RuntimeError(f"mutation survived focused regression: {name}")
    print(f"ok: mutation detected — {name}")


def main() -> int:
    base_env = os.environ.copy()
    with tempfile.TemporaryDirectory(prefix="eos-test-evidence-mutations-") as tmp_raw:
        tmp = Path(tmp_raw)
        mutations = [
            (
                "failed receipt accepted as passing simulation evidence",
                SIM,
                'if rec.get("result") != "pass":',
                "if False:",
                SIM_TEST,
                "EOS_SIM_CHECK",
            ),
            (
                "wrong test allowed to satisfy another test's simulation scenario",
                SIM,
                'if rec.get("path") != test_file:',
                "if False:",
                SIM_TEST,
                "EOS_SIM_CHECK",
            ),
            (
                "stale simulation receipt head accepted",
                SIM,
                'if rec.get("head_sha") != head_sha:',
                "if False:",
                SIM_TEST,
                "EOS_SIM_CHECK",
            ),
            (
                "stale corpus receipt head accepted",
                EVIDENCE,
                "if expected_head and head != expected_head:",
                "if False:",
                EVIDENCE_TEST,
                "EOS_TEST_EVIDENCE_TOOL",
            ),
            (
                "tampered corpus log checksum accepted",
                EVIDENCE,
                'if sha256_file(log_abs) != rec.get("log_sha256"):',
                "if False:",
                EVIDENCE_TEST,
                "EOS_TEST_EVIDENCE_TOOL",
            ),
            (
                "canonical runner workflow wiring no longer checked",
                EVIDENCE,
                "for runner in (SHELL_RUNNER, PYTHON_RUNNER):",
                "for runner in ():",
                EVIDENCE_TEST,
                "EOS_TEST_EVIDENCE_TOOL",
            ),
        ]
        for idx, (name, source, old, new, regression, env_name) in enumerate(mutations, 1):
            target = tmp / f"mutated-{idx}.py"
            mutated_copy(source, old, new, target)
            env = base_env.copy()
            env[env_name] = str(target)
            require_detected(name, ["bash", str(regression)], env)
    print(f"test evidence fault injection passed ({len(mutations)} mutations detected)")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except RuntimeError as exc:
        print(f"fault injection failed: {exc}", file=sys.stderr)
        raise SystemExit(1)

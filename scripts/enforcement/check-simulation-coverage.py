#!/usr/bin/env python3
"""Validate simulation coverage against successful execution receipts, not source tokens."""
from __future__ import annotations

import argparse
import base64
import hashlib
import json
import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def fail(msg: str) -> None:
    raise ValueError(msg)


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def resolve(root: Path, value: str) -> Path:
    p = Path(value)
    return p if p.is_absolute() else root / p


def load_receipts(root: Path, path: Path, head_sha: str) -> list[dict]:
    if not path.is_file():
        fail(f"execution receipt file not found: {path}")
    records = []
    for lineno, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not raw.strip():
            continue
        try:
            rec = json.loads(raw)
        except json.JSONDecodeError as exc:
            fail(f"{path}:{lineno}: invalid receipt JSON: {exc}")
        if rec.get("head_sha") != head_sha:
            fail(f"{path}:{lineno}: receipt head {rec.get('head_sha')!r} does not match expected head {head_sha!r}")
        if rec.get("result") not in {"pass", "fail", "skip", "waived"}:
            fail(f"{path}:{lineno}: invalid receipt result")
        log_value = str(rec.get("log_path") or "")
        if not log_value:
            fail(f"{path}:{lineno}: missing receipt log_path")
        encoded = rec.get("log_content_b64")
        if not isinstance(encoded, str) or not encoded:
            fail(f"{path}:{lineno}: missing self-contained receipt log content")
        try:
            log_bytes = base64.b64decode(encoded, validate=True)
        except Exception as exc:
            fail(f"{path}:{lineno}: invalid embedded receipt log content: {exc}")
        if hashlib.sha256(log_bytes).hexdigest() != rec.get("log_sha256"):
            fail(f"{path}:{lineno}: embedded receipt log checksum mismatch")
        rec = dict(rec)
        rec["_log_text"] = log_bytes.decode("utf-8", errors="replace")
        records.append(rec)
    return records


def parse_required(path: Path, env_required: str | None) -> list[str]:
    if env_required:
        return [x.strip() for x in env_required.split(",") if x.strip()]
    if not path.is_file():
        fail(f"required gates manifest missing: {path}")
    active = []
    seen = set()
    for lineno, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not raw or raw.startswith("#"):
            continue
        cols = raw.split("\t")
        if len(cols) != 4:
            fail(f"{path}:{lineno}: expected 4 tab-separated fields")
        gate, owner, status, reason = cols
        if not all((gate, owner, status, reason)):
            fail(f"{path}:{lineno}: missing required field")
        if gate in seen:
            fail(f"{path}:{lineno}: duplicate required gate {gate}")
        seen.add(gate)
        if status == "active":
            active.append(gate)
        elif status == "waived":
            if len(reason) < 25:
                fail(f"{gate}: required gate waiver reason is too short")
        else:
            fail(f"{gate}: invalid required gate status {status!r}")
    return active


def collect_coverage_files(primary: Path) -> list[Path]:
    files = [primary]
    extra = primary.parent / (primary.name[:-4] + ".d") if primary.name.endswith(".tsv") else Path(str(primary) + ".d")
    if extra.is_dir():
        files.extend(sorted(extra.glob("*.tsv")))
    return files


def receipt_satisfies(records: list[dict], test_file: str, token: str) -> bool:
    for rec in records:
        if rec.get("path") != test_file:
            continue
        if rec.get("result") != "pass":
            continue
        if token in rec.get("_log_text", ""):
            return True
    return False


def validate_cell(gate: str, kind: str, cell: str, test_file: str, records: list[dict]) -> None:
    if cell.startswith("covered:"):
        token = cell[len("covered:") :]
        if len(token) < 3:
            fail(f"{gate}: {kind} coverage token is too short")
        if test_file.lower() in {"none", "n/a"}:
            fail(f"{gate}: {kind} is marked covered but no test_file is provided")
        if not receipt_satisfies(records, test_file, token):
            fail(f"{gate}: {kind} execution-backed token {token!r} was not observed in a successful exact-head receipt for {test_file}")
        return
    if cell.startswith("waived:"):
        reason = cell[len("waived:") :]
        if len(reason) < 20:
            fail(f"{gate}: {kind} waiver reason is too short")
        if re.search(r"no .*waiver path|not supported|by design|non-waivable", reason, re.I):
            fail(f"{gate}: {kind} waiver describes a design decision; use none-by-design:")
        return
    if cell.startswith("none-by-design:"):
        reason = cell[len("none-by-design:") :]
        if len(reason) < 20:
            fail(f"{gate}: {kind} none-by-design reason is too short")
        return
    fail(f"{gate}: {kind} must be covered:<executed token>, waived:<reason>, or none-by-design:<reason>")


def freshness_text(cell: str) -> str:
    for prefix in ("covered:", "waived:", "none-by-design:"):
        if cell.startswith(prefix):
            return "" if prefix == "covered:" else cell[len(prefix) :]
    return cell


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("coverage_file", nargs="?")
    p.add_argument("--root", default=str(ROOT))
    p.add_argument("--receipts")
    p.add_argument("--head-sha")
    p.add_argument("--required-gates-file")
    args = p.parse_args()

    root = Path(args.root).resolve()
    coverage = resolve(root, args.coverage_file) if args.coverage_file else root / "scripts/enforcement/simulation-coverage.tsv"
    receipts = resolve(root, args.receipts) if args.receipts else Path(os.environ.get("EOS_TEST_RECEIPT_FILE", root / ".engineering-os/test-evidence/receipts.jsonl"))
    head_sha = args.head_sha or os.environ.get("EOS_TEST_HEAD_SHA") or os.environ.get("GITHUB_SHA")
    if not head_sha:
        try:
            head_sha = subprocess.check_output(["git", "-C", str(root), "rev-parse", "HEAD"], text=True).strip()
        except Exception:
            fail("expected head SHA is required")
    required_file = resolve(root, args.required_gates_file) if args.required_gates_file else Path(os.environ.get("EOS_SIM_COVERAGE_REQUIRED_GATES_FILE", root / "scripts/enforcement/coverage-required-gates.tsv"))
    min_rows = int(os.environ.get("EOS_SIM_COVERAGE_MIN_ROWS", "8"))
    records = load_receipts(root, receipts, head_sha)

    if not coverage.is_file():
        fail(f"missing simulation coverage manifest: {coverage}")

    seen = set()
    row_count = 0
    for file in collect_coverage_files(coverage):
        for lineno, raw in enumerate(file.read_text(encoding="utf-8").splitlines(), 1):
            if not raw or raw.startswith("#"):
                continue
            cols = raw.split("\t")
            if len(cols) != 9:
                fail(f"{file}:{lineno}: expected 9 tab-separated fields")
            gate, owner, enforcer, test_file, positive, negative, invalid, waiver, notes = cols
            row_count += 1
            if not all(cols):
                fail(f"{gate or file}:{lineno}: missing required field")
            if re.search(r"\s", gate):
                fail(f"{gate}: gate_id must not contain whitespace")
            if gate in seen:
                fail(f"{gate}: duplicate gate_id")
            seen.add(gate)
            for label, value in (("enforcer", enforcer), ("test_file", test_file)):
                if value.lower() not in {"none", "n/a"} and not resolve(root, value).is_file():
                    fail(f"{gate}: {label} file not found: {value}")
            prose = " ".join([freshness_text(positive), freshness_text(negative), freshness_text(invalid), freshness_text(waiver), notes])
            if re.search(r"\b(future loop|pending|not yet|todo|tbd)\b", prose, re.I):
                fail(f"{gate}: coverage row contains deferred language")
            validate_cell(gate, "positive", positive, test_file, records)
            validate_cell(gate, "negative", negative, test_file, records)
            validate_cell(gate, "invalid", invalid, test_file, records)
            validate_cell(gate, "waiver", waiver, test_file, records)

    if row_count < min_rows:
        fail(f"expected at least {min_rows} simulation coverage rows, found {row_count}")
    required = parse_required(required_file, os.environ.get("EOS_SIM_COVERAGE_REQUIRED_GATES"))
    missing = [g for g in required if g not in seen]
    if missing:
        fail("missing required simulation coverage gate: " + ", ".join(missing))
    print(f"simulation coverage checks passed ({row_count} gates, execution-backed)")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ValueError as exc:
        print(f"simulation coverage failed: {exc}", file=sys.stderr)
        raise SystemExit(1)

#!/usr/bin/env python3
"""Execution-backed evidence for the Engineering OS automated-test corpus."""
from __future__ import annotations

import argparse
import ast
import base64
import hashlib
import json
import os
import subprocess
import sys
from collections import Counter, defaultdict
from pathlib import Path

LEVELS = ("static", "fixture", "integration", "live-provider", "real-runtime")
TEST_DIR = Path("scripts/enforcement/tests")
LEVELS_FILE = Path("scripts/enforcement/test-evidence-levels.tsv")
SHELL_RUNNER = "scripts/enforcement/run-enforcement-tests.sh"
PYTHON_RUNNER = "scripts/enforcement/run-python-enforcement-tests.py"


def rel(root: Path, path: Path) -> str:
    return path.resolve().relative_to(root.resolve()).as_posix()


def python_role(path: Path) -> str:
    text = path.read_text(encoding="utf-8", errors="replace")
    if "EOS_TEST_ROLE: helper" in text:
        return "helper"
    try:
        tree = ast.parse(text)
    except SyntaxError as exc:
        raise ValueError(f"{path}: Python test candidate is not parseable: {exc}") from exc

    has_main_guard = False
    has_test_callable = False
    for node in ast.walk(tree):
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)) and node.name.startswith("test_"):
            has_test_callable = True
        if isinstance(node, ast.If):
            test = node.test
            if (
                isinstance(test, ast.Compare)
                and isinstance(test.left, ast.Name)
                and test.left.id == "__name__"
                and len(test.ops) == 1
                and isinstance(test.ops[0], ast.Eq)
                and len(test.comparators) == 1
                and isinstance(test.comparators[0], ast.Constant)
                and test.comparators[0].value == "__main__"
            ):
                has_main_guard = True
    if has_main_guard:
        return "standalone"
    if has_test_callable:
        return "unowned-style"
    return "helper"


def load_levels(root: Path) -> tuple[str, dict[str, tuple[str, str]]]:
    default = "static"
    overrides: dict[str, tuple[str, str]] = {}
    path = root / LEVELS_FILE
    if not path.exists():
        return default, overrides
    for raw in path.read_text(encoding="utf-8").splitlines():
        if not raw or raw.startswith("#"):
            continue
        cols = raw.split("\t")
        if cols[0] == "@default":
            if len(cols) < 2 or cols[1] not in LEVELS:
                raise ValueError(f"{LEVELS_FILE}: invalid default evidence level")
            default = cols[1]
            continue
        if len(cols) < 3:
            raise ValueError(f"{LEVELS_FILE}: expected path, level, reason")
        p, level, reason = cols[0], cols[1], cols[2]
        if level not in LEVELS:
            raise ValueError(f"{LEVELS_FILE}: invalid evidence level {level!r} for {p}")
        if p in overrides:
            raise ValueError(f"{LEVELS_FILE}: duplicate path {p}")
        overrides[p] = (level, reason)
    return default, overrides


def discover(root: Path) -> list[dict]:
    default_level, overrides = load_levels(root)
    test_root = root / TEST_DIR
    if not test_root.is_dir():
        raise ValueError(f"missing test directory: {TEST_DIR}")

    rows: list[dict] = []
    seen_ids: set[str] = set()
    for path in sorted(test_root.glob("test-*.sh")):
        rp = rel(root, path)
        level, reason = overrides.get(rp, (default_level, "conservative default; not explicitly promoted"))
        tid = f"shell:{rp}"
        if tid in seen_ids:
            raise ValueError(f"duplicate test id: {tid}")
        seen_ids.add(tid)
        rows.append({
            "id": tid,
            "path": rp,
            "language": "bash",
            "role": "standalone",
            "runner": SHELL_RUNNER,
            "required_direct_execution": True,
            "evidence_level": level,
            "evidence_reason": reason,
        })

    for path in sorted(test_root.glob("test-*.py")):
        rp = rel(root, path)
        role = python_role(path)
        level, reason = overrides.get(rp, (default_level, "conservative default; not explicitly promoted"))
        tid = f"python:{rp}"
        if tid in seen_ids:
            raise ValueError(f"duplicate test id: {tid}")
        seen_ids.add(tid)
        rows.append({
            "id": tid,
            "path": rp,
            "language": "python",
            "role": role,
            "runner": PYTHON_RUNNER if role == "standalone" else None,
            "required_direct_execution": role == "standalone",
            "evidence_level": level,
            "evidence_reason": reason,
        })

    unknown = [r for r in rows if r["role"] == "unowned-style"]
    if unknown:
        paths = ", ".join(r["path"] for r in unknown)
        raise ValueError(
            "Python test candidates with test_* callables but no executable main guard must either gain a canonical executable entrypoint or declare '# EOS_TEST_ROLE: helper': "
            + paths
        )

    stale = sorted(set(overrides) - {r["path"] for r in rows})
    if stale:
        raise ValueError(f"{LEVELS_FILE}: evidence-level overrides point to missing/non-test paths: {', '.join(stale)}")
    return rows


def git_head(root: Path) -> str:
    env = os.environ.get("EOS_TEST_HEAD_SHA") or os.environ.get("GITHUB_SHA")
    if env:
        return env.strip()
    try:
        return subprocess.check_output(["git", "-C", str(root), "rev-parse", "HEAD"], text=True).strip()
    except Exception:
        return "unknown"


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def append_receipt(*, root: Path, receipt_file: Path, test_path: str, runner: str, result: str, log_path: Path, head_sha: str, attempt: int, duration_ms: int) -> dict:
    inventory = {r["path"]: r for r in discover(root)}
    if test_path not in inventory:
        raise ValueError(f"receipt test path is not in discovered corpus: {test_path}")
    item = inventory[test_path]
    if item["role"] != "standalone":
        raise ValueError(f"helper/non-test cannot emit direct execution receipt: {test_path}")
    if runner != item["runner"]:
        raise ValueError(f"wrong runner for {test_path}: got {runner}, expected {item['runner']}")
    if result not in {"pass", "fail", "skip", "waived"}:
        raise ValueError(f"invalid receipt result: {result}")
    log_abs = log_path if log_path.is_absolute() else root / log_path
    if not log_abs.is_file():
        raise ValueError(f"receipt log missing: {log_abs}")
    try:
        log_rel = rel(root, log_abs)
    except ValueError:
        log_rel = str(log_abs.resolve())
    log_bytes = log_abs.read_bytes()
    record = {
        "schema_version": 1,
        "test_id": item["id"],
        "path": test_path,
        "language": item["language"],
        "runner": runner,
        "head_sha": head_sha,
        "attempt": int(attempt),
        "result": result,
        "duration_ms": int(duration_ms),
        "evidence_level": item["evidence_level"],
        "log_path": log_rel,
        "log_sha256": hashlib.sha256(log_bytes).hexdigest(),
        "log_content_b64": base64.b64encode(log_bytes).decode("ascii"),
    }
    receipt_file.parent.mkdir(parents=True, exist_ok=True)
    with receipt_file.open("a", encoding="utf-8") as f:
        f.write(json.dumps(record, sort_keys=True) + "\n")
    return record


def load_receipts(root: Path, receipt_file: Path, expected_head: str | None = None) -> list[dict]:
    if not receipt_file.is_file():
        raise ValueError(f"receipt file not found: {receipt_file}")
    inventory = {r["id"]: r for r in discover(root)}
    records: list[dict] = []
    for lineno, raw in enumerate(receipt_file.read_text(encoding="utf-8").splitlines(), 1):
        if not raw.strip():
            continue
        try:
            rec = json.loads(raw)
        except json.JSONDecodeError as exc:
            raise ValueError(f"{receipt_file}:{lineno}: invalid JSON: {exc}") from exc
        tid = str(rec.get("test_id") or "")
        if tid not in inventory:
            raise ValueError(f"{receipt_file}:{lineno}: unknown test_id {tid!r}")
        item = inventory[tid]
        if rec.get("path") != item["path"]:
            raise ValueError(f"{receipt_file}:{lineno}: path does not match inventory for {tid}")
        if rec.get("runner") != item["runner"]:
            raise ValueError(f"{receipt_file}:{lineno}: runner does not match inventory for {tid}")
        if rec.get("evidence_level") != item["evidence_level"]:
            raise ValueError(f"{receipt_file}:{lineno}: evidence level does not match inventory for {tid}")
        if rec.get("result") not in {"pass", "fail", "skip", "waived"}:
            raise ValueError(f"{receipt_file}:{lineno}: invalid result")
        head = str(rec.get("head_sha") or "")
        if expected_head and head != expected_head:
            raise ValueError(f"{receipt_file}:{lineno}: stale/wrong head for {tid}: got {head!r}, expected {expected_head!r}")
        log_value = str(rec.get("log_path") or "")
        if not log_value:
            raise ValueError(f"{receipt_file}:{lineno}: missing log_path")
        encoded = rec.get("log_content_b64")
        if not isinstance(encoded, str) or not encoded:
            raise ValueError(f"{receipt_file}:{lineno}: missing self-contained log content for {tid}")
        try:
            log_bytes = base64.b64decode(encoded, validate=True)
        except Exception as exc:
            raise ValueError(f"{receipt_file}:{lineno}: invalid embedded log content for {tid}") from exc
        if hashlib.sha256(log_bytes).hexdigest() != rec.get("log_sha256"):
            raise ValueError(f"{receipt_file}:{lineno}: embedded log checksum mismatch for {tid}")
        try:
            attempt = int(rec.get("attempt"))
        except Exception as exc:
            raise ValueError(f"{receipt_file}:{lineno}: invalid attempt for {tid}") from exc
        if attempt < 1:
            raise ValueError(f"{receipt_file}:{lineno}: attempt must be >= 1 for {tid}")
        records.append(rec)
    return records


def check_inventory(root: Path, workflow: Path | None = None) -> list[dict]:
    rows = discover(root)
    workflow = workflow or root / ".github/workflows/enforcement-tests.yml"
    if not workflow.is_file():
        raise ValueError(f"missing canonical enforcement workflow: {workflow}")
    text = workflow.read_text(encoding="utf-8", errors="replace")
    for runner in (SHELL_RUNNER, PYTHON_RUNNER):
        if runner not in text:
            raise ValueError(f"canonical workflow does not invoke required test runner: {runner}")
    if not any(r["language"] == "bash" and r["role"] == "standalone" for r in rows):
        raise ValueError("no standalone Bash tests discovered")
    return rows


def summarize(inventory: list[dict], records: list[dict], head_sha: str) -> dict:
    standalone = [r for r in inventory if r["required_direct_execution"]]
    helpers = [r for r in inventory if r["role"] == "helper"]
    by_id: dict[str, list[dict]] = defaultdict(list)
    for rec in records:
        by_id[rec["test_id"]].append(rec)

    unique_status = Counter()
    duplicate_attempts = 0
    evidence_levels = Counter()
    for item in standalone:
        rs = by_id.get(item["id"], [])
        duplicate_attempts += max(0, len(rs) - 1)
        results = {r["result"] for r in rs}
        if "fail" in results:
            status = "failed-at-least-once"
        elif "pass" in results:
            status = "passed"
        elif "waived" in results:
            status = "waived"
        elif "skip" in results:
            status = "skipped"
        else:
            status = "missing"
        unique_status[status] += 1
        if "pass" in results:
            evidence_levels[item["evidence_level"]] += 1

    return {
        "schema_version": 1,
        "head_sha": head_sha,
        "discovered_standalone_tests": len(standalone),
        "declared_helpers": len(helpers),
        "execution_attempts": len(records),
        "duplicate_attempts": duplicate_attempts,
        "unique_status": dict(sorted(unique_status.items())),
        "passed_evidence_levels": {level: evidence_levels.get(level, 0) for level in LEVELS},
        "tests": [{
            "id": item["id"], "path": item["path"], "role": item["role"], "runner": item["runner"],
            "evidence_level": item["evidence_level"], "attempts": len(by_id.get(item["id"], [])),
            "results": [r["result"] for r in by_id.get(item["id"], [])],
        } for item in inventory],
    }


def check_receipts(root: Path, receipt_file: Path, head_sha: str) -> dict:
    inventory = check_inventory(root)
    records = load_receipts(root, receipt_file, head_sha)
    by_id: dict[str, list[dict]] = defaultdict(list)
    for rec in records:
        by_id[rec["test_id"]].append(rec)
    missing = []
    no_pass = []
    for item in inventory:
        if not item["required_direct_execution"]:
            continue
        rs = by_id.get(item["id"], [])
        if not rs:
            missing.append(item["path"])
        elif not any(r["result"] == "pass" for r in rs):
            no_pass.append(item["path"])
    if missing:
        raise ValueError("required standalone tests missing exact-run receipts: " + ", ".join(missing))
    if no_pass:
        raise ValueError("required standalone tests have no passing exact-run receipt: " + ", ".join(no_pass))
    return summarize(inventory, records, head_sha)


def next_attempt(receipt_file: Path, test_id: str) -> int:
    if not receipt_file.exists():
        return 1
    n = 0
    for raw in receipt_file.read_text(encoding="utf-8").splitlines():
        if not raw.strip():
            continue
        try:
            rec = json.loads(raw)
        except Exception:
            continue
        if rec.get("test_id") == test_id:
            try:
                n = max(n, int(rec.get("attempt") or 0))
            except Exception:
                pass
    return n + 1


def path_arg(root: Path, value: str) -> Path:
    p = Path(value)
    return p if p.is_absolute() else root / p


def cmd_inventory(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve()
    payload = {"schema_version": 1, "tests": discover(root)}
    text = json.dumps(payload, indent=2, sort_keys=True)
    if args.output:
        path_arg(root, args.output).write_text(text + "\n", encoding="utf-8")
    print(text)
    return 0


def cmd_check_inventory(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve()
    workflow = path_arg(root, args.workflow) if args.workflow else None
    rows = check_inventory(root, workflow)
    print(f"test corpus inventory passed: standalone={sum(r['required_direct_execution'] for r in rows)} helpers={sum(r['role'] == 'helper' for r in rows)}")
    return 0


def cmd_record(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve()
    rec = append_receipt(root=root, receipt_file=path_arg(root, args.receipt_file), test_path=args.test_path, runner=args.runner, result=args.result, log_path=Path(args.log_path), head_sha=args.head_sha, attempt=args.attempt, duration_ms=args.duration_ms)
    print(json.dumps(rec, sort_keys=True))
    return 0


def cmd_next_attempt(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve()
    inventory = {r["path"]: r for r in discover(root)}
    item = inventory.get(args.test_path)
    if not item:
        raise ValueError(f"unknown test path: {args.test_path}")
    print(next_attempt(path_arg(root, args.receipt_file), item["id"]))
    return 0


def cmd_check_receipts(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve()
    summary = check_receipts(root, path_arg(root, args.receipt_file), args.head_sha)
    print(f"test execution receipts passed: unique={summary['discovered_standalone_tests']} attempts={summary['execution_attempts']} duplicates={summary['duplicate_attempts']}")
    return 0


def cmd_summary(args: argparse.Namespace) -> int:
    root = Path(args.root).resolve()
    inventory = check_inventory(root)
    records = load_receipts(root, path_arg(root, args.receipt_file), args.head_sha)
    summary = summarize(inventory, records, args.head_sha)
    text = json.dumps(summary, indent=2, sort_keys=True)
    if args.output:
        out = path_arg(root, args.output)
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(text + "\n", encoding="utf-8")
    print(f"unique deterministic tests: {summary['discovered_standalone_tests']}; attempts: {summary['execution_attempts']}; duplicate attempts: {summary['duplicate_attempts']}; helpers: {summary['declared_helpers']}")
    print("passed evidence levels: " + ", ".join(f"{k}={v}" for k, v in summary["passed_evidence_levels"].items()))
    return 0


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest="command", required=True)
    x = sub.add_parser("inventory"); x.add_argument("--root", default="."); x.add_argument("--output"); x.set_defaults(func=cmd_inventory)
    x = sub.add_parser("check-inventory"); x.add_argument("--root", default="."); x.add_argument("--workflow"); x.set_defaults(func=cmd_check_inventory)
    x = sub.add_parser("record"); x.add_argument("--root", default="."); x.add_argument("--receipt-file", required=True); x.add_argument("--test-path", required=True); x.add_argument("--runner", required=True); x.add_argument("--result", required=True); x.add_argument("--log-path", required=True); x.add_argument("--head-sha", required=True); x.add_argument("--attempt", type=int, required=True); x.add_argument("--duration-ms", type=int, required=True); x.set_defaults(func=cmd_record)
    x = sub.add_parser("next-attempt"); x.add_argument("--root", default="."); x.add_argument("--receipt-file", required=True); x.add_argument("--test-path", required=True); x.set_defaults(func=cmd_next_attempt)
    x = sub.add_parser("check-receipts"); x.add_argument("--root", default="."); x.add_argument("--receipt-file", required=True); x.add_argument("--head-sha", required=True); x.set_defaults(func=cmd_check_receipts)
    x = sub.add_parser("summary"); x.add_argument("--root", default="."); x.add_argument("--receipt-file", required=True); x.add_argument("--head-sha", required=True); x.add_argument("--output"); x.set_defaults(func=cmd_summary)
    return p


def main() -> int:
    try:
        args = build_parser().parse_args()
        return args.func(args)
    except ValueError as exc:
        print(f"test evidence failed: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())

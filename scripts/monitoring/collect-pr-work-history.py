#!/usr/bin/env python3
"""Generate the Operational Work History artifact for a PR run.

Always writes .engineering-os/work-history/latest.json and latest-summary.md
in the CI workspace. This is a build product: never committed, regenerated
fresh on every run, and validated directly by
scripts/enforcement/check-operational-work-history-evidence.sh.

Privacy contract: metadata-only. No raw model/user text, file contents, raw
shell commands, raw repository paths, connector payloads, environment values,
or credentials/secrets are written anywhere in the artifact. Repository paths,
commit subjects, and review authors are used transiently to compute counts,
hashes, and friction signals, but the artifact stores only hashes/buckets/counts.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

SCHEMA_VERSION = "eos.work_history.v1"
FIX_RETRY_REVERT_RE = re.compile(r"\b(fix|fixes|fixed|retry|retries|revert|reverts|reverted)\b", re.I)
FAILING_CONCLUSIONS = {"failure", "timed_out", "cancelled", "action_required"}

GOVERNANCE_CONTRACT_ID = "engineering-os-governance"
CONTRACT_PLACEHOLDER_RE = re.compile(
    r"^\s*(todo|tbd|placeholder|unknown|n/?a|none|later|fix later|not sure|unclear)\W*$", re.I
)


def stable_hash(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8", errors="replace")).hexdigest()[:16]


def run_git(args: list[str], cwd: Path, *, required: bool = True) -> str:
    try:
        return subprocess.check_output(args, cwd=cwd, stderr=subprocess.PIPE, text=True).strip()
    except subprocess.CalledProcessError as exc:
        if required:
            stderr = (exc.stderr or "").strip()
            print(f"ERROR_FOR_AGENT: git command failed: {' '.join(args)}", file=sys.stderr)
            if stderr:
                print(stderr, file=sys.stderr)
            raise
        return ""
    except FileNotFoundError as exc:
        if required:
            print(f"ERROR_FOR_AGENT: git command failed: {' '.join(args)} ({exc})", file=sys.stderr)
            raise
        return ""


def load_json_file(path: Path | None) -> tuple[Any, bool]:
    """Returns (data, unavailable)."""
    if path is None or not path.is_file():
        return None, True
    try:
        return json.loads(path.read_text(encoding="utf-8")), False
    except Exception:
        return None, True


def changed_files(root: Path, base_sha: str, checked_out_sha: str) -> list[str]:
    if not base_sha or not checked_out_sha:
        raise ValueError("base_sha and checked_out_sha are required to collect changed files")
    out = run_git(["git", "diff", "--name-only", f"{base_sha}...{checked_out_sha}"], root)
    return [line for line in out.splitlines() if line.strip()]


def commit_list(root: Path, base_sha: str, checked_out_sha: str) -> list[dict[str, str]]:
    if not base_sha or not checked_out_sha:
        raise ValueError("base_sha and checked_out_sha are required to collect commits")
    out = run_git(["git", "log", f"{base_sha}..{checked_out_sha}", "--format=%H%x1f%s"], root)
    commits = []
    for line in out.splitlines():
        if "\x1f" not in line:
            continue
        sha, subject = line.split("\x1f", 1)
        commits.append({"sha": sha, "subject": subject, "subject_hash": stable_hash(subject)})
    return commits


def path_metadata(paths: list[str]) -> dict[str, Any]:
    extensions = Counter()
    top_level = Counter()
    governance_count = 0
    for raw in paths:
        normalized = raw.replace("\\", "/")
        suffix = Path(normalized).suffix or "<none>"
        extensions[suffix] += 1
        top = normalized.split("/", 1)[0] if normalized else "<none>"
        top_level[top] += 1
        if normalized.startswith(("docs/operations/", ".github/workflows/", "scripts/enforcement/", "scripts/monitoring/", "core/")):
            governance_count += 1
        elif normalized in {"CLAUDE.md", "CLAUDE.template.md"} or normalized.endswith(".tsv"):
            governance_count += 1
    return {
        "changed_file_path_hashes": [stable_hash(p.replace("\\", "/")) for p in paths],
        "changed_file_extension_counts": dict(sorted(extensions.items())),
        "changed_file_top_level_counts": dict(sorted(top_level.items())),
        "governance_changed_files_count": governance_count,
    }


def load_result_loop_contract_ids() -> tuple[set[str], bool]:
    """Returns (valid_ids, manifest_unavailable).

    Resolved relative to this script's own file location (mirroring how
    check-operational-work-history-evidence.sh resolves ROOT from
    SCRIPT_DIR), not from --root, so this works the same whether the script
    runs inside the Engineering OS repo or an installed downstream target
    project that copied both files alongside each other via
    policy-gate-dependencies.tsv.
    """
    manifest_path = Path(__file__).resolve().parent.parent / "enforcement" / "result-loop-requirements.tsv"
    if not manifest_path.is_file():
        return set(), True
    lines = manifest_path.read_text(encoding="utf-8").splitlines()
    header_line = next((line for line in lines if line.startswith("# ") and "\t" in line), "")
    header = header_line[2:].split("\t") if header_line else []
    if "project_type_id" not in header:
        return set(), True
    idx = header.index("project_type_id")
    ids: set[str] = set()
    for raw in lines:
        if not raw or raw.startswith("#"):
            continue
        cells = raw.split("\t")
        if len(cells) > idx and cells[idx].strip():
            ids.add(cells[idx].strip())
    return ids, False


def concrete_contract_value(value: str) -> bool:
    clean = value.strip()
    return bool(clean) and len(clean) >= 2 and not CONTRACT_PLACEHOLDER_RE.fullmatch(clean)


def declared_result_loop_contract(pr_body: str) -> str | None:
    match = re.search(r"^##\s+Operational Work History Evidence\s*$", pr_body, re.I | re.M)
    if not match:
        return None
    rest = pr_body[match.end():]
    nxt = re.search(r"^##\s+", rest, re.M)
    section = rest[:nxt.start()] if nxt else rest
    field = re.search(r"(^|\n)\s*[-*]?\s*selected_result_loop_contract\s*:\s*(.+)", section, re.I)
    return field.group(2).strip() if field else None


def classify_result_loop_candidates(paths: list[str], valid_ids: set[str]) -> set[str]:
    """templates/<id>/... maps to that project_type_id when <id> is a known
    manifest id; every other changed path (including docs, since Stage 1 has
    no automatic filename-only exemption) falls into the governance bucket
    for Engineering OS's own tooling surface."""
    candidates: set[str] = set()
    for raw in paths:
        normalized = raw.replace("\\", "/")
        parts = normalized.split("/", 2)
        if len(parts) >= 2 and parts[0] == "templates" and parts[1] in valid_ids:
            candidates.add(parts[1])
        else:
            candidates.add(GOVERNANCE_CONTRACT_ID)
    return candidates


def derive_result_loop_contract(paths: list[str], pr_body: str, empty_run: bool) -> dict[str, Any]:
    """Computes the selected_result_loop_contract dimension of the artifact.
    Prefers deterministic derivation from changed paths; only consults a
    declared `selected_result_loop_contract:` PR-body field when derivation
    is genuinely ambiguous, and only accepts a declared value that is both a
    real manifest id and a member of the actual candidate set implied by the
    diff (rejects a valid-but-unrelated id)."""
    if empty_run or not paths:
        return {
            "required": False,
            "selection_source": "not_required",
            "selected_result_loop_contract": "",
            "validation_status": "not_applicable",
            "matched_manifest_row": "",
            "reason": "no changed files (empty run); no code/config/test/system-affecting path exists to select a result-loop contract for.",
        }

    valid_ids, manifest_unavailable = load_result_loop_contract_ids()
    if manifest_unavailable:
        return {
            "required": True,
            "selection_source": "manifest_unavailable",
            "selected_result_loop_contract": "",
            "validation_status": "unavailable",
            "matched_manifest_row": "",
            "reason": "scripts/enforcement/result-loop-requirements.tsv was not found next to this script; cannot derive or validate a result-loop contract.",
        }

    candidates = classify_result_loop_candidates(paths, valid_ids)

    if len(candidates) == 1:
        selected = next(iter(candidates))
        return {
            "required": True,
            "selection_source": "derived",
            "selected_result_loop_contract": selected,
            "validation_status": "valid",
            "matched_manifest_row": f"scripts/enforcement/result-loop-requirements.tsv#{selected}",
            "reason": f"deterministically derived: all {len(paths)} changed path(s) map to exactly one result-loop contract ({selected}).",
        }

    sorted_candidates = sorted(candidates)
    declared = declared_result_loop_contract(pr_body)
    if declared is None:
        return {
            "required": True,
            "selection_source": "ambiguous",
            "selected_result_loop_contract": "",
            "validation_status": "missing",
            "matched_manifest_row": "",
            "reason": (
                "changed paths imply multiple candidate result-loop contracts "
                f"({', '.join(sorted_candidates)}) and no selected_result_loop_contract: "
                "field was declared under ## Operational Work History Evidence."
            ),
        }

    declared = declared.strip()
    if not concrete_contract_value(declared):
        return {
            "required": True,
            "selection_source": "declared",
            "selected_result_loop_contract": declared,
            "validation_status": "placeholder",
            "matched_manifest_row": "",
            "reason": (
                f"declared selected_result_loop_contract '{declared}' looks like a placeholder; "
                f"declare a real contract id from ({', '.join(sorted_candidates)})."
            ),
        }
    if declared not in valid_ids:
        return {
            "required": True,
            "selection_source": "declared",
            "selected_result_loop_contract": declared,
            "validation_status": "unknown_id",
            "matched_manifest_row": "",
            "reason": (
                f"declared selected_result_loop_contract '{declared}' is not a known "
                "project_type_id in scripts/enforcement/result-loop-requirements.tsv."
            ),
        }
    if declared not in candidates:
        return {
            "required": True,
            "selection_source": "declared",
            "selected_result_loop_contract": declared,
            "validation_status": "invalid",
            "matched_manifest_row": "",
            "reason": (
                f"declared selected_result_loop_contract '{declared}' does not match any contract "
                f"implied by the changed paths (candidates: {', '.join(sorted_candidates)})."
            ),
        }

    return {
        "required": True,
        "selection_source": "declared",
        "selected_result_loop_contract": declared,
        "validation_status": "valid",
        "matched_manifest_row": f"scripts/enforcement/result-loop-requirements.tsv#{declared}",
        "reason": (
            f"explicitly declared in PR body; matches one of the {len(sorted_candidates)} candidate "
            f"contracts implied by changed paths ({', '.join(sorted_candidates)})."
        ),
    }


def extract_gap_id(branch: str, pr_body: str) -> str:
    match = re.search(r"gap[-_]([a-z0-9][a-z0-9-]*)", branch or "", re.I)
    if match:
        return match.group(1)
    match = re.search(r"\bgap:([a-z0-9][a-z0-9-]*)", pr_body or "", re.I)
    return match.group(1) if match else ""


def load_events(path: Path) -> list[dict[str, Any]]:
    """Mirrors scripts/monitoring/eos-telemetry-summary.py's event/attribute field
    naming intentionally, so both tools agree on what a "tool" or "category" is."""
    events: list[dict[str, Any]] = []
    if not path.is_file():
        return events
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        if not line.strip():
            continue
        try:
            record = json.loads(line)
        except Exception:
            continue
        if isinstance(record, dict):
            events.append(record)
    return events


def attr(record: dict[str, Any], key: str, default: str = "") -> str:
    value = record.get("attributes")
    if not isinstance(value, dict):
        return default
    return str(value.get(key, default) or default)


def telemetry_summary(telemetry_path: Path) -> dict[str, Any]:
    events = load_events(telemetry_path)
    if not events:
        return {"telemetry_available": False, "telemetry_events_count": 0}
    tools = Counter(attr(e, "eos.tool.name", "unknown") for e in events)
    categories = Counter(attr(e, "eos.tool.command.category", "none") for e in events)
    mcp_tools = Counter({name: count for name, count in tools.items() if name.startswith("mcp__")})
    return {
        "telemetry_available": True,
        "telemetry_events_count": len(events),
        "telemetry_tool_counts": dict(tools),
        "telemetry_command_category_counts": dict(categories),
        "telemetry_mcp_tool_counts": dict(mcp_tools),
    }


def ci_metadata(ci_json_path: Path | None) -> dict[str, Any]:
    data, unavailable = load_json_file(ci_json_path)
    checks: list[dict[str, str]] = []
    if not unavailable and isinstance(data, list):
        for item in data:
            if isinstance(item, dict):
                checks.append({
                    "name": str(item.get("name") or item.get("workflow") or "unknown"),
                    "conclusion": str(item.get("conclusion") or item.get("state") or item.get("status") or "unknown"),
                })
    failure_count = sum(1 for c in checks if c["conclusion"].lower() in FAILING_CONCLUSIONS)
    return {
        "ci_metadata_unavailable": unavailable,
        "ci_checks": checks,
        "ci_checks_count": len(checks),
        "ci_failure_count": failure_count,
    }


def review_metadata(reviews_json_path: Path | None) -> dict[str, Any]:
    data, unavailable = load_json_file(reviews_json_path)
    if unavailable:
        return {
            "review_metadata_unavailable": True,
            "review_decision": "",
            "review_count": 0,
            "review_state_counts": {},
            "review_summaries": [],
        }

    review_decision = ""
    raw_reviews: list[Any] = []
    if isinstance(data, dict):
        review_decision = str(data.get("reviewDecision") or "")
        candidate = data.get("reviews") or []
        raw_reviews = candidate if isinstance(candidate, list) else []
    elif isinstance(data, list):
        raw_reviews = data

    summaries: list[dict[str, str]] = []
    states = Counter()
    for item in raw_reviews:
        if not isinstance(item, dict):
            continue
        state = str(item.get("state") or item.get("reviewState") or "unknown")
        submitted_at = str(item.get("submittedAt") or item.get("submitted_at") or "")
        author = item.get("author")
        if isinstance(author, dict):
            author_value = str(author.get("login") or author.get("name") or "")
        else:
            author_value = str(author or "")
        states[state] += 1
        summaries.append({
            "state": state,
            "submitted_at": submitted_at,
            "author_hash": stable_hash(author_value) if author_value else "",
        })

    return {
        "review_metadata_unavailable": False,
        "review_decision": review_decision,
        "review_count": len(summaries),
        "review_state_counts": dict(sorted(states.items())),
        "review_summaries": summaries,
    }


def build_summary(record: dict[str, Any]) -> str:
    friction = record["friction_signals"]
    lines = [
        "# Operational Work History Summary",
        "",
        f"PR head SHA: {record['pr_head_sha'] or 'unknown'}",
        f"Checked-out SHA: {record['checked_out_sha'] or 'unknown'}",
        f"Base SHA: {record['base_sha'] or 'unknown'}",
        f"Branch: {record['branch'] or 'unknown'}",
        f"Changed files: {record['changed_files_count']}",
        f"Commits: {record['commits_count']}",
        "",
        "## CI",
        "",
        f"- metadata unavailable: {record['ci_metadata_unavailable']}",
        f"- checks observed: {record['ci_checks_count']}",
        f"- failing checks: {record['ci_failure_count']}",
        "",
        "## Review",
        "",
        f"- metadata unavailable: {record['review_metadata_unavailable']}",
        f"- decision: {record.get('review_decision', '') or 'unknown'}",
        f"- reviews observed: {record.get('review_count', 0)}",
        "",
        "## Telemetry (same-workspace only)",
        "",
        f"- available: {record['telemetry_available']}",
        f"- events: {record.get('telemetry_events_count', 0)}",
        "",
        "## Friction signals",
        "",
        f"- ci_failures: {friction['ci_failures']}",
        f"- repeated_cycle_commits: {friction['repeated_cycle_commits']}",
        f"- ci_metadata_unavailable: {friction['ci_metadata_unavailable']}",
        f"- review_metadata_unavailable: {friction['review_metadata_unavailable']}",
        f"- waiver_mentioned: {friction['waiver_mentioned']}",
        f"- any: {friction['any']}",
        "",
        "## Result-loop contract",
        "",
        f"- required: {record['result_loop_contract']['required']}",
        f"- selection_source: {record['result_loop_contract']['selection_source']}",
        f"- selected_result_loop_contract: {record['result_loop_contract']['selected_result_loop_contract'] or 'none'}",
        f"- validation_status: {record['result_loop_contract']['validation_status']}",
        "",
        "Privacy note: metadata-only. No raw model/user text, file contents, raw shell commands,",
        "raw repository paths, connector payloads, environment values, or credentials/secrets are stored.",
    ]
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=".")
    parser.add_argument("--pr-head-sha", default="")
    parser.add_argument("--base-sha", default="")
    parser.add_argument("--pr-number", default="")
    parser.add_argument("--ci-json", default=None)
    parser.add_argument("--reviews-json", default=None)
    parser.add_argument("--pr-body-file", default=None)
    parser.add_argument("--telemetry-file", default=None)
    parser.add_argument("--out", required=True)
    parser.add_argument("--empty-run", action="store_true")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)

    checked_out_sha = run_git(["git", "rev-parse", "HEAD"], root)
    branch = run_git(["git", "rev-parse", "--abbrev-ref", "HEAD"], root, required=False)
    repo_name = run_git(["git", "rev-parse", "--show-toplevel"], root, required=False)
    repo_name = Path(repo_name).name if repo_name else root.name

    pr_body = ""
    if args.pr_body_file:
        body_path = Path(args.pr_body_file)
        if body_path.is_file():
            pr_body = body_path.read_text(encoding="utf-8", errors="replace")

    raw_files = [] if args.empty_run else changed_files(root, args.base_sha, checked_out_sha)
    raw_commits = [] if args.empty_run else commit_list(root, args.base_sha, checked_out_sha)
    commits = [{"sha": c["sha"], "subject_hash": c["subject_hash"]} for c in raw_commits]

    telemetry_path = Path(args.telemetry_file) if args.telemetry_file else root / ".engineering-os/telemetry/events.jsonl"
    telemetry = telemetry_summary(telemetry_path)

    ci = ci_metadata(Path(args.ci_json) if args.ci_json else None)
    reviews = review_metadata(Path(args.reviews_json) if args.reviews_json else None)

    repeated_cycle_commits = sum(1 for c in raw_commits if FIX_RETRY_REVERT_RE.search(c["subject"]))
    waiver_mentioned = bool(re.search(r"\bwaiver\b", pr_body, re.I))
    friction = {
        "ci_failures": ci["ci_failure_count"],
        "repeated_cycle_commits": repeated_cycle_commits,
        "ci_metadata_unavailable": ci["ci_metadata_unavailable"],
        "review_metadata_unavailable": reviews["review_metadata_unavailable"],
        "waiver_mentioned": waiver_mentioned,
    }
    friction["any"] = any([
        friction["ci_failures"] > 0,
        friction["repeated_cycle_commits"] > 0,
        friction["ci_metadata_unavailable"],
        friction["review_metadata_unavailable"],
        friction["waiver_mentioned"],
    ])

    result_loop_contract = derive_result_loop_contract(raw_files, pr_body, bool(args.empty_run))

    record: dict[str, Any] = {
        "schema_version": SCHEMA_VERSION,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "pr_head_sha": args.pr_head_sha,
        "checked_out_sha": checked_out_sha,
        "base_sha": args.base_sha,
        "branch": branch,
        "repo": repo_name,
        "pr_number": args.pr_number,
        "gap_id": extract_gap_id(branch, pr_body),
        "empty_run": bool(args.empty_run),
        "changed_files_count": len(raw_files),
        **path_metadata(raw_files),
        "commits": commits,
        "commits_count": len(commits),
        **ci,
        **reviews,
        **telemetry,
        "friction_signals": friction,
        "result_loop_contract": result_loop_contract,
        "privacy_contract": "metadata-only",
    }

    (out_dir / "latest.json").write_text(json.dumps(record, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    (out_dir / "latest-summary.md").write_text(build_summary(record), encoding="utf-8")
    print(f"wrote {out_dir / 'latest.json'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
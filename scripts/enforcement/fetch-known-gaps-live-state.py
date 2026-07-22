#!/usr/bin/env python3
"""Fetch a safe normalized GitHub snapshot for canonical known-gap live-state claims."""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

CLAIMS_SCHEMA = "eos.known-gaps-live-claims.v1"
SNAPSHOT_SCHEMA = "eos.known-gaps-live-snapshot.v1"
DEFAULT_API_URL = "https://api.github.com"
DEFAULT_API_VERSION = "2022-11-28"
REPO_RE = re.compile(r"^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")
SHA_RE = re.compile(r"^[0-9a-f]{40}$")


class FetchError(Exception):
    """Raised when live metadata cannot be fetched or normalized safely."""


def _load_claims(path: Path) -> list[dict[str, Any]]:
    try:
        with path.open(encoding="utf-8") as handle:
            root = json.load(handle)
    except FileNotFoundError as exc:
        raise FetchError(f"missing claims file: {path}") from exc
    except json.JSONDecodeError as exc:
        raise FetchError(f"invalid claims JSON at line {exc.lineno}: {exc.msg}") from exc
    if not isinstance(root, dict) or root.get("schema_version") != CLAIMS_SCHEMA:
        raise FetchError(f"claims schema_version must be {CLAIMS_SCHEMA!r}")
    claims = root.get("claims")
    if not isinstance(claims, list) or not claims:
        raise FetchError("claims must be a non-empty array")
    normalized: list[dict[str, Any]] = []
    seen: set[str] = set()
    for index, raw in enumerate(claims):
        if not isinstance(raw, dict):
            raise FetchError(f"claims[{index}] must be an object")
        claim_id = raw.get("claim_id")
        repository = raw.get("repository")
        pull_number = raw.get("pull_number")
        base_branch = raw.get("base_branch")
        head_sha = raw.get("expected_head_sha")
        merge_sha = raw.get("expected_merge_commit_sha")
        if not isinstance(claim_id, str) or not claim_id.strip():
            raise FetchError(f"claims[{index}].claim_id must be non-empty")
        if claim_id in seen:
            raise FetchError(f"duplicate claim_id {claim_id}")
        seen.add(claim_id)
        if not isinstance(repository, str) or not REPO_RE.fullmatch(repository):
            raise FetchError(f"claims[{index}].repository must use owner/repo form")
        if isinstance(pull_number, bool) or not isinstance(pull_number, int) or pull_number <= 0:
            raise FetchError(f"claims[{index}].pull_number must be a positive integer")
        if not isinstance(base_branch, str) or not base_branch or any(
            char.isspace() for char in base_branch
        ):
            raise FetchError(f"claims[{index}].base_branch is invalid")
        if not isinstance(head_sha, str) or not SHA_RE.fullmatch(head_sha):
            raise FetchError(f"claims[{index}].expected_head_sha is invalid")
        if not isinstance(merge_sha, str) or not SHA_RE.fullmatch(merge_sha):
            raise FetchError(f"claims[{index}].expected_merge_commit_sha is invalid")
        normalized.append(
            {
                "claim_id": claim_id,
                "repository": repository,
                "pull_number": pull_number,
                "base_branch": base_branch,
                "expected_head_sha": head_sha,
                "expected_merge_commit_sha": merge_sha,
            }
        )
    return normalized


def _parse_next_link(link_header: str | None) -> str | None:
    if not link_header:
        return None
    for item in link_header.split(","):
        parts = [part.strip() for part in item.split(";")]
        if len(parts) < 2:
            continue
        url_part = parts[0]
        relations = parts[1:]
        if 'rel="next"' not in relations:
            continue
        if url_part.startswith("<") and url_part.endswith(">"):
            return url_part[1:-1]
    return None


class GitHubClient:
    def __init__(
        self,
        *,
        api_url: str,
        token: str | None,
        api_version: str,
        timeout: float,
        retries: int,
    ) -> None:
        parsed = urllib.parse.urlparse(api_url)
        if parsed.scheme != "https" or not parsed.netloc:
            allow_local = os.environ.get("EOS_ALLOW_INSECURE_LOCAL_GITHUB_API") == "1"
            is_local = parsed.scheme == "http" and parsed.hostname in {"127.0.0.1", "localhost"}
            if not (allow_local and is_local):
                raise FetchError("GitHub API URL must be HTTPS")
        self.api_url = api_url.rstrip("/")
        self.timeout = timeout
        self.retries = retries
        self.headers = {
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": api_version,
            "User-Agent": "engineering-os-known-gaps-live-state/1",
        }
        if token:
            self.headers["Authorization"] = f"Bearer {token}"

    def _request(self, url: str) -> tuple[Any, dict[str, str]]:
        last_error: Exception | None = None
        for attempt in range(self.retries + 1):
            request = urllib.request.Request(url, headers=self.headers, method="GET")
            try:
                with urllib.request.urlopen(request, timeout=self.timeout) as response:
                    payload = response.read()
                    try:
                        data = json.loads(payload.decode("utf-8"))
                    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
                        raise FetchError(
                            f"GitHub API returned invalid JSON for {urllib.parse.urlparse(url).path}"
                        ) from exc
                    return data, {key.lower(): value for key, value in response.headers.items()}
            except urllib.error.HTTPError as exc:
                path = urllib.parse.urlparse(url).path
                retryable = exc.code == 429 or 500 <= exc.code <= 599
                if not retryable or attempt >= self.retries:
                    raise FetchError(f"GitHub API HTTP {exc.code} for {path}") from exc
                last_error = exc
                delay = min(2 ** attempt, 5)
                retry_after = exc.headers.get("Retry-After")
                if retry_after and retry_after.isdigit():
                    delay = min(max(int(retry_after), 1), 5)
                time.sleep(delay)
            except (urllib.error.URLError, TimeoutError) as exc:
                path = urllib.parse.urlparse(url).path
                if attempt >= self.retries:
                    raise FetchError(f"GitHub API transport failure for {path}") from exc
                last_error = exc
                time.sleep(min(2 ** attempt, 5))
        raise FetchError("GitHub API request failed") from last_error

    def get(self, path: str, query: dict[str, Any] | None = None) -> Any:
        encoded_path = "/".join(
            urllib.parse.quote(segment, safe="") for segment in path.strip("/").split("/")
        )
        url = f"{self.api_url}/{encoded_path}"
        if query:
            url = f"{url}?{urllib.parse.urlencode(query)}"
        data, _ = self._request(url)
        return data

    def get_paginated(
        self,
        path: str,
        *,
        list_field: str,
        query: dict[str, Any] | None = None,
        max_pages: int = 20,
    ) -> list[Any]:
        params = dict(query or {})
        params.setdefault("per_page", 100)
        encoded_path = "/".join(
            urllib.parse.quote(segment, safe="") for segment in path.strip("/").split("/")
        )
        url = f"{self.api_url}/{encoded_path}?{urllib.parse.urlencode(params)}"
        items: list[Any] = []
        pages = 0
        while url:
            pages += 1
            if pages > max_pages:
                raise FetchError(
                    f"GitHub API pagination exceeded {max_pages} pages for /{encoded_path}"
                )
            data, headers = self._request(url)
            if not isinstance(data, dict) or not isinstance(data.get(list_field), list):
                raise FetchError(
                    f"GitHub API response for /{encoded_path} lacks array field {list_field!r}"
                )
            items.extend(data[list_field])
            next_url = _parse_next_link(headers.get("link"))
            if next_url and not next_url.startswith(f"{self.api_url}/"):
                raise FetchError("GitHub API pagination returned an unexpected host")
            url = next_url
        return items


def _normalize_workflow_runs(runs: list[Any]) -> list[dict[str, Any]]:
    result: list[dict[str, Any]] = []
    for raw in runs:
        if not isinstance(raw, dict):
            raise FetchError("workflow_runs contains a non-object entry")
        result.append(
            {
                "id": raw.get("id"),
                "name": raw.get("name"),
                "event": raw.get("event"),
                "head_sha": raw.get("head_sha"),
                "status": raw.get("status"),
                "conclusion": raw.get("conclusion"),
                "run_number": raw.get("run_number"),
                "run_attempt": raw.get("run_attempt"),
                "created_at": raw.get("created_at"),
                "updated_at": raw.get("updated_at"),
                "html_url": raw.get("html_url"),
            }
        )
    return result


def _normalize_check_runs(runs: list[Any], *, requested_sha: str) -> list[dict[str, Any]]:
    result: list[dict[str, Any]] = []
    for raw in runs:
        if not isinstance(raw, dict):
            raise FetchError("check_runs contains a non-object entry")
        app = raw.get("app")
        app_slug = app.get("slug") if isinstance(app, dict) else None
        result.append(
            {
                "id": raw.get("id"),
                "name": raw.get("name"),
                "head_sha": requested_sha,
                "status": raw.get("status"),
                "conclusion": raw.get("conclusion"),
                "started_at": raw.get("started_at"),
                "completed_at": raw.get("completed_at"),
                "details_url": raw.get("details_url"),
                "app_slug": app_slug,
            }
        )
    return result


def build_snapshot(claims: list[dict[str, Any]], client: GitHubClient) -> dict[str, Any]:
    entries: list[dict[str, Any]] = []
    for claim in claims:
        repository = claim["repository"]
        pull_number = claim["pull_number"]
        head_sha = claim["expected_head_sha"]
        merge_sha = claim["expected_merge_commit_sha"]
        base_branch = claim["base_branch"]

        pull = client.get(f"repos/{repository}/pulls/{pull_number}")
        if not isinstance(pull, dict):
            raise FetchError(f"pull response for {repository}#{pull_number} must be an object")
        pull_head = pull.get("head")
        pull_base = pull.get("base")
        if not isinstance(pull_head, dict) or not isinstance(pull_base, dict):
            raise FetchError(f"pull response for {repository}#{pull_number} lacks head/base objects")

        pr_runs = client.get_paginated(
            f"repos/{repository}/actions/runs",
            list_field="workflow_runs",
            query={"head_sha": head_sha, "event": "pull_request"},
        )
        push_runs = client.get_paginated(
            f"repos/{repository}/actions/runs",
            list_field="workflow_runs",
            query={"head_sha": merge_sha, "event": "push"},
        )
        check_runs = client.get_paginated(
            f"repos/{repository}/commits/{head_sha}/check-runs",
            list_field="check_runs",
            query={"filter": "all"},
        )
        compare = client.get(f"repos/{repository}/compare/{merge_sha}...{base_branch}")
        if not isinstance(compare, dict):
            raise FetchError(f"compare response for {repository} must be an object")
        merge_base = compare.get("merge_base_commit")
        merge_base_sha = merge_base.get("sha") if isinstance(merge_base, dict) else None

        entries.append(
            {
                "claim_id": claim["claim_id"],
                "repository": repository,
                "pull_number": pull_number,
                "pull": {
                    "state": pull.get("state"),
                    "merged": pull.get("merged"),
                    "head_sha": pull_head.get("sha"),
                    "merge_commit_sha": pull.get("merge_commit_sha"),
                    "base_ref": pull_base.get("ref"),
                    "merged_at": pull.get("merged_at"),
                    "html_url": pull.get("html_url"),
                },
                "base_containment": {
                    "base_branch": base_branch,
                    "status": compare.get("status"),
                    "ahead_by": compare.get("ahead_by"),
                    "behind_by": compare.get("behind_by"),
                    "total_commits": compare.get("total_commits"),
                    "merge_base_sha": merge_base_sha,
                    "html_url": compare.get("html_url"),
                },
                "pull_request_workflow_runs": _normalize_workflow_runs(pr_runs),
                "push_workflow_runs": _normalize_workflow_runs(push_runs),
                "check_runs": _normalize_check_runs(check_runs, requested_sha=head_sha),
            }
        )
    return {
        "schema_version": SNAPSHOT_SCHEMA,
        "generated_at": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "claims": entries,
    }


def _write_json_atomic(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(f".{path.name}.tmp")
    with temporary.open("w", encoding="utf-8") as handle:
        json.dump(data, handle, ensure_ascii=False, indent=2, sort_keys=True)
        handle.write("\n")
    temporary.replace(path)


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Fetch normalized GitHub live-state metadata for known-gap closure claims."
    )
    parser.add_argument("--claims", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--api-url", default=os.environ.get("GITHUB_API_URL", DEFAULT_API_URL))
    parser.add_argument(
        "--api-version", default=os.environ.get("EOS_GITHUB_API_VERSION", DEFAULT_API_VERSION)
    )
    parser.add_argument("--timeout", type=float, default=20.0)
    parser.add_argument("--retries", type=int, default=3)
    parser.add_argument("--require-token", action="store_true")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv or sys.argv[1:])
    if args.timeout <= 0:
        print("known gaps live-state fetch failed: timeout must be positive", file=sys.stderr)
        return 1
    if args.retries < 0 or args.retries > 10:
        print("known gaps live-state fetch failed: retries must be between 0 and 10", file=sys.stderr)
        return 1
    token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
    if args.require_token and not token:
        print("known gaps live-state fetch failed: GITHUB_TOKEN or GH_TOKEN is required", file=sys.stderr)
        return 1
    try:
        claims = _load_claims(args.claims)
        client = GitHubClient(
            api_url=args.api_url,
            token=token,
            api_version=args.api_version,
            timeout=args.timeout,
            retries=args.retries,
        )
        snapshot = build_snapshot(claims, client)
        _write_json_atomic(args.output, snapshot)
    except FetchError as exc:
        print(f"known gaps live-state fetch failed: {exc}", file=sys.stderr)
        return 1
    print(f"known gaps live-state snapshot written: {args.output} ({len(claims)} claim(s))")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

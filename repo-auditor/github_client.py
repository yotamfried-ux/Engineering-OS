from __future__ import annotations

import asyncio
import base64
from fnmatch import fnmatch
from typing import Any

import httpx

_GITHUB_API = "https://api.github.com"
_MAX_FILE_BYTES = 100_000  # skip files larger than 100 KB
_ENTRYPOINTS = ("main", "index", "app", "server", "entry", "cli", "run")


class GitHubClient:
    def __init__(self, token: str) -> None:
        self._headers = {
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
        }

    async def get_repo_meta(self, repo: str) -> dict[str, Any]:
        async with httpx.AsyncClient() as client:
            return await self._get(client, f"/repos/{repo}")

    async def get_repo_tree(self, repo: str) -> list[dict[str, Any]]:
        async with httpx.AsyncClient() as client:
            meta = await self._get(client, f"/repos/{repo}")
            branch = meta.get("default_branch", "main")
            tree_data = await self._get(
                client, f"/repos/{repo}/git/trees/{branch}?recursive=1"
            )
            return [f for f in tree_data.get("tree", []) if f.get("type") == "blob"]

    async def get_file(self, repo: str, path: str) -> str:
        async with httpx.AsyncClient() as client:
            return await self._fetch_file(client, repo, path)

    async def get_files_matching(
        self,
        repo: str,
        patterns: list[str],
        max_files: int = 30,
    ) -> dict[str, str]:
        tree = await self.get_repo_tree(repo)
        matched = [
            f["path"]
            for f in tree
            if any(fnmatch(f["path"], p) for p in patterns)
            and f.get("size", 0) < _MAX_FILE_BYTES
        ]
        matched = _smart_sample(matched, max_files)

        results: dict[str, str] = {}
        async with httpx.AsyncClient() as client:
            tasks = [self._fetch_file(client, repo, p) for p in matched]
            contents = await asyncio.gather(*tasks, return_exceptions=True)
            for path, content in zip(matched, contents):
                if isinstance(content, str):
                    results[path] = content
        return results

    async def get_workflows(self, repo: str) -> dict[str, str]:
        return await self.get_files_matching(
            repo,
            [".github/workflows/*.yml", ".github/workflows/*.yaml"],
            max_files=10,
        )

    async def _fetch_file(self, client: httpx.AsyncClient, repo: str, path: str) -> str:
        try:
            data = await self._get(client, f"/repos/{repo}/contents/{path}")
            if data.get("size", 0) > _MAX_FILE_BYTES:
                return f"[file too large: {data['size']} bytes — skipped]"
            raw = data.get("content", "")
            if data.get("encoding") == "base64":
                return base64.b64decode(raw).decode("utf-8", errors="replace")
            return raw
        except Exception as exc:
            return f"[error fetching {path}: {exc}]"

    async def _get(self, client: httpx.AsyncClient, path: str) -> dict[str, Any]:
        url = f"{_GITHUB_API}{path}"
        for attempt in range(4):
            r = await client.get(url, headers=self._headers, timeout=30)
            if r.status_code in (429, 502, 503):
                await asyncio.sleep(2 ** attempt)
                continue
            r.raise_for_status()
            return r.json()
        r.raise_for_status()
        return {}


def _smart_sample(paths: list[str], max_files: int) -> list[str]:
    if len(paths) <= max_files:
        return paths

    def _priority(p: str) -> int:
        name = p.rsplit("/", 1)[-1].lower().split(".")[0]
        depth = p.count("/")
        if any(name == e for e in _ENTRYPOINTS):
            return 0
        if depth == 0:
            return 1
        if depth == 1:
            return 2
        return depth + 3

    return sorted(paths, key=_priority)[:max_files]

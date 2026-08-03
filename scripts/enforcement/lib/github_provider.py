#!/usr/bin/env python3
"""Fail-closed GitHub REST provider for bypass provenance validation."""
from __future__ import annotations

from dataclasses import dataclass
import json
import os
import socket
import urllib.error
import urllib.parse
import urllib.request
from typing import Any, Mapping


class ProviderError(RuntimeError):
    pass


class _NoRedirect(urllib.request.HTTPRedirectHandler):
    """Reject every redirect.

    urllib's default handler replays the request — including the
    ``Authorization`` header — at the redirect target. The ``api_base`` check
    only constrains the first hop, so following a redirect could hand the
    control or protected token to another host. Redirects fail closed instead.
    """

    def redirect_request(self, req, fp, code, msg, headers, newurl):  # noqa: D102
        raise ProviderError(f"GitHub provider refused an HTTP {code} redirect")


def _path_id(value: Any, label: str) -> int:
    """Coerce a GitHub path ID to int so no caller can inject path segments."""
    if isinstance(value, bool) or not isinstance(value, int):
        raise ProviderError(f"{label} must be an integer path ID")
    if value <= 0:
        raise ProviderError(f"{label} must be a positive path ID")
    return value


@dataclass(frozen=True)
class Response:
    status: int
    headers: Mapping[str, str]
    body: Any


class GitHubProvider:
    MAX_COMMENT_PAGES = 50
    MAX_DEPLOYMENT_STATUS_PAGES = 10

    def __init__(
        self,
        control_token: str,
        protected_token: str,
        *,
        control_repository: str,
        protected_repository: str,
        api_base: str = "https://api.github.com",
        timeout: float = 10.0,
        user_agent: str = "engineering-os-bypass-validator",
    ) -> None:
        if not control_token or not protected_token:
            raise ProviderError("both control and protected repository tokens are required")
        if api_base != "https://api.github.com":
            raise ProviderError("untrusted GitHub API base")
        if timeout <= 0 or timeout > 30:
            raise ProviderError("provider timeout must be between 0 and 30 seconds")
        self.control_token = control_token
        self.protected_token = protected_token
        self.control_repository = control_repository
        self.protected_repository = protected_repository
        self.api_base = api_base.rstrip("/")
        self.timeout = timeout
        self.user_agent = user_agent

    def _token_for(self, full_name: str) -> str:
        if full_name == self.control_repository:
            return self.control_token
        if full_name == self.protected_repository:
            return self.protected_token
        raise ProviderError("provider request attempted an unbound repository")

    @staticmethod
    def _split_repo(full_name: str) -> tuple[str, str]:
        owner, sep, repo = full_name.partition("/")
        if not sep or not owner or not repo or "/" in repo:
            raise ProviderError("invalid repository full name")
        return owner, repo

    def _request(
        self,
        method: str,
        path: str,
        *,
        token: str,
        expected_status: tuple[int, ...] = (200,),
        payload: Any = None,
    ) -> Response:
        if not path.startswith("/") or path.startswith("//"):
            raise ProviderError("provider path must be absolute and relative to api.github.com")
        url = self.api_base + path
        data = None if payload is None else json.dumps(payload, sort_keys=True, separators=(",", ":")).encode("utf-8")
        request = urllib.request.Request(
            url,
            data=data,
            method=method,
            headers={
                "Accept": "application/vnd.github+json",
                "Authorization": f"Bearer {token}",
                "X-GitHub-Api-Version": "2022-11-28",
                "User-Agent": self.user_agent,
                "Content-Type": "application/json",
            },
        )
        opener = urllib.request.build_opener(_NoRedirect)
        try:
            with opener.open(request, timeout=self.timeout) as response:
                raw = response.read()
                status = response.status
                headers = {str(k).lower(): str(v) for k, v in response.headers.items()}
        except (urllib.error.HTTPError, urllib.error.URLError, TimeoutError, socket.timeout, OSError) as exc:
            raise ProviderError(f"GitHub provider request failed closed: {type(exc).__name__}: {exc}") from exc
        if status not in expected_status:
            raise ProviderError(f"unexpected GitHub status {status} for {method} {path}")
        try:
            body = json.loads(raw.decode("utf-8")) if raw else None
        except (UnicodeDecodeError, json.JSONDecodeError) as exc:
            raise ProviderError("GitHub provider returned malformed JSON") from exc
        return Response(status=status, headers=headers, body=body)

    @staticmethod
    def object_body(response: Response, label: str) -> dict[str, Any]:
        if not isinstance(response.body, dict):
            raise ProviderError(f"{label} response must be one JSON object")
        return response.body

    @staticmethod
    def list_body(response: Response, label: str) -> list[Any]:
        if not isinstance(response.body, list):
            raise ProviderError(f"{label} response must be one JSON array")
        return response.body

    def repository(self, full_name: str) -> dict[str, Any]:
        owner, repo = self._split_repo(full_name)
        path = f"/repos/{urllib.parse.quote(owner, safe='')}/{urllib.parse.quote(repo, safe='')}"
        return self.object_body(self._request("GET", path, token=self._token_for(full_name)), "repository")

    def issue_comment(self, full_name: str, comment_id: int) -> dict[str, Any]:
        owner, repo = self._split_repo(full_name)
        path = f"/repos/{urllib.parse.quote(owner, safe='')}/{urllib.parse.quote(repo, safe='')}/issues/comments/{_path_id(comment_id, 'comment_id')}"
        return self.object_body(self._request("GET", path, token=self._token_for(full_name)), "issue comment")

    def collaborator_permission(self, full_name: str, login: str) -> dict[str, Any]:
        owner, repo = self._split_repo(full_name)
        path = f"/repos/{urllib.parse.quote(owner, safe='')}/{urllib.parse.quote(repo, safe='')}/collaborators/{urllib.parse.quote(login, safe='')}/permission"
        return self.object_body(self._request("GET", path, token=self._token_for(full_name)), "collaborator permission")

    def workflow(self, full_name: str, workflow_id: int) -> dict[str, Any]:
        owner, repo = self._split_repo(full_name)
        path = f"/repos/{urllib.parse.quote(owner, safe='')}/{urllib.parse.quote(repo, safe='')}/actions/workflows/{_path_id(workflow_id, 'workflow_id')}"
        return self.object_body(self._request("GET", path, token=self._token_for(full_name)), "workflow")

    def workflow_run(self, full_name: str, run_id: int) -> dict[str, Any]:
        owner, repo = self._split_repo(full_name)
        path = f"/repos/{urllib.parse.quote(owner, safe='')}/{urllib.parse.quote(repo, safe='')}/actions/runs/{_path_id(run_id, 'run_id')}"
        return self.object_body(self._request("GET", path, token=self._token_for(full_name)), "workflow run")

    def issue_comments(self, full_name: str, issue_number: int) -> list[Any]:
        """Return every comment on the issue, traversing all pages."""
        owner, repo = self._split_repo(full_name)
        number = _path_id(issue_number, "issue_number")
        base = f"/repos/{urllib.parse.quote(owner, safe='')}/{urllib.parse.quote(repo, safe='')}/issues/{number}/comments"
        token = self._token_for(full_name)
        collected: list[Any] = []
        for page in range(1, self.MAX_COMMENT_PAGES + 1):
            response = self._request("GET", f"{base}?per_page=100&page={page}", token=token)
            batch = self.list_body(response, "issue comments")
            collected.extend(batch)
            if 'rel="next"' not in response.headers.get("link", ""):
                return collected
        raise ProviderError("issue comment pagination exceeded the supported bound")

    def create_issue_comment(self, full_name: str, issue_number: int, body: str) -> dict[str, Any]:
        if full_name != self.control_repository:
            raise ProviderError("write attempted outside the control repository")
        owner, repo = self._split_repo(full_name)
        path = f"/repos/{urllib.parse.quote(owner, safe='')}/{urllib.parse.quote(repo, safe='')}/issues/{_path_id(issue_number, 'issue_number')}/comments"
        return self.object_body(
            self._request("POST", path, token=self.control_token, expected_status=(201,), payload={"body": body}),
            "created issue comment",
        )

    def create_deployment(
        self,
        full_name: str,
        *,
        ref: str,
        task: str,
        environment: str,
        payload: Mapping[str, Any],
    ) -> dict[str, Any]:
        """Create one immutable provider attempt object in the control repository."""
        if full_name != self.control_repository:
            raise ProviderError("deployment write attempted outside the control repository")
        owner, repo = self._split_repo(full_name)
        path = f"/repos/{urllib.parse.quote(owner, safe='')}/{urllib.parse.quote(repo, safe='')}/deployments"
        body = {
            "ref": ref,
            "task": task,
            "auto_merge": False,
            "required_contexts": [],
            "payload": dict(payload),
            "environment": environment,
            "description": "Engineering OS one-shot bypass authorization attempt",
            "transient_environment": True,
            "production_environment": False,
        }
        return self.object_body(
            self._request("POST", path, token=self.control_token, expected_status=(201,), payload=body),
            "created deployment",
        )

    def deployment_statuses(self, full_name: str, deployment_id: int) -> list[Any]:
        owner, repo = self._split_repo(full_name)
        deployment = _path_id(deployment_id, "deployment_id")
        base = f"/repos/{urllib.parse.quote(owner, safe='')}/{urllib.parse.quote(repo, safe='')}/deployments/{deployment}/statuses"
        token = self._token_for(full_name)
        collected: list[Any] = []
        for page in range(1, self.MAX_DEPLOYMENT_STATUS_PAGES + 1):
            response = self._request("GET", f"{base}?per_page=100&page={page}", token=token)
            batch = self.list_body(response, "deployment statuses")
            collected.extend(batch)
            if 'rel="next"' not in response.headers.get("link", ""):
                return collected
        raise ProviderError("deployment-status pagination exceeded the supported bound")

    def create_deployment_status(
        self,
        full_name: str,
        deployment_id: int,
        *,
        state: str,
        description: str,
        environment: str,
    ) -> dict[str, Any]:
        if full_name != self.control_repository:
            raise ProviderError("deployment-status write attempted outside the control repository")
        if state not in {"success", "failure", "error"}:
            raise ProviderError("unsupported terminal deployment status")
        if not description or len(description) > 140:
            raise ProviderError("deployment-status description must be 1..140 characters")
        owner, repo = self._split_repo(full_name)
        deployment = _path_id(deployment_id, "deployment_id")
        path = f"/repos/{urllib.parse.quote(owner, safe='')}/{urllib.parse.quote(repo, safe='')}/deployments/{deployment}/statuses"
        return self.object_body(
            self._request(
                "POST",
                path,
                token=self.control_token,
                expected_status=(201,),
                payload={
                    "state": state,
                    "description": description,
                    "environment": environment,
                    "auto_inactive": False,
                },
            ),
            "created deployment status",
        )


class FixtureProvider:
    """Deterministic provider used only when a test passes --provider-fixture."""

    def __init__(self, fixture: Mapping[str, Any]) -> None:
        if not isinstance(fixture, dict):
            raise ProviderError("provider fixture must be one JSON object")
        self.fixture = fixture
        self.created_comments: list[dict[str, Any]] = []
        self.created_deployments: list[dict[str, Any]] = []
        self.created_deployment_statuses: list[dict[str, Any]] = []

    @classmethod
    def from_path(cls, path: str) -> "FixtureProvider":
        if os.environ.get("ENGINEERING_OS_BYPASS_TEST_MODE") != "1":
            raise ProviderError("fixture provider is disabled outside explicit test mode")
        try:
            with open(path, encoding="utf-8") as handle:
                value = json.load(handle)
        except (OSError, json.JSONDecodeError) as exc:
            raise ProviderError(f"cannot load provider fixture: {exc}") from exc
        return cls(value)

    def repository(self, full_name: str) -> dict[str, Any]:
        repos = self.fixture.get("repositories")
        value = repos.get(full_name) if isinstance(repos, dict) else None
        if not isinstance(value, dict):
            raise ProviderError(f"fixture repository missing: {full_name}")
        return json.loads(json.dumps(value))

    def issue_comment(self, full_name: str, comment_id: int) -> dict[str, Any]:
        comments = self.fixture.get("comments")
        value = comments.get(str(comment_id)) if isinstance(comments, dict) else None
        if not isinstance(value, dict):
            raise ProviderError(f"fixture comment missing: {comment_id}")
        return json.loads(json.dumps(value))

    def collaborator_permission(self, full_name: str, login: str) -> dict[str, Any]:
        perms = self.fixture.get("permissions")
        key = f"{full_name}:{login}"
        value = perms.get(key) if isinstance(perms, dict) else None
        if not isinstance(value, dict):
            raise ProviderError(f"fixture permission missing: {key}")
        return json.loads(json.dumps(value))

    def workflow(self, full_name: str, workflow_id: int) -> dict[str, Any]:
        workflows = self.fixture.get("workflows")
        key = f"{full_name}:{workflow_id}"
        value = workflows.get(key) if isinstance(workflows, dict) else None
        if not isinstance(value, dict):
            raise ProviderError(f"fixture workflow missing: {key}")
        return json.loads(json.dumps(value))

    def workflow_run(self, full_name: str, run_id: int) -> dict[str, Any]:
        runs = self.fixture.get("runs")
        key = f"{full_name}:{run_id}"
        value = runs.get(key) if isinstance(runs, dict) else None
        if not isinstance(value, dict):
            raise ProviderError(f"fixture run missing: {key}")
        return json.loads(json.dumps(value))

    def issue_comments(self, full_name: str, issue_number: int) -> list[Any]:
        issue_comments = self.fixture.get("issue_comments")
        key = f"{full_name}:{issue_number}"
        value = issue_comments.get(key) if isinstance(issue_comments, dict) else None
        if not isinstance(value, list):
            raise ProviderError(f"fixture issue comments missing: {key}")
        return json.loads(json.dumps(value))

    def create_issue_comment(self, full_name: str, issue_number: int, body: str) -> dict[str, Any]:
        next_id = int(self.fixture.get("next_comment_id", 900000 + len(self.created_comments)))
        created_at = str(self.fixture.get("created_comment_at", "2026-07-26T20:05:00Z"))
        user = self.fixture.get("created_comment_user", {"login": "github-actions[bot]", "id": 41898282, "type": "Bot"})
        created = {
            "id": next_id,
            "body": body,
            "created_at": created_at,
            "updated_at": created_at,
            "issue_url": f"https://api.github.com/repos/{full_name}/issues/{issue_number}",
            "repository_url": f"https://api.github.com/repos/{full_name}",
            "user": user,
        }
        self.created_comments.append(created)
        return json.loads(json.dumps(created))

    def create_deployment(
        self,
        full_name: str,
        *,
        ref: str,
        task: str,
        environment: str,
        payload: Mapping[str, Any],
    ) -> dict[str, Any]:
        responses = self.fixture.get("deployment_responses")
        index = len(self.created_deployments)
        if not isinstance(responses, list) or index >= len(responses) or not isinstance(responses[index], dict):
            raise ProviderError("fixture deployment response missing")
        self.created_deployments.append({
            "repository": full_name,
            "ref": ref,
            "task": task,
            "environment": environment,
            "payload": json.loads(json.dumps(dict(payload))),
        })
        return json.loads(json.dumps(responses[index]))

    def deployment_statuses(self, full_name: str, deployment_id: int) -> list[Any]:
        statuses = self.fixture.get("deployment_statuses")
        key = f"{full_name}:{deployment_id}"
        value = statuses.get(key) if isinstance(statuses, dict) else None
        if not isinstance(value, list):
            raise ProviderError(f"fixture deployment statuses missing: {key}")
        return json.loads(json.dumps(value))

    def create_deployment_status(
        self,
        full_name: str,
        deployment_id: int,
        *,
        state: str,
        description: str,
        environment: str,
    ) -> dict[str, Any]:
        user = self.fixture.get("created_deployment_status_user", {"login": "github-actions[bot]", "id": 41898282, "type": "Bot"})
        next_id = int(self.fixture.get("next_deployment_status_id", 910000 + len(self.created_deployment_statuses)))
        created_at = str(self.fixture.get("created_deployment_status_at", "2026-07-26T20:06:00Z"))
        created = {
            "id": next_id,
            "state": state,
            "description": description,
            "environment": environment,
            "created_at": created_at,
            "updated_at": created_at,
            "deployment_url": f"https://api.github.com/repos/{full_name}/deployments/{deployment_id}",
            "repository_url": f"https://api.github.com/repos/{full_name}",
            "creator": user,
        }
        self.created_deployment_statuses.append(created)
        return json.loads(json.dumps(created))

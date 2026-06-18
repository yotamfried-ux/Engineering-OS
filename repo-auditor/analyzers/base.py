from __future__ import annotations

import json
from dataclasses import dataclass
from typing import TYPE_CHECKING, Literal

import httpx

if TYPE_CHECKING:
    from github_client import GitHubClient

Severity = Literal["CRITICAL", "HIGH", "MEDIUM", "LOW"]
Aspect = Literal["code_quality", "security", "documentation", "cicd", "architecture"]

_NEMOTRON_URL = "https://integrate.api.nvidia.com/v1/chat/completions"
_MODEL = "nvidia/nemotron-ultra-253b-v1"
_SYSTEM_PROMPT = (
    "You are a senior code reviewer. Analyze the provided repository files and return findings "
    "as a JSON array. Each finding must have exactly these keys: "
    '"severity" (CRITICAL|HIGH|MEDIUM|LOW), "title" (string), '
    '"location" (string, e.g. "src/app.py:42" or ""), '
    '"description" (string), "recommendation" (string). '
    "Return ONLY a valid JSON array. No markdown fences, no explanation."
)


@dataclass
class Finding:
    severity: Severity
    aspect: str
    title: str
    location: str
    description: str
    recommendation: str


class BaseAnalyzer:
    aspect: str = ""
    aspect_instructions: str = ""

    def __init__(self, github: GitHubClient, nemotron_key: str) -> None:
        self.github = github
        self.nemotron_key = nemotron_key

    async def analyze(self, repo: str) -> list[Finding]:
        raise NotImplementedError

    async def _call_nemotron(
        self, files: dict[str, str], extra_instructions: str = ""
    ) -> list[Finding]:
        formatted = _format_files(files)
        instructions = extra_instructions or self.aspect_instructions
        user = (
            f"Aspect: {self.aspect}\nRepository files:\n\n{formatted}"
            f"\n\nAnalyze for: {instructions}"
        )
        raw = await self._nemotron_request(user)
        return self._parse_findings(raw)

    async def _nemotron_request(self, user: str) -> str:
        headers = {
            "Authorization": f"Bearer {self.nemotron_key}",
            "Content-Type": "application/json",
        }
        payload = {
            "model": _MODEL,
            "messages": [
                {"role": "system", "content": _SYSTEM_PROMPT},
                {"role": "user", "content": user},
            ],
            "response_format": {"type": "json_object"},
            "temperature": 0.1,
            "max_tokens": 4096,
        }
        for attempt in range(2):
            try:
                async with httpx.AsyncClient(timeout=120) as client:
                    r = await client.post(_NEMOTRON_URL, json=payload, headers=headers)
                    r.raise_for_status()
                    return r.json()["choices"][0]["message"]["content"]
            except Exception as exc:
                if attempt == 0:
                    continue
                return json.dumps([{
                    "severity": "HIGH",
                    "title": "Nemotron analysis failed",
                    "location": "",
                    "description": str(exc),
                    "recommendation": "Re-run the audit or verify Nemotron_api_key.",
                }])
        return "[]"

    def _parse_findings(self, raw: str) -> list[Finding]:
        try:
            data = json.loads(raw)
            if isinstance(data, dict):
                for key in ("findings", "results", "issues", "vulnerabilities"):
                    if key in data and isinstance(data[key], list):
                        data = data[key]
                        break
                else:
                    data = next(iter(data.values()), []) if data else []
            if not isinstance(data, list):
                return []
            out: list[Finding] = []
            for item in data:
                if not isinstance(item, dict):
                    continue
                sev = str(item.get("severity", "LOW")).upper()
                if sev not in ("CRITICAL", "HIGH", "MEDIUM", "LOW"):
                    sev = "LOW"
                out.append(Finding(
                    severity=sev,  # type: ignore[arg-type]
                    aspect=self.aspect,
                    title=str(item.get("title", "Unknown issue")),
                    location=str(item.get("location", "")),
                    description=str(item.get("description", "")),
                    recommendation=str(item.get("recommendation", "")),
                ))
            return out
        except json.JSONDecodeError:
            return [Finding(
                severity="HIGH",
                aspect=self.aspect,
                title="Response parse error",
                location="",
                description=f"Could not parse Nemotron response: {raw[:300]}",
                recommendation="Check Nemotron API response format.",
            )]


def _format_files(files: dict[str, str]) -> str:
    parts = []
    for path, content in files.items():
        truncated = content[:3000] + ("\n[truncated]" if len(content) > 3000 else "")
        parts.append(f"### {path}\n```\n{truncated}\n```")
    return "\n\n".join(parts) if parts else "(no files found)"

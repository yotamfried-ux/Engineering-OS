from __future__ import annotations

import re
from typing import TYPE_CHECKING

from .base import BaseAnalyzer, Finding

if TYPE_CHECKING:
    pass

_SECRET_PATTERNS: list[tuple[re.Pattern[str], str]] = [
    (re.compile(r'(?i)(api[_-]?key|apikey)\s*[=:]\s*["\']([A-Za-z0-9_\-]{20,})["\']'), "Hardcoded API key"),
    (re.compile(r'(?i)(password|passwd|pwd)\s*[=:]\s*["\']([^"\']{6,})["\']'), "Hardcoded password"),
    (re.compile(r'(?i)(secret|token|auth[_-]?token)\s*[=:]\s*["\']([A-Za-z0-9_\-]{20,})["\']'), "Hardcoded secret/token"),
    (re.compile(r'-----BEGIN (RSA |EC |DSA )?PRIVATE KEY-----'), "Private key in source"),
    (re.compile(r'(?i)aws_access_key_id\s*[=:]\s*["\']?AKIA[A-Z0-9]{16}'), "AWS access key"),
]

_SOURCE_PATTERNS = [
    "*.py", "src/**/*.py", "app/**/*.py",
    "*.ts", "*.tsx", "src/**/*.ts",
    "*.js", "*.jsx", "src/**/*.js",
    "requirements*.txt", "package.json", "Pipfile", "Pipfile.lock",
]
_ENV_PATTERNS = [".env", ".env.example", ".env.local", ".env.development"]


class SecurityAnalyzer(BaseAnalyzer):
    aspect = "security"
    aspect_instructions = (
        "Scan for security vulnerabilities including OWASP Top 10: "
        "(1) hardcoded credentials, API keys, passwords, tokens in source code, "
        "(2) SQL injection — string concatenation or f-strings used directly in database queries, "
        "(3) command injection — subprocess/exec calls with unvalidated user input, "
        "(4) XSS — unescaped user input rendered in HTML, "
        "(5) insecure direct object references — resource IDs used without authorization checks, "
        "(6) missing authentication or authorization on sensitive endpoints, "
        "(7) outdated or known-vulnerable dependency versions in requirements.txt or package.json, "
        "(8) path traversal — user-controlled file paths without sanitization. "
        "Assign CRITICAL to exposed credentials and injection vulnerabilities. "
        "HIGH to missing auth and known-CVE dependencies. MEDIUM to lesser vulnerabilities."
    )

    async def analyze(self, repo: str) -> list[Finding]:
        source_files = await self.github.get_files_matching(repo, _SOURCE_PATTERNS, max_files=30)
        env_files = await self.github.get_files_matching(repo, _ENV_PATTERNS, max_files=3)

        quick: list[Finding] = []
        for path, content in {**source_files, **env_files}.items():
            for pattern, title in _SECRET_PATTERNS:
                if pattern.search(content):
                    quick.append(Finding(
                        severity="CRITICAL",
                        aspect=self.aspect,
                        title=f"{title} detected",
                        location=path,
                        description=f"Static analysis found pattern matching '{title.lower()}' in {path}.",
                        recommendation="Move secret to an environment variable or secrets manager immediately. Rotate the exposed credential.",
                    ))

        # Send only source files to Nemotron — never send actual .env values
        safe_files = {
            k: v for k, v in source_files.items()
            if not k.startswith(".env")
        }
        nemotron_findings = await self._call_nemotron(safe_files)

        return quick + nemotron_findings

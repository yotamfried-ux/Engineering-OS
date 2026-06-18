#!/usr/bin/env python3
"""
Security review script using NVIDIA NIM (OpenAI-compatible inference).

Usage:
    git diff HEAD | python security-review-nvidia.py
    python security-review-nvidia.py --diff-file /tmp/diff.txt
    python security-review-nvidia.py --diff-file /tmp/diff.txt --output-json

Environment variables:
    NVIDIA_API_KEY   Required. Starts with nvapi-
    NVIDIA_MODEL     Optional. Default: meta/llama-3.1-70b-instruct
    NVIDIA_BASE_URL  Optional. Default: https://integrate.api.nvidia.com/v1
"""

import argparse
import json
import os
import sys

try:
    from openai import OpenAI
except ImportError:
    print("Error: openai package not installed. Run: pip install openai", file=sys.stderr)
    sys.exit(1)


SYSTEM_PROMPT = """You are a senior security engineer performing a code security review.
Analyze the provided git diff and identify security vulnerabilities.

Focus on:
- OWASP Top 10: injection (SQL, command, LDAP), XSS, IDOR, SSRF, broken auth
- Hardcoded secrets, API keys, passwords, tokens
- Insecure cryptography (weak algorithms, hardcoded salts, MD5/SHA1 for passwords)
- Missing input validation and output encoding
- Insecure direct object references and authorization gaps
- Unsafe deserialization
- Security misconfigurations (open CORS, debug mode, default credentials)
- Path traversal and file inclusion vulnerabilities
- Race conditions in security-sensitive code

For each finding, respond with a JSON array. Each item:
{
  "severity": "CRITICAL" | "HIGH" | "MEDIUM" | "LOW" | "INFO",
  "file": "<filename from diff>",
  "line": <line number or null>,
  "title": "<short title>",
  "description": "<what the vulnerability is and why it is dangerous>",
  "recommendation": "<specific fix or mitigation>"
}

If no security issues are found, return an empty array: []
Respond ONLY with the JSON array. No markdown, no prose."""


def get_diff(args: argparse.Namespace) -> str:
    if args.diff_file:
        with open(args.diff_file) as f:
            return f.read()
    if not sys.stdin.isatty():
        return sys.stdin.read()
    print("Error: provide diff via stdin or --diff-file", file=sys.stderr)
    sys.exit(1)


def run_review(diff: str) -> list[dict]:
    api_key = os.environ.get("NVIDIA_API_KEY")
    if not api_key:
        print("Error: NVIDIA_API_KEY environment variable not set", file=sys.stderr)
        sys.exit(1)

    base_url = os.environ.get("NVIDIA_BASE_URL", "https://integrate.api.nvidia.com/v1")
    model = os.environ.get("NVIDIA_MODEL", "meta/llama-3.1-70b-instruct")

    client = OpenAI(api_key=api_key, base_url=base_url)

    print(f"Running security review with {model}...", file=sys.stderr)

    response = client.chat.completions.create(
        model=model,
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": f"Review this git diff:\n\n{diff}"},
        ],
        max_tokens=4096,
        temperature=0.1,
    )

    content = response.choices[0].message.content.strip()

    try:
        findings = json.loads(content)
        if not isinstance(findings, list):
            raise ValueError("Expected JSON array")
        return findings
    except (json.JSONDecodeError, ValueError) as e:
        print(f"Warning: failed to parse model response as JSON: {e}", file=sys.stderr)
        print(f"Raw response:\n{content}", file=sys.stderr)
        return []


def format_text(findings: list[dict]) -> str:
    if not findings:
        return "✅ No security issues found."

    severity_order = {"CRITICAL": 0, "HIGH": 1, "MEDIUM": 2, "LOW": 3, "INFO": 4}
    findings.sort(key=lambda f: severity_order.get(f.get("severity", "INFO"), 5))

    lines = [f"🔒 Security Review — {len(findings)} finding(s)\n"]
    for i, f in enumerate(findings, 1):
        sev = f.get("severity", "?")
        emoji = {"CRITICAL": "🔴", "HIGH": "🟠", "MEDIUM": "🟡", "LOW": "🔵", "INFO": "⚪"}.get(sev, "⚫")
        lines.append(f"{emoji} [{sev}] {f.get('title', 'Finding')}")
        file_info = f.get("file", "")
        if f.get("line"):
            file_info += f":{f['line']}"
        if file_info:
            lines.append(f"   File: {file_info}")
        lines.append(f"   {f.get('description', '')}")
        lines.append(f"   Fix: {f.get('recommendation', '')}")
        lines.append("")
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="Security review via NVIDIA NIM")
    parser.add_argument("--diff-file", help="Path to diff file (default: stdin)")
    parser.add_argument("--output-json", action="store_true", help="Output raw JSON")
    args = parser.parse_args()

    diff = get_diff(args)
    if not diff.strip():
        print("No diff content to review.", file=sys.stderr)
        sys.exit(0)

    findings = run_review(diff)

    if args.output_json:
        print(json.dumps(findings, indent=2))
    else:
        print(format_text(findings))


if __name__ == "__main__":
    main()

from __future__ import annotations

from collections import Counter
from datetime import datetime

from analyzers.base import Finding

_SEVERITY_ORDER = {"CRITICAL": 0, "HIGH": 1, "MEDIUM": 2, "LOW": 3}
_SEVERITY_ICON = {"CRITICAL": "🔴", "HIGH": "🟠", "MEDIUM": "🟡", "LOW": "🔵"}


def build_report(repo: str, findings: list[Finding]) -> str:
    now = datetime.utcnow().strftime("%Y-%m-%d %H:%M UTC")
    sorted_findings = sorted(
        findings, key=lambda f: _SEVERITY_ORDER.get(f.severity, 9)
    )
    counts = Counter(f.severity for f in findings)

    lines: list[str] = [
        f"# 🔍 Repo Audit: `{repo}`",
        f"*Generated: {now}*",
        "",
        "## Executive Summary",
        "",
        "| Severity | Count |",
        "|----------|-------|",
    ]
    total = 0
    for sev in ("CRITICAL", "HIGH", "MEDIUM", "LOW"):
        n = counts.get(sev, 0)
        total += n
        lines.append(f"| {_SEVERITY_ICON[sev]} **{sev}** | {n} |")
    lines.append(f"| **Total** | **{total}** |")
    lines.append("")

    if not findings:
        lines.append("✅ No issues found.")
        return "\n".join(lines)

    current_sev: str | None = None
    for f in sorted_findings:
        if f.severity != current_sev:
            current_sev = f.severity
            icon = _SEVERITY_ICON[f.severity]
            lines.append(f"---\n\n## {icon} {f.severity}\n")

        lines.append(f"### [{f.aspect}] {f.title}")
        if f.location:
            lines.append(f"**Location:** `{f.location}`  ")
        lines.append(f"**Description:** {f.description}  ")
        lines.append(f"**Recommendation:** {f.recommendation}")
        lines.append("")

    return "\n".join(lines)

# Security agent skills discovered from an Instagram roundup

Discovery source: https://www.instagram.com/reel/DfMyh2EE02e/ (screenshots supplied 2026-11-14).
This is a **discovery shortlist**, not a security ranking, installation profile, or live qualification. GitHub stars and video ranks are not evidence of security effectiveness. Repository identities below were checked against their GitHub repository metadata on 2026-11-14; individual commands, licenses, skill locations, permissions and runtime behavior have **not** been qualified.

## Choose by job

| Need | Candidate / canonical repository | Trust / caveat |
| --- | --- | --- |
| Multi-phase coding-agent security audit | [Cloudflare Security Audit](https://github.com/cloudflare/security-audit-skill) | Tier A upstream; inspect implementation, required access, and output verification before use |
| Security guidance while editing code | [Anthropic Claude plugins official](https://github.com/anthropics/claude-plugins-official) — video labels `security-guidance` | Tier A directory; verify exact plugin availability and version before activation |
| Broad security skills and framework mappings | [Anthropic Cybersecurity Skills](https://github.com/mukul975/Anthropic-Cybersecurity-Skills) | **Tier C community**; despite the name, not an official Anthropic repository; selectively inspect skills |
| Security research and audit workflows | [Trail of Bits skills](https://github.com/trailofbits/skills) | Tier A organization upstream; choose only relevant skill and verify scope |
| AI agent / MCP / skill security scanning | [Snyk agent-scan](https://github.com/snyk/agent-scan) | Tier A upstream; distinct from general application SAST |
| Sentry team's agent skills | [getsentry/skills](https://github.com/getsentry/skills) | Tier A upstream; verify that a `security-review` skill exists and fits target task |
| OWASP-oriented security guidance | [agamm/claude-code-owasp](https://github.com/agamm/claude-code-owasp) | Tier C community, **not** an official OWASP repository; consult OWASP standards independently |
| Agent-facing code security skills | [Semgrep skills](https://github.com/semgrep/skills) | Tier A upstream; verify exact scan workflow, configuration and results |
| Claude Code Security Review | Exact canonical skill/source **unconfirmed from screenshot** | Do not infer official status or activation instructions |
| OpenAI security skill | Exact name and canonical repository **not visible in screenshot** | Identification pending; do not invent a link |

## Selection and verification

1. Route first through [security guidance](../../patterns/security/README.md) and the existing security evidence matrix, rather than making a parallel security gate.
2. Prefer official OWASP guidance for ASVS, Top 10 and test requirements. Skills are helpers, not standards.
3. Check for existing equivalent capabilities (CodeQL, dependency scanners, secret scanning, Semgrep, and project-native tests) before adopting another agent skill.
4. For a chosen candidate, inspect its real repository files and license, supported host, entry point, read/write permissions, credential requirements, installation instructions and overlap. Do not install merely because it appears here.
5. Run a bounded trial on an authorized non-production target. Preserve exact revision, scanner version, findings and manual verification. Report PASS / FAIL / PARTIAL / BLOCKED / NOT TESTED; never claim that a successful tool invocation proves the application secure.
6. Only after qualification should an executable capability receive the normalized registry contract and, where appropriate, an `external-skills/<name>/` wrapper. Never silently add it to `INSTALL-PROFILES.json`.

## Source limitations

The video is a creator's popularity list; positions and star counts are unverified and time-sensitive. Screenshots do not show full configuration or demonstrations. No installation, production scan, penetration test or live tool qualification was performed for this entry.

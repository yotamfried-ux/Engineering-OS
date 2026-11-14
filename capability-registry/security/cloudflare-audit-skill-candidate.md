# Cloudflare Security Audit Skill — multi-agent code review

**Canonical upstream:** https://github.com/cloudflare/security-audit-skill
**Status:** CANDIDATE / NOT INSTALLED / NOT QUALIFIED.

Upstream describes staged reconnaissance, parallel vulnerability hunting, adversarial validation and structured reporting. This is a source-code audit aid, **not** proof of a secure application or a substitute for OWASP ASVS/WSTG and executable security tests.

When evaluating, review agent prompts and executable tools, prompt-injection exposure, secret access, filesystem/network permissions, token budget, false-positive controls and reproducibility. Require findings tied to exact code locations, independently verified exploitability where safe, severity rationale and remediation regression evidence. Never authorize attacks on third-party systems.

If this capability is already cataloged in a different security registry record, deduplicate by canonical upstream before adoption; this candidate does not install it.

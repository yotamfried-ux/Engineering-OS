# PentAGI — autonomous penetration testing candidate

Canonical upstream: https://github.com/vxcontrol/pentagi
Official release history: https://github.com/vxcontrol/pentagi/releases
Status: **CATALOG ONLY / NOT INSTALLED / NOT SECURITY-QUALIFIED** (2026-11-14).

PentAGI is a self-hostable, agent-driven penetration-testing framework. Use as a possible dynamic security-testing backend **only for explicitly authorized assets in a controlled environment**. It is not a security certification and does not replace OWASP ASVS/WSTG, CodeQL, dependency scans, or human review. Do not auto-run against production or third-party infrastructure.

**Critical upstream security note:** release 2.2.0 describes remediation for **CVE-2026-14784**, involving a worker sandbox that could access a host Docker socket in affected configurations. If evaluated, require patched version, explicit container boundary checks, no host Docker socket exposure, network egress allowlist, scoped credentials, hard resource/time/token budgets, logs and kill switch. The upstream release says Docker-in-Docker now needs a separate worker daemon. Verify deployed version and configuration, not only the README.

**Qualification:** isolate disposable test target; review EULA/LICENSE, compose files, privileged capabilities, secrets, network egress, tool execution and AI provider costs; run a harmless representative scan with explicit approval; validate findings independently. Store evidence and residual risks. No live security tests were executed during this cataloging.

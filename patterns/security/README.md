# Software Security Verification

## Principle

No finite test suite proves that software is absolutely secure. Engineering-OS therefore reports **security verification coverage and residual gaps**, never the unconditional claim "secure".

Use standards to define requirements, testing guides to exercise them, and automated/manual tools to collect evidence.

## Canonical stack

### Web/API applications
- **OWASP ASVS 5.0.0** — stable security-control requirements and verification IDs.
- **OWASP WSTG 4.2 stable** — concrete web/API penetration-testing scenarios. Pin versioned scenario IDs.
- **NIST SSDF 1.1** — secure-development and vulnerability-management practices across the lifecycle.

### Mobile
- **OWASP MASVS** — mobile security requirements.
- **OWASP MASTG** — mobile security test cases/techniques.
- **OWASP MASWE** — mobile weakness taxonomy.

### Automated evidence
- **GitHub CodeQL** — SAST/data-flow vulnerability analysis for supported languages.
- **OSV-Scanner** — vulnerable open-source dependency matching.
- **Trivy** — dependency/image vulnerabilities, IaC misconfiguration and secrets.
- **Gitleaks** — secrets in repository history/files.
- **DAST/pentest scenarios** — execute applicable WSTG/MASTG cases against an authorized test target.

## Security layers

A serious qualification should consider, where applicable:
1. requirements/threat model;
2. SAST;
3. dependency/SCA;
4. secret scanning;
5. IaC/container/cloud configuration;
6. authentication;
7. authorization and tenant isolation;
8. session/token handling;
9. input/output/injection;
10. cryptography and sensitive-data storage;
11. SSRF/file/path/deserialization/business-logic boundaries;
12. API/web dynamic testing;
13. mobile platform/storage/network/resilience/privacy;
14. supply-chain/build provenance;
15. security logging/error behavior;
16. remediation + regression tests.

## Reporting

Each requirement/test gets PASS, FAIL, PARTIAL, BLOCKED, NOT TESTED, NOT APPLICABLE or FLAKY, plus evidence, exact revision/environment and source identifier.

A project may say:
> "No known critical/high findings were observed in the executed ASVS/WSTG/CodeQL/SCA/secret/configuration scope on revision X; N requirements remain untested."

It must not turn that into:
> "The software is secure."

## Source versions

- ASVS: pin stable v5.0.0 for production verification.
- WSTG: pin stable v4.2 scenario links; OWASP is developing v5.0.
- NIST SSDF: v1.1 is the current final base publication; Rev.1 / SSDF 1.2 is draft as of this catalog update.
- For tools, record the exact installed scanner/database version at execution time.

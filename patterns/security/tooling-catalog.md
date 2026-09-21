# Security Tooling Catalog

## CodeQL — SAST
Official: GitHub CodeQL/code scanning documentation and `github/codeql`.

Use for supported languages to identify vulnerability/error patterns through CodeQL queries and data-flow analysis. Record language coverage and query suite. A clean CodeQL run is **SAST evidence only**, not proof of overall security.

## OSV-Scanner — SCA
Official: Google OSV-Scanner v2 documentation and `google/osv-scanner`.

It extracts packages from source/images and matches them against vulnerability databases. Record manifests/lockfiles/images actually scanned and vulnerability database freshness.

## Trivy — vuln/config/secret/container
Official: Aqua Trivy documentation and `aquasecurity/trivy`.

Use for applicable filesystem/image vulnerability scanning, IaC misconfiguration checks and secret scanning. Misconfiguration scanning must be explicitly enabled in modes where it is not default.

## Gitleaks — secrets
Official repository: `gitleaks/gitleaks`.

Use repository-history and directory modes as applicable. A clean current-directory scan does not prove history is clean; record which mode/range ran.

## WSTG / MASTG — dynamic/manual
Automated scanners cannot replace authorization/business-logic/session/workflow testing. Map dynamic tests to stable OWASP scenario/test identifiers and preserve exact expected/actual evidence.

## Composition

Prefer overlapping scanners for high-risk surfaces when practical, but deduplicate findings by vulnerability/root cause. Scanner disagreement is investigation input, not a reason to pick the green result.

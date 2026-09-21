# Security Qualification Report

## Identity
Repository:  
Commit:  
Environment/deployment:  
Date:  
Threat model:  
ASVS/WSTG/MASVS versions:  
Tool/database versions:

## Scope
Describe web/API/mobile/CLI/cloud/container surfaces, roles/tenants, external providers, sensitive data and excluded surfaces.

## Automated scans
### SAST
Languages detected / languages scanned / query suite / findings.

### Dependencies
Manifests, lockfiles, images scanned; known-vulnerability findings.

### Secrets
Working tree + history scope; findings and rotations/remediation.

### IaC / containers
Files/images scanned; misconfigurations/vulnerabilities.

## Standards verification
Attach the security evidence matrix with ASVS requirements and applicable WSTG scenarios. For mobile, include MASVS controls mapped to MASTG tests.

## Dynamic/adversarial testing
Record target, account/role, scenario ID, request/action, expected secure behavior, actual behavior and evidence.

## Authorization matrix
Test anonymous, normal user, other user/tenant, privileged role and revoked/expired access where applicable.

## Remediation
Every confirmed vulnerability receives a regression test at the lowest layer that reproduces it, plus a boundary/system test when wiring matters.

## Residual risk
List NOT TESTED, PARTIAL and BLOCKED controls, unsupported scanner languages/frameworks, inaccessible infrastructure and assumptions.

## Conclusion
Do not state absolute security. State observed findings and verification coverage on the exact revision/environment.

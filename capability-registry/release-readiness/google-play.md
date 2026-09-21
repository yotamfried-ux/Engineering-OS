# Google Play Release Readiness

Google Play requirements and Play Console are authoritative vendor gates; this is a workflow wrapper, not a substitute for current Google documentation.

## Before submission
Use current Android/Google Play documentation to verify package/app-bundle requirements, target API and policy requirements, signing, versioning, permissions, privacy/data declarations, store listing assets and testing eligibility applicable at submission time.

## Engineering qualification
Combine:
- release build/install/launch;
- automated unit/integration/UI/device tests;
- Android reference testing patterns;
- MASVS/MASTG + MobSF where applicable;
- dependency/secret/configuration scans;
- accessibility and performance evidence;
- internal/closed testing as required/appropriate;
- Play Console pre-launch report.

## Pre-launch report
Treat Play's device/stability/performance/accessibility/security/privacy findings as additional external evidence. Fix relevant findings and rerun before production submission.

## Freshness rule
Google Play policy and target/API requirements change. Always re-check current official Google documentation at execution time; do not rely solely on this repository snapshot.

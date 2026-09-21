# Project Qualification — Proving What Actually Works

## Goal
A test run should produce an evidence-backed map of the project, not a binary "tests passed" claim. The question is: which user-visible and system capabilities were exercised on this exact revision, at which layer, with which real dependencies, and what remains untested?

## Capability × layer × evidence
Map each capability to required layers: static/build; unit; integration; contract; system/E2E; persistence/side effects; failure/recovery; security/authorization; observability; platform/device.

A capability is VERIFIED only when the layers required by its risk profile have fresh evidence. A passing unit test cannot prove wiring; a UI click cannot prove the intended backend side effect.

## Workflow
1. Discover manifests, tests/runners, CI, routes/jobs, DB schemas, integrations, roles, deploy targets and E2E/mobile flows.
2. Build concrete capability statements such as "owner can approve a submitted video" rather than "approval works".
3. For each capability record expected behavior, required layers, test/simulation, real vs mocked dependencies, assertion target, result, evidence and gaps.
4. Run cheapest to broadest: static/build → unit → integration/contract → E2E/system → failure simulations.
5. For every mutation verify both caller/UI observation and authoritative downstream state.
6. For critical checks use negative controls: a relevant defect/invalid fixture must fail for the expected reason.
7. Report PASS, FAIL, BLOCKED, NOT TESTED, PARTIAL, FLAKY or NOT APPLICABLE. Never turn missing evidence into PASS.

## Evidence quality
High confidence: production-like boundary + external observation + independent side-effect verification. Medium: representative integration with controlled substitutes. Low: mock-only evidence for a cross-boundary capability.

Do not calculate an overall percentage unless the project defines justified weights. Prefer counts by status plus critical gaps.

## Identity/freshness
Every report records repository, exact SHA, working-tree state if known, environment/deployment, timestamp, tool versions and test-account class. Evidence from another SHA/deployment is historical.

## Anti-patterns
- "All tests passed, therefore the app works."
- mocks presented as integration evidence.
- E2E that checks only UI text after a mutation.
- negative tests accepting any error.
- unit tests used as proof of production wiring.
- screenshots without machine assertions where possible.
- retry-until-green with only the green run reported.
- silent skips for missing credentials/devices.
- production user data/write credentials in qualification.

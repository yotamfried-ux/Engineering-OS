# Qualification Report

## Identity
Repository:  
Commit:  
Environment:  
Deployment:  
Started:  
Completed:  
Tool versions:

## Executive status
Do not write "project works" unless every critical capability is PASS at its required layers.

Counts: PASS / FAIL / PARTIAL / BLOCKED / NOT TESTED / FLAKY.

## Capability results
Use capability-matrix.md. Include evidence and distinguish real dependencies from mocks.

## Build/static
Record commands, exit codes and artifacts.

## Unit/integration/contract
Record discovered suites, suites actually executed, pass/fail/skip counts and missing suites. Test count is not capability coverage.

## E2E/simulation
For each journey record preconditions, actions, externally observed result and authoritative side-effect verification.

## Negative/recovery
Record expected failure reason, actual reason, retry/idempotency/recovery observations.

## Security/authorization
Record unauthenticated, cross-user/cross-tenant and role-boundary checks appropriate to the project.

## Observability
Record whether deliberately induced failures appear in expected logs/metrics/traces.

## Untested surface
List every discovered capability/platform without sufficient evidence.

## Failures/blockers
For each: symptom, expected, actual, evidence, likely layer, deterministic/flaky, next investigation.

## Conclusion
State only what evidence supports; explicitly name critical failures and untested surfaces.

# Testing Knowledge Map

This map routes an AI from a testing need to an authoritative method and maintained reference implementation. It complements the project qualification/status model; it does not invent test frameworks.

| Need | Preferred knowledge source | Reference implementation |
|---|---|---|
| Unit / functional | language-native runner; pytest/JUnit/Vitest/Jest docs | official runner repos |
| Integration with DB/cache/queue/service | Testcontainers official docs | official Testcontainers language repos |
| HTTP/message compatibility | Pact official docs | Pact Foundation repos and examples |
| Browser E2E / API+UI | Playwright official docs | microsoft/playwright |
| Mobile E2E | Maestro official docs | mobile-dev-inc/Maestro |
| Deep native mobile automation | Appium official docs | appium/appium |
| Property-based Python | Hypothesis docs | HypothesisWorks/hypothesis |
| Property-based JS/TS | fast-check docs | dubzzz/fast-check |
| Coverage-guided fuzzing/native | LLVM libFuzzer docs / AFL++ docs | AFLplusplus/AFLplusplus; LLVM compiler-rt fuzzing examples |
| Web/API security | OWASP WSTG | OWASP/wstg |
| Load/stress/spike/soak | Grafana k6 docs | grafana/k6 examples |
| Accessibility | axe-core docs / WCAG guidance | dequelabs/axe-core |
| Browser console/network/performance | Chrome DevTools docs | ChromeDevTools/chrome-devtools-mcp |
| Regression | target project's official runner + reproduced defect | project-specific test |
| Build/type/lint/package | toolchain official docs | target project toolchain |
| Database migration/schema | DB vendor docs + real disposable DB | Testcontainers + project migrations |
| Webhooks/events/queues | provider docs + Pact message contracts + real sandbox/broker where safe | Pact examples + provider test fixtures |
| Payments | payment provider official test/sandbox docs + E2E | provider SDK examples + project tests |
| Concurrency/race | runtime/framework official tooling; property/model testing where suitable | target-language tools + fast-check/Hypothesis |
| Failure/recovery/resilience | dependency/provider official failure semantics + real/simulated boundary failures | Testcontainers/Toxiproxy where appropriate + project-specific assertions |
| Observability | observability vendor docs | project-specific synthetic failure checks |
| Visual regression | browser/UI framework official visual-comparison guidance | Playwright screenshot assertions or project's established visual tool |
| Cross-browser | Playwright projects/device/browser docs | microsoft/playwright |
| Cross-device | Maestro/Appium device guidance | official repos |
| API schema | OpenAPI/JSON Schema implementation used by target project | official validator/tool repo |
| CLI | target language runner + process-level assertions | project-specific |
| Files/storage | storage provider emulator/sandbox or real disposable service | provider/Testcontainers patterns |
| AI/LLM behavior | model/provider eval documentation + task-specific datasets and graders | provider eval tooling; never substitute ordinary unit tests for semantic evaluation |

## Selection rules

1. Inspect the project's existing stack and tests before selecting a tool.
2. Prefer its established runner unless an authoritative capability is missing.
3. Use real disposable dependencies for integration evidence when practical.
4. Use contracts for compatibility, not as a replacement for all integration/E2E evidence.
5. Use E2E for critical user journeys, not to replace focused lower-level diagnosis.
6. Add property/fuzz/load/security/accessibility testing only where the project's surfaces make them applicable; do not mechanically run every category.
7. Every local code template must identify its upstream documentation/repository and what was adapted.
8. Every result feeds the capability matrix as PASS/FAIL/PARTIAL/BLOCKED/NOT TESTED/FLAKY, with exact revision and environment.

## Source qualification

A source enters this catalog only if it is an official vendor/framework source, a recognized standards/security project, or a maintained repository whose provenance is recorded. Community snippets are supporting material, never the canonical basis for a reusable testing pattern.

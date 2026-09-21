# Authoritative Testing Sources

This catalog is the source-of-truth policy for testing knowledge in Engineering-OS.

## Rule

Do **not** invent a testing technique, command, assertion pattern, or recommended ratio and present it as canonical. Prefer, in order:

1. official framework/vendor documentation;
2. official project/organization repositories and maintained examples;
3. standards/security organizations;
4. well-maintained reference repositories with provenance recorded.

Local examples must be labeled **adapted example** unless copied from an upstream example under compatible terms. Record the source and the behavior the example is intended to prove.

## Curated sources by test class

| Test class | Primary authoritative source | Reference repository / examples | What it contributes |
|---|---|---|---|
| Browser E2E / component | Playwright docs | `microsoft/playwright` | browser assertions, fixtures, isolation, projects, traces, API + UI testing |
| Mobile E2E | Maestro docs | `mobile-dev-inc/maestro` | black-box Android/iOS flows, device/system interaction |
| Native/device automation | Appium docs | `appium/appium` | WebDriver-based native/mobile automation |
| Integration with real dependencies | Testcontainers docs | `testcontainers/*` official org repos | disposable real DB/queue/service dependencies instead of in-memory mocks |
| API/message contract | Pact docs | `pact-foundation/pact-js` and Pact Foundation org | consumer/provider HTTP and message contracts |
| Property-based JS/TS | fast-check docs | `dubzzz/fast-check` | generated inputs, shrinking, model/race/fuzz extensions |
| Property-based Python | Hypothesis docs | `HypothesisWorks/hypothesis` | generated edge cases, shrinking, stateful/property testing |
| Load/performance | Grafana k6 docs | `grafana/k6`, especially `examples/` | load, protocol/browser performance scenarios and thresholds |
| Web security | OWASP WSTG | `OWASP/wstg` | stable test scenario taxonomy and security-testing methodology |
| Accessibility | axe-core docs | `dequelabs/axe-core` | automated accessibility rules and integration patterns |
| Browser diagnostics | Chrome DevTools docs + Chrome DevTools MCP | `ChromeDevTools/chrome-devtools-mcp` | console/network/performance evidence |
| Regression | framework-native test runner + reproduced bug | project-specific | red-before-fix/green-after-fix evidence; preserve the exact failure semantics |
| Build/static | language/build-tool official docs | project toolchain | compilation, type, lint and packaging evidence |
| Observability verification | project's observability vendor official docs | project-specific | induced failure visible in expected logs/metrics/traces |

## Evidence principles grounded in the sources

- Testcontainers exists specifically to exercise code against real disposable services rather than only mocks.
- Pact distinguishes contract verification from broad brittle end-to-end integration.
- fast-check and Hypothesis add generated-input/property testing and shrinking rather than replacing ordinary runners.
- Maestro drives Android/iOS from the presentation/device layer, so it is suitable for user-journey evidence but does not by itself prove backend persistence.
- OWASP WSTG provides named security-test scenarios; use those scenario IDs where applicable rather than inventing an ad-hoc security checklist.

## Repository-example policy

When adding code examples:
- prefer an official repository example;
- pin the upstream repository and relevant path in the local wrapper;
- explain what was adapted;
- do not imply an example proves more than its assertions observe;
- re-check upstream before major updates because APIs and recommended patterns change.

## Coverage policy

The capability/status framework in `project-qualification.md` remains the reporting model. The *test implementation* for each row must come from the authoritative sources above or the target project's own existing test conventions. Engineering-OS may compose those methods, but should not invent a new test framework.

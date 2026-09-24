# Testing Fast Path

Use this when the task is **write or choose a test**, not when qualifying the whole project.

Read this file first. Open the longer testing docs only when the fast path is insufficient.

## Route

| Need | Default | Escalate when |
|---|---|---|
| Pure logic / transformation | existing language-native unit runner | behavior crosses I/O/process boundaries |
| Bug regression | lowest layer that reproduces the bug | only a higher layer can reproduce it |
| DB/cache/queue/service wiring | integration test with a real disposable dependency | external provider requires sandbox/contract evidence |
| API compatibility | contract/schema test | runtime side effects also matter |
| Web user journey | Playwright | browser internals/perf need Chrome DevTools |
| Mobile user journey | Maestro | deeper native/device control needs Appium/Mobile Next |
| Load/performance | k6 or project-native benchmark | profiling requires runtime/vendor tooling |

Rule: **reuse the project's established runner first**. Do not introduce a new framework when the current one can express the test.

## Copy/adapt skeletons

### TypeScript / Vitest or Jest — unit/regression

Source: Vitest/Jest official docs.

```ts
describe("behavior", () => {
  it("handles the important case", () => {
    const actual = subject(input);
    expect(actual).toEqual(expected);
  });
});
```

For a bug: make this test fail on the broken revision before applying the fix.

### Python / pytest — unit/regression

Source: pytest official docs.

```py
def test_behavior():
    actual = subject(input_value)
    assert actual == expected
```

Prefer parametrization for meaningful input classes rather than duplicate tests.

### Integration — real disposable dependency

Source: Testcontainers official docs and language-specific package docs.

```text
arrange: start disposable dependency + seed minimal state
act: call the real adapter/repository/service
assert: read authoritative state back from that dependency
cleanup: container/transaction/fixture teardown
```

Do not call a mocked database an integration test.

### API/contract

Source: Pact/OpenAPI/JSON Schema implementation used by the project.

```text
given: provider state / schema
when: consumer request or message
then: assert only fields/semantics the consumer depends on
negative control: remove/break one required field and confirm failure
```

### UI/system

Web: Playwright. Mobile: Maestro.

Keep UI assertions for user-visible behavior and separately verify authoritative
backend state for mutations such as payment, upload, approval, delivery or
persistence.

## Minimal decision rule

Choose the **cheapest layer that can falsify the claim**:

1. static/type/build;
2. unit;
3. integration/contract;
4. UI/system;
5. external side-effect evidence.

Do not replace a fast lower-level test with E2E merely because an E2E tool exists.

## Deeper sources

- Patterns and examples: `patterns/testing/README.md`
- Full routing/source map: `patterns/testing/TESTING-KNOWLEDGE-MAP.md`
- Whole-project qualification: `patterns/testing/project-qualification.md`
- Application testing tools: `capability-registry/application-testing/README.md`
- Qualification templates: `templates/testing/`

# Testing Patterns
> See [pattern-lifecycle.md](../../core/pattern-lifecycle.md) for scoring.

## Overview
Apply these patterns whenever you write, review, or refactor tests. The patterns here are language-agnostic and apply to web APIs, UI components, background workers, and CLI tools alike. Prefer these structures as defaults; deviate only with an explicit comment explaining why.

---

## Pattern: Test Pyramid

**Problem:** Suites dominated by slow, brittle E2E tests create long feedback loops and make it hard to pinpoint failures.

**Solution:** Maintain a ratio that favors fast, focused unit tests at the base, integration tests in the middle, and a small number of E2E tests only for critical user journeys at the top.

**Implementation Notes:**
- Aim for roughly 70% unit / 20% integration / 10% E2E. Adjust for your domain (an API gateway shifts weight toward integration).
- Unit tests run in milliseconds and cover pure functions, transformations, and edge cases.
- Integration tests hit real adapters (database, cache, queue) in an isolated environment; use test containers or a local dev stack.
- E2E tests drive the deployed application from outside — they are expensive to write and maintain; reserve them for checkout flows, auth, and other hard-to-mock paths.
- Keep unit and integration tests in CI on every commit; run E2E on merge to main or on a schedule.

**Example:**
```typescript
// Unit test — pure logic, no I/O
describe("calculateDiscount", () => {
  it("applies 10% for orders over $100", () => {
    expect(calculateDiscount(150, "MEMBER")).toBe(15);
  });
  it("returns 0 for orders under threshold", () => {
    expect(calculateDiscount(50, "MEMBER")).toBe(0);
  });
});

// Integration test — real DB connection via test container
describe("OrderRepository.save", () => {
  it("persists an order and returns the generated ID", async () => {
    const repo = new OrderRepository(testDb);
    const id = await repo.save({ userId: "u1", total: 150 });
    const found = await testDb.orders.findUnique({ where: { id } });
    expect(found).not.toBeNull();
  });
});

// E2E test — real browser / HTTP client
test("user can complete checkout", async ({ page }) => {
  await page.goto("/cart");
  await page.click("[data-testid=checkout-btn]");
  await expect(page.locator("[data-testid=success-message]")).toBeVisible();
});
```

**Common Mistakes:**
- Writing integration tests for every unit of logic — makes the suite slow without adding coverage value.
- Mocking the database in integration tests — you are then testing the mock, not the integration.
- Letting E2E tests become the primary regression safety net.

**Security Considerations:**
- E2E test environments should not share credentials with production.
- Scrub any real PII from test fixtures before committing them.

**Testing:**
Measure suite run time by level. If integration tests take longer than 2 minutes or E2E tests exceed 20% of suite time, rebalance.

---

## Pattern: Arrange-Act-Assert (AAA)

**Problem:** Tests without a consistent structure are hard to read, maintain, and diagnose on failure.

**Solution:** Divide every test into three clearly separated phases: set up state (Arrange), invoke the unit under test (Act), and verify the outcome (Assert).

**Implementation Notes:**
- Use blank lines or comments to visually separate the three sections.
- Each test asserts exactly one behaviour. Multiple assertions for one logical outcome are fine; multiple unrelated outcomes in one test are not.
- The Arrange section should use helpers and factories — never inline large data structures.
- The Act section is a single call or interaction. If you need more, the unit is doing too much.

**Example:**
```typescript
describe("UserService.deactivate", () => {
  it("sets status to inactive and clears sessions", async () => {
    // Arrange
    const user = await createTestUser({ status: "active" });
    await createTestSession({ userId: user.id });

    // Act
    await userService.deactivate(user.id);

    // Assert
    const updated = await db.users.findUnique({ where: { id: user.id } });
    const sessions = await db.sessions.findMany({ where: { userId: user.id } });
    expect(updated?.status).toBe("inactive");
    expect(sessions).toHaveLength(0);
  });
});
```

**Common Mistakes:**
- Combining arrange and assert into a single statement — hides intent and makes failures cryptic.
- Putting side effects in the assert phase (e.g., calling the API again inside `expect()`).
- Sharing mutable Arrange state between tests without resetting it — causes order-dependent failures.

**Security Considerations:**
- Do not Arrange real user passwords or API keys — use constant test values that are obviously fake (e.g., `"test-secret-abc"`).

**Testing:**
Review: does the failure message from a broken test immediately tell you which assertion failed and what the actual value was? If not, the AAA split needs tightening.

---

## Pattern: Test Factories & Fixtures

**Problem:** Duplicated, inline test data across hundreds of tests makes maintenance expensive and obscures which properties are actually relevant to each test.

**Solution:** Centralise object creation in factory functions that provide sensible defaults and accept only the properties a given test cares about.

**Implementation Notes:**
- Factories return ready-to-use objects (or insert them into the DB and return the result); callers override only what matters for the test.
- Use `faker` or equivalent for random-but-realistic data to catch edge cases that fixed strings miss.
- Keep factories close to the domain: `createUser`, `createOrder`, `createProduct` — not `createTestObject`.
- For database-backed factories, run them inside a transaction that rolls back after each test, or truncate tables in `afterEach`.

**Example:**
```typescript
import { faker } from "@faker-js/faker";

// factories/user.ts
export async function createTestUser(overrides: Partial<User> = {}): Promise<User> {
  return db.users.create({
    data: {
      email: faker.internet.email(),
      username: faker.internet.username(),
      status: "active",
      role: "member",
      ...overrides,
    },
  });
}

// In a test — only the relevant field is specified
it("rejects login for suspended users", async () => {
  const user = await createTestUser({ status: "suspended" });
  const result = await authService.login(user.email, "password");
  expect(result.error).toBe("account_suspended");
});
```

**Common Mistakes:**
- Hardcoding the same email address in all user factories — causes unique constraint failures when tests run in parallel.
- Creating factories that require a long chain of dependent objects to be set up by the caller.
- Sharing a single factory instance across tests that mutate the returned object.

**Security Considerations:**
- Factories should never call external services or use real API keys — mock or stub at the boundary.

**Testing:**
Verify that calling the same factory twice without overrides produces two distinct, valid records with different generated values.

---

## Pattern: Contract Testing

**Problem:** Integration between services breaks silently when a provider changes its API response shape without updating consumers.

**Solution:** Define a consumer-driven contract that describes the subset of the provider's API the consumer depends on; verify the contract against the real provider in CI.

**Implementation Notes:**
- Use Pact (JavaScript/Python/Go/Java) or a compatible library. The consumer publishes a pact file; the provider verifies it.
- Contracts are not schema validators — they capture only what the consumer actually uses. A provider can add fields freely; removing or renaming fields breaks the contract.
- Publish pact files to a Pact Broker so provider teams can run verification without access to consumer code.
- Run consumer tests on every commit; run provider verification on every provider deploy.

**Example:**
```typescript
// Consumer side — defines what it expects from the Orders API
import { PactV3, MatchersV3 } from "@pact-foundation/pact";

const provider = new PactV3({ consumer: "WebApp", provider: "OrdersAPI" });

describe("OrdersAPI contract", () => {
  it("returns order summary for a valid order ID", async () => {
    await provider
      .given("order 42 exists")
      .uponReceiving("a request for order 42")
      .withRequest({ method: "GET", path: "/orders/42" })
      .willRespondWith({
        status: 200,
        body: {
          id: MatchersV3.integer(42),
          status: MatchersV3.string("shipped"),
          total: MatchersV3.decimal(99.99),
        },
      })
      .executeTest(async (mockServer) => {
        const client = new OrdersClient(mockServer.url);
        const order = await client.getOrder(42);
        expect(order.status).toBe("shipped");
      });
  });
});
```

**Common Mistakes:**
- Writing provider-driven contracts (the provider decides what the consumer gets) — this defeats the purpose.
- Including every field in the contract, not just what the consumer uses — makes contracts fragile to innocent provider additions.
- Skipping broker publication and verifying only locally — provider teams cannot know when they break a contract.

**Security Considerations:**
- Pact files may reveal internal API shapes — treat the broker as an internal tool; do not expose it publicly.

**Testing:**
The contract test must fail when you remove a field from a mock response that the consumer accesses. Confirm provider verification fails against a deliberately broken provider response.

---

## Pattern: Regression Test on Every Bug

**Problem:** Bugs that are fixed without a test tend to reappear — either because the root cause recurs or because a future refactor reintroduces the same mistake.

**Solution:** Before fixing any bug, write a test that reproduces the failure. The test must be red before the fix and green after. Ship the test alongside the fix.

**Implementation Notes:**
- The test description must include the issue/ticket reference so future developers can trace back to the original report.
- Write the test at the lowest level that can reproduce the bug: prefer a unit test if the logic is isolated, integration if it requires the DB or a network call.
- If the bug required a specific sequence of states to reproduce, encode that sequence in the test's Arrange phase.
- After the fix, run the full suite to ensure the new test does not expose hidden regressions elsewhere.

**Example:**
```typescript
// Bug: negative quantities were accepted in cart — ticket #CART-88
describe("Cart.addItem — regression #CART-88", () => {
  it("rejects items with quantity less than 1", () => {
    const cart = new Cart();
    expect(() => cart.addItem({ productId: "p1", quantity: -1 })).toThrow(
      "Quantity must be at least 1"
    );
    expect(() => cart.addItem({ productId: "p1", quantity: 0 })).toThrow(
      "Quantity must be at least 1"
    );
  });

  it("accepts items with quantity of 1 or more", () => {
    const cart = new Cart();
    expect(() => cart.addItem({ productId: "p1", quantity: 1 })).not.toThrow();
  });
});
```

**Common Mistakes:**
- Writing the test after the fix — you cannot confirm it would have caught the original bug.
- Writing a test that passes against the broken code (the test is testing the wrong thing).
- Using a test that is too high-level (e.g., full E2E) for a bug that could be reproduced at the unit level — slows the suite unnecessarily.

**Security Considerations:**
- Security bugs (injection, auth bypass) must get a regression test that proves the exploit path is closed, in addition to any broader audit.

**Testing:**
Check out the commit just before the fix and run only the new regression test — it must fail. Then check out the fix commit and verify it passes.

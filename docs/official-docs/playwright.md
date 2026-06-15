# Playwright — Official Documentation Index

## Official Documentation
**Primary:** https://playwright.dev/docs/intro
**GitHub:** https://github.com/microsoft/playwright
**Changelog:** https://github.com/microsoft/playwright/releases
**API Reference:** https://playwright.dev/docs/api/class-playwright

---

## Key Sections (Recommended Reading Order)

1. [Installation](https://playwright.dev/docs/intro#installing-playwright) — `npm init playwright@latest` scaffolds config, example tests, and GitHub Actions workflow.
2. [Writing Tests](https://playwright.dev/docs/writing-tests) — Understand the `test` / `expect` model and auto-waiting before writing any assertions.
3. [Locators](https://playwright.dev/docs/locators) — The primary selector API; prefer role-based locators (`getByRole`, `getByLabel`) over CSS/XPath.
4. [Page API](https://playwright.dev/docs/api/class-page) — Navigation, input, dialog, and network interception on a single browser tab.
5. [Fixtures](https://playwright.dev/docs/test-fixtures) — How to extend the base `test` object with shared setup/teardown; replaces `beforeEach`/`afterEach` for reusable context.
6. [Test Configuration](https://playwright.dev/docs/test-configuration) — `playwright.config.ts` options: projects, base URL, retries, parallel workers, and reporter selection.
7. [Authentication State](https://playwright.dev/docs/auth) — Save and reuse logged-in browser state with `storageState` to avoid logging in on every test.
8. [Trace Viewer](https://playwright.dev/docs/trace-viewer-intro) — `show-trace` command to inspect network, DOM snapshots, and console logs for failing tests.
9. [CI Integration](https://playwright.dev/docs/ci) — Cached browser binaries, HTML report upload, and shard-based parallel runs on GitHub Actions.

---

## Important APIs / Concepts

- **`page.getByRole()`** — Preferred locator; queries by ARIA role and accessible name — resilient to CSS class changes.
- **`page.getByLabel()`** / **`page.getByPlaceholder()`** — For form inputs; ties tests to visible user-facing text.
- **`page.getByTestId()`** — Use `data-testid` attributes when role/label is ambiguous or unavailable.
- **`expect(locator).toBeVisible()`** — Auto-waiting assertion; retries until the element is visible or the timeout expires.
- **`storageState`** — Serialized cookies + `localStorage`; set in `globalSetup` and passed to browser context for auth reuse.
- **`page.route()`** — Intercept and mock network requests; useful for testing error states without a real backend.
- **`test.use({ storageState })`** — Apply saved auth state to a specific test or test file.
- **`--ui` flag** — `npx playwright test --ui` opens the interactive UI runner for step-through debugging.
- **Trace** — Enable with `trace: 'on-first-retry'` in config; captures screenshots, network, and DOM at each action.

---

## Common Patterns

- E2E test setup with auth — see [patterns/testing/README.md](../../patterns/testing/README.md)
- API mocking in tests — see [patterns/testing/README.md](../../patterns/testing/README.md)

---

## Related External Systems

- see [external-systems/playwright/README.md](../../external-systems/playwright/README.md)

---

## Gotchas & Version Notes

- **Auto-waiting is built in:** Do not add `page.waitForTimeout()` as a workaround for flakiness — find the correct assertion to wait on instead.
- **Locator vs ElementHandle:** `Locator` is lazy and auto-retries; `ElementHandle` is eagerly resolved and fragile. Always use `Locator`.
- **`test.describe.configure({ mode: 'parallel' })`** — Tests within a file run serially by default; opt in to parallel mode explicitly.
- **Browser binary installation:** Browsers are not in `node_modules`; `npx playwright install` must run in CI before test execution.
- **`--shard` for CI speed:** Use `--shard=1/4` across multiple CI jobs; combine HTML reports with `merge-reports` command.
- **v1.40+ `locator.filter()`:** Replaces chained `.nth()` hacks for finding one item within a list based on child content.
- **`page.waitForResponse()` ordering:** Register the route intercept before the action that triggers it, or the response may be missed.

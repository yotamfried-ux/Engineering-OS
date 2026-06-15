# Playwright Examples

## Repository
**URL:** https://github.com/microsoft/playwright
**Owner:** Microsoft
**Purpose:** Official Playwright repository. The `examples/` directory and the broader
test suite demonstrate E2E testing patterns, including auth session fixtures, Page Object
Model structure, network interception, visual regression, and CI/CD integration.

## What to Learn from It
- Page Object Model (POM): encapsulating selectors and actions in reusable classes
- Auth fixture pattern: sign in once, save storage state, reuse across all tests
- Network interception: mocking API responses and asserting outgoing requests
- Parallel test execution: worker configuration and test isolation strategies
- Visual comparison: `toHaveScreenshot()` for pixel-level regression detection
- Trace viewer: capturing and inspecting full test execution traces for debugging
- Component testing: testing React/Vue/Svelte components in isolation without a browser
- CI configuration: GitHub Actions and Docker setup for headless Playwright runs
- Accessibility testing: integrating `@axe-core/playwright` for a11y assertions

## Recommended Sections / Examples
- `examples/` — official quickstart examples including todo-app and GitHub API interaction
- `tests/` — Playwright's own test suite; study for advanced fixture and hook usage
- `docs/src/auth.md` — auth state reuse pattern; most impactful single concept to learn first
- `docs/src/page-object-models.md` — POM design guide with annotated code
- `docs/src/ci.md` — CI configuration matrix for GitHub Actions, GitLab CI, Azure Pipelines
- `docs/src/network.md` — request interception, response mocking, and HAR recording
- `docs/src/test-components.md` — component testing setup and mounting API
- `docs/src/trace-viewer.md` — using the trace viewer to debug flaky tests
- `packages/playwright-test/src/fixtures.ts` — study fixture dependency resolution internals

## Related Patterns
- see [patterns/api/README.md](../../patterns/api/README.md)

## Related Architectures
- see [docs/architecture-guides/](../architecture-guides/)

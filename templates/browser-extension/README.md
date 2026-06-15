# Browser Extension Template

## Overview
Use this template for Chrome and Firefox extensions built on Manifest V3. Suited for developer tools, productivity enhancers, web scrapers, page annotators, and AI-powered browser assistants. The core challenge is Manifest V3's service-worker-based background model (no persistent background pages), strict CSP, and the permission review process required by the Chrome Web Store and Firefox Add-ons store.

## Recommended Architecture Options
- **Content script only** — Simplest; script injected into pages; no background needed for purely in-page tools; limited to page DOM and a subset of extension APIs.
- **Content script + background service worker** — Standard; content script handles DOM, service worker handles API calls, storage sync, and cross-tab state; message passing via `chrome.runtime`.
- **Content script + background + side panel / popup** — Full-featured; add a persistent side panel (Chrome 114+) or popup for rich UI without injecting a large UI into every page.

## Recommended Frameworks & Platforms
| Layer | Options |
|---|---|
| Build tool | WXT (recommended), Plasmo, Vite + CRXJS plugin |
| UI (popup / side panel) | React + Tailwind, Svelte, Vue |
| Content script UI | React shadow DOM, vanilla JS (avoids host page style conflicts) |
| Storage | `chrome.storage.sync` (small, synced), `chrome.storage.local` (larger, device-only), IndexedDB |
| Background logic | Service worker (MV3); no DOM access; keep alive via `chrome.alarms` |
| Messaging | `chrome.runtime.sendMessage` / `chrome.tabs.sendMessage` with typed message schemas |
| Backend (optional) | Any REST API; auth via `chrome.identity` OAuth |
| Testing | Vitest (unit), Playwright (E2E with `--load-extension`) |

## Required Components
- `manifest.json`: `manifest_version: 3`, minimal `permissions`, `host_permissions` scoped to required domains only
- Background service worker: handles API calls, alarm scheduling, cross-tab coordination; must be stateless between wakes
- Content script: injected per `matches` pattern; communicates with background via message passing; uses shadow DOM for injected UI to avoid style leakage
- Popup or side panel: entry point for user settings and on-demand actions; built as a normal web page
- Options page: persistent settings UI; saves to `chrome.storage.sync`
- Storage abstraction: typed wrapper around `chrome.storage` with schema versioning for migrations
- `chrome.alarms`: heartbeat for periodic background tasks (MV3 service workers cannot use `setInterval` reliably)
- Update checker: compare manifest version against a release endpoint; show badge notification on update
- Error boundary: uncaught errors in content scripts caught and reported without crashing host page

## Security Checklist
- [ ] Request only the minimum permissions needed; avoid `<all_urls>` — scope `host_permissions` to exact domains
- [ ] Content Security Policy in manifest disallows `unsafe-inline` and `unsafe-eval`
- [ ] No remote code execution: all scripts bundled; no `eval`, no `innerHTML` with external content
- [ ] API keys and secrets never bundled in extension source — call a backend proxy instead
- [ ] User data in `chrome.storage` encrypted if it contains PII or auth tokens
- [ ] `chrome.identity` OAuth token stored only for the session; not written to `storage.sync`
- [ ] Message listeners validate `sender.id` and `sender.origin` before acting
- [ ] Content script does not expose internal APIs to the host page's JavaScript context
- [ ] Privacy policy URL submitted with store listing before collecting any user data

## Testing Checklist
- [ ] Unit tests for all business logic in background and content modules (Vitest, no browser APIs needed)
- [ ] Message passing integration test: mock `chrome.runtime` with `jest-chrome` or `sinon-chrome`
- [ ] E2E test: load unpacked extension in Playwright, verify content script injects correctly on target URL
- [ ] Storage migration: install old version, upgrade to new, verify data migrated without loss
- [ ] Manifest permissions: confirm extension works after user denies optional permissions
- [ ] Service worker revival: simulate SW termination; verify alarm wakes it and state is restored from storage
- [ ] Firefox compatibility: run on Firefox with `web-ext lint` and `web-ext run`
- [ ] Performance: content script adds < 50 ms to page load on target sites

## Deployment Checklist
- [ ] `web-ext lint` passes with no errors or warnings
- [ ] Extension package built with production flags (no source maps, no debug logging)
- [ ] Version bumped in `manifest.json` before each store submission
- [ ] Screenshots and promotional images prepared at required dimensions (1280×800, 440×280)
- [ ] Privacy policy hosted at a stable public URL and referenced in store listing
- [ ] Permissions justified in store listing "single purpose" description
- [ ] Chrome Web Store developer account has 2FA enabled
- [ ] Automated publish via Chrome Web Store API in CI (optional; requires API key in secret manager)
- [ ] Firefox Add-ons submission prepared separately if cross-browser support required

## Reference Repositories
- [wxt-dev/wxt](https://github.com/wxt-dev/wxt) — Modern Vite-based extension framework with HMR, TypeScript, and MV3 support
- [PlasmoHQ/plasmo](https://github.com/PlasmoHQ/plasmo) — Extension framework with React, automated store publishing, CSUI for shadow DOM injection
- [GoogleChrome/chrome-extensions-samples](https://github.com/GoogleChrome/chrome-extensions-samples) — Official Chrome extension samples for MV3 APIs

## Official Documentation
- [Chrome Extension Docs (MV3)](https://developer.chrome.com/docs/extensions/develop) — Architecture, APIs, service workers, permissions
- [Chrome Web Store Publish Guide](https://developer.chrome.com/docs/webstore/publish) — Submission, review, and update process
- [Firefox Extension Workshop](https://extensionworkshop.com/documentation/develop/) — Firefox-specific MV3 differences and Add-ons store publishing
- [web-ext CLI](https://extensionworkshop.com/documentation/develop/web-ext-technical-reference/) — Build, lint, run, and sign Firefox extensions

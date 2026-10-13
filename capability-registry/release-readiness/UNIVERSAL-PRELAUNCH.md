# Universal pre-launch checklist for *any* public software product

Use this from the first sprint, not the last day. For each requirement, document platform/applicability, owner, exact release revision, test environment, concrete evidence and result; not every item is mandatory for every product.

## 1. Scope and feasibility (before building)

- Product value, intended user, first complete user journey and minimal **meaningful native/product functionality**.
- Markets, languages/RTL, supported OS/browser/device versions, accessibility needs, age group and sector regulations.
- Select release targets: web, Google Play, Apple App Store, desktop package, partner marketplace, enterprise/private. Distinguish each's policies.
- Developer/merchant legal entity, accounts, verification, taxes and banking, publisher contact, support workflow and review access.
- Monetization classification: physical service vs digital good, one-time vs subscription, actual payment platform; check store billing requirements *before* designing checkout.
- Data map: customer fields, user-generated media, device data, trackers, AI vendors, subprocessors, hosting region, deletion/retention.
- Rights: brand, user content, image/font/video/music, OSS dependencies, privacy/terms and accessibility requirements. Specialist approval where needed.

## 2. Product completeness and user experience

- Every advertised store/listing feature works in production-like conditions, not only a prototype or web splash screen.
- Functional paths: first launch → onboarding/permissions (just in time) → login/account recovery → primary value → backend confirmation → repeat use → logout/account management → deletion if required.
- States: empty/loading/errors/conflicts/retries/timeouts/offline/denied permissions/canceled payments/partial uploads; meaningful recovery.
- Real test users including new account, returning account, non-admin, admin and cross-tenant users. Test unauthorized access and data isolation.
- Keyboard/screen-reader/focus/touch/zoom/text scale, language/RTL, dark/light themes and reduced motion as appropriate; no off-screen controls.
- Marketing copy/screenshots reflect **actual current build**; working contact/support and transparent pricing.
- Deep links, app links/universal links, sharing, email-confirmation links, password resets and receipt links work end-to-end.

## 3. Code, build and data quality

- Protected/main branch policy, reviewed PR, reproducible builds, pinned dependencies and release versioning; record artifact hash, commit, signed provenance.
- Static analysis, lint/type tests, unit/integration/contract/E2E with meaningful assertions; no hidden skips. Compare actual backend state after actions.
- Prod/stage separated; correct API keys, project IDs, allowed redirect URIs, domain allowlists, no test server endpoints shipped.
- Database schema migrations tested with backward compatibility and rollback plan; backups AND restore verification.
- Background tasks, notifications, queue retries, upload resumability and idempotency; clean up incomplete artifacts.
- Mobile-specific: signing, package/bundle IDs, target SDK, SDK permissions, memory compatibility, emulator and actual device validation.
- Dependency SCA, supply-chain/license scan, secrets scanning, OWASP ASVS/MASVS according to product, auth/session/tenant permissions and cloud storage restrictions.
- TLS/security headers when relevant, rate limiting, abuse protection, encryption and token rotation, least privilege and environment permissions.
- Crash-free real install/start, reasonable memory/battery, performance, startup speed, network and low-storage stress.

## 4. Law, privacy and safety

- Approved privacy policy & terms on actually reachable URL; point-of-collection disclosures, developer contact, accurate SDK/cookie/advertising and store privacy declarations.
- Separate marketing preference/opt-out where required; consent/withdrawal effective in actual network traffic, not just checkbox visuals.
- Account and personal-data deletion paths consistent with store policies, law and retention exceptions; actual backend and processor workflow tested.
- Age targeting, child safety, UGC reporting/moderation/block, health/finance/AI claims and any local permissions/license if product triggers them.
- Do not equate a scanner PASS with legal compliance, or legal docs presence with proven secure implementation.
- Data handling, exports and backups reviewed to avoid unauthorized secondary copies in telemetry/support and training.

## 5. Publication packaging and visibility

- Production domain with correct DNS/HTTPS, valid trusted certificate, canonical links, redirect rules, robots/noindex intent and Search Console (public web).
- Store metadata: icon, feature graphic/screenshots, localization, category/age ratings, permissions declaration, support and privacy URLs, accurate demo/reviewer access.
- Release notes and external communication prepared; no false promises, copyright/trademark infringement or fake testimonials.
- Store approval gates: Play account/testing eligibility, Apple demo/test account, current SDK/API targets and billing paths.
- CDN cache/invalidation, service worker and mobile update compatibility; test old client against new server.

## 6. Launch control, observability and support

- Named owner can press release, pause staged rollout and roll back; irreversible data migrations need explicit forward-fix/data recovery plan.
- Metrics for availability, error/crash rates, queue depth, auth failures, delivery failures, latency, conversion and business-critical integrity checks.
- Alerts have destinations and escalation; verify alerts with controlled synthetic failure. Traces/logs redact secrets/PII.
- Real recovery and disaster drill, backup restoration, emergency runbook, customer incident messaging and support route.
- Publish in stages where possible, monitor cohort behavior and fix defects before full rollout. Release blocked if monitoring is untested for high-risk flows.
- Run **post-release real-user smoke tests** using safe test accounts. Confirm real production domains, reviewer assets and legal pages remain accessible.

## Release decision

**Block** on: unverified core paid/data-mutating journey, public secrets/customer data, known critical access leak, legally prohibited distribution, materially false privacy/finance/store declaration, nonexistent reviewer access, unsatisfied platform account gates, missing signing or invalid build, broken refund/deletion when required, no operational control of irreversible changes.

For small low-risk projects, establish proportionate evidence and do not add unnecessary certification theater. Carry nonblocking cosmetic issues as documented `PARTIAL` with owner and deadline; no fabricated overall "100% ready".

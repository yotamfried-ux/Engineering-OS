# Pre-launch & publication knowledge — web, Android, iOS and connected products

**Last researched:** 2026-10-13. **Status:** REFERENCE ONLY. Official platform requirements are changeable; verify current publisher rules before every submission. This library gives an AI developer concrete steps, evidence expectations and decision gates. It does **not** automatically obtain store approval, a legal opinion, or production certification.

## Fast routing: use only the path your project needs

| Deliverable | Start here | Then use |
|---|---|---|
| Any public launch, including customer-facing APIs, desktop tools, SaaS, kiosks or apps | [Universal prelaunch gate](UNIVERSAL-PRELAUNCH.md) | [Evidence and launch decision](RELEASE-EVIDENCE-AND-GATES.md), [operating after launch](POST-LAUNCH-OPERATIONS.md) |
| Android app in Google Play | [Google Play approval playbook](GOOGLE-PLAY-SUBMISSION.md) | Existing [Google Play readiness wrapper](google-play.md), [store listing and review package](STORE-LISTING-AND-REVIEW-PACK.md) |
| iPhone/iPad/macOS app in Apple store | [Apple submission playbook](APPLE-APP-STORE-SUBMISSION.md) | [Store review package](STORE-LISTING-AND-REVIEW-PACK.md) |
| Website / public SaaS | [Website launch, Google Search and SEO](WEBSITE-LAUNCH-AND-SEARCH.md) | Universal gate and operations |
| App or site denied publication | [Policy rejection and repair](REJECTION-AND-RECOVERY.md) | Store-specific reviewer evidence and rollback |
| Project-specific checklist to copy into project | [Release evidence template](RELEASE-EVIDENCE-AND-GATES.md) | Existing [project qualification](../../patterns/testing/project-qualification.md) |
| Complex feature: subscription, privacy, analytics, age-restricted, health, financial, video uploads, AI | Store-specific policy + [official source index](OFFICIAL-LAUNCH-SOURCES.md) | Security [patterns](../../patterns/security/README.md), applicable legal review |

**Legal companion:** [PR #298](https://github.com/yotamfried-ux/Engineering-OS/pull/298) adds `docs/legal-compliance/` and is currently a separate, unmerged draft; do **not** assume those paths exist on `main` until merged. Publication documents link official policies and existing technical verification. Likewise [PR #297](https://github.com/yotamfried-ux/Engineering-OS/pull/297) covers enhanced UX/content separately.

## Seven-stage agent process

1. **Choose distribution**: web public / private SaaS / Play / App Store / PWA / direct APK. Identify actual target countries, account type, category, monetization, users' age and data.
2. **Confirm feasibility before building features**: look up applicable current store policies, target SDK, billing, permissions, content, review accounts and regulatory licenses. Some high-risk business models cannot simply be "fixed" in metadata.
3. **Build for the launch environment**: production IDs, entitlements, secrets, domains, storage, access rules, data deletion, billing, emails, URLs; set up deterministic release builds and versioned assets.
4. **Qualify real journeys**: actual install/open/login/core action/backend side effect/offline/errors/account deletion, real tester devices, accessibility, performance, privacy and security.
5. **Prepare publication metadata**: true screenshots, descriptions, labels, privacy/deletion/support links, age/content rating, reviewer credentials, accurate declarations and territories.
6. **Release progressively**: internal/closed beta where applicable, review submission or web canary, error monitoring, user/support escalation, owner-approved promote/rollback.
7. **Maintain compliance & reliability**: reviews, incidents, renewals, policy updates, dependency/SDK changes, product claims and support.

## Output contract for an AI worker

- `release-scope.md`: product/market/platform, account type, store eligibility hypotheses, version/commit, business model.
- `policy-and-declarations.md`: official link, applicable rule, current date, code/evidence and owner; mark unverified items.
- `release-qualification.md`: complete capability × test-layer matrix, actual build/emulator/device, backend side effects, failures and coverage limits.
- `store-review-pack.md` (if stores): store metadata, screenshots, permissions, privacy/Data safety, test account, reviewer route, tax/billing and country settings.
- `release-runbook.md`: release authority, rollout, monitoring alarms, rollback/kill switch, support, data migration/recovery.

Small projects may combine these into one file. **Never simulate a store approval**, click submit using unapproved legal text, or mark backend mocks as real app testing.

## Status vocabulary

- `PASS`: real executed check on exact build with linkable evidence.
- `FAIL`: observed failure requiring action.
- `PARTIAL`: only some required layers or devices validated.
- `BLOCKED`: cannot test or release due to identifiable dependency.
- `NOT TESTED`: no evidence; do not silently convert to PASS.
- `NOT APPLICABLE`: explicitly justified per feature/market.
- `POLICY REVIEW REQUIRED`: regulatory or store-policy interpretation unresolved; a passing unit test does not clear it.

**Approval is a platform decision.** A verified checklist increases submission quality but cannot promise acceptance or SEO ranking.

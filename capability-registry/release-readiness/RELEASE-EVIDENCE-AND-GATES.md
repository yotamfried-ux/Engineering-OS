# Release evidence package, policy decision and go/no-go gate

**Engineering-OS is a knowledge library, not a continuous release runtime.** These are human-readable templates and test criteria; no CI check or store submission is automatically set up just by adding Markdown. Connect to [project qualification](../../patterns/testing/project-qualification.md), [security patterns](../../patterns/security/README.md) and [deployment patterns](../../patterns/deployment/README.md).

## Evidence schema — copy into target project as release-qualification.md

```yaml
product: "<name>"
repository_and_commit: "<actual SHA + clean/diff note>"
distribution: ["web|google_play|apple_app_store|other"]
environment: "<prod-like and actual region>"
release_artifacts:
  android_aab: "<hash and version or N/A>"
  apple_archive: "<hash and SDK or N/A>"
  website_build: "<deployment URL/hash or N/A>"
platform_policy_checked_at: "<date with official URLs>"
target_sdk_and_build_tools: "<as applicable>"
legal_and_privacy_review: "<approved policy revisions/owners or PENDING>"
store_console_status: "<NOT_SUBMITTED|TESTING|SUBMITTED|REJECTED|APPROVED>"
reviewer_access: "<secure reference, NEVER credential>"
testing_evidence:
  unit_integration: "<CI URLs, exact SHA>"
  real_e2e: "<device/browser, test account, network and backend assertion>"
  security_authorization: "<matrix and findings>"
  accessibility_localization: "<scope and result>"
  performance: "<metrics and environment>"
  data_rights_and_permissions: "<actual flows or N/A>"
  store_or_search_validation: "<Play pre-launch/TestFlight/Search Console>"
operational_readiness: "<monitoring alert drill + backup restore + rollback>"
blocking_risks: ["<issue links>"]
untested_scope: ["<explicit gaps>"]
release_decision: "NO_GO|CONDITIONAL_REVIEW|GO"
decision_owner_and_time: "<named authorized human>"
```

## Ten minimum evidence gates

| Check | PASS proof | FAIL / blocker |
|---|---|---|
| 1. Scope | Supported platform/market/audience/monetization/SDK/account types recorded | Unknown store account eligibility for intended release |
| 2. Build | Signed artifact/version/tag matches reviewed repo SHA and tested build | Debug build or unknown AAB/IPA deployed |
| 3. Primary task | Representative installation→core action→authoritative backend outcome captured | Mock-only success, false confirmation, crash, dead UI |
| 4. Recovery | Network loss/duplicate action/permissions denied/error/suspend/resume tested | Data loss, double charge, upload stuck without recovery |
| 5. Security/privacy | Scoped access controls, tenant isolation, SDK data map, leakage scan, legal policy consistency | Known critical leak or materially false disclosure |
| 6. Payment/transaction | Actual method correct for digital vs physical, real pricing and cancellation | Unlawful billing or inaccurate checkout |
| 7. Store/site metadata | Store/website claims, links, screenshots, indexing controls all match release | Missing reviewer credentials or false app description |
| 8. Testing eligibility | Play personal 12-for-14-day status if applicable; Apple test/review access and current SDK | Production track locked or required build policy unmet |
| 9. Operation | Owner-on-call, alerts tested, backups restored, rollback or safe forward-fix | Critical workflow cannot be operated or recovered |
| 10. Owner authorization | Explicit decision tied to build and residual risks | No qualified sign-off for binding legal terms or app submission |

## Status vocab: resist false green

- PASS — observed actual current build/environment with evidence.
- FAIL — reproduced issue; link to blocking finding.
- PARTIAL — exercised a subset of platforms/states/requirements.
- BLOCKED — missing permission, build, device, policy clarification or external dependency.
- NOT TESTED — no evidence, even if expected to work.
- NOT APPLICABLE — justified with actual product scope/market.
- POLICY REVIEW REQUIRED — current platform/territory issue needs specialist determination.

**GO criteria:** no known blocking critical risk, no undisclosed untested critical scope, accurate policies/metadata, actual owner authorization. GO means **ready to submit/deploy** within assessed scope; it is **not** Google or Apple approval and doesn't mean lawsuit-proof.

## Example: booking platform

- Live selected appointment ≠ confirmed reservation; verify server persisted booking ID and exclusivity.
- Authenticated user A can't retrieve B's booking/media even by guessed URL.
- Payment gateway callback reconciled; no double-commit; cancellation/refund flow reflects service contract and platform billing policy.
- Transactional reminders vs marketing separated, correctly subscribed/unsubscribed.
- App store demo account lets reviewer choose sample provider/date and complete a sandbox booking without real user's data.
- Android release AAB/targetSdk/16KB report and Play Console eligibility checked; Apple Xcode SDK and account deletion/review credentials checked.
- Web link shows real 200 canonical pages without staging noindex; confirmation email link points to actual domain.
- Support and data deletion routes work; staging, production and cloud storage remain isolated.

## Hard boundaries for automation

AI may generate drafts, execute authorized non-destructive test builds, populate checklist with evidence, compare requirements and propose fixes. It cannot invent store approval, unilaterally accept legally binding terms, leak access credentials, publish unaudited customer data, or claim legal approval on behalf of counsel. Submit/promote/rollback are controlled by product owner's explicit authorization and actual store access.

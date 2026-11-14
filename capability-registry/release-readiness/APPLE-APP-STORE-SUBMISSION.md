# Apple App Store / TestFlight review-preparation playbook

**Checked against official Apple sources:** 2026-10-13. Apple alone decides App Review results. Read [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) in full for product-specific sections; prioritize **Safety, Performance, Business, Design and Legal**. Also see [official index](OFFICIAL-LAUNCH-SOURCES.md), [review pack](STORE-LISTING-AND-REVIEW-PACK.md) and [universal checklist](UNIVERSAL-PRELAUNCH.md).

## Before coding: decide store model and capabilities

- Confirm active Apple Developer Program membership, correct legal identity / individual vs organization, App Store Connect roles, App ID / Bundle ID ownership, certificates and signing.
- Classify app type: native, cross-platform (Expo/React Native), game, SaaS companion, UGC, account-based, health, finance or AI. Store review checks **actual native usefulness**, accurate behavior and business model.
- Decide if **In-App Purchase is required for digital features** by Apple Guideline 3.1, noting regional entitlements and exceptions. Booking real-world appointments/services may be treated differently from digital subscriptions. Do not implement external payment links until applicable current guidelines + entitlements verified.
- Review age-appropriate content, children, UGC safety and account sign-in rules (e.g. Sign in with Apple when triggered); read actual store sections not remembered slogans.

## Technical build and functional test

| Gate | Implementation / inspection |
|---|---|
| Toolchain | **Since 2026-04-28**, uploaded apps must use **Xcode 26+** and the applicable platform **SDK 26+** (see [Apple minimum requirements](https://developer.apple.com/news/upcoming-requirements/?id=04282026a)); record archive build toolchain |
| Identity | Stable bundle ID, marketing version, build number, release flavor, entitlements, app groups/push keys/provisioning profiles; no dev provisioning or sandbox endpoints shipped |
| Complete experience | Real install on supported iPhone/iPad, cold start, login/recovery, core task, server-side confirmation, network failure/recovery, deep links, permissions, account management |
| iPad/support | If iPad targeted, real adaptive screen, safe area, rotations, multiline text, controls and device screenshots, not scaled-up phone interface only |
| Privacy | App privacy questionnaire includes **all integrated third-party SDK** data; privacy policy URL and in-app access, ATT/tracking permissions if applicable, precise data deletion as Apple 5.1.1 requires |
| User accounts | If account can be created, provide readily discoverable option to **initiate deletion in the app**. Don't replace deletion with deactivation; honor appropriate lawful retention limits. [Review Guidelines §5.1](https://developer.apple.com/app-store/review/guidelines/#privacy) |
| Quality | Avoid crashes, hidden unfinished/beta features, empty pages, nonfunctional links, placeholder images, misleading screenshots, rejected code/design patterns |
| Media/commerce | UGC report/block/moderate capabilities when needed, in-app purchase testing where applicable, export/privacy controls, licensed assets |

## Submission checklist in App Store Connect

1. **Create app record** with app name, Bundle ID, SKU, primary language, supported OS/platform and capabilities. Confirm tax/banking/paid apps agreements where relevant.
2. **Build archive & upload** from supported Xcode/Transporter/CI path. Confirm build processes successfully and matches exactly tested release SHA/artifact; select target version.
3. **App Privacy**: [official manage privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy), working privacy policy URL; all data types and purposes including partners/SDKs; no falsely empty data declaration.
4. **Metadata**: truthful description, name, subtitle, keywords, support & marketing URL as needed, age rating and app availability/pricing. Capture **real in-app screenshots** following [device specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications), localized for supported markets.
5. **Review access**: a nonexpiring demonstration account or fully functional demo mode, instructions for 2FA/permissions, sample content and any hardware/integrations; backend reachable by Apple's reviewers. [Complete review information](https://developer.apple.com/help/app-review/before-submitting-for-review/complete-review/). Store credentials securely; keep them out of repos.
6. **Reviewer notes**: concisely describe new/complex functions (uploads, AI, subscriptions, special account roles), why permissions are necessary, external equipment or reviewer account transitions, sandbox purchases.
7. **TestFlight**: distribute to internal and/or external testers as appropriate; investigate real feedback. External TestFlight distribution may have its own beta review; it is not full production App Store approval.
8. **Submit for review** via [App Store Connect official workflow](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app). Choose auto/manual/phased release based on operational plan. Watch messages; fix specific guideline citations and resubmit.
9. **After approval**: release only with authorized human decision; smoke test production login, backend and IAP/subscription status where relevant. Monitor crashes, reviews, payment/refund, support and API compatibility.

## Common rejection/failure scenarios and repair

| Scenario | What agent must verify |
|---|---|
| Guideline 2.1 incomplete app | Reviewer can use actual production backend and full content; no dead buttons/crash/test-only paywall |
| Guideline 2.3 metadata inaccurate | Screenshots, version, iPad support, advertising and claims match uploaded binary |
| Guideline 3.1 payment | Digital vs real-world service classification, entitlements and IAP behavior; contract/legal review |
| Guideline 4 design/minimum functionality | Native-quality interactive experience, no static wrapper or template spam; usable on all declared devices |
| Guideline 5.1 privacy/deletion | Accurate privacy URL/labels, real accessible deletion, consent and restricted personal data |
| UGC and sensitive user groups | Reporting/blocking/moderation, verified special category documentation |

## Review evidence metadata template

```yaml
platform: app_store
developer_account_status: "<confirmed>"
app_id_bundle_id: "<exact>"
build_sha_archive_id: "<traceable artifact>"
xcode_and_sdk_version: "<actual>"
privacy_labels_review: "PASS|FAIL|NOT_TESTED"
account_deletion: "<tested or N/A>"
app_review_credentials_reference: "<secure location, no secret values>"
metadata_screenshots: "<review links/captures>"
testflight_builds: "<real test links/results>"
iap_model_and_entitlements: "<reviewed>"
store_submission_status: "NOT_SUBMITTED|WAITING_FOR_REVIEW|IN_REVIEW|REJECTED|APPROVED"
human_release_authorization: "<named reviewer/decision>"
```

**Important:** Apple review can reject after all local checks pass; only App Store Connect is authoritative about status. Never auto-publish, invent approvals or copy another app's privacy/review text.

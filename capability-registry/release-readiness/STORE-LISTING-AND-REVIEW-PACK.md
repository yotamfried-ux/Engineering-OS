# Store listing, review credentials, screenshots and declarations

The uploaded binary, public metadata and actual service are reviewed together. All claims must match an exact release SHA; use [Play guide](GOOGLE-PLAY-SUBMISSION.md) or [Apple guide](APPLE-APP-STORE-SUBMISSION.md) for policy-specific rules.

## Publication inventory

Record app name/locales, package or bundle ID, build/version, markets, supported devices, age rating, app category, merchant, prices, feature summary, support contact, public privacy/Terms URLs, real account deletion route, accurate screenshot assets, SDK data inventory and store privacy labels. Record approval owner and revision for every claim.

**Text character limits as of 2026-10-13:** Google Play app name 30 characters, short description 80, full description 4000 (per [Play Console setup](https://support.google.com/googleplay/android-developer/answer/9859152?hl=en)). Apple's app name and subtitle each max 30 characters (see [App information](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information)). Recheck Console before export.

## Graphic assets

- Use screen captures from actual tested build on supported device and with synthetic non-personal fixture data. Never showcase fictional features, fabricated reviews or actual private customers.
- Useful ordering: who the app serves; main workflow; result/confirmation; supporting feature; trustworthy details — every promise backed by implementation.
- Correct screen sizes and assets for actual current target platforms. Apple [screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications) require at least one screenshot and allow up to ten for each relevant device size. Check Apple platform specifics and Google Play Console dimensions at upload time rather than hard-coding stale sizes.
- Confirm Hebrew/RTL or other localization, legible safe-area text, screenshots of premium capabilities only if they're actually available, rights to imagery/fonts/brand assets.
- Save capture provenance: device/OS, application SHA/build, locale, actual screen, date, license/right to use.

## Reviewer access pack — confidential

Never commit credentials, OTP secrets, review tokens or real customer records to GitHub. Provide reviewer credentials directly in Play Console/App Store Connect private review fields, or a permitted controlled secure mechanism.

Document: build version; product audience and core purpose; demo account that remains valid throughout review; step-by-step path to core outcome; test fixtures, 2FA/test phone approach, remote hardware/permissions required, sandbox purchase instructions if applicable, backend availability; location of account deletion, privacy and support; notes on non-obvious or newly changed features.

Review the full journey with a new device login before submission — including a confirmed backend side effect. Do not force reviewers to create real personal data just to reach the advertised core product.

## Review declarations reconciliation

| Topic | Google Play | Apple App Store |
|---|---|---|
| Collected/shared data | Data safety form + public in-app/privacy URLs and third-party SDKs | App Privacy labels + policy URL; include integrated SDKs |
| Account deletion | In-app and external web request for apps supporting in-app account creation | Initiate deletion inside app for apps allowing account creation |
| Ads/age | Ads, target audience, content rating, health and financial declarations as applicable | Age rating, ATT and privacy disclosures where applicable |
| In-app purchases | Play Billing for eligible digital goods subject to current regional exceptions | App Review Guideline 3.1/IAP, geography-specific rights and entitlements |
| Restricted features | Permission declarations including location/contacts/SMS when triggered | Purpose strings/permission gating, age/UGC moderation/regulation where triggered |
| Review login | Play App access instructions | App Store Connect App Review demo account/notes |

## Review-pack example (fill from project truth; NOT a sample credential)

- Build: exact release SHA, app versionCode/build number, .aab/IPA artifact fingerprint.
- Purpose: what the customer can actually do and why they need this app.
- Review steps: launch → sign in with secure stored demo → create example object → confirm on server → manage/delete sample.
- Data: link to reviewed data inventory, real privacy policy, SDK and notice screenshots.
- Permissions: each requested permission, in-app entry point and explanation.
- Payments: digital-vs-physical analysis, real billing integration or not applicable with justification.
- Contacts: functioning support and review contacts.
- Disclosure: known limitations; no blank main screens or unreachable feature paths.

## Exit criteria

Full review pack populated with **real** data, reviewer account tested, store console declarations reconciled with actual network traffic and permissions, owner authorized submission. If one is unknown, mark NOT TESTED or BLOCKED, not approved.

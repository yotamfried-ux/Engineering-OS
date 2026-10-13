# Official launch and app-store policy sources (2026-10-13 snapshot)

This is a **versioned source atlas, not frozen law**. Before submitting an update, verify the official current page and record `checked_at`, `version/deadline`, account/country/OS class, policy interpretation and reviewer. Store/OS requirements can change without a repo update.

| Domain | Official source | Why to consult |
|---|---|---|
| Google Play — account & app setup | [Create/set up your app](https://support.google.com/googleplay/android-developer/answer/9859152?hl=en) | Identity, listing, content, bundles and console setup |
| Google Play — required closed test | [Personal developer testing eligibility](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en) | For personal Play Console accounts created after 2023-11-13: **12 opted-in testers continuously for 14 days**, then apply for production access (2026 snapshot). Not universal for all account classes |
| Google Play — current API | [Target API rules](https://developer.android.com/google/play/requirements/target-sdk) | From **2026-08-31**, regular new apps/updates **API 36+**, Wear/Auto **35+**, TV/XR **34+**; existing-app visibility separate |
| Android — native memory support | [16 KB page sizes](https://developer.android.com/guide/practices/page-sizes) | 64-bit native/SDK compatibility (Android 15+ targets); Google Play 16 KB compatibility and future update enforcement |
| Android — developer ID | [Developer verification rollout](https://developer.android.com/developer-verification/guides) | **2026-09-30** regional enforcement in Brazil, Indonesia, Singapore and Thailand; global expansion announced for 2027 |
| Google Play — privacy/content | [User Data policy](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en) | Public app+console privacy policy, Data safety, deletion in-app and external when account creation |
| Google Play — declarations | [Prepare for app review](https://support.google.com/googleplay/android-developer/answer/9859455?hl=en-EN) | Review account instructions, ads, target audience, content rating, high-risk permissions |
| Google Play — usefulness | [Functionality and user experience policy](https://support.google.com/googleplay/android-developer/answer/9898783?hl=en) | Broken, nonresponsive or near-empty apps are not accepted |
| Google Play — billing | [Google Play Billing](https://developer.android.com/google/play/billing) | Digital vs physical services; check applicable regional alternative-payment programs and policy |
| Google Play — health/financial declarations | [Health declaration](https://support.google.com/googleplay/android-developer/answer/14738291?hl=en), [financial declaration](https://support.google.com/googleplay/android-developer/answer/13849271?hl=en-GB) | Declarations may be needed even if answer is "no features" (app/category scoped) |
| Apple — binding review sections | [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) | Safety, performance, business (including IAP), design/quality, legal, UGC, moderation |
| Apple — build SDK | [2026 minimum SDK notice](https://developer.apple.com/news/upcoming-requirements/?id=04282026a) | Since **2026-04-28**: Xcode **26+** with applicable platform **SDK 26+** for new App Store Connect uploads (see full platform exceptions/specs) |
| Apple — App Store Connect | [ASC Help](https://developer.apple.com/help/app-store-connect/) | Account, signing, screenshots, prices, TestFlight, review status |
| Apple — submission | [Submit an app](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app) | Build/metadata/review steps |
| Apple — review login | [Complete review information](https://developer.apple.com/help/app-review/before-submitting-for-review/complete-review/) | Credentials, reviewer notes and access to all features |
| Apple — data privacy | [Manage app privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy) | Privacy URL and accurate SDK-level data collection / nutrition labels |
| Apple — account deletion | [Guideline 5.1.1(v)](https://developer.apple.com/app-store/review/guidelines/#privacy) | Apps allowing account creation must allow initiation of deletion in-app, with lawful exceptions |
| Apple — screenshots | [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications) | Actual supported devices/dimensions; don't hardcode screenshots for future devices |
| Google Search — eligibility | [Search Essentials](https://developers.google.com/search/docs/essentials), [technical requirements](https://developers.google.com/search/docs/essentials/technical) | Crawlable, 200 success, indexable content; no guarantee of indexing |
| Google Search — sitemaps | [Build/submit sitemap](https://developers.google.com/search/docs/crawling-indexing/sitemaps/build-sitemap) | Canonical URLs, generation and verification |
| Google Search — structured data | [Introduction / rich-result eligibility](https://developers.google.com/search/docs/appearance/structured-data/intro-structured-data) | Use supported schema types, reflect visible truth, test |
| Website UX performance | [web.dev Core Web Vitals](https://web.dev/articles/vitals) | Typical targets LCP ≤2.5 s, INP ≤200 ms, CLS ≤0.1 at p75, field vs lab |
| Web accessibility | [W3C WCAG 2.2](https://www.w3.org/TR/WCAG22/) | Technical criteria; legal threshold differs by market |
| Secure release | [OWASP ASVS](https://owasp.org/www-project-application-security-verification-standard/), [NIST SSDF](https://csrc.nist.gov/pubs/sp/800/218/final) | Risk-focused verification and secure development; not proof of legal clearance |

## Source usage checklist

1. Follow **official vendor version** and current change announcements, not just this snapshot.
2. Classify each as `PLATFORM_POLICY`, `LEGAL_IF_APPLICABLE`, `ENGINEERING_RECOMMENDATION` or `BUSINESS_DECISION`.
3. The developer and target market may change which obligations apply (e.g., old organization account ≠ new personal account, paid digital feature ≠ physical appointment).
4. Record exact checked build, runtime, SDK, Play Console and ASC submission status; do not infer production eligibility from an internal/test track.
5. If policy conflicts with static catalog, prefer official current policy and mark catalog `STALE`; ask domain reviewer for ambiguous interpretations.

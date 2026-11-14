# Google Play submission and approval-preparation playbook (Android)

**Research snapshot:** 2026-10-13; recheck Google sources **on submission day**. Approval is Google Play's decision; this guide describes eligibility and evidence, not a guarantee. Pair with [official policy index](OFFICIAL-LAUNCH-SOURCES.md), existing [google-play.md](google-play.md), [universal gate](UNIVERSAL-PRELAUNCH.md) and [review pack](STORE-LISTING-AND-REVIEW-PACK.md).

## Pre-development feasibility: do this before writing payment/login/media features

1. Confirm Play developer account is verified and in good standing; record personal/organization account type and creation date, verification and target countries. For distribution outside Play, check [Android developer verification](https://developer.android.com/developer-verification/guides) separately.
2. Classify every paid item: **digital in-app entitlement/subscription vs physical goods/services**; Google's [Play Billing](https://developer.android.com/google/play/billing) covers digital goods, with region/program exceptions. A physical haircut/restaurant booking does not automatically need Play Billing, but digital add-ons might. Store billing and legal terms must match implementation.
3. Prove the app is genuinely functional and mobile-appropriate, not a static web shell or broken sign-in flow; [functionality policy](https://support.google.com/googleplay/android-developer/answer/9898783?hl=en).
4. Determine target users/children/health/finance/news/UGC. Identify all dangerous/restricted permissions, ads, sensitive data, third-party SDKs and AI processing before integrating them.

## Build and technical gate

| Gate | Action | Evidence |
|---|---|---|
| Application identity | Stable unique `applicationId`, release name/versionCode increments, correct publisher, production deep links | Manifest/version on exact signed binary |
| Binary packaging | Produce valid signed **Android App Bundle (.aab)** for store releases, enroll/configure Play App Signing and protect upload keys | AAB metadata/signature + Play Console processing; do not publish keystore |
| Target API | For regular Android new submissions/updates since **2026-08-31**: target **Android 16 / API 36+**; Wear OS/Android Automotive **API 35+**; TV/XR **API 34+**. Existing-app discoverability has separate threshold | Gradle/Expo manifest, targetSdk + official [policy](https://developer.android.com/google/play/requirements/target-sdk) checked today |
| Native binary compatibility | Support 16 KB page sizes on 64-bit devices as applicable (especially NDK, graphics/video/Expo native deps); check Play warnings and devices. [Official compatibility guide](https://developer.android.com/guide/practices/page-sizes). Google currently announces update enforcement change by **2027-02-01**; use most recent policy before upload | Inspect ELF/NDK dependencies + run compatible 16 KB emulator/device |
| Actual device tests | Cold/warm launch, network changes, gestures, background/resume, low storage, kill/restart, authentication, crash ANR and accessibility | Device model/OS, log-free redacted captures, backed side effects |
| Security & privacy | Sensitive permission minimization, runtime prompt only at relevant feature, RLS/tenant isolation, encrypted transport, no embedded secrets, storage/SDK audit, account deletion where relevant | ASVS/MASVS + network trace + deletion and privacy test |
| Stable services | Production or authorized review backend live; email, media, payments and links functional; no expiring reviewer credentials | Real reviewer test account and E2E evidence |

## Google Play Console — exact submission route

1. **Create app**: [official setup](https://support.google.com/googleplay/android-developer/answer/9859152?hl=en); name, default language, app/game, free/paid choice, support email, declarations and Play App Signing.
2. **Main store listing**: truthful localized title (**up to 30 characters**), short description (**up to 80**) and full description (**up to 4000**) in the current console; screenshots and store assets that depict current real app. Verify current image dimensions/required asset types in console before generating.
3. **App content declarations**: [official prepare review](https://support.google.com/googleplay/android-developer/answer/9859455?hl=en-EN). Accurate app access/reviewer instructions; privacy policy, Data safety, ads, audience/age, content rating, special permissions, health/financial declarations even where 'none' required.
4. **Privacy and deletion**: every app needs publicly accessible non-PDF policy linked in console **and in app**, covering third-party SDK data handling; apps enabling account creation in app need both in-app deletion request and externally accessible deletion request URL, with lawful retention exceptions described. [Official User Data policy](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en). No policy boilerplate invented.
5. **Testing tracks**: start Internal, then Closed for representative testers/edge cases; use real install via Play and pre-launch report findings. If **personal Play developer account created after 2023-11-13**, Google requires **at least 12 continuously opted-in closed testers for at least 14 consecutive days** before applying for production access. [Official requirement](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en). This is **not** universal to existing organization accounts, and reaching day 14 does **not** itself confer production approval.
6. **Apply for production access when required**: answer questions truthfully about target audience, tests, feedback, fixes and readiness; wait for Google decision and resolve any request. Do not treat an internal APK or closed-track green run as publishing approval.
7. **Submit .aab to Production** only after gating: inspect version, release notes, tester rollout, countries/devices, whether managed publishing is set, current policy notices and Play Console dashboard warnings.
8. **Monitor review & rollout**: respond with clear evidence to review findings; use staged rollout, Android vitals and user feedback; halt rollout and submit corrected bundle if needed.

## Account access, permissions and common rejection-prevention

- Reviewer credentials must be non-expiring and allow access to all gated features, plus any sample data or 2FA bypass mechanism that does **not** compromise production accounts. Never put credentials in public issue/PR.
- Crash/freezes, blank screens, broken upload, live backend down or no valuable mobile functionality → test on actual installed release.
- Sensitive permission not essential to a feature or undeclared → remove or explain with just-in-time disclosure and console forms.
- Privacy policy missing/inaccessible, Data safety/SDK mismatch, no account deletion link → verify with anonymous browser plus deletion E2E.
- Listing/screenshots promise functionality not in build, age/rating mismatch, fake screenshots/testimonials, misleading payment terms → verify against release build.
- Advertising/marketing/UGC/financial/health features trigger special rules; no shortcut with generic Terms or disclaimers.
- For app with user-uploaded video/audio: verify media permissions, foreground/background upload handling, copyright, processing/AI provider details and reports/moderation depending on user-generated visibility.

## Store approval evidence sheet

```yaml
platform: google_play
account_type_and_created_at: "<verified, not assumed>"
production_access: "APPROVED|APPLICATION_PENDING|NOT_ELIGIBLE|UNKNOWN"
android_build: "<AAB path/hash/versionCode/targetSdk>"
reviewer_access: "<private secure reference, NEVER password in repo>"
data_safety_checked_against_sdk_scan: "PASS|FAIL|NOT_TESTED"
privacy_policy_url: "<public URL>"
deletion_in_app_and_web: "<tested endpoints/UX or N/A with reason>"
testers_12_for_14d: "<only if new personal account; verified Console evidence>"
prelaunch_report: "<link, finding disposition>"
billing_model_and_policy: "<reviewed>"
release_risk_approval: "<authorized human/status>"
```

**Never claim approved until Play Console explicitly reports approval.** Record review status and target track distinctly.

# Rejection triage and recovery — Google Play, App Store, web visibility

A store rejection is a **decision about a submitted build and metadata**, not proof that an entire codebase is broken. Do not blindly rebuild, resubmit repeatedly or conceal blocked features from review. Gather official rejection notice and exact rule first.

## Procedure

1. Record app ID, build SHA/version, platform, track, reviewer response date, cited guideline/policy, console rejection state, screenshots and reproducible user route. **Do not reproduce credentials/PII publicly.**
2. Classify: (a) technical install/crash/performance, (b) incomplete core task/backend unavailable, (c) metadata/assets mismatch, (d) privacy/deletion/Data safety/ATT/permissions, (e) IAP/financial/child/UGC/regulated feature, (f) test/reviewer account access, (g) developer-account verification/testing eligibility, or (h) disputed policy interpretation.
3. Open the canonical live policy: [Apple guidelines](https://developer.apple.com/app-store/review/guidelines/) or [Google review prep](https://support.google.com/googleplay/android-developer/answer/9859455?hl=en-EN). Confirm whether rule applies to this device/market/app type. Distinguish store enforcement from law.
4. Reproduce defect on the exact rejected production-equivalent binary with test account/real backend. Capture failure evidence and redacted console logs. For rejection based only on missing documentation, document that accurately rather than invent a code defect.
5. Propose smallest compliant fix and regression test; review privacy/billing copy and legal terms with accountable owner. Preserve unrelated product behavior and backwards compatibility.
6. Produce new signed build with incremented version and exact SHA where required; update screenshots, disclosures, rating, store metadata and reviewer notes to match corrected build.
7. Test internal/closed/TestFlight route and the previously rejected exact flow **plus negative cases**, verify authoritative backend effects, then resubmit via official portal.
8. If policy interpretation is materially unclear and compliance is supported by evidence, use official reviewer reply/appeal channels; don't promise an appeal will be granted.

## Reviewer response template (original, edit before submission)

> We reviewed the cited policy and reproduced the issue with build [old version]. In build [new version], we changed [specific behavior] and tested [concrete device + flow + result]. Reviewers can access the affected feature at [steps] using the credentials provided in the private reviewer-access fields. We also updated [store/privacy metadata] to match the actual data behavior. Please see [private appropriate evidence location].

Never send test passwords in a public GitHub issue, or write "fully compliant" without scoped sign-off.

## Class → remedy

| Rejection reason | Focused fix |
|---|---|
| Broken/incomplete app | Working live service, no crash/blank screen, account/test fixtures, release-binary E2E |
| Review cannot sign in | Valid nonexpiring demo, instructions for 2FA/special roles, no IP/device blocking |
| Missing/deceptive metadata | Replace screenshot/description/locale/plan to show exact functionality |
| Privacy/Data safety inaccurate | Audit *all* SDK/network payloads, correct policy and labels, enforce deletion/consent |
| Billing noncompliant | Correct digital-vs-physical classification and current regional billing rules |
| Sensitive permissions | Remove unnecessary scope, use narrower picker/API, declare/disclose necessity |
| Account testing requirement | Obtain closed testers/eligibility and console production-access approval |
| UGC/children/regulated | Add required safeguards and counsel-approved statements or withdraw feature |
| Security / secret leak | Revoke keys, repair authorization, test and investigate incident as needed |
| Website not indexed | Diagnose Crawl/Index status, robots/noindex, 200, canonical, content, Search Console; indexing not guaranteed |

## Never do

- Circumvent review with dormant hidden code/features or different behavior for reviewers vs real customers.
- Claim passing unit tests equals approved store status.
- Reuse a rejected binary and simply change the version string without relevant verified change.
- Alter payment, age, privacy or regulated use model without separate store/legal assessment.
- Collect real reviewer or customer credentials in public logs.

# Cookies, SDK tracking, consent and promotional communications

**Not all apps need a cookie banner.** Consent necessity depends on geography, technology, purpose and exemptions. Mobile SDK IDs, local storage, pixels, advertising tags and device fingerprinting may also be covered. Never auto-install or enable analytics before scope review. Canonical sources: [ICO current technologies guidance](https://ico.org.uk/for-organisations/direct-marketing-and-privacy-and-electronic-communications/guidance-on-the-use-of-storage-and-access-technologies/what-are-storage-and-access-technologies/), [consent implementation](https://ico.org.uk/for-organisations/direct-marketing-and-privacy-and-electronic-communications/guidance-on-the-use-of-storage-and-access-technologies/how-do-we-manage-consent-in-practice/), [electronic marketing](https://ico.org.uk/for-organisations/direct-marketing-and-privacy-and-electronic-communications/guidance-on-direct-marketing-using-electronic-mail/), and relevant Israeli law confirmed by qualified counsel.

## Technology inventory template

| SDK/tag/cookie | Owner/vendor | Data & recipient | Purpose | Essential? why | User geography | Lawful basis / consent trigger | Lifetime | Controlled in production? | Evidence |
|---|---|---|---|---|---|---|---|---|---|
| Session identifier | `<real provider>` | `<scope>` | Auth | Assess technical necessity | `<scope>` | `<review>` | `<verified>` | `<test>` | `<network trace>` |
| Analytics SDK | `<actual>` | `<events/IDs>` | Measurement | Not automatically essential | `<scope>` | `<review>` | `<verified>` | `<test>` | `<network trace>` |
| Ad pixel | `<actual>` | `<device/browsing>` | Advertising | Not essential to requested service | `<scope>` | `<review>` | `<verified>` | `<test>` | `<network trace>` |

**UK** technology requirements can cover mobile apps and devices. For **EU** services assess national ePrivacy implementation plus GDPR; don't transplant UK PECR verbatim. For **Israel** assess privacy/direct-marketing/communications duties according to law and context; don't assert "all Israeli websites must show a cookie banner."

## Consent manager: behavioral requirements when consent is required

1. Prior to optional device access/SDK firing, show concise purposes and meaningful granular choices: essential, analytics, personalization, marketing (real inventory only).
2. Never preselect optional categories if affirmative consent required. Don't infer consent from continuing to browse.
3. Offer a genuine reject path and prevent dark-pattern hierarchy; accessibility and screen-reader support; usable on small devices.
4. Persist exact consent **purpose and notice version**, timestamp, locale, consent signal, withdrawal/regrant (limited evidence, no unnecessary PII).
5. Make withdrawal/settings easy to find later; block future processing immediately when relevant; implement vendor-side opt-out/deletion implications as needed.
6. If scripts were wrongly activated early, banner appearance cannot retroactively cure the processing. Validate through network traces.
7. Consent should be requested again only when justified by changed purposes/technologies, legal rules or expiry/quality of consent, not on every refresh.
8. Determine legal basis per purpose; essential security/transactional processing may have different legal ground from marketing.

## Event-driven release tests

- `fresh_user_no_choice`: non-exempt optional vendor requests absent until valid choice.
- `reject_optional`: no optional analytics/ad requests afterward; booking/login still functional.
- `analytics_only`: analytics on (if permitted), advertising off.
- `withdraw`: tracking stops after withdrawal; downstream vendor update where required.
- `different_device_locale`: stable readable controls, RTL, keyboard and screen reader.
- `new_vendor_version`: audit detects new client requests; privacy notice and inventory reviewed.
- `double_submits/offline`: preference saved exactly once or accurately marked pending.

## Email, SMS, push and WhatsApp

**Critical distinction:** appointment confirmation/service reminder that is necessary for the transaction is *not interchangeable* with a promotion ("20% off next visit"). Evaluate whether content and sending practice constitutes advertising by local law; "transactional" labels don't override actual promotional content.

- Keep marketing opt-in separate where required, not hidden inside Terms agreement.
- Keep permission and channel evidence: who consented, what they saw, when, source, opt-out, current status and suppression list.
- Implement working unsubscribe/STOP or equivalent for promotional messages with channel-relevant rules; enforce suppression before every send and synchronize with vendors.
- Include correct sender/operator identity and details required by territory and channel.
- Do not assume prior purchase is unconditional marketing consent: some countries have limited exceptions with constraints; verify.
- Provide delivery logs without leaking raw tokens, financial data or sensitive user content.
- Never invent urgency, fake scarcity or customer reviews; [FTC review guidance](https://www.ftc.gov/business-guidance/advertising-marketing/endorsements-influencers-reviews) and product-local advertising law apply where relevant.

## Edge cases and alerts

- Consent manager accidentally rendered *after* SDK init = blocker where prior consent required.
- Changes in tracking SDK with unchanged privacy policy = mismatch, review.
- User refuses marketing but unsubscribed contact stays in imported CSV = sending suppression failure.
- Private booking/health messages in lock-screen notification = minimize exposure by default.
- Cookies or analytics introduced through third-party embeds = still audit actual network traffic.
- "No data sold" does not mean "no data transferred to vendors"; reflect true processor sharing/recipient descriptions.

**Evidence output:** inventory, data-flow screenshot, network trace before/after consent, suppression and withdrawal tests, policy diff and legal reviewer status. No blanket "GDPR compliant" claim.

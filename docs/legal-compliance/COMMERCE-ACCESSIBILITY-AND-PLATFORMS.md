# Consumer transactions, accessibility, app stores and high-risk products

**Check product & territory before applying a rule.** General practices below reduce avoidable exposure but do not replace local statutory analysis. Refer to [source atlas](OFFICIAL-SOURCES.md).

## Selling services, appointments or SaaS subscriptions

| Risk | Visible content / user control | Engineering behavior & evidence |
|---|---|---|
| Identity and terms | Correct operator, customer support contact, service scope and booking/product description | Consistent website, invoices and merchant |
| Price and taxes | Actual total/fee/currency, taxes or additional charges, delivery/service details and limitations where law requires | Cross-check rendered total against payment provider invoice |
| Recurring payments | Renewal cadence, trial conversion, next charge, cancel terms before signing up | Save accepted offer/version + subscription status, idempotent retries |
| Cancel/change/refund | Straightforward correct request route, change/cancel deadline and product-specific exceptions | UI & backend state synchronized; refund tests and accessible status |
| Misleading practices | No invented scarcity, reviews, fees or fake customer endorsements | Marketing claim inventory with substantiation |
| Disputes/support | Genuine contact, reference and receipt; escalation for service issues | Support messages/ticket channel actually works |
| Marketplace/provider | Clarify platform vs independent provider obligations, cancellation policy and real-party identity | Verify contractual role and liability allocation; escalate to counsel |

**Israel:** internet cancellations and disclosures may be subject to Consumer Protection Law requirements; see [Knesset legal explainer](https://main.knesset.gov.il/Activity/Legislation/Laws/Pages/LawBill.aspx?lawitemid=2002974). Exact cancellation windows, exceptions (especially certain dated services), fees, consumer categories and required formats depend on service and current law. **Never use a universal 14-day cancellation promise or absolute 'no refunds' just because a template says so.**

**US subscriptions:** FTC's 2024 Click-to-Cancel rule was subject to legal change; **do not assert it is currently operative** solely from original announcement. Use the [FTC's current rule/proceedings](https://www.ftc.gov/legal-library/browse/rules/negative-option-rule) and verify ROSCA/current FTC and relevant state law at launch. Clarity and honest enrollment/cancellation remain critical independent of rule status.

## Accessibility: legal obligations vs technical guidance

- If publicly offered service is subject to Israeli accessibility law, investigate Equal Rights for Persons with Disabilities regulations, applicable service accessibility rules, Israeli Standard 5568 and potential exceptions; professional assessment of the actual operator/service is required. [Israeli Ministry of Justice statement example](https://content.justice.gov.il/Accessibility/declaration1.html).
- Technical WCAG 2.2 is a **useful target** but does not automatically mean every jurisdiction legally requires that exact version; document statutory standard/level based on scope. [W3C WCAG 2.2](https://www.w3.org/TR/WCAG22/).
- Test keyboard navigation, screen-reader labels, semantic structure, contrast, focus, captions/media, forms, errors, RTL, reduced motion, zoom and mobile targets. Accessibility widget/badge ≠ compliance.
- Only publish an **accurate** statement of audited support, known limitations, contact method and alternative access route if relevant. No "100% accessible" boilerplate.

## Mobile store-specific requirements (separate from legislation)

**Google Play** [User Data policy](https://support.google.com/googleplay/android-developer/answer/10144311?hl=en):
- Published active privacy policy link on store + in app, accurate Data safety statements (including included SDKs).
- If app lets users create an account, required accessible deletion request in app and on external web resource; deletion of associated data subject to justified retention exceptions, not mere account suspension.
- App/release reviews must reflect true actual app behavior.

**Apple** [User Privacy and Data Use](https://developer.apple.com/app-store/user-privacy-and-data-use/):
- Accurate App Privacy Nutrition Labels including third-party SDK practices, privacy manifests and tracking permission under ATT where applicable.
- Verify current App Review Guidelines for account deletion, subscriptions and user-generated content features separately; don't project Android deletion wording onto iOS.

## Minors, regulated claims, AI and media

- Products directed at children or with known child users require specialized local age/parental consent and data-safety review. US [FTC COPPA guidance](https://www.ftc.gov/business-guidance/resources/childrens-online-privacy-protection-rule-six-step-compliance-plan-your-business) where relevant.
- Healthcare/mental health, banking/credit/payments, investment advice, children/education, employment, biometric identification, dating, real-money gaming and physical safety can carry sector rules. Mark `COUNSEL REQUIRED`; no generic waiver makes prohibited operations lawful.
- AI chat, generation and decision support: disclose factual scope/limits as applicable, do not misrepresent human identity/accuracy, review model data handling, copyright, rights and cross-border transfers; assess jurisdiction-specific AI legal rules **at implementation time**, not from static assumed effective dates.
- Public images, recordings and reviews require privacy/IP/consent checks, including faces, voices, music and likeness.

## Launch checklist

1. Localized customer contract terms and actual merchant/operator confirmed.
2. Consent/payment/final-charge actions tested; exact customer-visible amounts match backend.
3. Cancellation/refund and account deletion routes run end-to-end when required.
4. Accessibility tested and statement limited to verified coverage.
5. Store forms/labels compare against SDK and data inventories.
6. Minors and regulated products escalated; review decisions documented.
7. Legal review of any limitation-of-liability, arbitration, law/forum, warranty, refunds and intellectual-property clauses documented.

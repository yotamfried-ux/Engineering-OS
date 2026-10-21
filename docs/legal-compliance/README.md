# Legal and platform compliance — Israel first, international conditional

Status: engineering issue-spotting, NOT legal advice. Reviewed 2026-10-21. Qualified Israeli counsel should review actual policies/contracts and high-risk launches. Legal requirements depend on operator, audience, data and markets.

## Jurisdiction decision
Record operator establishment, user locations, targeting/marketing, processing locations, processors, content and age groups. Israel is the baseline; EU GDPR, US state privacy laws, COPPA, DMCA and other laws are conditional, not universal. Do not blindly transplant US arbitration or DMCA clauses into Israeli terms.

## Israel-specific checks
1. Privacy: Law for Protection of Privacy, 1981, including Amendment 13; review definitions of personal data, transparency, registration/notification triggers, DPO appointment triggers, processor arrangements, security and enforcement. Check Privacy Protection Regulations (Data Security), 2017, and regulator guidance. Do not assert all databases require registration.
2. Consumer law: Consumer Protection Law, 1981, including distance selling, cancellation, clear pricing and subscriptions where applicable; review Israeli disclosure and refund requirements.
3. Accessibility: Equal Rights for Persons with Disabilities Law, 1998, accessibility regulations and applicable Israeli Standard 5568. Scope/exemptions require assessment; WCAG alone is not a legal determination.
4. Copyright: Israeli Copyright Law, 2007, rights and permissions for assets, licenses, UGC takedown handling and evidence preservation. US DMCA agent registration is NOT a blanket Israeli requirement.
5. Terms/contracts: Israeli Contracts (Standard Form Contracts) Law, 1982; review unfair terms, limitations of liability, arbitration and jurisdiction clauses. None eliminates litigation risk.
6. Marketing: Communications Law (Telecommunications and Broadcasting), 1982, section 30A, and applicable consumer/privacy requirements for promotional messaging.
7. Cyber and incident response: document access controls, logging, retention, incident classification and notification duties according to applicable Israeli privacy law and regulations.
8. Tax, invoices, business registration and sector-specific licensing are conditional; route to accountant or counsel, not a universal software rule.

## International/platform conditional checks
- Apple App Privacy Details / privacy nutrition labels, SDK privacy manifests, account deletion, UGC reporting/moderation, App Review rules.
- Google Play Data safety, privacy policy, account deletion, permissions, SDK disclosures, target API requirements.
- AI marketing: no unsupported performance claims or misleading impersonation; FTC deception standards apply where US jurisdiction exists, not a universal AI-label mandate. Check EU AI Act obligations only for applicable activities and timelines.
- US DMCA 17 USC 512(c) designated agent and notice/counter-notice procedure: assess only if seeking relevant US safe-harbor protections.
- Arbitration/class-action waiver: enforceability varies by jurisdiction and consumer contract; never promise immunity.

## Required artifacts per product
Jurisdiction matrix; personal data inventory and processing map (including third-party SDKs); privacy notice and retention/deletion schedule; user-rights workflow; terms and consumer disclosures; UGC/content/IP process if applicable; AI claims substantiation; store declarations; signed legal-review decision and open-risk register. Every statement links to applicable source and review date.

## Official sources
Israel Privacy Protection Authority Amendment 13 Q&A: https://www.gov.il/he/pages/tikun13_qa
Israel PPA: https://www.gov.il/he/departments/the_privacy_protection_authority
Israeli legislation database: https://www.nevo.co.il/ (publisher; verify binding text against official legislation)
Official legislation portal: https://www.gov.il/he/departments/ministry_of_justice
Apple: https://developer.apple.com/app-store/review/guidelines/
Apple privacy: https://developer.apple.com/app-store/app-privacy-details/
Google Play user data: https://support.google.com/googleplay/android-developer/answer/10144311
Google Play Data safety: https://support.google.com/googleplay/android-developer/answer/10787469
US Copyright Office DMCA: https://www.copyright.gov/dmca-directory/
FTC advertising: https://www.ftc.gov/business-guidance/advertising-marketing
EU GDPR: https://eur-lex.europa.eu/eli/reg/2016/679/oj
EU AI Act: https://eur-lex.europa.eu/eli/reg/2024/1689/oj

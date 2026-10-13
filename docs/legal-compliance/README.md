# Legal, privacy, consumer protection & compliance — engineering knowledge map

**Status:** REFERENCE ONLY; curated 2026-10-13. **Not legal advice, an attorney-client opinion, a compliance certification, or ready-to-publish legal text.** The point is to build defensible practices and surface questions for qualified counsel. Terms and disclaimers **cannot waive non-waivable consumer/privacy rights or excuse negligent security**. Every obligation depends on applicable law, users, product category and actual implementation.

**Default user scenario:** Israeli software product. EU/EEA, UK, US states and distribution-platform rules apply **only if scope tests are satisfied**. This is a multi-jurisdiction library, NOT a blanket statement that every rule applies globally.

## Agent fast path (only read what your project needs)

1. [APPLICABILITY-AND-ROUTING.md](APPLICABILITY-AND-ROUTING.md) — audience, market, data, payments, platform, regulators, legal questions, conditional jurisdiction matrix.
2. [OFFICIAL-SOURCES.md](OFFICIAL-SOURCES.md) — canonical regulators, provisions, exact source dates, and examples. Research there, not from another company's copied Terms of Service.
3. [DATA-INVENTORY-AND-RIGHTS.md](DATA-INVENTORY-AND-RIGHTS.md) — fact inventory, data purpose, lawfulness, access/deletion, cross-border transfers, retention, DPO/registration flags.
4. [PUBLIC-DOCUMENTS-AND-MICROCOPY.md](PUBLIC-DOCUMENTS-AND-MICROCOPY.md) — what appears on-site/in-app, notices, plain-language prompts, example **DRAFT** privacy and terms outlines.
5. [COOKIES-CONSENT-AND-MARKETING.md](COOKIES-CONSENT-AND-MARKETING.md) — consent UX, email/SMS/push, unsubscribe, truthful product claims.
6. [SECURITY-AND-INCIDENT-LAW.md](SECURITY-AND-INCIDENT-LAW.md) — privacy/security obligations as product/operational controls, breach workflow, evidence; pair with existing `patterns/security/` tests.
7. [VENDORS-LICENSES-AND-CONTRACTS.md](VENDORS-LICENSES-AND-CONTRACTS.md) — DPA/SaaS contracts, processors, SDKs, cloud, OSS, images/fonts/assets, API and AI services.
8. [COMMERCE-ACCESSIBILITY-AND-PLATFORMS.md](COMMERCE-ACCESSIBILITY-AND-PLATFORMS.md) — consumer terms, renewal/cancel, accessibility, app stores, minors, regulated verticals.
9. [RELEASE-LEGAL-QUALITY-GATE.md](RELEASE-LEGAL-QUALITY-GATE.md) — evidence/approval gates. Legal review pending = **NOT CLEARED**.
10. [EXAMPLE-BOOKING-APP.md](EXAMPLE-BOOKING-APP.md) — worked Israeli appointment booking application, with privacy/consent/transaction examples, approval flags.

## Public documents vs non-public evidence

| User-facing surface (when applicable) | Internal operational evidence (when applicable) |
|---|---|
| Privacy notice and just-in-time collection notice | Data map, processing purpose/legal basis and retention schedule |
| Terms of service / EULA + acceptable use | Risk review of rights, prohibited actions, liability wording, jurisdiction |
| Cookie/tracking notice and preferences | SDK/cookie scan, tags blocked until valid consent where required |
| Prices, subscriptions, cancellation/refund and contact details | Paid-flow tests, notices/consent versions, receipt and dispute evidence |
| Accessibility statement/contact (where required or useful) | Accessibility testing and actual issue/remediation log |
| AI-generated content disclosure or other regulated feature notices | AI/provider data flows, customer ownership, safety/human review |
| Account/data deletion or privacy request channel | Authenticated request workflow, deletion/retention proof, vendor fan-out |
| Security/contact and incident messages when needed | Risk classification, access logs, incident register, breach assessment/reporting |

Not every product needs every public page or a cookie pop-up. Do **not** copy terms from competitors or publish placeholders. Don't publish internal incident playbooks, customer datasets, secrets, private security architecture, or vendor agreement pricing.

## Rules for AI agents

- **Scope first**: identify controller/processor role, entity, markets, category of users, categories of data, billing/renewal, channel (web/app/email), age groups, cross-border transfers and regulated purpose.
- **Reality before claims**: inspect code/config/data flows, runtime SDKs and processors before writing notices. An attractive privacy policy that lies about data collection increases exposure.
- **Law vs policy vs recommendation**: annotate each claim as `REQUIRED_IF_APPLICABLE`, `PLATFORM_POLICY`, `CONTRACTUAL`, or `BEST_PRACTICE`; link primary source and scope.
- **Never default to consent for all processing**: determine appropriate ground per purpose under applicable law. Require separate consent where law demands it; document alternative bases where permitted.
- **No fake protection**: no blanket `we are fully GDPR compliant`, `100% secure`, `no liability whatsoever`, `deleting the account immediately deletes all backups`, or `never share data` without facts.
- **Use human review**: legal/compliance owner approves every customer-facing contract, policy, consumer-rights exception, cross-border data arrangement and changing legal conclusion before publishing.
- **Version & evidence**: track precise document version, presentation location, acceptance action/time (only where acceptance is legally meaningful), UI screenshots, applicable locale, reviewer and test cases.
- **Privacy safety**: demo/test with synthetic personal data. Do not log actual passwords, full auth tokens, user financial details, sensitive media or raw customer prompts in public CI evidence.

## Relation to other Engineering-OS work

- **Technical assurance**: [security verification](../../patterns/security/README.md) covers OWASP/NIST vulnerability testing, not legal applicability.
- **UI/UX**: [UI library](../ui-ux/README.md) covers legible actions, consent and accessibility behavior, not adequacy of statutory notices. Another draft PR may add an experience atlas; keep legal routing independent of unmerged work.
- **External services**: [external-systems](../../external-systems/) and [capability registry](../../capability-registry/README.md) help inspect actual processors and permissions.
- **Deployment/CI**: `PASS` on security scans ≠ lawful processing. Legal clearance is separately recorded.

**Maintenance:** recheck jurisdiction sources at feature changes, new market entry, new data/SDK, pricing/marketing changes, vendor switch, serious incident and before launch; log `last_verified`, counsel sign-off and legal uncertainty. Some official agencies publish policy changes frequently.

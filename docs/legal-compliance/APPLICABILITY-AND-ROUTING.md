# Applicability triage and agent decision tree

**Never deliver one universal legal boilerplate.** This is a project-fact collection and specialist-review route, not a mechanism that decides legal obligations conclusively. Reference [official sources](OFFICIAL-SOURCES.md).

## Phase A — discover facts (record `unknown` rather than guess)

- Legal entity/individual operator; legal identity, trading name, address, jurisdiction, contact.
- Markets actually targeted; language/currency/advertising/distribution; where users reside; paid/free; B2C/B2B and subprocessor customers.
- Product: appointment booking, marketplace, SaaS, media/AI, analytics, education, health, finance, kids, gambling, employer/employee, IoT, regulated advice.
- Channel: website, Android/iOS, desktop, extension, kiosk, voice/assistant, email/SMS/WhatsApp, API, payment processor.
- Personal data by *actual* category and source (users, guests, uploaded content, images/voice/face, booking notes, payment metadata, telemetry, device IDs); minors; sensitive categories.
- Why processing occurs and who chooses purpose/means; controller, joint controller or processor; vendors, tenants and cross-border transfers.
- Real money movement; renewals/trials/invoices/refunds; merchant of record; subscription cancellation channels.
- Ad/marketing/tracking pixels/analytics tools; SDK cookie inventories; legal ground and existing opt-in/opt-out.
- Platform terms, third-party content and open-source/media/font license lineage; data retention & deletion tooling; actual security measures.
- Location of servers, backup, logs, administrators, subprocessors, recipients. **Never invent residency**.
- User-facing promises already made; languages/locales, audience accessibility, support methods, previous incidents and complaints.

## Phase B — conditional routing

| Trigger discovered | Consult | Outcome (not assumed by default) |
|---|---|---|
| Any personal data in Israeli business | Israel PPA law + security guide, privacy notice, database-role analysis | Evaluate disclosure, lawful collection/use, access/correction, security-level classification, documentation, notification/registration/DPO when triggered |
| EU establishment, EU targeting or behavior monitoring | EU GDPR and EDPB | Assess controller/processor, Article 6 basis, special category Art 9, rights, DPIA, DPA, transfer mechanism, EU representative/DPO when applicable |
| UK users/targeting; device storage or direct marketing | UK GDPR + ICO PECR guidance | Separately assess tracker consent and email marketing; UK not assumed same as EU |
| California residents and statutory business threshold/criteria | CPPA official notices/rules | Notice at collection, privacy rights and opt-out if applicable; not universal for every SaaS |
| Child-directed service or known users under age thresholds | FTC COPPA if US scope, applicable child privacy/consumer protection locally | Child-specific age/parental consent, retention, trackers, defaults; legal review required |
| Payment, automatic renewal, booking, marketplace | Consumer protection, tax/invoicing, payment processor contract and scheme rules | Real billing total, refunds/cancellation disclosures, receipts, recurring consent, dispute workflow; exceptions require counsel |
| iOS / Android distribution | Apple App Store / Google Play policies | Privacy labels/Data safety, permissions, deletion and store subscription policies as applicable |
| Marketing emails/SMS/push | Local electronic marketing law; EU/UK ePrivacy/PECR if relevant | Distinguish operational notices from advertising; consent, preferences, suppression, records |
| Cloud, subcontractors, cross-border flows | Local transfers + GDPR Ch V where applicable; DPA, vendor agreements | Adequacy/SCC/other allowed mechanism if required, processor documentation, region/transfer review |
| User content, AI or third-party models | IP/copyright, model contract, privacy, AI rules in relevant markets | Ownership/licensing, input/output confidentiality, training permissions, prohibited-use and AI transparency if triggered |
| Public-facing service | Accessibility regulations of served territory and technical WCAG standards | Correct standard/exceptions, accessible service, truthful statement/contact; no unsupported exemption claim |
| Highly regulated vertical | Healthcare, finance, children, employment, biometrics, safety-critical jurisdiction-specific counsel | Specialist owner approval and product controls; generic templates not enough |

## Phase C — legal obligations mapping template

```yaml
project: "<actual repo/app>"
revision: "<exact commit>"
territory: "<jurisdiction>"
trigger_and_evidence: "<business fact / observed code behavior>"
obligation: "<specific compliance action>"
obligation_type: REQUIRED_IF_APPLICABLE # or PLATFORM_POLICY / CONTRACTUAL / BEST_PRACTICE
source_url: "<official link>"
source_version: "<last verified>"
status: NOT_TESTED # PASS / FAIL / PARTIAL / BLOCKED / NOT_TESTED / NOT_APPLICABLE
owner: "<legal or privacy accountable person>"
deadline: "<only after verified>"
user_facing_text: "<reviewed URL/version or N/A>"
technical_control: "<code/config/test/run>"
legal_reviewer: "<person/status>"
residual_risk: "<specific unresolved question>"
```

## Phase D — prioritize

**Block release and escalate** when: no lawful purpose for sensitive/children's data, private data publicly exposed, deceptive billing or fabricated legal claims, unverifiable rights/deletion process where required, unresolved serious incident, unauthorized third-party sharing, prohibited asset license, mandatory legal review absent for a critical domain, or key notices materially false.

**Don't block merely because** a hypothetical extra law somewhere might apply. Tag `OUT_OF_SCOPE — evidence`, `TO_ASSESS` or `COUNSEL_REQUIRED` and identify who can resolve it.

## AI agent route

1. Read this brief and only relevant source chapters.
2. Inventory existing product behavior from code and actual vendors; produce evidence and questions.
3. Draft **internal** obligation matrix and concrete user-facing text in `DRAFT—LEGAL REVIEW REQUIRED` status.
4. Implement permitted technical controls with tests on separate branch; avoid deleting/retaining user data without policy approval.
5. Ask accountable humans to approve obligations, agreement terms and jurisdictions **before publication**.
6. Provide linkable evidence that UI and back-end behavior match approved policy and that relevant store policies are covered.
7. Reopen review when product scope, vendors, trackers, data category, launch territories or law changes.

**Successful work** = relevant risks surfaced and tracked + implemented/tested controls where authorized, **not** a promise of being lawsuit-proof.

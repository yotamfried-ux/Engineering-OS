# Privacy by design: data inventory, legal basis, retention and rights

**Scope:** internal engineering and legal assessment. An inventory is the input for disclosures; **do not write privacy text from guesses**. See [territory triage](APPLICABILITY-AND-ROUTING.md) and [regulator sources](OFFICIAL-SOURCES.md).

## Personal-data ledger (repeat per purpose and data flow)

| Field | Record what actually exists |
|---|---|
| Source / subject | customer, employee, provider, child's guardian, visitor, guest, uploaded third party |
| Field & sensitivity | names/contact, booking notes, IDs, messages, media, location, health, device/cookie/behavior IDs, payment metadata, IP, auth logs; redact examples |
| Purpose | scheduling/fulfilment, security, billing, requested communication, optional analytics, direct marketing, model processing |
| Legal ground | **if GDPR applies**, document Art. 6 basis per distinct purpose; if sensitive Art. 9 condition; if Israel applies, counsel-assessed permitted purpose/consent/notice under Israeli law |
| Controller / processor | each accountable legal entity, subcontractor, DPA/instructions |
| Access | roles/tenants, admin controls, vendor access, secrets, system logs; enforce minimum privilege |
| Storage/transfers | primary host, region, backups, processors/SDKs, overseas countries and applicable safeguards |
| Transparency | which privacy notice/just-in-time dialog informs person and **when** |
| Lifetime | planned period or objective criterion, legal hold exceptions, deletion timing, backup expiry, evidence |
| Data-subject rights | access/correction/deletion/etc. if legally available; authentication, tracking and exceptions |
| Security controls | classification and applicable legal/contract standard, encryption, access audit, response plan |
| Evidence | code path, db schema, network behavior, actual vendor invoice/contract, UI screenshot, test run |
| Owner/review | engineering owner, privacy/legal reviewer, last verified |

An inventory for `appointment.bookings` might record: customer's phone, service, staff member, time, status, notes; why each field is needed; who sees it; whether reminders are operational or marketing; whether providers act independently or on customer instructions; and what happens to deleted bookings in backups.

## Avoid conflating GDPR and Israeli law

- **GDPR, only if applicable:** lawful basis per purpose; don't select "consent" simply because it sounds safest. Transparent notices, purpose limitation and data minimization, security, transfers and controller-processor contracts may apply. Rights (access, erasure, portability, object etc.) have grounds, limits and exceptions; do not promise unconditional deletion or immediate resolution.
- **Israel:** Amendment 13 changes personal-data/role definitions and regulator powers; assess section 11 collection notice, individual access/correction obligations and security regulations on the actual database. Registration/notification/DPO tests are **conditional**; consult the updated PPA guidance.
- **EEA-origin data held in Israel:** distinct Israeli regulations may add deletion/retention/accuracy/notice rules in specific circumstances; see [PPA EEA-origin guidance](https://www.gov.il/he/pages/europe_transfer?chapterIndex=6).

## User request process — engineerable workflow

1. Single discoverable route: in-app Privacy/Account controls or accessible web/email request path. Avoid requiring another account to submit requests.
2. Record request `type`, `received_at`, `jurisdiction`, owner, `status`; do not put user secrets in tickets.
3. Verify identity **proportionately**, preventing unauthorized release; avoid collecting ID documents unnecessarily.
4. Assess scope and exemptions with qualified owner. Controller vs processor matters: processor may need to refer request to its customer under DPA.
5. Search controlled systems + integrated vendors + exports + caches + backups. Apply approved retention/legal hold schedule and documented backup expiry.
6. Fulfil access/rectify/delete/restrict/port/opt-out as required for jurisdiction; confirm outcome or lawful refusal with reasons.
7. Record event timestamps and verifiable completion evidence; secure delivery of exported records; accessible user updates.
8. Conduct representative tests, including requester not found, unverifiable requester, suspended account, third-party content and simultaneous in-flight jobs.

**Example end-user text (draft, not a universal legal entitlement):**
> `לבקשת עיון, תיקון או מחיקת מידע, פנו אלינו ב-[כתובת]. נבדוק את בקשתכם בהתאם לדין החל ונעדכן אתכם לגבי הטיפול בה.`

Don't write `we erase all your data from every system in 24 hours` unless independently provable and legally consistent with retention duties.

## Retention & deletion design requirements

- Retention decisions by category and purpose — not a single `keep everything indefinitely` setting.
- Split user-content deletion from security logs, fraud-prevention records, accounting records and backups with documented legal justification and bounded lifecycle.
- Implement deletion/expiry jobs, deletion idempotency, vendor cascades and revocation of access tokens/shares.
- Treat logs containing IP/device identifiers, free-text notes and media as possible personal data.
- **No silent shadow copies** in staging, S3, backups, support tickets, analytics, AI prompt/transcript storage or error trackers. Inventory all destinations.
- Track privacy obligations across system changes (new SDK, facial recognition, location, video uploads, LLM prompts, cross-border vendor).

## Evidence to store in *project*

```text
data-map.md / data-map.csv
processing-register.md
retention-deletion-matrix.md
privacy-rights-workflow.md
processors-and-transfers.md
legal-owner-approval.md
```

Record `NOT TESTED` for unverified deletion paths and `BLOCKED` for missing vendor contract or unknown legal ground; never claim compliance from documentation alone.

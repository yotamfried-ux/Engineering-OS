# Worked example — legal and security architecture for an Israeli booking application

**Scenario assumptions (hypothetical, NOT about an actual repo):** Israeli small business provides booking for third-party service providers. End users enter names and contact details, select time/service and receive booking confirmations/reminders. Optional marketing and analytics may exist. Payments, health notes and EU-targeting are `UNKNOWN` pending real code and business review. Do not publish any example text verbatim.

## Apply the decision tree

| Question | Business evidence to inspect | Legal/compliance action |
|---|---|---|
| Who runs app? | Corporate/sole-proprietor identity, support email, merchant of record, provider relationships | Privacy operator identity, ToS seller/provider roles, proper contact |
| What is collected? | Actual web/mobile forms, DB columns, logs, object storage, SDKs, email/SMS payloads | Data ledger: first name, phone/email, time, service, professional, notes, IP/session |
| Who can view bookings? | Customer/admin/provider auth, tenant ids, RLS rules, exports | Test least privilege, exact provider scope, no cross-tenant leakage |
| Is marketing separate? | SMS templates and queue rules; provider marketing access | Transactional confirmation vs promotions, channel/legal consent/suppression |
| Where is data processed? | Hosting, DB, email/SMS gateway, AI, error tracker, CDN, backups | Vendor contracts + processor/transfer review and honest privacy disclosure |
| Are fees charged? | Checkout, gateway, invoices, merchant/appointment terms | Transparent total, payment recipient, cancellation/refund rights; qualify exact product |
| Are clients children or health patients? | Business audience, booking-note contents, clinical use | Escalate sensitive/child/sector-specific counsel and enhanced controls |
| Is EU/UK targeting real? | Ad targeting, locale/currency/offer, traffic and support | Separate territorial scope test; don't call all visitors GDPR covered by default |
| Is account deletion required? | iOS/Android app presence; accounts; applicable user rights | App/store deletion paths and backend retention handling |
| Is database registration/notice/DPO required? | Scale, sensitivity, data purpose, organizational activities | Evaluate Amendment 13 and 2026 PPA DPO guidance, not blanket registration |

## Customer journey — content **and** enforcement

| Step | Example copy (Hebrew; preliminary UX only) | Required working behavior |
|---|---|---|
| Browse services | `בחרו שירות ובדקו שעות פנויות` | Only real available offerings, actual provider/prices where displayed |
| Contact details | `נשתמש בפרטים כדי לנהל את התור ולשלוח עדכונים עליו. לפרטים נוספים: מדיניות פרטיות.` | Display applicable full collection disclosure at time of collection; validate required data/minimize notes |
| Optional promotions | `אני רוצה לקבל גם הצעות שיווקיות ב-SMS` | Separate free choice and suppression; no bundled requirement for booking |
| Review | `לפני האישור: [שירות], [תאריך ושעה], [מיקום], [מחיר סופי], [מדיניות ביטול]` | Verified schedule, taxes/fees and policy link; review/change path |
| Submit | `בודקים שהתור עדיין פנוי…` | Atomic server-side availability and idempotency; protect from double booking |
| Confirmed | `התור נקבע. מספר אישור: [מזהה שרת]` | Only after authoritative commit, receipt with management/cancel path |
| Cancel/change | `ביטול התור` + true effects/fees/terms | Backend policy/consumer-rights check; notify correct recipients |
| Rights request | `בקשה לעיון, תיקון או מחיקת מידע` | Identity verification, legal schedule/exemptions, complete vendor fan-out |
| Marketing settings | `עדכונים שיווקיים: כבוי/מופעל` | Consent history, opt-out and queued-send suppression |

## Example internal data inventory (complete with ACTUAL values before launch)

```yaml
product: "Israeli appointment system — illustrative"
operator: UNKNOWN
controllers_and_processors: TO_REVIEW # provider/client relationship may vary
end_user_fields: ["name", "contact", "booking/service", "status", "device/usage metadata if actually collected"]
optional_fields: ["customer notes", "marketing choice"] # only if present in real product
payment_provider: UNKNOWN
hosting_region: UNKNOWN
analytics_sdk: UNKNOWN
transactional_messaging: UNKNOWN
email_sending: UNKNOWN
retention_policy: NOT_APPROVED
eu_scope: NOT_ASSESSED
israel_database_security_level: NOT_ASSESSED
israel_registration_notice_dpo: NOT_ASSESSED
policy_text_status: DRAFT_NOT_APPROVED
```

## Security + incident simulation cases

1. Guest user guesses another user's booking ID → cannot see/edit/receive booking or private data.
2. Provider A uses API to fetch Provider B schedule/customer record → denied by tenant boundary.
3. Booking conflict → no fake confirmation and no duplicate charge.
4. SMS provider / error tracker accidentally receives extra personal fields → minimization/redaction, vendor review and regression test.
5. Customer opts out of promotions → no queued marketing message sent, while critical booked-service communications follow applicable rules.
6. Customer requests deletion → lawful records retained only under approved reasons, correct user data deleted or anonymized, processor notices and response tested.
7. Security incident in isolated test environment → owner triages, classifies jurisdictions/severity, records clock/decisions and follows relevant notification process.

**Review gate:** Operator/legal counsel must approve specific privacy text, Terms, cancellation policy, real vendor/transfer arrangements, age/sector features and exact enforcement evidence. Do not claim this example makes real app compliant.

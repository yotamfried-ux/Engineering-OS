# Legal/compliance release quality gate — evidence before claims

**Gate scope:** product-specific statutory, regulatory, consumer, platform and contractual exposure. This complements security/functional/accessibility gates and cannot replace counsel's legal opinion. Do not mark `COMPLIANT` from Markdown existence. Review every real product rollout, new market, new personal data collection/SDK, customer agreement update, billing change, new processor, children/sensitive-data feature, or material privacy incident.

## Required evidence matrix

| Review field | Acceptance evidence | Escalation |
|---|---|---|
| Responsible legal entity & target markets | Business identity, operator contact, countries targeted, consumer/business classification; `legal-scope.md` | Unknown seller/market or regulated activity |
| Current law source & scope | Official citation URL and verified date, applicability reason per issue, owner | A generic template treated as binding law |
| Personal-data inventory & purpose | Fields/recipient/retention/roles/transfer map tied to actual code and vendors | Unknown processing or unreviewed sensitive/child data |
| Public privacy notices | Approved version, factual comparison to actual data use, in-context disclosures & working contact | Misleading policy, missing required notices or unsupported promises |
| Terms/consumer rights | Reviewed legal terms, transparent prices/refunds/cancel/renewal where relevant; accessibility | Hidden fees, forbidden waivers, unlawful flows |
| Cookie/tracker & marketing controls | Actual request captures before/after opt-in/withdrawal, SDK inventory, marketing opt-out | Unauthorized tracking or promotional messaging where consent/opt-out required |
| User data rights | Authenticated request workflow, processing and response, vendor propagation, legal retention exceptions | Required deletion/access impossible or unreviewed refusal |
| Technical/legal security | Level/risk assessment, test scope & findings, access restrictions, processor agreements and incident plan | Exposed secrets/PII, exploitable authorization, unresolved critical finding |
| Vendors & intellectual property | DPA/transfer review, OSS/asset licenses and permission to distribute, SDK store labels | Unlicensed asset/code, unknown vendor sharing |
| Platform & industry rules | App Store/Play Console compliance, children/health/finance/AI domain counsel | Unsupported platform claims or regulated feature without review |
| Review approval | Named owner, legal counsel sign-off on public text/critical obligations, date, exact version and scope | Approval missing or out of date |

## Status vocabulary — **separate** from engineering tests

- `READY_FOR_COUNSEL`: draft source-backed, evidence ready, **not** authorized to publish.
- `LEGAL_REVIEW_APPROVED`: named qualified reviewer signed off for specifically stated territory/products/text revision. Not a guarantee of no lawsuits.
- `CONDITIONAL_APPROVAL`: explicit residual issues with due dates/assignee and owner acceptance where legally permissible.
- `BLOCKED`: critical statutory/contractual issue, impossible request flow, major contradiction, unapproved customer terms, or prohibited conduct.
- `NOT_ASSESSED`: insufficient facts/research; not an exemption.
- `NOT_APPLICABLE`: documented jurisdiction/feature exclusion and source evidence.

**Do not silently translate** internal technical tests PASS into `LEGAL_REVIEW_APPROVED`. An AI agent **cannot self-sign** a lawyer's approval. No automatic publication or production terms change without explicit authorized approval.

## Suggested project artifact: `legal-qualification.md`

```markdown
# Legal & Compliance qualification
Product + revision/build + environment:
Markets/target audience:
Operator identity:
Processing role (controller/processor) and data categories:
Applicable obligations: (obligation, jurisdiction, source link/version, reviewer)
Excluded obligations: (why outside scope, evidence)
Policy revision URLs and dates:
UX captures of consent, forms, cancel, privacy center:
Vendor/data-flow/retention/license evidence:
Security test and incident-management evidence:
Payment/store/accessibility findings:
PASS: (specific implementation tests, *not* a general legal opinion)
FAIL:
NOT ASSESSED / OPEN LEGAL QUESTIONS:
Risk owner + due dates:
Qualified legal review decision and approval date:
Release authorization: NOT GRANTED until approved by responsible human
```

## Engineering acceptance tests that support (but cannot prove) legal review

1. All legal links resolve anonymously and on mobile. Policies have genuine contact and last-updated version.
2. Point-of-collection microcopy reflects actual field purpose; no unintended collection via hidden SDKs.
3. Consent-required optional trackers remain inactive until affirmative choice and stop on withdrawal.
4. Signup confirmation records only actual document versions and acceptance actions, not inferred blanket consent.
5. Opt-out for marketing correctly suppresses queued sends from email/SMS integrations.
6. "Delete account" flow accurately carries through all primary systems and vendor requests while handling lawful retention in separate records.
7. Preview of recurring cost, billing schedule, cancellation/complaint process matches charged amount.
8. Negative path: failed bookings/payments don't show successful transaction, don't double-charge, preserve valid state.
9. App store Data safety/Privacy labels are cross-checked with real permission/SDK behaviors.
10. Scan build for unlicensed packages/assets, secret exposures, authorization regression, accessibility failures and evidence leaking private data.

**Operational audit cadence:** release review + trigger-based review on policy/vendor/feature/law changes. Preserve historical versions/receipts/approval evidence with an approved retention period and privacy safeguards.

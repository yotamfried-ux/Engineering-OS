# Launch-day, first week and ongoing maintenance

The goal is stable service and truthful communications **after** the storefront listing/web URL is public. Store acceptance doesn't validate the backend, production users or ongoing policy compliance.

## Pre-launch operational runbook

- Name a release captain, product owner, security/incident owner, support contact, and authorized rollback decision-maker.
- Have exact artifact SHA/build, region/tenant, staged rollout cohort, deployment/feature flags and SQL migration state.
- Define error-budget/threshold hypothesis for availability, 5xx, p95 latency, crashes/ANR, failed login, purchase, booking collisions, messaging and background queues. Select thresholds appropriate to real baseline, not arbitrary universal numbers.
- Test alert routing with synthetic alarm, including after-hours escalation; confirm logs redact PII and never expose auth tokens.
- Confirm production backups and a recent independent restore, rollback plan for app/frontend, forward-fix path for irreversible DB mutation, and compatibility with old mobile clients.
- Prepare status page/support FAQ/incident message drafts, store review monitoring owners, Play Console/App Store Connect roles and customer contact.

## T0 — public release

1. Owner authorizes. Gate verifies release version, CI/test evidence, review/store permission, legal sign-offs when needed and production backend health.
2. Deploy/roll out small portion where possible; avoid disabling safeguards for speed.
3. Run safe genuine **production smoke**: app downloaded from actual store/web (not developer build), launch, login, sample core action, server-confirmed state, no unauthorized leakage, help/privacy links and customer recovery paths.
4. Check push/SMS/email from sandbox-safe sample records only. Validate real deliverability and correct links.
5. Monitor immediate crash spikes, auth rate, duplicate purchase, payment verification, queue backlog, storage growth, error budget.
6. If threshold breached, stop release/rollback safely or disable feature with flag. Record facts, customer impact and recovery.

## T+1 day to T+7 days

- Review actual user journey drop-off, reviews/crash logs, store rejection/flags, payment dispute and support trends, accessibility and localization feedback.
- Audit SDK additions, actual privacy declarations and store privacy labels, app age/advertising reports.
- Verify backups, alert coverage and account deletion/marketing suppression.
- For web, inspect Search Console crawl/index errors and field Core Web Vitals when data exists. Indexing and ranking may take time or never occur, regardless of launch.
- Confirm no persistent staging/test emails, debug logs, shared credentials or production data in external testing tools.
- Hold retrospective, prioritize issues with exact reproduction, assign fixes and regression evidence.

## Continuous maintenance

- Re-evaluate store policy changes, target SDK/SDK minimums, device architectures and permission policies; schedule review before announced deadlines. Owners must follow upstream announcements, not assume this document auto-updates.
- Patch vulnerable components and track dependencies/licenses/processor contract changes.
- Test every new version on exact bundle, current devices, old-server/client compatibility and rollback route.
- Security/incident drills; notifications to authorities/users are incident/jurisdiction-specific and require competent assessment.
- Review customer communication and truthfulness of pricing/screenshots/descriptions, privacy policies and store declarations after adding SDKs/features.
- Accessibility audits and product telemetry guardrails; document actual user harms and support response.

## Incident classification and change freeze

| Signal | Immediate action |
|---|---|
| PII/tenant leak or secret compromise | Isolate/revoke, incident response, legal review, preserve evidence and consider notification deadlines |
| Double-charge or incorrect entitlement | Halt relevant billing feature, identify impacted transactions, reconcile refunds/receipts |
| Booking/upload server side effect broken | Stop new failing requests or activate safe queue, preserve partial work, repair and prove outcome |
| Crash/ANR surge | Pause Play staged rollout/App release path as allowed, compare build/environment and rollback/forward fix |
| Missing privacy/deletion link | Fix user-facing link and store declaration quickly, assess exposure and review platform policy |
| Search indexing issue | Fix technical issue; monitor Search Console; don't claim Google will index afterward |

Every remediation must link issue, exact incident window, corrected revision and independent verification. `Resolved` requires measured recovery, not simply closing an issue.

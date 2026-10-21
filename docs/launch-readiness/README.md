# Launch readiness — agent routing and evidence

Status: KNOWLEDGE ONLY; not a claim that any application passed. Reviewed 2026-10-21. Sources are authoritative links, recheck at release time.

## Routing
1. Identify target: web, API, Android, iOS; jurisdictions and audience; payments, UGC, AI, children, personal data.
2. Open [the 20-check coverage matrix](twenty-checks.md), [Israel/legal decision guide](../legal-compliance/README.md), and existing [security patterns](../../patterns/security/README.md).
3. Record applicability (REQUIRED / CONDITIONAL / NOT APPLICABLE with rationale), owner, exact commit, environment, tool version, evidence URL, status (PASS / FAIL / PARTIAL / BLOCKED / NOT TESTED / NOT APPLICABLE).
4. Block release on applicable unresolved critical security defects, unverified data handling, failed core journeys or mandatory store requirements. Legal interpretation requires qualified review; a checklist cannot guarantee immunity from claims.
5. Do not confuse docs existence with test execution. Missing evidence = NOT TESTED.

## Release gates
- Threat model, authorization/tenant isolation, secret and dependency scans, secure server validation, abuse controls.
- Recovery: error handling, database outages, backup restore and rollback drills, monitoring/alerts.
- Performance: representative load test, N+1 queries, media optimization, render profiling.
- UX: mobile layouts, accessibility, empty/error/loading states, functional core controls.
- Payments: signed webhooks, idempotency, no sensitive card storage; use provider documentation.
- Privacy: data inventory incl. SDKs, lawful notices and rights, retention/deletion, platform disclosures.
- Store: Apple App Review, Google Play policy, real-device qualification and store metadata.

## AI evaluation protocol
A/B compare the same frozen app specification, agent/model/version, time budget and tools: A without library routing; B with this index and relevant docs. Use isolated worktrees, at least 3 paired trials, blind independent scoring and identical tests. Track critical/high security findings, applicable legal/store requirement omissions (reviewed by specialist), verified test pass rate, accessibility violations, core-task completion, cost/time, and hallucinated PASS claims. Preserve prompts, retrieved documents, commits, logs and test evidence. Do not claim causality from a single run.

## Primary sources
- OWASP ASVS 5.0: https://asvs.owasp.org/
- OWASP MASVS: https://mas.owasp.org/MASVS/
- NIST SSDF: https://csrc.nist.gov/Projects/ssdf
- Apple review: https://developer.apple.com/app-store/review/guidelines/
- Google Play: https://support.google.com/googleplay/android-developer/answer/10144311
- Google SRE: https://sre.google/books/
- WCAG: https://www.w3.org/TR/WCAG22/

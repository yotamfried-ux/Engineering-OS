# Website, SaaS & public web launch — complete preflight

**As-of:** 2026-10-13. Websites do not normally need Google's *app-store approval* to be reachable on the Internet. Google Search indexing/visibility is separate and **not guaranteed**. If a PWA is packaged for stores, apply relevant store policies.

Official references: [Search Essentials](https://developers.google.com/search/docs/essentials), [technical requirements](https://developers.google.com/search/docs/essentials/technical), [sitemaps](https://developers.google.com/search/docs/crawling-indexing/sitemaps/build-sitemap), [structured data](https://developers.google.com/search/docs/appearance/structured-data/intro-structured-data), [Web Vitals](https://web.dev/articles/vitals).

## 1. Domain, infrastructure and production data

- Confirm domain ownership, DNS records for root and www, nameservers, CDN/proxy, trusted TLS cert with renewal and HTTP→HTTPS behavior. Test canonical redirects, no redirect loops.
- Separate production and staging domains/data. Authenticate or noindex staging appropriately; production must never ship test API keys, localhost redirects or demo payment endpoints.
- Verify auth/OAuth callbacks, email domain, password-reset/invite links, CORS and allowed origins for canonical HTTPS host. Sensitive Google OAuth scopes may require separate consent verification by Google (not Google Play).
- Database migrations/backups **plus successful restore test**; queue workers, cron, storage private/public ACLs, rate limits, CDN cache, retries and cleanup.
- Email deliverability: SPF/DKIM/DMARC per provider; verify actual delivered confirmation, password reset and support/cancellation message, not just API accepted response.
- Health endpoint, alerts, escalation contacts, rollback build and schema compatibility.

## 2. Google Search and public SEO

| Check | Concrete test | Important limit |
|---|---|---|
| Crawlability | Public page returns HTTP 200 and is not blocked by robots/auth/noindex; inspect unauthenticated in Search Console | Private dashboards/user content must NOT be exposed or indexed |
| Rendering | Crawler can access meaningful indexable body content/HTML; verify JS rendering if used | Search eligibility ≠ indexing guarantee |
| Titles/content | Unique informative title, H1, useful text, descriptive internal links, appropriate meta information | No keyword stuffing or invented service claims |
| Canonical | Correct canonical URLs and intentional redirects; hreflang only for real localized counterparts | Avoid conflicting canonical/hreflang |
| Sitemap | XML or other supported sitemap with absolute canonical public URLs, submit through Search Console | Discovery hint, not ranking/index promise |
| Robots | Intentional robots.txt and page-level indexing controls tested for actual production domain | Robots is NOT an access-control mechanism |
| Structured data | Mark up only visible facts using Google-supported types, run Rich Results Test | Valid schema does not guarantee rich-result display |
| Search Console | Verify site/property, URL Inspection, sitemap, coverage and crawl/report findings | Recheck after deployment |
| Localization | Hebrew/RTL, English, language switching, currency, dates and accessible text | No mismatched translations |
| Social previews | Open Graph metadata, accurate share title/image/description and correct canonical destination | Social crawling varies by platform |

Sample checks (adapt to real host, no credentials):
- curl -I https://example.com/
- curl -I https://www.example.com/
- curl -I https://example.com/robots.txt
- curl -I https://example.com/sitemap.xml

HTTP 200 on a sitemap does not establish correct URLs. Inspect and validate its contents.

## 3. Performance, usability and design

- Google Core Web Vitals typical **good** field thresholds at p75: **LCP ≤ 2.5 s, INP ≤ 200 ms, CLS ≤ 0.1** on mobile/desktop separately. These are user-experience targets, not hard Google Search acceptance gates.
- Lighthouse/DevTools lab tests, mobile throttling and real-user performance monitoring when traffic exists. Optimize images/fonts/bundles/hydration, caching and layout stability.
- Test new and returning users, signup/deletion, real purchase/booking state, form errors, denied permissions, network drops, background jobs, return/restore.
- Accessible navigation, focus, keyboard, contrast, mobile touch, screen reader, zoom and RTL; correct UI for supported breakpoints.
- PWA as applicable: manifest, icon, service worker cache/update, offline fallback, push permission and installed-app links on supported systems.

## 4. Security, privacy and legal conditions

- Server-side authorization for every route and tenant (RLS where applicable); private storage and media, server-bound webhook signatures, short-lived tokens, secrets in secret manager only.
- SAST, SCA, vulnerability scanning, secrets scanning and relevant DAST on authorized environments; [security verification](../../patterns/security/README.md).
- Consent-controlled tracking where required, approved privacy policy/Terms and meaningful collection notices; account data/export/deletion and real vendor retention/backup policies.
- Enforce CSRF/XSS/CSP and secure cookies/session handling as appropriate; abuse protection, request size/rate limits, secure uploads.
- Accessibility legal requirements are locale-specific; document verified applicable standard and reviewer.

## 5. Production release and aftercare

1. Pin release SHA, environment, artifact, tenant and migrations.
2. Deploy to staging and run build/static/unit/integration/E2E/security/accessibility with real backend side-effect assertions and recovery scenarios.
3. Release with flag/canary/rolling deployment where practical; verify latest and old clients remain compatible.
4. Run safe production smoke (public + authenticated, no real customer transactions), test domain and link/callback behavior.
5. Verify Google Search Console and sitemap, capture baseline vitals; monitor indexing later.
6. Confirm alerts with controlled synthetic failures and safe support path; document escalation and rollback.
7. Follow [post-launch operations](POST-LAUNCH-OPERATIONS.md) and [release evidence](RELEASE-EVIDENCE-AND-GATES.md).

## Common launch defects

- Staging noindex remains in production, bad canonical/redirect.
- OAuth or email verification points to localhost or wrong environment.
- Private routes/media leaked to sitemap or logged by analytics.
- Client success state shown before backend booking/payment confirmation.
- Uploads stuck without retry or cleanup, or storage bucket publicly open.
- Third-party tracker fires before valid consent where required.
- Missing/misconfigured sender verification or backend service.
- Destructive migration breaks existing sessions/app versions.

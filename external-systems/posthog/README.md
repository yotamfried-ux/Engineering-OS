# PostHog

## Overview
PostHog is an open-source product analytics platform that combines event tracking, session recording, feature flags, A/B testing, and error monitoring in a single self-hostable product. Built by PostHog, Inc., its core value proposition is giving teams full ownership of their user data — everything can run on your own infrastructure with no data leaving your environment.

## Capabilities
- Event-based product analytics with funnels, retention curves, user paths, and cohort analysis
- Session recordings with DOM replay — watch exactly what users did leading up to a conversion or drop-off
- Feature flags with percentage rollouts, targeting by user properties, and multi-variate support
- A/B testing and experimentation with statistical significance tracking
- Heatmaps and click maps (web only) without additional tooling
- Error tracking and performance monitoring with stack traces linked to session recordings
- Group analytics for B2B SaaS: track behavior at the organization/company level, not just individual users
- Surveys and in-app feedback widgets
- Data pipelines: export events to BigQuery, S3, Snowflake, or Redshift for warehouse analysis
- PostHog cloud (US and EU regions) or fully self-hosted on any Docker/Kubernetes environment

## When to Use
- Need product analytics + session recording + feature flags in one tool without stitching together Mixpanel + FullStory + LaunchDarkly
- GDPR/HIPAA or data-sovereignty requirement where user data cannot go to third-party SaaS — self-host PostHog on your own infra
- Early-stage product where understanding user behavior, running feature experiments, and fixing bugs all happen in the same tool
- B2B SaaS product needing company-level (group) analytics to track account health and feature adoption

## Limitations
- Self-hosted PostHog requires non-trivial infra for high-traffic sites (Kafka, ClickHouse, Redis) — the all-in-one Docker Compose is only for low volume
- UI is more complex than Mixpanel or Amplitude for non-technical stakeholders — steeper onboarding for PMs
- Session recordings have a storage and processing cost at high volume, even on PostHog Cloud
- Experimentation (A/B testing) is less mature statistically than dedicated tools like Statsig or Optimizely — limited sequential testing support
- PostHog Cloud free tier limits are strict (1M events/month); self-hosted has no such limits but requires ops expertise

## Integration Guide
1. Sign up at https://posthog.com or deploy self-hosted via Docker Compose
2. Install the SDK: `npm install posthog-js` (browser), `pip install posthog` (Python/backend), or use the mobile SDKs
3. Initialize and capture events:
   ```javascript
   import posthog from "posthog-js";
   posthog.init("phc_your_project_api_key", {
     api_host: "https://us.i.posthog.com", // or your self-hosted URL
   });
   posthog.identify("user_123", { email: "user@example.com", plan: "pro" });
   posthog.capture("checkout_completed", { revenue: 49, plan: "pro" });
   ```
4. For feature flags: `posthog.isFeatureEnabled("new-checkout")` — returns boolean; wrap new code paths with this guard
5. For server-side events (backend), use the Python/Node SDK with your project API key and the `capture()` method — events are batched and sent asynchronously
6. For group analytics: call `posthog.group("company", "acme_inc", { name: "Acme Inc", plan: "enterprise" })` to associate subsequent events with the company

## Setup
```bash
# Browser (npm)
npm install posthog-js

# Python (server-side)
pip install posthog

# Node.js (server-side)
npm install posthog-node

# Self-hosted (Docker Compose — low volume only)
git clone https://github.com/PostHog/posthog
cd posthog
docker compose -f docker-compose.yml up -d

# Environment variables
export POSTHOG_API_KEY=phc_your_project_api_key
export POSTHOG_HOST=https://us.i.posthog.com  # or your self-hosted URL
```

## Pricing Notes
- **PostHog Cloud free tier:** 1M events/month, 5K session recordings/month, unlimited feature flags — sufficient for early-stage products
- **Paid:** ~$0.00005/event after 1M/month; session recordings ~$0.005/recording; A/B testing included at any paid tier
- **Self-hosted:** Free and open-source (MIT license); pay only for your infrastructure
- Watch for: session recordings are the largest cost driver on PostHog Cloud — set sampling rates (e.g., record 10% of sessions) to control costs; self-hosted at high volume requires significant Kafka/ClickHouse compute

## Reference Repositories
- [PostHog/posthog](https://github.com/PostHog/posthog) — full PostHog platform source (Python/Django backend, React frontend)
- [PostHog/posthog-js](https://github.com/PostHog/posthog-js) — official browser JavaScript SDK
- [PostHog/posthog-python](https://github.com/PostHog/posthog-python) — official Python SDK for server-side event capture

## Official Documentation
- [PostHog Docs](https://posthog.com/docs) — complete guides for all features
- [JavaScript Web SDK](https://posthog.com/docs/libraries/js) — browser SDK setup and autocapture configuration
- [Feature Flags](https://posthog.com/docs/feature-flags) — rollout, targeting, and local evaluation
- [Self-Hosting](https://posthog.com/docs/self-host) — Docker and Kubernetes deployment guides

## Common Pitfalls
- **Autocapture vs. explicit events** — PostHog's autocapture records clicks and pageviews automatically, but these events have unstable names that change with UI refactors; for reliable funnel analysis, always instrument explicit `posthog.capture()` calls for key actions.
- **`identify()` should be called once per session after login** — calling it on every page load with the same user creates unnecessary noise; call it once after sign-in and once after sign-out (with `posthog.reset()`).
- **Feature flag local evaluation requires a personal API key** — local evaluation (no network call) needs a server-side personal API key with the flags bootstrap; without it, every `isFeatureEnabled()` call is a network request, adding latency.

## Examples
1. **Funnel drop-off analysis:** Instrument signup → onboarding step 1 → step 2 → first value event with `posthog.capture()` → build a funnel in PostHog → session recordings filtered to users who dropped off at step 2 reveal a confusing UI element → fix deployed behind a feature flag to 10% of users → funnel conversion tracked in real time.
2. **Feature flag rollout:** New pricing page wrapped in `if posthog.isFeatureEnabled("new-pricing")` → roll out to 5% of users → monitor conversion rate and error tracking in PostHog — if both improve, increment rollout to 100% and archive the flag.
3. **B2B account health dashboard:** `posthog.group("company", company_id)` on every event → PostHog Groups dashboard shows per-account feature adoption, session frequency, and last-active date → CS team uses this to identify accounts at churn risk without building a custom analytics query.

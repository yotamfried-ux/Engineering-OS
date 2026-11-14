# Product Analytics, Experimentation, Growth & Launch Readiness

## Official tool and methodology references

| Source | URL | Primary use |
|---|---|---|
| Google Analytics developer docs | https://developers.google.com/analytics | Web/app event collection and reporting |
| Google Tag Manager | https://developers.google.com/tag-platform/tag-manager | Governed tagging and consent-aware implementation |
| Amplitude documentation | https://amplitude.com/docs | Product funnels, cohorts and retention |
| Mixpanel documentation | https://docs.mixpanel.com/ | Product events, segmentation and funnels |
| PostHog documentation | https://posthog.com/docs | Product analytics, feature flags, experiments, session replay |
| Statsig documentation | https://docs.statsig.com/ | Experimentation and feature rollout |
| LaunchDarkly docs | https://launchdarkly.com/docs | Feature flags, progressive rollout |
| GrowthBook docs | https://docs.growthbook.io/ | Experiment analysis and feature flags |
| Google Search Central | https://developers.google.com/search/docs | SEO, indexing and structured data |
| Google web.dev | https://web.dev/ | Performance, discoverability and usability |
| Microsoft Clarity docs | https://learn.microsoft.com/en-us/clarity/ | Session behavior analysis with privacy safeguards |

## Measurement plan: define before implementation

North-star metric, acquisition, activation, engagement, retention, referral and revenue; map each to explicit events and owner. For booking: `booking_page_viewed`, `service_selected`, `slot_selected`, `booking_submitted`, `booking_confirmed`, `booking_cancelled`. Do not log sensitive form values, emails or direct identifiers as analytics properties.

Event dictionary fields: event_name, description, trigger, anonymous/user identity policy, allowed properties and types, consent basis, retention, source, owner, schema version and QA checks.

Funnels should distinguish users vs events, sessions vs people, unique vs repeat conversion, and conversion window. Segment by acquisition source, device, language, new/returning, plan and cohort only where lawful and statistically meaningful.

## Experiment protocol

1. State falsifiable hypothesis, primary metric, guardrail metrics and minimum detectable effect.
2. Define eligible population, randomization unit, traffic allocation, sample-size/power plan and stopping rules before exposure.
3. Validate assignment, exposure logging and instrumentation; guard against sample-ratio mismatch.
4. Avoid peeking and cherry-picking; report effect size, uncertainty and practical significance.
5. Check negative effects on accessibility, speed, complaints, refunds and long-term retention.
6. Roll out progressively with rollback plan and monitor real-world outcomes.

## Growth and commercialization beyond engineering

- Positioning, competitive differentiation, messaging and landing-page clarity.
- Acquisition channels, organic search, attribution limitations, paid acquisition unit economics.
- Activation and time-to-value, onboarding, habit loops without coercion.
- Retention cohorts, churn reasons, lifecycle messaging and support feedback.
- Monetization: pricing tiers, conversion to paid, ARPU, LTV/CAC and payback, with explicit assumptions.
- Voice of customer: surveys, interviews, support tickets, review mining and churn interviews.
- Launch readiness: product analytics QA, accessibility, SEO, privacy notice, consent, security, performance and support operations.

## Privacy and ethics gates

Apply applicable Israeli privacy law and any relevant foreign rules before enabling analytics, session recording, cookies or profiling. Verify current requirements with qualified counsel where necessary. Minimize data, honor consent choices, configure retention/access controls, and never capture passwords, payment details or sensitive fields in replay.

## Agent completion checklist

- Event schema validated with test events, duplicate suppression and cross-device assumptions documented.
- Funnel queries reconcile with transactional backend totals within a documented tolerance.
- Experiment has pre-registered metrics and stopping rule.
- Dashboard differentiates observed results from causal conclusions.
- Instrumentation and experiments have rollback and privacy review.


## Organic social content strategy: official platform documentation

This section documents **official platform guidance and measurement interfaces**, not advice from social-media creators. Content strategy claims are hypotheses until measured on the target account.

### Primary sources

| Official source | Documented use |
| --- | --- |
| [YouTube Help: new, casual and regular viewers](https://support.google.com/youtube/answer/10246996/understand-returning-amp-new-viewers-data) | Audience segmentation; familiar topics, formats and branding for returning viewers |
| [YouTube Help: audience development tips](https://support.google.com/youtube/answer/13615784) | Experimenting with topics for discovery, series for loyalty, community engagement |
| [YouTube Help: audience analytics](https://support.google.com/youtube/answer/9314416) | Audience interests, formats watched, new and returning viewers |
| [YouTube Help: key moments for audience retention](https://support.google.com/youtube/answer/9314415) | Retention, intros, spikes, dips and segment-level improvement |
| [Meta Instagram Graph API: IG User Insights](https://developers.facebook.com/docs/graph-api/reference/shadow-ig-user/insights/) | Official documented metrics include reach, follows/unfollows, views, shares and saves; access, availability and metric definitions depend on account and API context |

### Reusable agent workflow

1. Define a target audience, topic pillars and 2-3 repeatable formats; create a content calendar with sustainable cadence. Consistency is a **strategy to test**, not a guaranteed ranking signal.
2. Build a backlog of candidate ideas from documented audience interests, customer questions, and prior high-performing content. Track topic, angle, audience need and intended action.
3. For each published item, record platform, format, publish time, content pillar, hook, reach/views, shares, saves, follows attributable where supported, and retention metrics where available.
4. Compare performance within similar formats and distribution windows. Use rates with explicitly stated denominators (e.g. shares/reach, saves/reach); never conflate views, accounts reached, followers or unique viewers.
5. Test the hypotheses that consistent series improve returning viewers, shareable ideas increase distribution, and save-worthy content correlates with future engagement. Do not assert platform algorithm causality without suitable evidence.
6. Review weekly; keep privacy-safe aggregated data, document confounders, and avoid fabricated metrics or unapproved account access.

### Evidence boundaries

Official documentation supports **measurement and platform-specific creator guidance**, not a universal formula such as `shares = views` or `saves = followers`. The Instagram discovery clip is deliberately **not cited as a knowledge source**. No claims about Instagram ranking internals are made here.

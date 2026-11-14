# When to split a web backend — architecture decision record

**Type:** engineering knowledge, not an installable tool. Use measurable requirements, **not** a fixed threshold of 1,000 users.

Official sources:
- [Next.js Route Handlers](https://nextjs.org/docs/app/getting-started/route-handlers)
- [Next.js Server Functions and Actions](https://nextjs.org/docs/app/getting-started/updating-data)
- [Nuxt server directory](https://nuxt.com/docs/guide/directory-structure/server)

Next.js Route Handlers and Nuxt server routes can implement server-side APIs in the same repository and deployment as the UI. For a simple application, keeping the backend co-located reduces separate deployment and configuration surfaces. However, a separate backend may be warranted **at any user count** when independent scaling, worker runtime constraints, isolation, specialized workloads, organizational ownership, or external API consumers justify it.

Agent decision checklist: enumerate current server responsibilities, data boundaries, job duration, deployment limitations, latency/SLOs, authentication and secret handling; compare integrated and separated architectures for complexity, security, operating cost and testability; record an ADR and migration trigger. Never assume server-side framework routes remove the need for access controls, transactions, queues or database policies.

The screenshot's broader list of premature-optimization examples (microservices, Redis cache, custom auth, dashboards, multi-region, language rewrites, four nines, sharding and 100% test coverage) is **not** an evidence-backed universal prohibition. Decide each based on real requirements; security and correctness are non-negotiable at small scale.

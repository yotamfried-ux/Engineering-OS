# Web Frameworks & Platforms

## Overview
Consult this guide when choosing a web framework for a new project or evaluating migration options. Use it alongside `core/connector-policy.md` when a platform decision involves infrastructure or hosting. This guide covers full-stack frameworks, server-side rendering (SSR), static site generation (SSG), single-page apps (SPA), and lightweight API routers.

**Decision heuristic:**
- React ecosystem + full-stack + production scale → Next.js
- React + fine-grained data loading + progressive enhancement → Remix
- Vue ecosystem → Nuxt
- Svelte + minimal bundle + simplicity → SvelteKit
- Python team + batteries-included → Django
- PHP team + rapid CRUD → Laravel
- Ruby team + convention-heavy → Rails
- Edge/serverless lightweight API → Hono

## Frameworks

### Next.js
**Type:** Full-stack React framework  
**Language:** TypeScript / JavaScript  
**Best For:** Production React apps requiring SSR, SSG, or hybrid rendering; teams that want a single framework for frontend and API routes  
**Official Docs:** https://nextjs.org/docs  
**GitHub:** https://github.com/vercel/next.js  
**Key Strengths:**
- App Router enables React Server Components for zero-bundle server-side logic
- Built-in image optimization, font optimization, and route-level caching
- First-class Vercel deployment with edge middleware support
- Large ecosystem and community; de-facto standard for React at scale
- Supports SSR, SSG, ISR (Incremental Static Regeneration), and SPA modes simultaneously

**Watch Out For:**
- App Router vs Pages Router split causes documentation fragmentation; verify which paradigm examples target
- Caching behavior in App Router is complex and has shifted across minor versions — always pin and read release notes
- Vendor alignment with Vercel; some features are optimized for Vercel's infrastructure and behave differently on self-hosted deployments

---

### Remix
**Type:** Full-stack React framework  
**Language:** TypeScript / JavaScript  
**Best For:** Apps with complex, nested data-loading requirements; teams that prioritize progressive enhancement and web platform standards  
**Official Docs:** https://remix.run/docs  
**GitHub:** https://github.com/remix-run/remix  
**Key Strengths:**
- Nested route loaders and actions colocate data-fetching with UI, eliminating waterfall fetches
- Built on web-standard Request/Response APIs — runs on Node, Deno, Cloudflare Workers, and more
- Automatic error boundaries and deferred streaming with `<Await>` for progressive loading
- Form submissions are first-class citizens; no client-side fetch boilerplate for mutations

**Watch Out For:**
- SSG is partial and limited compared to Next.js — not suitable for large static sites
- Smaller ecosystem than Next.js; fewer third-party integrations are Remix-native
- Acquired by Shopify (2022) and merged direction with React Router v7 — verify current project status before committing

---

### Nuxt
**Type:** Full-stack Vue framework  
**Language:** TypeScript / JavaScript (Vue)  
**Best For:** Vue teams that need SSR, SSG, or hybrid rendering with a batteries-included experience  
**Official Docs:** https://nuxt.com/docs  
**GitHub:** https://github.com/nuxt/nuxt  
**Key Strengths:**
- Auto-imports for components, composables, and utilities — reduces boilerplate significantly
- Universal rendering: switch per-route between SSR, SSG, SPA, and ISR via `routeRules`
- Nuxt Modules ecosystem provides first-class integrations for auth, i18n, image, and more
- Nitro server engine enables deployment to Node, edge runtimes, and serverless with minimal config

**Watch Out For:**
- Magic auto-imports improve DX but can obscure where values originate — use IDE tooling (Volar) to trace imports
- Nuxt 3 is a full rewrite from Nuxt 2; migration is non-trivial for large codebases
- Smaller talent pool than React-based frameworks in most hiring markets

---

### SvelteKit
**Type:** Full-stack Svelte framework  
**Language:** TypeScript / JavaScript (Svelte)  
**Best For:** Teams prioritizing minimal runtime bundle size, developer simplicity, and avoiding virtual DOM overhead  
**Official Docs:** https://kit.svelte.dev/docs  
**GitHub:** https://github.com/sveltejs/kit  
**Key Strengths:**
- Svelte compiles components to vanilla JS — no virtual DOM, resulting in smaller bundles and faster runtime
- File-based routing with colocated `+page.server.ts` load functions mirrors Remix's data-loading model
- Built-in adapters for Node, Vercel, Netlify, Cloudflare Pages, and static output
- Simple reactivity model reduces cognitive overhead for state management

**Watch Out For:**
- Svelte 5 introduced runes — a significant reactivity model change; verify which version tutorials and libraries target
- Smaller ecosystem and fewer UI component libraries compared to React or Vue
- Less enterprise adoption means fewer established patterns for large-scale architecture

---

### Django
**Type:** Full-stack web framework (server-rendered)  
**Language:** Python  
**Best For:** Python teams building data-driven apps, admin interfaces, or APIs with extensive ORM needs; projects that benefit from a mature, batteries-included framework  
**Official Docs:** https://docs.djangoproject.com  
**GitHub:** https://github.com/django/django  
**Key Strengths:**
- Built-in ORM, admin interface, authentication, forms, and migration system — minimal setup for CRUD apps
- Django REST Framework (DRF) makes building REST APIs straightforward with serializers and viewsets
- Strong security defaults: CSRF protection, SQL injection prevention, XSS escaping out of the box
- Mature ecosystem with 20+ years of production use across high-traffic sites

**Watch Out For:**
- Synchronous by default; async support (ASGI/channels) exists but is bolted on, not native
- Template system is intentionally limited — not suited for complex client-side interactivity without a separate JS layer
- ORM can generate inefficient queries on complex relationships; use `select_related`/`prefetch_related` and query analysis tools

---

### Laravel
**Type:** Full-stack web framework (server-rendered)  
**Language:** PHP  
**Best For:** PHP teams building web apps or APIs rapidly; projects where the team is already invested in the PHP ecosystem  
**Official Docs:** https://laravel.com/docs  
**GitHub:** https://github.com/laravel/laravel  
**Key Strengths:**
- Eloquent ORM, Blade templating, Artisan CLI, queues, scheduling, and broadcasting included out of the box
- Laravel Jetstream and Breeze provide scaffolding for auth, including Livewire and Inertia.js stacks
- Inertia.js enables building SPAs with React/Vue without a separate API — a compelling full-stack alternative to Next.js for PHP shops
- Vast shared-hosting compatibility and low barrier to deployment

**Watch Out For:**
- PHP's historical reputation affects hiring; team skill availability varies by region
- "Magic" Facade pattern can make tracing code paths and writing unit tests non-obvious for newcomers
- Performance ceiling is lower than Node or compiled-language backends without additional infrastructure (Octane, FrankenPHP)

---

### Rails
**Type:** Full-stack web framework (server-rendered)  
**Language:** Ruby  
**Best For:** Ruby teams prioritizing convention over configuration, rapid prototyping, and monolithic application development  
**Official Docs:** https://guides.rubyonrails.org  
**GitHub:** https://github.com/rails/rails  
**Key Strengths:**
- Convention-over-configuration minimizes boilerplate — standard CRUD apps require minimal decisions
- Active Record, Action Cable (WebSockets), Action Mailer, Active Job, and Active Storage all included
- Hotwire (Turbo + Stimulus) enables SPA-like interactivity without JavaScript frameworks
- Battle-tested at scale (GitHub, Shopify, Basecamp); rich ecosystem of gems

**Watch Out For:**
- Ruby's ecosystem is smaller than it was at peak Rails popularity — fewer new libraries, slower hiring
- Memory consumption per process is high; horizontal scaling requires careful tuning
- "Magic" metaprogramming makes stack traces and debugging less transparent than explicit frameworks

---

### Hono
**Type:** Lightweight web framework / API router  
**Language:** TypeScript / JavaScript  
**Best For:** Edge and serverless API endpoints, middleware-heavy routing, lightweight backend services, and multi-runtime deployments  
**Official Docs:** https://hono.dev/docs  
**GitHub:** https://github.com/honojs/hono  
**Key Strengths:**
- Runs natively on Cloudflare Workers, Deno, Bun, Node, AWS Lambda, and Vercel Edge without adaptation
- Tiny core (~14 kB) with a familiar Express-like routing API and full TypeScript support
- Built-in RPC client (`hono/client`) enables type-safe API calls from frontend code
- Middleware ecosystem covers auth, CORS, rate limiting, caching, and more

**Watch Out For:**
- Not a full-stack framework — no built-in ORM, templating beyond JSX, or admin; pair with a database client and separate frontend
- Community and third-party ecosystem is young compared to Express or Fastify
- Edge runtime constraints (no native Node modules, limited CPU time per request) apply when targeting Cloudflare Workers

---

## Rendering Model Quick Reference

| Framework | SSR | SSG | SPA | Edge Runtime |
|---|---|---|---|---|
| Next.js | ✓ | ✓ | ✓ | ✓ (App Router) |
| Remix | ✓ | partial | ✗ | ✓ |
| Nuxt | ✓ | ✓ | ✓ | ✓ |
| SvelteKit | ✓ | ✓ | ✓ | ✓ |
| Django | ✓ | ✗ | ✗ | ✗ |
| Laravel | ✓ | ✗ | ✗ | ✗ |
| Rails | ✓ | ✗ | ✗ | ✗ |
| Hono | ✓ | ✗ | ✗ | ✓ |

## Official Starter Templates

| Framework | Starter Repository | Stars |
|---|---|---|
| Next.js | [vercel/next.js/examples](https://github.com/vercel/next.js/tree/canary/examples) | 130k+ |
| Next.js (T3) | [t3-oss/create-t3-app](https://github.com/t3-oss/create-t3-app) | 25k+ |
| Remix | [remix-run/remix/templates](https://github.com/remix-run/remix/tree/main/templates) | 30k+ |
| Nuxt | [nuxt/starter](https://github.com/nuxt/starter) | — |
| SvelteKit | [sveltejs/kit/create-svelte](https://github.com/sveltejs/kit/tree/master/packages/create-svelte) | 20k+ |
| Django | [wsvincent/django-starter-project](https://github.com/wsvincent/django-starter-project) | — |
| Hono | [honojs/hono/examples](https://github.com/honojs/hono/tree/main/examples) | 22k+ |

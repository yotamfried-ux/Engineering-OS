# Web / Frontend — Common Bugs & Fixes

> Sources: Next.js error docs, React docs, Vercel troubleshooting, MDN Web Docs, web.dev

## Hydration

| Symptom | Root Cause | Fix |
|---|---|---|
| `Hydration failed because the initial UI does not match` | Server and client render different HTML | Don't use `Date.now()`, `Math.random()`, or browser APIs in render; use `useEffect` for client-only values |
| `window is not defined` on server | Accessing browser global during SSR | Guard with `typeof window !== "undefined"` or move to `useEffect` |
| HTML nesting warning causes hydration error | Invalid HTML structure (e.g., `<p>` inside `<p>`) | Fix semantic HTML; use `<div>` instead of `<p>` for block containers |
| Hydration mismatch with auth state | Server renders unauthenticated, client rehydrates with user | Use a loading state for auth-dependent UI; render consistently on both sides |

## Caching (Next.js / Vercel)

| Symptom | Root Cause | Fix |
|---|---|---|
| Stale data after deploy | `fetch` with `cache: "force-cache"` in Server Components | Use `revalidate` or `cache: "no-store"` for dynamic data; use ISR for semi-static |
| Page not updating after content change | ISR `revalidate` interval too long | Call `revalidatePath()` / `revalidateTag()` on-demand after CMS updates |
| API response cached unexpectedly | Next.js auto-caches `fetch` in Server Components | Opt out with `{ cache: "no-store" }` or `{ next: { revalidate: 0 } }` |
| `cookies()` / `headers()` breaks static generation | Dynamic functions prevent static rendering | Move dynamic data fetching to Client Component or use route segment config `dynamic = "force-dynamic"` |

## CORS

| Symptom | Root Cause | Fix |
|---|---|---|
| `CORS policy` error in browser | API not returning `Access-Control-Allow-Origin` header | Add CORS headers on the API server; for Next.js API routes use `cors` npm package or set headers manually |
| Preflight `OPTIONS` request fails | Server doesn't handle `OPTIONS` method | Return 200 for OPTIONS with appropriate CORS headers |
| Cookie not sent on cross-origin request | `credentials: "include"` not set | Set `credentials: "include"` on `fetch`; set `Access-Control-Allow-Credentials: true` and explicit origin (not `*`) |

## Performance

| Symptom | Root Cause | Fix |
|---|---|---|
| Large bundle size | Importing entire library instead of tree-shakable subset | Use named imports; check bundle with `@next/bundle-analyzer`; use dynamic `import()` for heavy components |
| LCP (Largest Contentful Paint) poor | Hero image not prioritized | Add `priority` prop to `next/image` for above-the-fold images |
| Layout shift (CLS) | Image without dimensions or dynamic content inserting above existing content | Always set `width`/`height` on images; reserve space for dynamic content |
| Fonts causing FOUT | Font loaded after initial render | Use `next/font` with `display: "swap"`; preconnect to font CDN |

## State Management

| Symptom | Root Cause | Fix |
|---|---|---|
| State persists across user sessions | Global state (Zustand store, Redux) not reset on logout | Clear all stores on logout; scope user state to auth context |
| State updates not reflected in UI | Mutating state directly instead of returning new object | Always return new object/array from state updaters; never mutate |
| Infinite re-render loop | `useEffect` dependency array includes an object/array created in render | Memoize objects with `useMemo`; use primitive dependencies where possible |

## Sources
- [Next.js Error Docs](https://nextjs.org/docs/messages)
- [React Hydration Errors](https://react.dev/link/hydration-mismatch)
- [Vercel Troubleshooting](https://vercel.com/docs/errors)
- [web.dev Core Web Vitals](https://web.dev/vitals/)
- [MDN CORS Guide](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)

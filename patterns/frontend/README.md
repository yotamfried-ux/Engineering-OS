# Frontend Patterns
> See [pattern-lifecycle.md](../../core/pattern-lifecycle.md) for scoring.

## Overview

Patterns for building performant, maintainable React/Next.js frontends. Covers the Server/Client Component boundary in the App Router, optimistic UI updates, rendering large lists without jank, and form state with schema validation. Apply these before reaching for heavier abstractions.

---

## Pattern: Server Components vs Client Components

**Problem:** In the Next.js App Router every component is a Server Component by default, but adding `"use client"` too high in the tree forces entire subtrees to run in the browser, bloating the bundle and losing server-side data access.

**Solution:** Keep data fetching and static markup in Server Components; push `"use client"` as far down the tree as possible to the smallest interactive leaf that actually needs it.

**Implementation Notes:**
- Server Components can `async/await` directly — no `useEffect` needed for initial data.
- Client Components cannot import Server Components; the boundary is one-way (server → client).
- Pass server-fetched data to Client Components as props — never re-fetch on the client what you already have.
- Shared layout wrappers (nav, shell) should stay as Server Components; only interactive islands go client.
- Use `React.lazy` / `dynamic({ ssr: false })` for third-party widgets that access `window`.

**Example:**
```tsx
// app/dashboard/page.tsx — Server Component
import { MetricsCard } from "./MetricsCard"; // Client Component

export default async function DashboardPage() {
  const metrics = await fetchMetrics(); // runs on server, never ships to browser
  return <MetricsCard initialData={metrics} />;
}

// components/MetricsCard.tsx — Client Component
"use client";
import { useState } from "react";

export function MetricsCard({ initialData }: { initialData: Metrics }) {
  const [data, setData] = useState(initialData);
  return <div onClick={() => refresh(setData)}>{data.value}</div>;
}
```

**Common Mistakes:**
- Wrapping the entire `<body>` in `"use client"` — makes the whole app a client bundle.
- Importing a Client Component into a Server Component is fine; the reverse is not.
- Calling `cookies()` or `headers()` inside a Client Component — these are server-only APIs.

**Security Considerations:**
- Never pass secret env vars as props from Server to Client Components; they will be serialized into the HTML.
- Validate and sanitize all data on the server before passing it down, even as props.

**Testing:**
Test Server Components with integration tests (e.g., `@testing-library/react` with Next.js test utilities or Playwright). Client Component units can be tested with `render()` from `@testing-library/react` in jsdom. Assert that props received by the Client Component match what the server would supply.

---

## Pattern: Optimistic Updates

**Problem:** Waiting for a server round-trip before reflecting user actions (e.g., liking a post, reordering a list) makes the UI feel sluggish even on fast connections.

**Solution:** Apply the change to local state immediately, fire the server request in the background, and roll back to the previous state if the request fails.

**Implementation Notes:**
- Store a snapshot of the pre-mutation state before applying the optimistic change.
- Use `useOptimistic` (React 19+) or manage a `pendingState` manually with `useState`.
- Always show a subtle error toast and revert on failure — silent rollbacks confuse users.
- Avoid optimistic updates for destructive or irreversible actions (delete account, charge payment).

**Example:**
```tsx
"use client";
import { useOptimistic, useTransition } from "react";

export function LikeButton({ post }: { post: Post }) {
  const [optimisticPost, setOptimistic] = useOptimistic(post);
  const [, startTransition] = useTransition();

  function handleLike() {
    startTransition(async () => {
      setOptimistic({ ...optimisticPost, likes: optimisticPost.likes + 1 });
      try {
        await likePost(post.id);
      } catch {
        // useOptimistic auto-reverts when the transition settles with an error
        toast.error("Failed to like post");
      }
    });
  }

  return <button onClick={handleLike}>♥ {optimisticPost.likes}</button>;
}
```

**Common Mistakes:**
- Not reverting on network error — leaves UI out of sync with server state.
- Applying optimistic updates to paginated lists without reconciling the server response.
- Mutating the original object instead of creating a new reference (breaks React's diffing).

**Security Considerations:**
- The server must still validate and authorize every mutation — the client-side change is cosmetic only.

**Testing:**
Mock the API call to reject. Assert that the UI reverts to its original state and the error toast appears. Also test the happy path: mock a successful response and confirm the optimistic value persists after the server confirms.

---

## Pattern: Infinite Scroll / Virtual List

**Problem:** Rendering thousands of DOM nodes at once causes layout thrashing, high memory use, and slow initial paint; yet users expect seamless scrolling through large datasets.

**Solution:** Use an `IntersectionObserver` sentinel at the bottom of the list to trigger the next page fetch (infinite scroll), and render only the rows currently in the viewport using a windowing library (virtual list).

**Implementation Notes:**
- For infinite scroll alone (moderate lists ~200–500 items): `IntersectionObserver` + cursor pagination is sufficient.
- For very large lists (1 000+ items): add `@tanstack/react-virtual` or `react-window` to virtualize the DOM.
- Always show a skeleton loader or spinner while the next page loads.
- Debounce or throttle the observer callback to avoid multiple simultaneous fetches.

**Example:**
```tsx
"use client";
import { useRef, useEffect } from "react";
import { useInfiniteQuery } from "@tanstack/react-query";

export function PostList() {
  const sentinelRef = useRef<HTMLDivElement>(null);
  const { data, fetchNextPage, hasNextPage, isFetchingNextPage } =
    useInfiniteQuery({
      queryKey: ["posts"],
      queryFn: ({ pageParam }) => fetchPosts(pageParam),
      getNextPageParam: (last) => last.nextCursor ?? undefined,
      initialPageParam: undefined,
    });

  useEffect(() => {
    const el = sentinelRef.current;
    if (!el) return;
    const observer = new IntersectionObserver(([entry]) => {
      if (entry.isIntersecting && hasNextPage && !isFetchingNextPage) {
        fetchNextPage();
      }
    });
    observer.observe(el);
    return () => observer.disconnect();
  }, [hasNextPage, isFetchingNextPage, fetchNextPage]);

  const posts = data?.pages.flatMap((p) => p.items) ?? [];
  return (
    <>
      {posts.map((post) => <PostRow key={post.id} post={post} />)}
      <div ref={sentinelRef} />
      {isFetchingNextPage && <Spinner />}
    </>
  );
}
```

**Common Mistakes:**
- Placing the sentinel inside a container with `overflow: hidden` — the observer never fires.
- Not cleaning up the `IntersectionObserver` in the `useEffect` return — causes memory leaks.
- Forgetting to disable the observer when `hasNextPage` is false, triggering repeated empty fetches.

**Security Considerations:**
- Validate cursor tokens server-side to prevent clients from requesting arbitrary data offsets.

**Testing:**
Mock `IntersectionObserver` in jsdom (it is not implemented natively). Trigger the sentinel intersection manually and assert that `fetchNextPage` was called. Test the end-of-list state where `hasNextPage` is false.

---

## Pattern: Form State Management (React Hook Form + Zod)

**Problem:** Managing form field state, validation errors, touched state, and submission loading with `useState` grows combinatorially; ad-hoc validation logic diverges from server-side schemas.

**Solution:** Use React Hook Form for performant, uncontrolled field management and Zod for a single schema that validates on both the client and the server.

**Implementation Notes:**
- Define the Zod schema once and derive the TypeScript type with `z.infer<typeof schema>` — no duplicate type definitions.
- Use `zodResolver` from `@hookform/resolvers/zod` to wire validation.
- Use `formState.errors` for field-level error messages; use `setError("root")` for server-returned errors.
- Call `reset()` after successful submission to clear state.

**Example:**
```tsx
"use client";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";

const schema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
});
type FormData = z.infer<typeof schema>;

export function LoginForm() {
  const { register, handleSubmit, formState: { errors, isSubmitting }, setError } =
    useForm<FormData>({ resolver: zodResolver(schema) });

  async function onSubmit(data: FormData) {
    const result = await login(data);
    if (!result.ok) {
      setError("root", { message: result.error });
    }
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input {...register("email")} />
      {errors.email && <p>{errors.email.message}</p>}
      <input type="password" {...register("password")} />
      {errors.password && <p>{errors.password.message}</p>}
      {errors.root && <p>{errors.root.message}</p>}
      <button disabled={isSubmitting}>Login</button>
    </form>
  );
}
```

**Common Mistakes:**
- Using `watch()` on every field for display purposes — it re-renders on every keystroke; use `getValues()` instead.
- Defining the Zod schema inside the component — recreated on every render, breaking memoization.
- Not handling `setError("root")` for API errors — users see no feedback on server rejection.

**Security Considerations:**
- Client-side Zod validation is UX only. Always re-validate with the same schema server-side (e.g., in a Next.js Server Action or API route) before trusting the data.
- Sanitize string fields server-side even after Zod validation to prevent XSS in rendered output.

**Testing:**
Use `@testing-library/react` with `userEvent` to simulate typing and submission. Assert that invalid input shows the correct error message without submitting. Assert that a mocked server error surfaces via `errors.root`. Assert that the form resets after a successful mock submission.

## Official References
- [React Docs](https://react.dev) — React official documentation
- [Next.js Docs](https://nextjs.org/docs) — full-stack React framework
- [TanStack Query Docs](https://tanstack.com/query/latest/docs/framework/react/overview) — server state management
- [Zustand Docs](https://docs.pmnd.rs/zustand/getting-started/introduction) — lightweight client state
- [Tailwind CSS Docs](https://tailwindcss.com/docs) — utility-first CSS framework

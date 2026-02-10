# Next.js Stack Module

> Framework-specific knowledge for Next.js 14/15 App Router projects. Add to your project's `debugging.md` or `tech-stack.md`.

## Architecture: Server Components vs Client Components

### The Mental Model

By default, **all components in the App Router are React Server Components (RSC)**. They run on the server, have zero client-side JavaScript, and can directly access databases, file systems, and environment variables.

Client Components are opted into with `"use client"` at the top of the file. They run on both server (for SSR) and client, and are required for interactivity (state, effects, event handlers, browser APIs).

### Decision Guide

| Need | Component Type |
|------|---------------|
| Fetch data, access DB | Server Component |
| `useState`, `useEffect` | Client Component (`"use client"`) |
| `onClick`, `onChange`, event handlers | Client Component |
| Access `window`, `localStorage` | Client Component |
| Import a client-only library (e.g., chart lib) | Client Component |
| Static content, no interactivity | Server Component (default) |

### Common Mistakes

**Mistake: Adding `"use client"` to a layout or page just because a child needs it.**
The `"use client"` directive creates a boundary. Everything imported by a client component becomes client code too. Keep the boundary as low as possible in the component tree.

```tsx
// BAD: Entire page is now client-side
"use client"
export default function Page() {
  return <div><InteractiveWidget /><StaticContent /></div>
}

// GOOD: Only the interactive part is client
export default function Page() {
  return <div><InteractiveWidget /><StaticContent /></div>
}
// InteractiveWidget.tsx has "use client", StaticContent.tsx does not
```

**Mistake: Trying to pass non-serializable props from Server to Client Components.**
Props crossing the server/client boundary must be serializable (no functions, no classes, no Date objects).

## useSearchParams and Suspense

**This is the #1 missed gotcha in Next.js 15.**

`useSearchParams()` must be wrapped in a Suspense boundary, or the entire page will opt into client-side rendering during the build.

```tsx
// BAD: Build warning or error
"use client"
import { useSearchParams } from 'next/navigation'

export default function Page() {
  const searchParams = useSearchParams() // Breaks static generation
  return <div>{searchParams.get('q')}</div>
}

// GOOD: Wrapped in Suspense
import { Suspense } from 'react'
import { SearchResults } from './SearchResults'

export default function Page() {
  return (
    <Suspense fallback={<div>Loading...</div>}>
      <SearchResults />
    </Suspense>
  )
}
```

## Middleware

### Pattern: Auth Protection

```typescript
// middleware.ts (root of project)
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export function middleware(request: NextRequest) {
  const token = request.cookies.get('session')?.value

  // Protect dashboard routes
  if (request.nextUrl.pathname.startsWith('/dashboard') && !token) {
    return NextResponse.redirect(new URL('/login', request.url))
  }

  return NextResponse.next()
}

export const config = {
  // Skip middleware for static files and API routes you want public
  matcher: ['/((?!api/public|_next/static|_next/image|favicon.ico).*)'],
}
```

### Middleware Gotchas

- Middleware runs on the **Edge Runtime** — no Node.js APIs (no `fs`, no native modules)
- Middleware runs on **every matched request**, including prefetches — keep it fast
- Cannot modify the response body, only headers/cookies and redirects
- `matcher` config uses a subset of regex — test patterns carefully

## Metadata API

```typescript
// Static metadata
export const metadata: Metadata = {
  title: 'My App',
  description: 'Description',
  openGraph: { title: 'My App', description: 'Description', images: ['/og.png'] },
}

// Dynamic metadata (for pages with params)
export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const product = await getProduct(params.id)
  return {
    title: product.name,
    description: product.description,
  }
}
```

**Gotcha:** `generateMetadata` blocks rendering — keep data fetches fast or use cached/deduped queries.

## Caching (The Hard Part)

Next.js has four caching layers. Understanding them prevents the most confusing bugs.

### 1. Request Memoization (per-request)
Same `fetch()` call in multiple server components during one render is automatically deduped. Only one network request is made.

### 2. Data Cache (cross-request, server)
`fetch()` results are cached by default in production. To opt out:
```typescript
fetch(url, { cache: 'no-store' })        // Never cache
fetch(url, { next: { revalidate: 60 } }) // Cache for 60 seconds
```

### 3. Full Route Cache (build-time)
Static routes are rendered at build time and cached. Dynamic routes (using `cookies()`, `headers()`, `searchParams`) skip this cache.

### 4. Router Cache (client-side, 30s/5min)
Prefetched routes are cached in the browser. **This is the most confusing one.** After a `router.push()`, the user may see stale data.

**Fix stale data after mutation:**
```typescript
import { revalidatePath } from 'next/cache'

// In a Server Action or Route Handler:
revalidatePath('/dashboard') // Revalidate a specific path
revalidateTag('products')    // Revalidate by cache tag
```

```typescript
// Client-side force refresh:
import { useRouter } from 'next/navigation'
const router = useRouter()
router.refresh() // Invalidates the router cache for current route
```

## Environment Variables

| Prefix | Available In | Use Case |
|--------|-------------|----------|
| `NEXT_PUBLIC_` | Server + Client (bundled into JS) | Public API URLs, feature flags |
| No prefix | Server only | API keys, database URLs, secrets |

**Common errors:**
- `process.env.MY_SECRET` is `undefined` in a client component — it needs `NEXT_PUBLIC_` prefix
- `NEXT_PUBLIC_` vars are inlined at **build time**, not runtime — changing them requires a rebuild
- In `.env.local`, no quotes needed around values unless they contain spaces

## Dynamic Routes

```
app/blog/[slug]/page.tsx        → /blog/my-post
app/shop/[...slug]/page.tsx     → /shop/a/b/c (catch-all)
app/shop/[[...slug]]/page.tsx   → /shop OR /shop/a/b/c (optional catch-all)
```

### generateStaticParams

```typescript
// Pre-render known routes at build time
export async function generateStaticParams() {
  const posts = await getPosts()
  return posts.map((post) => ({ slug: post.slug }))
}
```

## Loading and Error Boundaries

```
app/
  dashboard/
    loading.tsx    → Shown while page.tsx is loading (streaming)
    error.tsx      → Shown if page.tsx throws (must be "use client")
    not-found.tsx  → Shown when notFound() is called
    page.tsx
```

**`error.tsx` must be a client component** because error boundaries only work on the client. It receives `error` and `reset` props:

```tsx
"use client"
export default function Error({ error, reset }: { error: Error; reset: () => void }) {
  return (
    <div>
      <h2>Something went wrong</h2>
      <button onClick={() => reset()}>Try again</button>
    </div>
  )
}
```

## Common Build Errors

### `Error: Unsupported Server Component type: undefined`
You're importing a client-only library in a server component, or a component is exporting something unexpected. Check your imports.

### `Error: Event handlers cannot be passed to Client Component props from Server Components`
You're passing an `onClick` (or similar) from a server component to a client component. Move the handler into the client component.

### `Dynamic server usage: headers/cookies`
Calling `headers()` or `cookies()` in a component that Next.js expects to be static. Add `export const dynamic = 'force-dynamic'` to the page, or restructure to avoid these calls in static contexts.

### `TypeError: Cannot read properties of null (reading 'useContext')`
Usually means a client hook (`useState`, `useContext`, etc.) is being used in a server component. Add `"use client"` to the file.

### `Module not found: Can't resolve 'fs'`
You're importing a Node.js module in client-side code. Move the import to a server component, API route, or server action.

### Hydration mismatch warnings
Server and client render different HTML. Common causes:
- Using `Date.now()` or `Math.random()` during render
- Browser extensions injecting elements
- Conditional rendering based on `typeof window`

**Fix:** Use `useEffect` for client-only values, or suppress with `suppressHydrationWarning`.

## Server Actions

```typescript
// Inline in a server component
export default function Page() {
  async function handleSubmit(formData: FormData) {
    "use server"
    const name = formData.get('name')
    await db.insert({ name })
    revalidatePath('/dashboard')
  }

  return <form action={handleSubmit}>...</form>
}

// Separate file (reusable)
// app/actions.ts
"use server"
export async function createItem(formData: FormData) { ... }
```

**Gotcha:** Server Actions are POST requests under the hood. They can be called from client components but the function itself runs on the server. Never put secrets as arguments — the client can see the arguments in network requests.

## Route Handlers (API Routes)

```typescript
// app/api/items/route.ts
import { NextRequest, NextResponse } from 'next/server'

export async function GET(request: NextRequest) {
  const items = await db.query('SELECT * FROM items')
  return NextResponse.json(items)
}

export async function POST(request: NextRequest) {
  const body = await request.json()
  const item = await db.insert(body)
  return NextResponse.json(item, { status: 201 })
}
```

**Gotcha:** Route handlers are cached by default when using `GET` with no dynamic functions. Add `export const dynamic = 'force-dynamic'` if you need fresh data every time.

## Next.js 15 Specific Changes

- `params` and `searchParams` are now **async** in page/layout components — must be `await`ed
- Fetch requests are **no longer cached by default** (reversal from Next.js 14)
- `next/headers` functions (`cookies()`, `headers()`) are now async
- React 19 is used under the hood — `ref` is a regular prop, `forwardRef` is no longer needed

# Debugging Playbook

> Hard-won patterns for common fullstack issues. Add your own as you encounter them.

## Import / Export Safety

**Always grep before removing any export, type, or component.**
Transitive imports mean a file three levels deep might depend on something you think is unused.

```bash
# Before deleting any export
grep -r "ImportName" --include="*.ts" --include="*.tsx" src/
```

- Duplicate export names across files cause silent webpack/turbopack build failures
- Re-exports from barrel files (`index.ts`) mask actual usage — check the barrel too
- Default exports are harder to trace than named exports; prefer named exports
- Circular imports: if A imports B and B imports A, one will be `undefined` at runtime

## Next.js Gotchas

| Problem | Cause | Fix |
|---------|-------|-----|
| `useSearchParams` hydration error | Missing Suspense boundary | Wrap component in `<Suspense>` |
| `headers()` / `cookies()` error in client component | Server-only API used client-side | Move to server component or API route |
| Middleware can't use `fs`, `path` | Middleware runs on Edge runtime | Use API routes for Node.js APIs |
| `metadata` export ignored | Exported from client component (`"use client"`) | Only export metadata from server components |
| Hot reload breaks after schema change | Prisma client stale | Run `prisma generate`, restart dev server |
| `next/dynamic` SSR mismatch | Component uses `window` / `document` | Use `dynamic(() => import(...), { ssr: false })` |
| API route returns HTML instead of JSON | Missing `NextResponse.json()` | Return `NextResponse.json(data)` not `Response(data)` |
| Parallel routes 404 in production | Missing `default.tsx` | Add `default.tsx` to every parallel route slot |
| Build fails: "Dynamic server usage" | Using dynamic APIs in static page | Add `export const dynamic = 'force-dynamic'` |

## React Gotchas

- **Stale closure in useEffect:** If your effect references state but the dependency array is empty, you'll read the initial value forever. Add the state to deps or use a ref.
- **setState not updating immediately:** State updates are asynchronous. If you need the new value right after setting it, use the callback form: `setState(prev => prev + 1)`.
- **Infinite re-render loop:** Creating new objects/arrays in render that are passed as deps to useEffect. Memoize with `useMemo` or move outside the component.
- **Key prop resets component state:** Changing a component's `key` unmounts and remounts it. Use this intentionally for resets, avoid it accidentally.
- **Event handler `this` binding:** Arrow functions in class components auto-bind; regular functions do not.

## TypeScript Patterns

| Problem | Cause | Fix |
|---------|-------|-----|
| "implicitly has type 'any'" | Missing type annotation in callback | Add explicit types: `(e: React.ChangeEvent<HTMLInputElement>)` |
| "Type 'X' is not assignable to type 'Y'" | Structural mismatch | Check optional vs required fields, `null` vs `undefined` |
| `@ts-ignore` hiding real bugs | Suppressed error | Use `@ts-expect-error` instead (fails if error goes away) |
| Types pass but runtime crashes | Type assertion (`as`) bypassing checks | Avoid `as`; use type guards (`if ('key' in obj)`) |
| Generic inference fails | Too many nested generics | Break into intermediate type variables |
| `strict: true` catches different errors than IDE | IDE using different tsconfig | Run `tsc --noEmit` as part of CI |

## Database Issues

- **Prisma "record not found":** Check that `where` clause matches an existing row. Use `findFirst` instead of `findUnique` if the field isn't unique.
- **Supabase RLS returns empty array (not 403):** The query succeeds but policies filter out all rows. Check RLS policies in the Supabase dashboard.
- **Connection pool exhaustion in serverless:** Each serverless invocation opens a new connection. Use connection pooling (`?pgbouncer=true`) or Prisma Accelerate.
- **Migration drift:** If you manually edited the DB, `prisma migrate dev` will detect drift. Use `prisma db pull` to sync schema from DB, then generate a new migration.
- **Supabase auth + RLS:** `auth.uid()` in RLS policies requires the request to include a valid JWT. API routes using the service role key bypass RLS entirely.

## Environment / Path Issues

- **Windows path formats:** Bash tools use `/c/Users/you/`, Read/Write/Edit tools use `C:\Users\you\`
- **`.env.local` not loading:** Only loaded by `next dev` / `next build`. Plain Node scripts need `dotenv/config`.
- **Port already in use:** `lsof -i :3000` (macOS/Linux) or `netstat -ano | findstr :3000` (Windows) to find the process.
- **Node version mismatch:** Use `.nvmrc` or `.node-version` file. Run `nvm use` before installing dependencies.
- **`EACCES` permission error on npm install:** Never use `sudo npm`. Fix permissions or use nvm.

## General Patterns

- **"It works locally but not in production":** Check environment variables, build-time vs runtime config, and Edge vs Node.js runtime differences.
- **Hydration mismatch:** Server and client rendered different HTML. Common causes: browser extensions, `Date.now()`, `Math.random()`, `window` checks.
- **CORS errors:** The server needs to return `Access-Control-Allow-Origin` headers. In Next.js API routes, set headers explicitly or use middleware.
- **"Module not found" after install:** Clear `.next` cache, delete `node_modules`, reinstall. Check that the import path casing matches the file system (case-sensitive on Linux).
- **Webhook not firing locally:** Use `ngrok` or `stripe listen --forward-to localhost:3000/api/webhook` for Stripe.

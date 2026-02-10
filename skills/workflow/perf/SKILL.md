---
name: perf
description: Performance audit — bundle size analysis, database query optimization, React re-render detection, API response profiling, and Lighthouse suggestions, prioritized by impact.
---

# Performance Audit Skill

## Trigger

Activated by `/perf` or when the user asks about performance, slow pages, large bundles, slow queries, or optimization.

## Modes

| Command | Behavior |
|---------|----------|
| `/perf` | Full performance audit across all categories |
| `/perf bundle` | Bundle size analysis only |
| `/perf db` | Database query performance only |
| `/perf render` | React/UI re-render analysis only |
| `/perf api` | API endpoint response time analysis only |
| `/perf lighthouse` | Lighthouse-style web vitals suggestions |
| `/perf [file]` | Performance review of a specific file |

## Execution Strategy

### Phase 1 — Profile (parallel)

Run all applicable analyses simultaneously based on the project's tech stack:

**1. Bundle Size Analysis**

Detect the bundler and analyze output:

| Bundler | Detection | Analysis Command |
|---------|-----------|-----------------|
| webpack | `webpack.config.*`, Next.js | `npx next build` (check `.next/` output), or `npx webpack --profile --json > stats.json` |
| Vite | `vite.config.*` | `npx vite build --report` |
| Rollup | `rollup.config.*` | Build and check output sizes |
| esbuild | `esbuild` in scripts | Build and check output sizes |

Static analysis (no build required):
- Scan `import` statements for known heavy libraries:
  - `moment` (330KB) -> suggest `date-fns` or `dayjs`
  - `lodash` (full import) -> suggest `lodash-es` or individual imports
  - `@mui/material` (full import) -> suggest tree-shaking or specific imports
  - `@fortawesome/fontawesome-svg-core` (full set) -> suggest specific icon imports
  - `chart.js` (full) -> check if tree-shaking is configured
  - `firebase` (full SDK) -> suggest modular imports
- Check for dynamic imports (`React.lazy`, `next/dynamic`, `import()`) on heavy components.
- Look for duplicate dependencies (different versions of same library in lock file).
- Check for `sideEffects: false` in package.json for tree-shaking.
- Analyze image assets: check for unoptimized images (large PNG/JPG that could be WebP/AVIF).

**2. Database Query Analysis**

Scan the codebase for query patterns that indicate performance issues:

**N+1 Queries:**
```
# Prisma: findMany followed by individual queries in a loop
pattern: findMany.*\.then.*\.map.*find(Unique|First)
# Also check for: queries inside .map(), .forEach(), for...of loops
# Drizzle/Knex: select() inside loops
```
- Suggest: use `include` (Prisma), `with` (Drizzle), or `JOIN` to batch.

**Missing Indexes:**
- Read the schema for foreign key columns that lack indexes.
- Check `WHERE` clauses in raw SQL queries against indexed columns.
- Look for `ORDER BY` on non-indexed columns in large tables.
- Prisma: check `@@index` directives in `schema.prisma`.
- SQL: check `CREATE INDEX` statements in migrations.

**Unbounded Queries:**
- Queries without `LIMIT` / `take` / pagination.
- `SELECT *` on tables with many columns or large text/blob fields.
- Missing cursor-based or offset pagination on list endpoints.

**Expensive Operations:**
- Full-text search without proper indexes (no `tsvector`, no search engine).
- Aggregations on unindexed columns (`COUNT`, `SUM`, `GROUP BY`).
- Subqueries that could be JOINs.
- Multiple sequential queries that could be combined into one.

**3. React Re-render Detection**

Scan React components for common re-render causes:

| Issue | Pattern to Find | Fix |
|-------|----------------|-----|
| Inline object/array props | `prop={{ }}` or `prop={[]}` in JSX | Extract to variable or `useMemo` |
| Inline function props | `onClick={() => ...}` passed to child components | `useCallback` or extract handler |
| Missing memo on expensive components | Large components receiving frequently-changing parent props | `React.memo()` wrapper |
| Context over-subscription | `useContext` consuming a large context with frequent updates | Split context or use selectors |
| Missing dependency arrays | `useEffect(() => {}, )` without deps or with missing deps | Add correct dependency array |
| State in wrong component | State defined high in tree that only affects a subtree | Move state closer to where it is used |
| Unnecessary state | State derived from props or other state | Compute during render instead |
| Large list without virtualization | `.map()` rendering 100+ items without windowing | Use `react-window` or `react-virtualized` |

**4. API Response Time Analysis**

- Identify API routes and check for performance issues:
  - Sequential awaits that could be parallel (`Promise.all`)
  - Missing caching (no `Cache-Control` headers, no Redis/in-memory cache)
  - Large response payloads (returning full objects when client needs a subset)
  - No pagination on list endpoints
  - Synchronous operations that could be queued (email sending, image processing)
  - Missing response compression (no gzip/brotli middleware)
- Check for middleware that runs on every request unnecessarily.
- Look for expensive operations in hot paths (file I/O, external API calls without caching).

**5. Lighthouse / Web Vitals Suggestions**

Check the codebase for patterns that affect Core Web Vitals:

**LCP (Largest Contentful Paint):**
- Hero images without `priority` prop (Next.js) or `loading="eager"`
- Web fonts blocking render (missing `font-display: swap` or `next/font`)
- Large JavaScript bundles blocking main thread
- Missing server-side rendering for above-the-fold content

**FID/INP (Interaction to Next Paint):**
- Long-running synchronous JavaScript on the main thread
- Heavy computation during render (no Web Worker offloading)
- Event handlers that trigger expensive operations without debouncing

**CLS (Cumulative Layout Shift):**
- Images without `width` and `height` attributes
- Dynamically injected content above the fold
- Web fonts causing layout shift (FOUT)
- Missing skeleton loaders for async content

**General:**
- Missing `<link rel="preconnect">` for third-party origins
- No service worker for caching static assets
- Uncompressed assets (missing gzip/brotli in server config)
- Third-party scripts loaded synchronously in `<head>`

### Phase 2 — Prioritize by Impact

Score each finding on two axes:

| Impact | Description |
|--------|-------------|
| **High** | Affects every user on every page load, measurable improvement expected (>100ms savings, >50KB reduction) |
| **Medium** | Affects specific pages or interactions, moderate improvement expected |
| **Low** | Minor optimization, negligible user-facing improvement |

| Effort | Description |
|--------|-------------|
| **Quick win** | Less than 30 minutes, low risk of regressions |
| **Moderate** | 1-4 hours, some testing required |
| **Significant** | Full day or more, architectural change |

Prioritize: High Impact + Quick Win first, then High Impact + Moderate Effort.

### Phase 3 — Report

```
Performance Audit Report
========================
Date: YYYY-MM-DD
Scope: [Full project / specific area]

Quick Wins (do these first)
---------------------------
1. [Finding] — Impact: High, Effort: Quick
   Location: path/to/file.ts:42
   Current: What the code does now.
   Recommended: What it should do, with code example.
   Expected improvement: ~200ms faster page load / ~80KB smaller bundle.

2. ...

Medium-Term Improvements
------------------------
1. [Finding] — Impact: High, Effort: Moderate
   ...

Architecture Considerations
----------------------------
1. [Finding] — Impact: High, Effort: Significant
   ...

Metrics Summary
---------------
- Estimated total bundle size reduction: ~XXX KB
- Estimated query count reduction: ~XX queries per page
- Key pages affected: /dashboard, /api/users
- Recommended next steps (in priority order):
  1. ...
  2. ...
  3. ...
```

### Phase 4 — Fix (if requested)

When the user asks to implement optimizations:
1. Start with Quick Wins.
2. Apply one optimization at a time so the impact of each can be measured.
3. Run tests after each change to catch regressions.
4. For database changes, verify query plans with `EXPLAIN ANALYZE` if possible.
5. For bundle changes, compare before/after sizes.

## Framework-Specific Checks

### Next.js
- Check `next.config.js` for `experimental.optimizeCss`, image optimization settings.
- Verify `next/image` is used instead of raw `<img>` tags.
- Check for `use client` directives on components that could be Server Components.
- Verify route segment caching with `export const revalidate` or `export const dynamic`.
- Check for proper use of `loading.tsx` and `Suspense` boundaries.

### Vite / SPA
- Check for proper code splitting at route level.
- Verify `build.rollupOptions.output.manualChunks` for vendor splitting.
- Check for CSS-in-JS runtime overhead (consider extraction).

### Node.js API
- Check for cluster mode or worker threads for CPU-bound operations.
- Verify connection pooling for database connections.
- Check for memory leaks: global caches without eviction, event listener accumulation.

## Memory Integration

- Store baseline performance metrics (bundle size, query counts, load times) in the memory graph.
- Track improvements over time to show progress.
- Remember project-specific performance patterns and past optimizations to avoid redundant analysis.

## Cross-Skill Chaining

| Trigger | Chain to |
|---------|----------|
| Database needs new indexes | Chain to `/migrate` to create index migration |
| Optimizations ready for review | Chain to `/pr` to submit changes |
| Performance fix may break tests | Chain to `/test` to verify |
| Performance issue reveals architectural problem | Chain to `/doc adr` to document the decision |
| Heavy dependency should be replaced | Chain to `/security` to vet the replacement |

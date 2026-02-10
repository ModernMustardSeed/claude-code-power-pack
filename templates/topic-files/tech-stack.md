# Tech Stack Reference

> Canonical reference for technologies, conventions, and architecture patterns used across projects.

## Core Technologies

| Technology | Version | Role | Docs |
|-----------|---------|------|------|
| TypeScript | 5.x | Language | typescriptlang.org |
| Next.js | 15.x | Fullstack framework | nextjs.org/docs |
| React | 19.x | UI library | react.dev |
| Node.js | 20+ | Runtime | nodejs.org |
| Tailwind CSS | 4.x | Utility-first CSS | tailwindcss.com |
| PostgreSQL | 16 | Primary database | postgresql.org |
| Prisma | 6.x | ORM / migrations | prisma.io/docs |
| Supabase | - | BaaS (auth, storage, realtime) | supabase.com/docs |
| Stripe | - | Payments & billing | stripe.com/docs |
| Vercel | - | Hosting & edge functions | vercel.com/docs |
<!-- Customize versions and tools to match your stack -->

## Design System

| Layer | Tool | Notes |
|-------|------|-------|
| Component library | shadcn/ui | Copy-paste components, fully customizable |
| Icons | Lucide React | Tree-shakable, consistent stroke width |
| Animation | Framer Motion | Declarative animations, layout transitions |
| Charts | Recharts / Tremor | Recharts for custom, Tremor for dashboards |
| Forms | React Hook Form + Zod | RHF for performance, Zod for validation |
| Toast / Notifications | Sonner | Lightweight, accessible |
| Theme | next-themes | Dark mode with system preference support |

## Architecture Patterns

### App Router Structure (Next.js 14+)
```
app/
  layout.tsx          # Root layout (providers, fonts, metadata)
  page.tsx            # Landing page
  (marketing)/        # Route group: public pages (no layout nesting)
  (app)/              # Route group: authenticated app
    layout.tsx        # App shell (sidebar, nav)
    dashboard/
    settings/
  api/
    webhooks/stripe/  # Webhook handlers
```

### Data Flow
```
Client Component
  -> Server Action / API Route
    -> Service Layer (business logic)
      -> ORM (Prisma / Supabase client)
        -> Database
```

### Auth Pattern
- Use middleware for route protection (redirect unauthenticated users)
- Server components: read session via `auth()` or `getServerSession()`
- Client components: use auth hooks (`useSession`, `useUser`)
- API routes: validate session before processing

### Error Handling
- Server actions: return `{ success: boolean, error?: string }` objects
- API routes: return proper HTTP status codes with JSON error bodies
- Client: use error boundaries for component-level failures
- Global: `app/error.tsx` and `app/not-found.tsx` for catch-all handling

## Conventions

### File Naming
- Components: `PascalCase.tsx` (e.g., `UserProfile.tsx`)
- Utilities: `kebab-case.ts` (e.g., `format-date.ts`)
- Hooks: `camelCase.ts` prefixed with `use` (e.g., `useAuth.ts`)
- Types: co-located in `types.ts` or `types/` directory
- Constants: `SCREAMING_SNAKE_CASE` in `constants.ts`

### Code Style
- Prefer named exports over default exports (easier to grep and refactor)
- Prefer `interface` over `type` for object shapes (better error messages)
- Prefer `const` arrow functions for components: `const Button = () => {}`
- Colocate related files: component + hook + types in same directory
- Barrel exports (`index.ts`) only for public API of a module, not internal files

### Git Conventions
- Branch naming: `feature/short-description`, `fix/issue-description`, `chore/task`
- Commits: imperative mood, concise ("Add user auth flow" not "Added user auth flow")
- PRs: descriptive title + summary of changes + test plan

### Environment Variables
- Server-only secrets: `SECRET_KEY`, `DATABASE_URL` (no `NEXT_PUBLIC_` prefix)
- Client-safe values: `NEXT_PUBLIC_APP_URL`, `NEXT_PUBLIC_STRIPE_KEY`
- Never commit `.env` files. Use `.env.example` with placeholder values.

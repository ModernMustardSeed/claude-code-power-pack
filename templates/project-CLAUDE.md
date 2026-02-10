# PROJECT_NAME - Project CLAUDE.md

## What This Is

<!-- One-paragraph description of the project, its purpose, and who it serves. -->

## Tech Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| Framework | Next.js | 15.x |
| Language | TypeScript | 5.x |
| Database | PostgreSQL / Supabase | - |
| ORM | Prisma / Drizzle | - |
| Auth | NextAuth / Supabase Auth / Clerk | - |
| Payments | Stripe | - |
| Styling | Tailwind CSS | 4.x |
| UI Components | shadcn/ui | - |
| Hosting | Vercel / Railway / AWS | - |
<!-- Customize to match your actual stack -->

## Architecture

```
src/
  app/              # Next.js App Router pages and layouts
    api/            # API routes
    (auth)/         # Auth-related pages (grouped route)
    dashboard/      # Protected dashboard pages
  components/       # React components
    ui/             # Base UI components (shadcn)
  lib/              # Shared utilities, clients, helpers
    db.ts           # Database client
    auth.ts         # Auth helpers
    stripe.ts       # Payment helpers
  types/            # TypeScript type definitions
  hooks/            # Custom React hooks
prisma/
  schema.prisma     # Database schema
```
<!-- Update to match your actual file structure -->

## Build & Run

```bash
# Install dependencies
pnpm install

# Set up environment
cp .env.example .env.local
# Fill in required values (see Environment Variables below)

# Database setup
pnpm prisma generate
pnpm prisma db push    # or: pnpm prisma migrate dev

# Development
pnpm dev               # http://localhost:3000

# Production build
pnpm build
pnpm start

# Other useful commands
pnpm lint              # ESLint
pnpm type-check        # tsc --noEmit
pnpm test              # Run test suite
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `DATABASE_URL` | Yes | PostgreSQL connection string |
| `NEXTAUTH_SECRET` | Yes | Random string for session encryption |
| `NEXTAUTH_URL` | Dev only | `http://localhost:3000` for local dev |
| `STRIPE_SECRET_KEY` | Yes | Stripe API secret key |
| `STRIPE_WEBHOOK_SECRET` | Yes | Stripe webhook signing secret |
| `NEXT_PUBLIC_STRIPE_KEY` | Yes | Stripe publishable key |
<!-- Add your project-specific env vars -->

## Known Issues

- <!-- Issue 1: description and workaround -->
- <!-- Issue 2: description and workaround -->

## Current State

**Last updated:** YYYY-MM-DD
**Branch:** main
**Status:** Active development / Stable / Maintenance

<!-- Brief description of what's been done, what's in progress, and what's next. -->

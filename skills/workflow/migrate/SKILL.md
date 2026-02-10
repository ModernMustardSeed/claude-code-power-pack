---
name: migrate
description: Database migration helper — detect ORM, understand schema, plan migration with rollback strategy, generate and apply migration files with safety checks.
---

# Database Migration Skill

## Trigger

Activated by `/migrate` or when the user asks to change the database schema, add a column, create a table, modify relations, or run migrations.

## Modes

| Command | Behavior |
|---------|----------|
| `/migrate` | Interactive — assess current state and ask what to change |
| `/migrate plan [description]` | Generate a migration plan without applying |
| `/migrate create [name]` | Create a new migration file |
| `/migrate status` | Show pending and applied migrations |
| `/migrate up` | Apply pending migrations |
| `/migrate down` | Roll back the most recent migration |
| `/migrate reset` | Roll back all migrations (requires explicit confirmation) |

## Execution Strategy

### Phase 1 — Detect (parallel)

Run all of these simultaneously to understand the database setup:

**1. Identify the ORM / Migration Tool**

| Indicator | Tool |
|-----------|------|
| `schema.prisma` file | Prisma |
| `drizzle.config.*` + `drizzle/` dir | Drizzle |
| `supabase/migrations/` dir or `supabase` in deps | Supabase CLI |
| `knexfile.*` | Knex |
| `alembic.ini` or `alembic/` dir | Alembic (Python) |
| `migrations/` dir with Django patterns | Django |
| `*.sql` files in a `migrations/` dir with no ORM | Raw SQL |
| `typeorm` in deps, `ormconfig.*` | TypeORM |

**2. Read Current Schema**
- Prisma: read `prisma/schema.prisma`
- Drizzle: read schema files (usually `src/db/schema.ts` or `drizzle/schema.ts`)
- Supabase: read `supabase/migrations/*.sql` and any `schema.sql`
- Knex: read latest migration files and any seed files
- Raw SQL: read all `.sql` files in the migrations directory

**3. Check Migration State**
- Prisma: `npx prisma migrate status`
- Drizzle: `npx drizzle-kit check` or list files in `drizzle/`
- Supabase: `supabase migration list` or check `supabase/migrations/` directory
- Knex: `npx knex migrate:status`
- Alembic: `alembic current` and `alembic history`

**4. Check Database Connection**
- Locate the database connection string in `.env` or config files.
- Verify the connection target (local dev, staging, production). **Warn immediately if it appears to point at production.**
- Note the database engine (PostgreSQL, MySQL, SQLite, etc.).

### Phase 2 — Understand

Before making any changes:

1. Map out the current schema: tables, columns, types, constraints, indexes, relations.
2. Identify what needs to change based on the user's request.
3. Check for potential conflicts:
   - Will a column rename break existing queries?
   - Will a NOT NULL constraint fail on existing rows?
   - Will a foreign key constraint be violated by existing data?
   - Are there views, triggers, or functions that reference the affected tables?
4. Present a summary of the current schema and the proposed changes to the user.

### Phase 3 — Plan

Generate a detailed migration plan:

```
Migration Plan
==============
Name: add-user-preferences-table
Type: Schema change (non-destructive)

Changes:
1. CREATE TABLE "user_preferences" (
     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
     theme VARCHAR(20) DEFAULT 'system',
     notifications_enabled BOOLEAN DEFAULT true,
     created_at TIMESTAMPTZ DEFAULT now(),
     updated_at TIMESTAMPTZ DEFAULT now()
   )
2. CREATE INDEX idx_user_preferences_user_id ON user_preferences(user_id)

Rollback:
1. DROP INDEX IF EXISTS idx_user_preferences_user_id
2. DROP TABLE IF EXISTS "user_preferences"

Risk Assessment:
- Destructive: No
- Data loss: No
- Downtime required: No
- Estimated execution time: < 1s
```

Classify the migration risk:

| Risk Level | Criteria |
|------------|----------|
| **Safe** | Additive only — new tables, new nullable columns, new indexes |
| **Caution** | Adding NOT NULL columns with defaults, renaming (may break app code) |
| **Dangerous** | Dropping columns/tables, changing types, removing constraints |
| **Requires downtime** | Locking operations on large tables, full table rewrites |

### Phase 4 — Generate

Create the migration file using the project's ORM tooling:

**Prisma:**
```bash
# Update schema.prisma first, then:
npx prisma migrate dev --name <migration-name> --create-only
```

**Drizzle:**
```bash
npx drizzle-kit generate --name <migration-name>
```

**Supabase:**
```bash
supabase migration new <migration-name>
# Then write SQL into the generated file
```

**Knex:**
```bash
npx knex migrate:make <migration-name>
# Then write up() and down() functions
```

**Raw SQL:**
Create a timestamped file: `migrations/YYYYMMDDHHMMSS_<name>.sql`
Include both UP and DOWN sections clearly separated.

For all ORMs: Always generate both the forward migration and the rollback.

### Phase 5 — Dry Run (if supported)

- Prisma: `npx prisma migrate dev --create-only` (generates without applying)
- Supabase: review the generated SQL before `supabase db push`
- Knex: use `--dry-run` flag if available
- For raw SQL: parse the SQL for syntax errors and validate against the current schema

If dry run is not natively supported, read the generated migration file and verify it manually before applying.

### Phase 6 — Apply (requires confirmation)

**Never apply automatically. Always ask the user to confirm.**

Present:
1. The exact SQL that will be executed (or the ORM command).
2. The target database (dev/staging/prod).
3. The rollback command if something goes wrong.

Then apply:
- Prisma: `npx prisma migrate dev`
- Drizzle: `npx drizzle-kit push` or `npx drizzle-kit migrate`
- Supabase: `supabase db push` (local) or `supabase migration up` (remote)
- Knex: `npx knex migrate:latest`
- Alembic: `alembic upgrade head`

### Phase 7 — Verify

After applying:
1. Run `migrate status` to confirm the migration was applied.
2. Check that the schema matches expectations (introspect if possible).
3. Run the application's test suite to catch broken queries.
4. If the ORM generates types (Prisma, Drizzle), regenerate them:
   - Prisma: `npx prisma generate`
   - Drizzle: types are usually inferred, but verify imports still work

## Safety Rules

1. **Always plan a rollback** before applying any migration. Every UP must have a corresponding DOWN.
2. **Never drop tables or columns without explicit user approval.** Ask specifically: "This will permanently delete the X table/column and all its data. Proceed?"
3. **Never apply migrations to production** without the user explicitly confirming the target.
4. **Warn about data-destructive operations**: column drops, type changes that truncate data, removing constraints that had semantic meaning.
5. **Back up before dangerous migrations.** Suggest `pg_dump` or equivalent before destructive operations.
6. **One concern per migration.** Do not bundle unrelated schema changes into a single migration file.
7. **Never modify an already-applied migration.** Always create a new migration to make further changes.

## Memory Integration

- Store the current schema state in the memory graph after each migration for quick reference in future sessions.
- Track migration history (names, dates, status) so multi-session work stays consistent.
- Record any migration-related issues (failed rollbacks, data fixups) for future reference.

## Cross-Skill Chaining

| Trigger | Chain to |
|---------|----------|
| Migration changes auth tables | Chain to `/security` to verify access control is intact |
| Schema change may break tests | Chain to `/test` to run the suite after migration |
| Migration is ready for review | Chain to `/pr` to submit as a pull request |
| Need to document schema changes | Chain to `/doc adr` to create an architecture decision record |
| Performance concerns with new indexes/queries | Chain to `/perf` for query analysis |

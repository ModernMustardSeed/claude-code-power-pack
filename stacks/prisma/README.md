# Prisma Stack Module

> Framework-specific knowledge for Prisma ORM (schema design, migrations, query optimization, common errors). Add to your project's `debugging.md` or `tech-stack.md`.

## Schema Design Patterns

### Basic Model

```prisma
model User {
  id        String   @id @default(cuid())
  email     String   @unique
  name      String?
  posts     Post[]
  profile   Profile?
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@index([email])
  @@map("users") // Custom table name
}
```

### Relation Types

#### One-to-Many

```prisma
model User {
  id    String @id @default(cuid())
  posts Post[]
}

model Post {
  id       String @id @default(cuid())
  author   User   @relation(fields: [authorId], references: [id], onDelete: Cascade)
  authorId String

  @@index([authorId]) // Always index foreign keys
}
```

#### One-to-One

```prisma
model User {
  id      String   @id @default(cuid())
  profile Profile?
}

model Profile {
  id     String @id @default(cuid())
  user   User   @relation(fields: [userId], references: [id], onDelete: Cascade)
  userId String @unique // @unique makes it one-to-one
}
```

#### Many-to-Many (Implicit)

```prisma
model Post {
  id         String     @id @default(cuid())
  categories Category[]
}

model Category {
  id    String @id @default(cuid())
  posts Post[]
}
// Prisma creates a join table automatically: _CategoryToPost
```

#### Many-to-Many (Explicit — recommended for additional fields)

```prisma
model Post {
  id         String         @id @default(cuid())
  categories PostCategory[]
}

model Category {
  id    String         @id @default(cuid())
  posts PostCategory[]
}

model PostCategory {
  post       Post     @relation(fields: [postId], references: [id], onDelete: Cascade)
  postId     String
  category   Category @relation(fields: [categoryId], references: [id], onDelete: Cascade)
  categoryId String
  assignedAt DateTime @default(now()) // Extra field on the join

  @@id([postId, categoryId]) // Composite primary key
}
```

### Enum Pattern

```prisma
enum Role {
  USER
  ADMIN
  MODERATOR
}

model User {
  id   String @id @default(cuid())
  role Role   @default(USER)
}
```

### JSON Field Pattern

```prisma
model Settings {
  id       String @id @default(cuid())
  metadata Json   // Stored as JSONB in PostgreSQL
}
```

```typescript
// Query JSON fields
const settings = await prisma.settings.findMany({
  where: {
    metadata: {
      path: ['theme'],
      equals: 'dark',
    },
  },
})
```

## Migration Workflow

### Creating Migrations

```bash
# Generate migration from schema changes (development)
npx prisma migrate dev --name add_posts_table

# This does three things:
# 1. Creates SQL migration file in prisma/migrations/
# 2. Applies the migration to your dev database
# 3. Regenerates Prisma Client
```

### Applying Migrations

```bash
# Development (creates + applies + generates client)
npx prisma migrate dev

# Production (applies pending migrations only — no generation)
npx prisma migrate deploy

# Reset database (drops all data, re-applies all migrations)
npx prisma migrate reset
```

### Migration Safety Rules

1. **Never edit an applied migration.** If you made a mistake, create a new migration to fix it.
2. **Never delete a migration file** that has been applied to any environment.
3. **Review generated SQL** before committing. Prisma makes reasonable choices but check:
   - Column types match expectations
   - Default values are correct
   - Cascade behavior is intentional
4. **Additive changes are safe** (new tables, new nullable columns, new indexes).
5. **Destructive changes need care** (dropping columns, renaming tables, changing types).

### Handling Destructive Changes

```bash
# Prisma will warn you about data loss. To proceed:
npx prisma migrate dev --name remove_old_column

# If you need custom SQL for data migration:
# 1. Create an empty migration
npx prisma migrate dev --create-only --name migrate_data
# 2. Edit the generated SQL file to add data migration logic
# 3. Apply it
npx prisma migrate dev
```

## Client Generation

```bash
# Regenerate the Prisma Client after schema changes
npx prisma generate

# This is automatically run by `prisma migrate dev`
# But you need to run it manually after:
# - Pulling schema changes: npx prisma db pull
# - Changing generator config in schema.prisma
```

### Singleton Pattern (Avoid Hot Reload Issues)

```typescript
// lib/prisma.ts
import { PrismaClient } from '@prisma/client'

const globalForPrisma = globalThis as unknown as { prisma: PrismaClient }

export const prisma = globalForPrisma.prisma || new PrismaClient()

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma
```

**Why:** In development, Next.js hot reload creates a new `PrismaClient` on every file change. This exhausts database connections. The singleton pattern reuses the existing client.

## Query Optimization

### Select Only What You Need

```typescript
// BAD: Fetches all columns
const users = await prisma.user.findMany()

// GOOD: Only fetches what you need
const users = await prisma.user.findMany({
  select: {
    id: true,
    name: true,
    email: true,
  },
})
```

### Avoiding N+1 Queries

```typescript
// BAD: N+1 — one query per user to get posts
const users = await prisma.user.findMany()
for (const user of users) {
  const posts = await prisma.post.findMany({ where: { authorId: user.id } })
}

// GOOD: Single query with include
const users = await prisma.user.findMany({
  include: {
    posts: true, // Prisma uses a JOIN or separate batched query
  },
})

// GOOD: Even better — select only needed fields
const users = await prisma.user.findMany({
  select: {
    id: true,
    name: true,
    posts: {
      select: {
        id: true,
        title: true,
      },
    },
  },
})
```

### Batch Operations

```typescript
// BAD: Individual creates in a loop
for (const item of items) {
  await prisma.post.create({ data: item })
}

// GOOD: Batch create
await prisma.post.createMany({
  data: items,
  skipDuplicates: true, // Optional: skip on unique constraint violation
})

// GOOD: Transaction for related operations
await prisma.$transaction([
  prisma.post.create({ data: postData }),
  prisma.category.update({ where: { id: catId }, data: { postCount: { increment: 1 } } }),
])

// GOOD: Interactive transaction for complex logic
await prisma.$transaction(async (tx) => {
  const user = await tx.user.findUnique({ where: { id: userId } })
  if (!user) throw new Error('User not found')
  await tx.post.create({ data: { ...postData, authorId: user.id } })
})
```

### Pagination

```typescript
// Offset pagination (simple but slow for large datasets)
const posts = await prisma.post.findMany({
  skip: 20,
  take: 10,
  orderBy: { createdAt: 'desc' },
})

// Cursor pagination (fast and consistent)
const posts = await prisma.post.findMany({
  take: 10,
  cursor: { id: lastPostId },
  skip: 1, // Skip the cursor itself
  orderBy: { createdAt: 'desc' },
})
```

### Raw Queries (Escape Hatch)

```typescript
// When Prisma's query builder isn't enough
const result = await prisma.$queryRaw`
  SELECT p.*, COUNT(c.id) as comment_count
  FROM posts p
  LEFT JOIN comments c ON c.post_id = p.id
  GROUP BY p.id
  HAVING COUNT(c.id) > ${minComments}
  ORDER BY comment_count DESC
`

// For mutations
await prisma.$executeRaw`
  UPDATE posts SET view_count = view_count + 1 WHERE id = ${postId}
`
```

**Gotcha:** Always use tagged template literals (`$queryRaw\`...\``) not string concatenation. Tagged templates are SQL-injection safe. String concatenation is NOT.

## Seeding

```typescript
// prisma/seed.ts
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

async function main() {
  // Upsert to make seeding idempotent
  const admin = await prisma.user.upsert({
    where: { email: 'admin@example.com' },
    update: {},
    create: {
      email: 'admin@example.com',
      name: 'Admin',
      role: 'ADMIN',
    },
  })

  console.log({ admin })
}

main()
  .then(async () => { await prisma.$disconnect() })
  .catch(async (e) => {
    console.error(e)
    await prisma.$disconnect()
    process.exit(1)
  })
```

```json
// package.json
{
  "prisma": {
    "seed": "tsx prisma/seed.ts"
  }
}
```

```bash
# Run seed
npx prisma db seed

# Seed also runs automatically with:
npx prisma migrate reset
```

## Common Errors

### P2002: Unique constraint violation

```
Error: Unique constraint failed on the constraint: `User_email_key`
```

**Cause:** Trying to create/update a record with a value that already exists in a unique column.

**Fix:**
```typescript
// Use upsert instead of create
await prisma.user.upsert({
  where: { email: 'user@example.com' },
  update: { name: 'Updated Name' },
  create: { email: 'user@example.com', name: 'New User' },
})
```

### P2025: Record not found

```
Error: An operation failed because it depends on one or more records that were required but not found.
```

**Cause:** `update`, `delete`, or `findUniqueOrThrow` on a record that doesn't exist. Also occurs when a required relation is missing.

**Fix:**
```typescript
// Use findUnique + null check instead of findUniqueOrThrow
const user = await prisma.user.findUnique({ where: { id: userId } })
if (!user) {
  // Handle missing record
}

// Or use updateMany/deleteMany which return count instead of throwing
const { count } = await prisma.user.deleteMany({ where: { id: userId } })
```

### P2003: Foreign key constraint failed

```
Error: Foreign key constraint failed on the field: `Post_authorId_fkey`
```

**Cause:** Trying to create a record with a foreign key that doesn't exist, or deleting a record that other records depend on.

**Fix:** Ensure the referenced record exists, or add `onDelete: Cascade` to the relation.

### P1001: Can't reach database server

```
Error: Can't reach database server at `localhost:5432`
```

**Cause:** Database isn't running, wrong connection string, or network issue.

**Fix:**
- Check `DATABASE_URL` in `.env`
- Ensure the database server is running
- Check firewall/network rules

### `PrismaClientInitializationError: Unable to require .prisma/client/default`

**Cause:** Prisma Client hasn't been generated, or was generated for a different platform.

**Fix:**
```bash
npx prisma generate
```

For deployment (e.g., Docker), ensure `prisma generate` runs after `npm install`:
```json
{
  "scripts": {
    "postinstall": "prisma generate"
  }
}
```

### `TypeError: Cannot read properties of undefined (reading 'findMany')`

**Cause:** Importing `PrismaClient` incorrectly or the model name doesn't match.

**Fix:** Model names in code are camelCase of the schema model name:
```prisma
model UserProfile { ... }  // Schema
```
```typescript
prisma.userProfile.findMany()  // Code (camelCase)
```

### Slow queries / Connection pool exhaustion

**Symptoms:** Queries hang, timeout errors, "Too many database connections" in logs.

**Fix:**
```prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
  // Connection pool settings
  // Add ?connection_limit=5 to DATABASE_URL for serverless
}
```

```
# .env — for serverless environments (Vercel, Lambda)
DATABASE_URL="postgresql://user:pass@host:5432/db?connection_limit=5&pool_timeout=10"
```

For Vercel/serverless, consider using Prisma Accelerate or PgBouncer for connection pooling.

## Prisma Studio

```bash
# Visual database browser
npx prisma studio
# Opens at http://localhost:5555
```

Useful for:
- Quick data inspection during development
- Manually creating/editing records for testing
- Verifying migration results

## Middleware (Soft Delete Example)

```typescript
const prisma = new PrismaClient().$extends({
  query: {
    $allModels: {
      async findMany({ model, operation, args, query }) {
        args.where = { ...args.where, deletedAt: null }
        return query(args)
      },
      async delete({ model, operation, args, query }) {
        // Convert delete to soft delete
        return prisma[model].update({
          ...args,
          data: { deletedAt: new Date() },
        })
      },
    },
  },
})
```

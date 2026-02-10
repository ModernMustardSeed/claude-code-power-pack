# Supabase Stack Module

> Framework-specific knowledge for Supabase (Auth, Database, RLS, Edge Functions, Realtime, Storage). Add to your project's `debugging.md` or `tech-stack.md`.

## Row Level Security (RLS)

RLS is the most powerful and most misunderstood feature of Supabase. **When RLS is enabled on a table and no policies exist, ALL queries return empty results.** This is the #1 source of "my data disappeared" bugs.

### Policy Patterns

#### Authenticated Users Can Read All Rows

```sql
CREATE POLICY "Authenticated users can read"
  ON public.posts
  FOR SELECT
  TO authenticated
  USING (true);
```

#### Owner-Only Access

```sql
-- Users can only read their own rows
CREATE POLICY "Users can read own data"
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Users can only update their own rows
CREATE POLICY "Users can update own data"
  ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)      -- Row must belong to user (existing row)
  WITH CHECK (auth.uid() = user_id); -- New data must also belong to user

-- Users can insert rows for themselves
CREATE POLICY "Users can insert own data"
  ON public.profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own rows
CREATE POLICY "Users can delete own data"
  ON public.profiles
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);
```

#### Admin Access

```sql
-- Admin role can do anything
CREATE POLICY "Admins have full access"
  ON public.posts
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.user_roles
      WHERE user_roles.user_id = auth.uid()
      AND user_roles.role = 'admin'
    )
  );
```

#### Public Read, Authenticated Write

```sql
-- Anyone can read (including anonymous)
CREATE POLICY "Public read access"
  ON public.posts
  FOR SELECT
  TO anon, authenticated
  USING (published = true);

-- Only authenticated users can insert
CREATE POLICY "Authenticated insert"
  ON public.posts
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = author_id);
```

### RLS Gotchas

**Silent filtering is the default behavior.** When a policy prevents access, Supabase does NOT throw an error — it simply returns no rows (for SELECT) or silently fails (for INSERT/UPDATE/DELETE). This makes debugging extremely difficult.

```typescript
// This returns [] (empty array), NOT an error, if RLS blocks access
const { data, error } = await supabase.from('posts').select('*')
// data = []
// error = null  <-- No error! Just empty results!
```

**Debugging RLS:**
1. Test with the service role key (bypasses RLS) to confirm data exists
2. Check `auth.uid()` is what you expect: `SELECT auth.uid();` in SQL editor
3. Use `EXPLAIN` on your query to see which policies are applied
4. Check that RLS is enabled: `ALTER TABLE posts ENABLE ROW LEVEL SECURITY;`

**The `USING` vs `WITH CHECK` distinction:**
- `USING` — Filters which existing rows can be seen/modified (applied to SELECT, UPDATE, DELETE)
- `WITH CHECK` — Validates the new/modified data (applied to INSERT, UPDATE)
- For UPDATE, you typically need both

## Auth Flows

### Email/Password

```typescript
// Sign up
const { data, error } = await supabase.auth.signUp({
  email: 'user@example.com',
  password: 'secure-password',
})

// Sign in
const { data, error } = await supabase.auth.signInWithPassword({
  email: 'user@example.com',
  password: 'secure-password',
})

// Sign out
await supabase.auth.signOut()
```

### OAuth (Google, GitHub, etc.)

```typescript
const { data, error } = await supabase.auth.signInWithOAuth({
  provider: 'google',
  options: {
    redirectTo: 'http://localhost:3000/auth/callback',
  },
})
```

**Gotcha:** The redirect URL must be added to your Supabase project's Auth settings under "Redirect URLs." Localhost URLs are allowed for development.

### Magic Link

```typescript
const { data, error } = await supabase.auth.signInWithOtp({
  email: 'user@example.com',
  options: {
    emailRedirectTo: 'http://localhost:3000/auth/callback',
  },
})
```

### Auth with Next.js (SSR)

Use `@supabase/ssr` for server-side auth:

```typescript
// lib/supabase/server.ts
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'

export async function createClient() {
  const cookieStore = await cookies()

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll()
        },
        setAll(cookiesToSet: { name: string; value: string; options?: any }[]) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            )
          } catch {
            // Called from Server Component — can't set cookies
            // This is expected in middleware/route handlers
          }
        },
      },
    }
  )
}
```

**Gotcha:** The `setAll` callback typing. If you get "implicit any" errors, explicitly type the parameter as shown above. The `try/catch` is required because `setAll` may be called from a Server Component where cookie setting is not allowed.

### Auth Callback Route

```typescript
// app/auth/callback/route.ts
import { createClient } from '@/lib/supabase/server'
import { NextResponse } from 'next/server'

export async function GET(request: Request) {
  const { searchParams, origin } = new URL(request.url)
  const code = searchParams.get('code')
  const next = searchParams.get('next') ?? '/'

  if (code) {
    const supabase = await createClient()
    const { error } = await supabase.auth.exchangeCodeForSession(code)
    if (!error) {
      return NextResponse.redirect(`${origin}${next}`)
    }
  }

  return NextResponse.redirect(`${origin}/auth/error`)
}
```

## Migration Workflow

### Creating Migrations

```bash
# Generate a new migration file
supabase migration new add_posts_table

# This creates: supabase/migrations/[timestamp]_add_posts_table.sql
```

### Writing Migrations

```sql
-- supabase/migrations/20240101000000_add_posts_table.sql
CREATE TABLE public.posts (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  content TEXT,
  author_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  published BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Always enable RLS
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;

-- Add policies
CREATE POLICY "Users can read published posts"
  ON public.posts FOR SELECT
  USING (published = true);

CREATE POLICY "Authors can manage own posts"
  ON public.posts FOR ALL
  TO authenticated
  USING (auth.uid() = author_id)
  WITH CHECK (auth.uid() = author_id);

-- Indexes for common queries
CREATE INDEX idx_posts_author ON public.posts(author_id);
CREATE INDEX idx_posts_published ON public.posts(published) WHERE published = true;
```

### Applying Migrations

```bash
# Apply to local database
supabase db reset     # Resets and re-applies all migrations

# Apply to remote
supabase db push      # Pushes new migrations to linked project

# Pull remote schema changes (e.g., changes made in Dashboard)
supabase db pull      # Generates migration file from remote diff
```

### Migration Gotchas

- **Never edit an applied migration.** Create a new migration to make changes.
- **`supabase db reset` drops all data.** Only use in development.
- **Always include RLS policies in migrations.** Tables without policies silently return empty.
- Test migrations locally with `supabase db reset` before pushing to production.

## Edge Functions

```typescript
// supabase/functions/hello/index.ts
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  // CORS headers for browser requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    })
  }

  // Get auth user from request
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
  )

  const { data: { user } } = await supabase.auth.getUser()

  return new Response(JSON.stringify({ user }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
```

```bash
# Deploy
supabase functions deploy hello

# Invoke locally
supabase functions serve   # Starts local function server
curl -i --location --request POST 'http://localhost:54321/functions/v1/hello' \
  --header 'Authorization: Bearer <anon-key>'
```

**Gotcha:** Edge Functions run on Deno, not Node.js. Use `esm.sh` for npm packages, not bare `import`.

## Realtime Subscriptions

```typescript
// Subscribe to all changes on a table
const channel = supabase
  .channel('posts-changes')
  .on(
    'postgres_changes',
    { event: '*', schema: 'public', table: 'posts' },
    (payload) => {
      console.log('Change received:', payload)
    }
  )
  .subscribe()

// Subscribe to specific events
  .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'posts' }, handleInsert)
  .on('postgres_changes', { event: 'UPDATE', schema: 'public', table: 'posts' }, handleUpdate)
  .on('postgres_changes', { event: 'DELETE', schema: 'public', table: 'posts' }, handleDelete)

// Filter by column value
  .on('postgres_changes', {
    event: 'INSERT',
    schema: 'public',
    table: 'posts',
    filter: 'author_id=eq.<user-id>'
  }, handleInsert)

// Cleanup
supabase.removeChannel(channel)
```

### Realtime Gotchas

- **RLS applies to Realtime too.** If a user can't SELECT a row, they won't receive realtime events for it.
- **Enable Realtime per table** in the Supabase Dashboard (Database > Replication) or via SQL:
  ```sql
  ALTER PUBLICATION supabase_realtime ADD TABLE posts;
  ```
- **Always unsubscribe** when the component unmounts to prevent memory leaks.
- **Payload size limit:** Large row changes may be truncated. Keep rows reasonably sized.

## Storage

### Upload

```typescript
const { data, error } = await supabase.storage
  .from('avatars')
  .upload(`${userId}/avatar.png`, file, {
    cacheControl: '3600',
    upsert: true,  // Overwrite if exists
  })
```

### Download / Get Public URL

```typescript
// Public URL (bucket must be public)
const { data } = supabase.storage.from('avatars').getPublicUrl('path/to/file.png')

// Signed URL (for private buckets)
const { data, error } = await supabase.storage
  .from('private-docs')
  .createSignedUrl('path/to/file.pdf', 3600) // Expires in 1 hour
```

### Storage Policies

```sql
-- Allow users to upload to their own folder
CREATE POLICY "Users can upload own avatar"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Allow public read on public bucket
CREATE POLICY "Public read for avatars"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'avatars');
```

## Common Errors

### `JWSError JWSInvalidSignature`
- The JWT secret doesn't match between your client and Supabase project
- Fix: Check `SUPABASE_ANON_KEY` and `SUPABASE_URL` are correct

### `relation "public.tablename" does not exist`
- Table hasn't been created, or schema mismatch
- Fix: Run migrations, check you're querying the right schema

### `new row violates row-level security policy`
- RLS `WITH CHECK` clause is rejecting the insert/update
- Fix: Check that the data being written matches your RLS policies

### `permission denied for table tablename`
- RLS is enabled but no policies grant access, or using wrong role
- Fix: Add appropriate policies, check you're using the correct auth token

### Empty results (no error)
- RLS is silently filtering rows
- Fix: Test with service role key. If data appears, your RLS policies need adjustment.

### `Could not find the public.users table` (auth)
- Supabase auth uses the `auth.users` table, not `public.users`
- If you need a public users/profiles table, create one and sync via trigger:

```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email)
  VALUES (new.id, new.email);
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

### `TypeError: supabase.auth.getSession is not a function`
- Version mismatch. `getSession()` is v2 API. v1 used `session()`.
- Fix: Check your `@supabase/supabase-js` version matches your code.

## Client Setup Pattern

```typescript
// lib/supabase/client.ts (browser client)
import { createBrowserClient } from '@supabase/ssr'

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  )
}
```

```typescript
// For non-Next.js projects
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_ANON_KEY!
)
```

## TypeScript Types Generation

```bash
# Generate types from your database schema
supabase gen types typescript --linked > src/types/database.types.ts

# Use the types
import { Database } from '@/types/database.types'

const supabase = createClient<Database>(url, key)

// Now you get full autocomplete on .from('table').select('*')
```

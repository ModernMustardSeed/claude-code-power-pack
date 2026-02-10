# Memory - Brain Boot Sequence

## Session Protocol

**On every session start:**
1. Call `read_graph` from MCP memory to load persistent context
2. Check topic files for current project status and known issues
3. Resume any in-progress work from previous session

**On every session end:**
- Persist new learnings to memory graph via `add_observations`
- Update topic files if patterns or gotchas were discovered

## Self-Healing Rules

- If a memory graph call fails, continue without it — do not block the session
- If a topic file is missing, create it on first write
- If context is stale (>7 days old), verify before acting on it
- Always prefer fresh file reads over cached memory for code state

## Identity

**Name:** YOUR_NAME
**Email:** YOUR_EMAIL
**Organization:** YOUR_ORG

## Project Registry

| Project | Status | Path | Notes |
|---------|--------|------|-------|
| Example App | Active | ~/example-app | In development, priority |
| API Service | Stable | ~/api-service | Deployed, maintenance mode |
| Old Project | Dormant | ~/old-project | Archived, reference only |
<!-- Add your projects here. Status: Active / Stable / Dormant -->

## Environment

- **OS:** Windows/macOS/Linux
- **Shell:** Bash / Zsh / PowerShell
- **Node:** v20+ (via nvm)
- **Package Manager:** pnpm / npm / yarn
- **Path format (Windows):** Bash uses `/c/Users/you/`, Read/Write uses `C:\Users\you\`

## Topic File Links

- [Project Status](./topic-files/projects-status.md)
- [Debugging Playbook](./topic-files/debugging.md)
- [Tech Stack Reference](./topic-files/tech-stack.md)
- [Workflows & Preferences](./topic-files/workflows.md)

## Cross-Project Gotchas

### TypeScript
- Removing a type? Grep every file before deleting — transitive imports break silently
- `strict: true` in tsconfig catches different errors than IDE — always run `tsc --noEmit`
- Duplicate export names across files cause webpack/turbopack failures

### Next.js
- `useSearchParams()` requires a Suspense boundary in Next.js 14+
- App Router: server components cannot use hooks or browser APIs
- Middleware runs on edge — no Node.js APIs (fs, path, etc.)
- `next/headers` and `next/navigation` are server-only in app dir

### React
- State updates in event handlers are batched; in async callbacks they may not be
- `useEffect` cleanup runs before every re-execution, not just unmount
- Keys on list items must be stable — never use array index for mutable lists

### Database / ORM
- Prisma: always run `prisma generate` after schema changes
- Supabase: RLS policies silently return empty arrays — check policies first
- Connection pooling: serverless functions need `?pgbouncer=true`

## Current Priorities

1. <!-- Priority 1 -->
2. <!-- Priority 2 -->
3. <!-- Priority 3 -->

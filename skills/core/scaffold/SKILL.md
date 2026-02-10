---
name: scaffold
description: Generate new projects, features, components, API routes, and agent scaffolds from templates with sensible defaults. Auto-creates CLAUDE.md for new projects and updates the memory graph.
---

# Scaffold - Project and Feature Generator

## Purpose

Bootstrap new projects, features, components, API routes, and agent systems with sensible defaults and consistent structure. Every scaffold includes the metadata and configuration needed for the rest of the skill system to work (CLAUDE.md, memory graph entries, gitignore, etc.).

## Usage

```
/scaffold project [name]           # New project with framework selection
/scaffold feature [name]           # New feature module in current project
/scaffold component [name]         # New UI component with test and stories
/scaffold api [path]               # New API route with handler and types
/scaffold agent [name]             # New AI agent with tool definitions
/scaffold middleware [name]         # New middleware with chain integration
/scaffold test [file]              # Generate tests for an existing file
```

## Execution Strategy

### Phase 1: Context and Memory Load (blocking)

```
Action: mcp__memory__read_graph
Purpose: Understand existing projects, tech stacks, and established patterns.
Extract:
  - Existing project names (to avoid conflicts)
  - Preferred tech stacks and patterns
  - Coding conventions observed in previous reviews
  - Project relationships (monorepo structure, shared libraries)
```

Also read the current project's configuration if scaffolding within an existing project:

```bash
# If in a project directory
cat package.json 2>/dev/null
cat tsconfig.json 2>/dev/null
ls src/ 2>/dev/null
```

### Phase 2: Gather Requirements

Based on the scaffold type, determine what needs to be configured:

#### Project Scaffold Requirements

Ask for or detect:
- **Name**: Required (from command argument)
- **Framework**: Next.js / React / Node.js / Python / Go / Rust (ask if not specified)
- **Features**: Auth, database, API, AI/LLM, payments (ask which)
- **Package manager**: npm / pnpm / yarn / bun (detect from system or ask)
- **Deploy target**: Vercel / Railway / Fly.io / Docker (optional)

If the developer provides minimal input, use these **stack defaults**:

| Choice | Default |
|--------|---------|
| Web app | Next.js 14+ with App Router |
| API server | Node.js with Express or Hono |
| Full-stack | Next.js with API routes |
| AI agent | TypeScript with tool-calling pattern |
| CLI tool | Node.js with Commander |
| Package manager | pnpm (if available), otherwise npm |
| Styling | Tailwind CSS |
| Database | Prisma with SQLite (dev), Postgres (prod) |
| Auth | NextAuth.js / Supabase Auth |
| Testing | Vitest |
| Linting | ESLint + Prettier |

#### Feature/Component/API Requirements

Detect from the existing project:
- Framework and version
- File naming conventions (kebab-case, PascalCase, etc.)
- Directory structure (src/components/, app/, pages/, etc.)
- Import style (absolute paths, aliases like @/)
- State management pattern (if applicable)
- API pattern (REST, tRPC, GraphQL)

### Phase 3: Generate Files

#### Project Scaffold

Create the following structure (adapt based on framework):

```
<project-name>/
  .git/                    # Initialize git
  .gitignore               # Comprehensive ignore file
  .env.example             # Template for required env vars (NO actual secrets)
  CLAUDE.md                # Project instructions for Claude Code
  package.json             # With scripts: dev, build, test, lint
  tsconfig.json            # Strict TypeScript config
  README.md                # Basic readme with setup instructions
  src/
    app/                   # Next.js App Router (or equivalent entry point)
      layout.tsx
      page.tsx
      globals.css
    components/            # Shared UI components
      ui/                  # Base UI primitives
    lib/                   # Shared utilities
      utils.ts
    types/                 # Type definitions
      index.ts
  tests/                   # Test files
    setup.ts
  public/                  # Static assets
```

**CLAUDE.md for new projects:**

```markdown
# CLAUDE.md — [Project Name]

## Overview
[One-line description]

## Tech Stack
- Framework: [Next.js 14 / etc.]
- Language: [TypeScript / etc.]
- Database: [if applicable]
- Deployment: [if known]

## Project Structure
[Key directories and what they contain]

## Development
- Install: `pnpm install`
- Dev server: `pnpm dev`
- Build: `pnpm build`
- Test: `pnpm test`
- Lint: `pnpm lint`

## Environment Variables
[List from .env.example with descriptions]

## Key Patterns
[Document any architectural decisions made during scaffolding]

## Notes
[Any caveats or known limitations]
```

#### Feature Scaffold

```
src/features/<name>/
  index.ts                 # Public API (barrel export)
  <name>.tsx               # Main component or logic
  <name>.test.ts           # Tests
  <name>.types.ts          # Type definitions
  hooks/                   # Feature-specific hooks (if React)
    use-<name>.ts
  utils/                   # Feature-specific utilities
    <name>-helpers.ts
```

#### Component Scaffold

```
src/components/<name>/
  index.ts                 # Barrel export
  <name>.tsx               # Component implementation
  <name>.test.tsx          # Component tests
  <name>.stories.tsx       # Storybook stories (if Storybook detected)
```

Component template:

```typescript
import { type ComponentProps } from "react";

interface <Name>Props {
  // Props here
}

export function <Name>({ ...props }: <Name>Props) {
  return (
    <div>
      {/* Implementation */}
    </div>
  );
}
```

#### API Route Scaffold

For Next.js App Router:

```
src/app/api/<path>/
  route.ts                 # Route handler (GET, POST, PUT, DELETE)
```

Route template:

```typescript
import { NextRequest, NextResponse } from "next/server";

export async function GET(request: NextRequest) {
  try {
    // Implementation
    return NextResponse.json({ data: null });
  } catch (error) {
    console.error("[API] GET /<path> error:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    // Validate body
    // Implementation
    return NextResponse.json({ data: null }, { status: 201 });
  } catch (error) {
    console.error("[API] POST /<path> error:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}
```

#### Agent Scaffold

```
src/agents/<name>/
  index.ts                 # Agent entry point
  <name>.agent.ts          # Agent definition and system prompt
  tools/                   # Tool definitions
    index.ts
    <tool-name>.tool.ts
  types.ts                 # Agent-specific types
  <name>.test.ts           # Agent tests
```

Agent template:

```typescript
import { type Tool } from "./types";

export const <name>Agent = {
  name: "<name>",
  description: "<description>",
  systemPrompt: `You are a helpful assistant that...`,
  tools: [] as Tool[],

  async run(input: string) {
    // Agent execution logic
  },
};
```

#### Middleware Scaffold

```
src/middleware/<name>.ts   # Middleware implementation
```

#### Test Scaffold

Given an existing file, generate a test file:

1. Read the source file
2. Identify exports (functions, classes, components)
3. Generate test cases covering:
   - Happy path for each export
   - Error cases and edge cases
   - Type checking (if TypeScript)
4. Place the test file adjacent to the source or in tests/ directory (match project convention)

### Phase 4: Post-Scaffold Setup

After generating files:

```bash
# Install dependencies (if new project)
cd <project_path> && pnpm install

# Initialize git (if new project)
cd <project_path> && git init && git add -A && git commit -m "chore: initial scaffold"

# Verify build works
cd <project_path> && pnpm build
```

### Phase 5: Memory Update

```
Action: mcp__memory__create_entities
Purpose: Register new project or feature in the knowledge graph

For new projects:
  - Entity: project name
  - Observations: path, tech stack, scaffold date, status

Action: mcp__memory__create_relations
Purpose: Link to related projects (e.g., "depends-on", "sibling-of")
```

### Phase 6: Output Summary

```
## Scaffold Complete — [Type]: [Name]

### Files Created
- path/to/file1.ts (component)
- path/to/file2.ts (test)
- path/to/file3.ts (types)

### Next Steps
1. [Most important thing to do next]
2. [Second thing]
3. [Third thing]

### Configuration Needed
- [ ] Set up environment variables (see .env.example)
- [ ] Configure database connection
- [ ] Add authentication provider credentials

### Commands
- Start development: `pnpm dev`
- Run tests: `pnpm test`
```

## Conventions

### Naming

| Context | Convention | Example |
|---------|-----------|---------|
| Project directory | kebab-case | `my-project` |
| React component | PascalCase | `UserProfile.tsx` |
| Utility function | camelCase | `formatDate.ts` |
| API route | kebab-case | `api/user-profile/route.ts` |
| Test file | match source + `.test` | `UserProfile.test.tsx` |
| Type file | match source + `.types` | `user-profile.types.ts` |
| Hook | `use-` prefix, kebab-case file | `use-auth.ts` |

### What NOT to Scaffold

- Secrets or real API keys (use .env.example with placeholder values)
- Large vendor files or binaries
- IDE-specific configuration (let developers bring their own)
- Opinionated formatting rules (use project defaults or standard configs)

## Cross-Skill Chaining

- After scaffolding a project -> `/setup` to verify everything works
- After scaffolding -> `/sync` to commit the generated code
- After scaffolding an API -> `/review` to check the generated code
- Need to understand existing codebase first -> `/setup` before scaffolding features
- Ready to ship -> `/deploy` to deploy the new project

## Notes

- Scaffolding is opinionated by design. Sensible defaults beat infinite configurability.
- Always generate .env.example, never .env. Never put real secrets in scaffolded files.
- Match existing project conventions when scaffolding within an existing project. Do not impose a new style.
- If the project already uses a pattern (e.g., barrel exports, specific test structure), detect and follow it.
- Generate the minimum viable scaffold. It is easier to add than to remove.
- Every scaffolded project must work immediately: install, build, and dev server should all succeed on the first try.

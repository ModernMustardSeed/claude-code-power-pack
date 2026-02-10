---
name: doc
description: Documentation generator — produce API docs, project READMEs, architecture decision records, and changelogs by reading the codebase and git history.
---

# Documentation Generator Skill

## Trigger

Activated by `/doc` or when the user asks to generate, update, or improve documentation.

## Modes

| Command | Behavior |
|---------|----------|
| `/doc api` | Generate API documentation from route handlers |
| `/doc readme` | Generate or update a project README |
| `/doc adr [decision]` | Create an Architecture Decision Record |
| `/doc changelog` | Generate a changelog from git history |
| `/doc [file]` | Generate inline documentation for a specific file |
| `/doc update` | Refresh existing docs to match current code |

## Execution Strategy

### Phase 1 — Analyze Codebase (parallel)

Before generating any documentation, understand the project:

1. Read `package.json` / `pyproject.toml` / `go.mod` — project name, description, dependencies, scripts
2. Identify the tech stack: framework, language, database, deployment target
3. Read existing documentation: `README.md`, `docs/`, `CONTRIBUTING.md`, `CHANGELOG.md`
4. Check for documentation config: `.typedoc.json`, `jsdoc.json`, `mkdocs.yml`, `docusaurus.config.js`
5. Scan project structure: `ls` top-level directories and key subdirectories
6. `git log --oneline -20` — recent activity for changelog and context

### Mode: `/doc api`

Generate API documentation from the codebase.

**Phase 2a — Discover Routes (parallel)**

Scan for API route definitions based on the framework:

| Framework | Where to Look |
|-----------|---------------|
| Next.js App Router | `app/**/route.ts`, `app/**/route.js` |
| Next.js Pages Router | `pages/api/**/*.ts`, `pages/api/**/*.js` |
| Express | `app.get/post/put/delete/patch()`, `router.*()` |
| Fastify | `fastify.get/post()`, route registration files |
| Flask | `@app.route()`, `@blueprint.route()` |
| Django | `urls.py` patterns |
| Hono | `app.get/post()`, route definitions |

For each route, extract:
- HTTP method (GET, POST, PUT, DELETE, PATCH)
- Path (including dynamic segments)
- Request body schema (from TypeScript types, Zod schemas, or validation middleware)
- Query parameters
- Response shape (from return statements, TypeScript return types)
- Authentication requirements (middleware, decorators)
- Error responses

**Phase 3a — Generate**

Output format options (ask user preference if unclear):

**OpenAPI/Swagger (YAML):**
```yaml
openapi: 3.0.3
info:
  title: Project API
  version: 1.0.0
paths:
  /api/users:
    get:
      summary: List all users
      parameters:
        - name: page
          in: query
          schema:
            type: integer
      responses:
        '200':
          description: List of users
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: '#/components/schemas/User'
```

**Markdown table format:**
```markdown
## API Reference

### Users

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | /api/users | List all users | Required |
| POST | /api/users | Create a user | Required |
| GET | /api/users/:id | Get user by ID | Required |
```

With request/response examples for each endpoint.

---

### Mode: `/doc readme`

Generate a comprehensive project README.

**Phase 2b — Gather (parallel)**

1. Read existing `README.md` if present (to preserve custom content).
2. Detect setup requirements: Node version (`.nvmrc`, `engines`), Python version, env vars needed.
3. Identify available scripts: `npm run *`, `Makefile` targets, `docker-compose` services.
4. Check for deployment config: `Dockerfile`, `vercel.json`, `railway.json`, `fly.toml`.
5. Scan for license: `LICENSE` file.
6. Check for CI: `.github/workflows/`, `.gitlab-ci.yml`.

**Phase 3b — Generate**

Structure:

```markdown
# Project Name

Brief description (1-2 sentences from package.json or inferred from code).

## Features

- Key feature 1
- Key feature 2

## Tech Stack

- Framework: Next.js 14
- Database: PostgreSQL via Prisma
- Auth: NextAuth.js
- Deployment: Vercel

## Getting Started

### Prerequisites

- Node.js >= 18
- PostgreSQL

### Installation

1. Clone the repository
2. Install dependencies: `npm install`
3. Copy environment variables: `cp .env.example .env`
4. Set up database: `npx prisma migrate dev`
5. Start dev server: `npm run dev`

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| DATABASE_URL | PostgreSQL connection string | Yes |
| NEXTAUTH_SECRET | Auth encryption key | Yes |

## Scripts

| Script | Description |
|--------|-------------|
| `npm run dev` | Start development server |
| `npm run build` | Create production build |
| `npm test` | Run test suite |

## Project Structure

Brief description of key directories.

## Contributing

How to contribute (if applicable).

## License

License type.
```

Only include sections that are relevant to the actual project. Do not add placeholder sections.

---

### Mode: `/doc adr [decision]`

Create an Architecture Decision Record.

**Phase 2c — Context**

1. Check for existing ADRs in `docs/adr/`, `docs/decisions/`, or `adr/`.
2. Read recent ADRs to match numbering and format conventions.
3. If no ADR directory exists, create `docs/adr/` and an initial `0001-record-architecture-decisions.md`.

**Phase 3c — Generate**

Use the standard ADR format (Michael Nygard template):

```markdown
# [ADR-NNNN] [Title of Decision]

## Status

Proposed | Accepted | Deprecated | Superseded by [ADR-XXXX]

## Context

What is the issue that we're seeing that is motivating this decision or change?

## Decision

What is the change that we're actually proposing or doing?

## Consequences

What becomes easier or more difficult to do because of this change?

### Positive
- Benefit 1
- Benefit 2

### Negative
- Tradeoff 1
- Tradeoff 2

### Neutral
- Side effect 1
```

Auto-populate the context from the codebase and conversation. Ask the user to confirm the decision and consequences.

---

### Mode: `/doc changelog`

Generate a changelog from git history.

**Phase 2d — Gather**

```bash
# Get all commits since last tag (or last N commits)
git log --oneline --no-merges $(git describe --tags --abbrev=0 2>/dev/null || echo "HEAD~50")..HEAD
# Get tags for version history
git tag --sort=-version:refname
# Get commit details with conventional commit parsing
git log --format="%H %s" --no-merges HEAD~50..HEAD
```

**Phase 3d — Generate**

Follow [Keep a Changelog](https://keepachangelog.com/) format:

```markdown
# Changelog

## [Unreleased]

### Added
- New feature X (#123)
- Support for Y

### Changed
- Updated Z behavior to handle edge case (#456)

### Fixed
- Bug where A caused B (#789)

### Removed
- Deprecated Q endpoint

## [1.2.0] - 2026-01-15

### Added
- ...
```

Parse conventional commit prefixes to categorize:
- `feat:` -> Added
- `fix:` -> Fixed
- `chore:`, `refactor:` -> Changed
- `docs:` -> Documentation
- `BREAKING CHANGE:` -> highlight prominently

---

## Quality Standards

All generated documentation must:

1. **Be accurate.** Every statement must be verifiable against the actual codebase. Do not guess at behavior.
2. **Be current.** Reflect the code as it exists now, not as it was or might be.
3. **Be useful.** Include practical examples, not just type signatures.
4. **Be maintainable.** Prefer formats that are easy to update. Avoid generated docs that will immediately go stale.
5. **Match existing style.** If the project already has docs, match their tone, format, and level of detail.

## Memory Integration

- Store documentation metadata (what was generated, when, for which version) in the memory graph.
- Track which files are documented and which lack documentation.
- Remember project-specific documentation conventions for future sessions.

## Cross-Skill Chaining

| Trigger | Chain to |
|---------|----------|
| README reveals missing tests | Suggest `/test write` for untested areas |
| API docs reveal auth gaps | Suggest `/security` audit |
| Changelog ready for release | Chain to `/pr` to submit |
| ADR involves schema changes | Reference `/migrate` for implementation |
| Documentation reveals performance concerns | Suggest `/perf` audit |

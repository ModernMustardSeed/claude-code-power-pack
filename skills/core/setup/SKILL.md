---
name: setup
description: Onboard into any codebase - detects framework, language, package manager, maps architecture, finds entry points, checks environment, verifies build, and generates a project CLAUDE.md. The "I just cloned this, now what?" skill.
---

# Setup - Codebase Onboarding

## Purpose

Go from "I just cloned this repo" to "I understand this codebase and can work in it" in a single command. Detects everything about a project automatically, verifies the development environment is ready, and produces a CLAUDE.md that makes every future session productive.

## Usage

```
/setup                   # Onboard into the current directory
/setup [path]            # Onboard into a specific project path
/setup --refresh         # Re-analyze a project and update its CLAUDE.md
```

## Execution Strategy

### Phase 1: Memory Check (blocking)

```
Action: mcp__memory__read_graph
Purpose: Check if this project already exists in the knowledge graph.
         If it does, load previous context to compare against current state.
Extract:
  - Existing project entity (if any)
  - Known tech stack, scripts, and conventions
  - Previous issues or setup notes
```

If the project already exists in memory and `--refresh` was not specified, ask: "This project is already onboarded. Run with --refresh to update, or continue for a fresh analysis?"

### Phase 2: Parallel Detection Sweep

Run ALL of the following simultaneously to build a complete picture of the project.

#### 2A: Language and Framework Detection

Read these files (whichever exist):

```
package.json             -> Node.js ecosystem (check dependencies for framework)
tsconfig.json            -> TypeScript configuration
jsconfig.json            -> JavaScript with path aliases
Cargo.toml               -> Rust
go.mod                   -> Go
pyproject.toml           -> Python (modern)
setup.py / setup.cfg     -> Python (legacy)
requirements.txt         -> Python (pip)
Pipfile                  -> Python (pipenv)
Gemfile                  -> Ruby
pom.xml                  -> Java (Maven)
build.gradle             -> Java/Kotlin (Gradle)
composer.json            -> PHP
mix.exs                  -> Elixir
pubspec.yaml             -> Dart/Flutter
```

From `package.json`, detect framework by checking dependencies:

| Dependency | Framework |
|-----------|-----------|
| `next` | Next.js (check version: 12/13/14/15) |
| `react` (no next) | React SPA |
| `vue` | Vue.js |
| `svelte` / `@sveltejs/kit` | Svelte / SvelteKit |
| `@angular/core` | Angular |
| `express` | Express.js |
| `hono` | Hono |
| `fastify` | Fastify |
| `@remix-run/node` | Remix |
| `astro` | Astro |
| `nuxt` | Nuxt |
| `electron` | Electron |
| `react-native` | React Native |

Also detect:

| Dependency / File | Technology |
|-------------------|-----------|
| `prisma` / `schema.prisma` | Prisma ORM |
| `drizzle-orm` | Drizzle ORM |
| `@supabase/supabase-js` | Supabase |
| `firebase` | Firebase |
| `stripe` | Stripe payments |
| `@auth/core` / `next-auth` | Auth.js / NextAuth |
| `tailwindcss` / `tailwind.config.*` | Tailwind CSS |
| `@trigger.dev/sdk` | Trigger.dev |
| `.github/workflows/` | GitHub Actions CI/CD |

#### 2B: Package Manager Detection

```bash
# Check for lockfiles (order = priority)
test -f "<path>/pnpm-lock.yaml" && echo "pnpm"
test -f "<path>/bun.lockb" && echo "bun"
test -f "<path>/yarn.lock" && echo "yarn"
test -f "<path>/package-lock.json" && echo "npm"

# Check for workspace configuration (monorepo)
# pnpm-workspace.yaml, workspaces in package.json, lerna.json, turbo.json
```

#### 2C: Project Structure Mapping

```bash
# Get directory tree (depth-limited)
find <path> -maxdepth 3 -type d \
  -not -path "*/node_modules/*" \
  -not -path "*/.next/*" \
  -not -path "*/.git/*" \
  -not -path "*/dist/*" \
  -not -path "*/__pycache__/*" \
  -not -path "*/.turbo/*" \
  | head -50

# Count files by type
find <path> -type f -name "*.ts" | wc -l
find <path> -type f -name "*.tsx" | wc -l
find <path> -type f -name "*.js" | wc -l
find <path> -type f -name "*.py" | wc -l
find <path> -type f -name "*.go" | wc -l
```

#### 2D: Entry Point Discovery

Look for entry points based on detected framework:

| Framework | Entry Points |
|-----------|-------------|
| Next.js (App Router) | `app/layout.tsx`, `app/page.tsx`, `middleware.ts` |
| Next.js (Pages) | `pages/_app.tsx`, `pages/index.tsx` |
| React SPA | `src/index.tsx`, `src/App.tsx`, `src/main.tsx` |
| Express | `src/index.ts`, `src/server.ts`, `src/app.ts` |
| Python | `main.py`, `app.py`, `src/__main__.py` |
| Go | `main.go`, `cmd/*/main.go` |
| Rust | `src/main.rs`, `src/lib.rs` |

Also check `package.json` for `main`, `module`, and `exports` fields.

#### 2E: Configuration File Inventory

Check for and read key configuration files:

```
.env.example / .env.template    -> Required environment variables
.eslintrc* / eslint.config.*    -> Linting rules
.prettierrc* / prettier.config* -> Formatting rules
vercel.json                     -> Vercel deployment config
railway.json / railway.toml     -> Railway deployment config
netlify.toml                    -> Netlify deployment config
fly.toml                        -> Fly.io deployment config
docker-compose.yml              -> Docker services
Dockerfile                      -> Container build
.github/workflows/*.yml         -> CI/CD pipelines
```

#### 2F: Git Analysis

```bash
git -C <path> log --oneline -20
git -C <path> log --format="%aN" | sort | uniq -c | sort -rn | head -5
git -C <path> branch -a
git -C <path> remote -v
git -C <path> log --format="%cr" -1
```

Extract:
- Recent commit history (what has been worked on)
- Top contributors
- Branch structure
- Remote configuration
- Last activity date

### Phase 3: Environment Verification

#### 3A: Check Required Environment Variables

```bash
# Extract from .env.example
if [ -f "<path>/.env.example" ]; then
    # Parse variable names
    grep -E "^[A-Z_]+" <path>/.env.example | cut -d= -f1
fi

# Check if .env exists
test -f "<path>/.env" && echo "HAS_ENV" || echo "MISSING_ENV"

# If .env exists, check which required vars are set (without reading values)
if [ -f "<path>/.env" ]; then
    for var in $(grep -E "^[A-Z_]+" <path>/.env.example | cut -d= -f1); do
        grep -q "^${var}=" <path>/.env && echo "${var}: SET" || echo "${var}: MISSING"
    done
fi
```

#### 3B: Check Runtime Dependencies

```bash
# Node.js version
node --version 2>/dev/null

# Package manager version
pnpm --version 2>/dev/null
npm --version 2>/dev/null
yarn --version 2>/dev/null
bun --version 2>/dev/null

# Database tools (if project uses them)
psql --version 2>/dev/null
redis-cli --version 2>/dev/null

# Other runtimes
python3 --version 2>/dev/null
go version 2>/dev/null
rustc --version 2>/dev/null
```

#### 3C: Install Dependencies (with confirmation)

If dependencies are not installed:

```
Dependencies are not installed. Install with [pnpm install]? [Y/n]
```

If confirmed:
```bash
cd <path> && <package_manager> install
```

#### 3D: Verify Build

```bash
cd <path> && <package_manager> run build 2>&1
```

Report: pass/fail with relevant error output.

### Phase 4: Architecture Analysis

Based on all collected data, synthesize an understanding of the architecture:

1. **Application type**: Web app, API server, CLI tool, library, monorepo, mobile app
2. **Architecture pattern**: MVC, feature-sliced, domain-driven, component-based, microservices
3. **Data flow**: Client -> API -> Database, SSR/SSG, SPA with REST/GraphQL
4. **Key abstractions**: What are the main modules, services, or domains?
5. **External integrations**: Third-party APIs, services, databases
6. **Build pipeline**: How does code get from source to production?

Read 3-5 key files to understand patterns:

- Main entry point
- A representative component or module
- Database schema or models (if applicable)
- API route handler (if applicable)
- Configuration or constants file

### Phase 5: Generate CLAUDE.md

If the project does not have a CLAUDE.md (or `--refresh` was specified), generate one:

```markdown
# CLAUDE.md — [Project Name]

## Overview
[1-2 sentences describing what this project does]

## Tech Stack
- **Framework**: [Name + version]
- **Language**: [TypeScript/JavaScript/Python/etc.]
- **Package Manager**: [pnpm/npm/yarn/bun]
- **Database**: [if applicable]
- **Auth**: [if applicable]
- **Deployment**: [platform if detected]
- **CI/CD**: [if detected]

## Project Structure
```
[Annotated directory tree — key directories only, with descriptions]
```

## Development

### Prerequisites
- Node.js [version]
- [Package manager] [version]
- [Any other requirements]

### Getting Started
```bash
[clone command]
[install command]
[env setup command]
[dev server command]
```

### Available Scripts
| Script | Command | Description |
|--------|---------|-------------|
| dev | `pnpm dev` | Start development server |
| build | `pnpm build` | Production build |
| test | `pnpm test` | Run test suite |
| lint | `pnpm lint` | Run linter |

## Environment Variables
| Variable | Required | Description |
|----------|----------|-------------|
| [VAR_NAME] | Yes/No | [What it's for] |

## Architecture
[Brief description of the architecture pattern and data flow]

### Key Entry Points
- [Main entry]: [what it does]
- [API entry]: [what it does]
- [Config]: [what it configures]

### Key Patterns
- [Pattern 1: e.g., "API routes use middleware chain for auth"]
- [Pattern 2: e.g., "Components follow feature-sliced design"]
- [Pattern 3: e.g., "Database access through repository pattern"]

## External Services
- [Service 1]: [what it's used for]
- [Service 2]: [what it's used for]

## Known Issues
- [Any issues discovered during setup]

## Notes
- [Anything else useful for future sessions]
```

If a CLAUDE.md already exists and `--refresh` was specified, show a diff of proposed changes and ask before overwriting.

### Phase 6: Onboarding Report

```
## Setup Complete — [Project Name]

### Project Profile
- Type: [Web app / API / CLI / Library / Monorepo]
- Framework: [Next.js 14 / Express / etc.]
- Language: [TypeScript / Python / etc.]
- Size: [N files, N lines estimated]
- Last active: [relative time]
- Contributors: [count]

### Environment Status
| Check | Status |
|-------|--------|
| Dependencies installed | YES/NO |
| Required env vars set | N/M present |
| Build passes | YES/NO |
| Dev server starts | YES/NO (if checked) |
| Tests pass | YES/NO / N/A |

### Missing Setup
- [ ] [Environment variable X needs to be set]
- [ ] [Database needs to be migrated]
- [ ] [Docker services need to be started]

### Architecture Overview
[3-5 sentence summary of how the codebase is organized]

### Suggested First Actions
1. [Most useful thing to do first in this codebase]
2. [Second most useful]
3. [Third]

### Generated Files
- CLAUDE.md [created/updated/already existed]
```

### Phase 7: Memory Update

```
Action: mcp__memory__create_entities (if new project)
Action: mcp__memory__add_observations (always)
Data:
  - Project name, path, tech stack
  - Framework and version
  - Entry points
  - Architecture pattern
  - Setup date
  - Any issues encountered
  - Build status
```

## Monorepo Handling

If a monorepo is detected (turbo.json, pnpm-workspace.yaml, lerna.json, or workspaces in package.json):

1. Identify all packages/apps within the monorepo
2. Report the workspace structure
3. Identify shared packages vs. deployable apps
4. Check if each workspace builds independently
5. Document inter-workspace dependencies

## Handling Common Issues

| Issue | Detection | Action |
|-------|-----------|--------|
| Wrong Node version | `engines` in package.json vs `node --version` | Suggest nvm/fnm |
| Missing .env | No .env but .env.example exists | Offer to copy template |
| Lockfile mismatch | Lockfile for different PM than detected | Warn and suggest fix |
| Outdated deps | `npm audit` findings | Report but do not auto-fix |
| Missing git hooks | husky/lint-staged in deps but not installed | Suggest `pnpm prepare` |
| Port conflicts | Common dev ports (3000, 5432, 6379) | Check and warn |

## Cross-Skill Chaining

- After setup -> `/status` to check project health
- After setup -> `/review` to do an initial code review
- Missing tests -> `/scaffold test [file]` to generate test stubs
- Ready to start working -> `/boot` for full session initialization
- New feature needed -> `/scaffold feature [name]` using detected conventions
- Ready to deploy -> `/deploy` with detected platform configuration

## Notes

- This skill is read-heavy and write-light. The only file it creates is CLAUDE.md (with permission).
- Never modify project code during setup. This is strictly an analysis tool.
- If build fails during setup, report the error clearly but do not attempt to fix it. That is a task for the developer.
- For large projects (100+ files), focus on key directories and patterns rather than reading everything.
- The generated CLAUDE.md should be accurate enough to commit to the repo. It is documentation, not a scratch pad.
- When running `--refresh`, preserve any manual edits the developer added to CLAUDE.md. Merge changes, do not overwrite.
- Setup should complete in under 2 minutes for typical projects. If analysis is taking too long, report what was gathered so far and offer to continue.

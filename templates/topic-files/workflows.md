# Workflows & Preferences

> How you like to work, what Claude can do autonomously, and available automation tools.

## How You Work

- **Approach:** Ship fast, iterate. Working software over perfect abstractions.
- **Branching:** Feature branches off main, squash-merge PRs.
- **Testing:** Test critical paths. Don't test implementation details.
- **Reviews:** Claude drafts PRs. You review before merge.
- **Deploys:** Merge to main = auto-deploy to staging. Manual promote to prod.
<!-- Customize these to match your actual workflow preferences -->

## Automation Boundaries

| Action | Autonomous | Ask First |
|--------|-----------|-----------|
| Read/write local files | Yes | - |
| Run builds, linters, tests | Yes | - |
| Git commit (local) | Yes | - |
| Git push / create PR | - | Yes |
| Web search / docs lookup | Yes | - |
| Update memory graph | Yes | - |
| Send emails or messages | - | Yes |
| Post to social media | - | Yes |
| Delete files or branches | - | Yes |
| Deploy to production | - | Yes |
| Spend money (API calls, services) | - | Yes |

## Custom Skills

> Skills are reusable Claude Code slash commands in `~/.claude/skills/`.

| Skill | Category | Description |
|-------|----------|-------------|
| `/boot` | Core | Initialize session, load memory graph, check priorities |
| `/audit` | Core | Scan project for security issues, outdated deps, code smells |
| `/status` | Core | Show all project statuses and current priorities |
| `/sync` | Core | Pull latest changes, update deps, regenerate types |
| `/deploy` | Core | Build, test, and deploy to target environment |
| `/review` | Core | Code review with suggestions and security checks |
| `/scaffold` | Core | Generate new project from template with full config |
| `/setup` | Core | Initialize a new project with standard tooling |
| `/pr` | Workflow | Create a pull request with summary and test plan |
| `/test` | Workflow | Generate or run tests for the current feature |
| `/debug` | Workflow | Investigate and fix a bug with structured approach |
| `/security` | Workflow | Run security audit (deps, secrets, headers, RLS) |
| `/migrate` | Workflow | Plan and execute database or framework migration |
| `/doc` | Workflow | Generate or update documentation |
| `/perf` | Workflow | Profile and optimize performance bottlenecks |
| `/social` | Productivity | Draft social media posts for multiple platforms |
| `/leads` | Productivity | Research and qualify leads from various sources |
| `/gtm` | Productivity | Go-to-market planning and execution |
| `/research` | Productivity | Deep research on a topic with sources |
| `/briefing` | Productivity | Morning briefing: calendar, emails, priorities |

## MCP Server Capabilities

| Server | What It Does | Key Commands |
|--------|-------------|--------------|
| **filesystem** | Read/write/search files anywhere | `read_file`, `write_file`, `search_files`, `list_directory` |
| **memory** | Persistent knowledge graph across sessions | `read_graph`, `add_observations`, `create_entities`, `search_nodes` |
| **github** | Full GitHub API access | `create_pull_request`, `list_issues`, `create_branch`, `search_code` |
| **puppeteer** | Browser automation and screenshots | `navigate`, `click`, `fill`, `screenshot`, `evaluate` |
| **google-workspace** | Calendar, email, docs, sheets, drive | `get_events`, `send_gmail_message`, `get_doc_content` |
| **context7** | Up-to-date library documentation | `resolve-library-id`, `query-docs` |
| **sequential-thinking** | Multi-step reasoning for complex problems | `sequentialthinking` |
<!-- Add or remove MCP servers to match your configuration -->

## Sequential Thinking Usage Guide

Use the sequential-thinking MCP for problems that need step-by-step reasoning:

**When to use it:**
- Debugging a multi-file issue where the root cause is unclear
- Planning a refactor that touches many components
- Designing a new feature with complex requirements
- Making architectural decisions with tradeoffs

**When NOT to use it:**
- Simple code edits or file operations
- Tasks where the solution is obvious
- Quick lookups or searches

**Pattern:**
1. Start with a broad hypothesis
2. Each thought narrows the search space
3. Revise earlier thoughts when new evidence appears
4. End with a concrete action plan

## Session Patterns

### Starting a Session
1. `/boot` to load context and memory
2. `/status` to see what needs attention
3. Pick the highest-priority task and begin

### Ending a Session
1. Commit any work in progress (even to a WIP branch)
2. Update memory graph with key learnings
3. Note next steps in the relevant topic file

### Context Recovery (After /compact)
- CLAUDE.md reloads automatically (it's in the project root)
- Memory graph persists across compacts (call `read_graph`)
- Topic files are always available via filesystem
- The compact summary preserves key session state

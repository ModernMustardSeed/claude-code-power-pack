# Claude Code Power Pack

The ultimate agentic setup for Claude Code (Opus 4.6). A complete memory system, 20 production-ready skills, stack-specific modules, and self-healing infrastructure that makes Claude Code actually remember you, your projects, and how you work.

## Why This Exists

Out of the box, Claude Code starts every session blank. It doesn't know your projects, your conventions, your debugging history, or your preferences. You re-explain everything. Every. Single. Time.

This power pack fixes that with a **4-layer memory architecture** that persists across sessions, self-heals, and gets smarter over time.

## What's Inside

| Component | Count | Description |
|-----------|-------|-------------|
| **Skills** | 20 | Production-ready slash commands for common workflows |
| **Templates** | 7 | CLAUDE.md, MEMORY.md, topic files, per-project config |
| **Stack Modules** | 6 | Pluggable knowledge for Next.js, React Native, Supabase, Prisma, Tailwind, Docker |
| **Hooks** | 3 | Pre-commit secret scanning, build validation, session logging |
| **Keybindings** | 1 | Optimized keyboard shortcuts |
| **MCP Guide** | 1 | Which servers to use, why, and how to configure them |
| **Init Scripts** | 2 | One-command setup for macOS/Linux and Windows |

## The 4-Layer Memory Architecture

```
Layer 1: MEMORY.md (Brain Boot Sequence)
  - Auto-loaded every session (200-line cap)
  - Your identity, all projects, environment, priorities
  - Self-healing rules and session protocol

Layer 2: Topic Files (Deep Knowledge)
  - projects-status.md — detailed state per project
  - debugging.md — error patterns, gotchas, fixes
  - tech-stack.md — architecture decisions, conventions
  - workflows.md — how you work, skill inventory

Layer 3: MCP Knowledge Graph (Entities & Relations)
  - Persistent across all sessions
  - Stores: projects, people, decisions, leads, research
  - Queryable with mcp__memory__read_graph

Layer 4: Per-Project CLAUDE.md (Auto-Context)
  - Drops into each project root
  - Auto-loaded when you cd into a project
  - Tech stack, conventions, known issues, build commands
```

## Quick Start

### macOS / Linux
```bash
git clone https://github.com/ModernMustardSeed/claude-code-power-pack.git
cd claude-code-power-pack
chmod +x init.sh
./init.sh
```

### Windows (PowerShell)
```powershell
git clone https://github.com/ModernMustardSeed/claude-code-power-pack.git
cd claude-code-power-pack
.\init.ps1
```

### Manual Setup
If you prefer to cherry-pick:
1. Copy skills you want from `skills/` to `~/.claude/skills/`
2. Copy `templates/CLAUDE.md` to your home directory, customize it
3. Copy `templates/MEMORY.md` to `~/.claude/projects/<your-project>/memory/`
4. Copy topic files from `templates/topic-files/` to the same memory directory

## Skills Reference

### Core Skills (8)
Essential operations that every developer needs.

| Skill | Command | Description |
|-------|---------|-------------|
| Boot | `/boot` | Full session startup — loads memory graph, checks projects, calendar, priorities |
| Audit | `/audit` | Self-healing scan — verifies memory, checks projects, fixes stale data |
| Status | `/status` | Git status across all projects with actionable flags |
| Sync | `/sync` | Safe commit and push across one or all projects |
| Deploy | `/deploy` | Build verification + platform-detected deployment |
| Review | `/review` | Security-first code review with severity tiers |
| Scaffold | `/scaffold` | Generate projects, features, components, API routes |
| Setup | `/setup` | Onboard into any codebase — detect stack, explain architecture |

### Workflow Skills (7)
Development workflow automation.

| Skill | Command | Description |
|-------|---------|-------------|
| PR | `/pr` | Full PR workflow — branch, commit, push, open PR with auto-description |
| Test | `/test` | Detect test framework, run tests, write missing tests, coverage |
| Debug | `/debug` | Systematic debugging — reproduce, isolate, hypothesize, fix, verify |
| Security | `/security` | Dependency audit + secret scan + OWASP review |
| Migrate | `/migrate` | Safe database migrations with rollback planning |
| Doc | `/doc` | Generate API docs, READMEs, architecture decision records |
| Perf | `/perf` | Performance audit — bundle, queries, rendering, Lighthouse |

### Productivity Skills (5)
Business and content operations.

| Skill | Command | Description |
|-------|---------|-------------|
| Research | `/research` | Multi-source deep research with structured output |
| Briefing | `/briefing` | Daily briefing — calendar, email, projects, priorities |
| Social | `/social` | Platform-optimized social media content drafting |
| Leads | `/leads` | Lead generation, qualification, and CRM integration |
| GTM | `/gtm` | Go-to-market strategy with launch checklist |

## Stack Modules

Stack modules add framework-specific knowledge to your debugging.md and tech-stack.md. Drop them into your topic files to give Claude deep knowledge of your stack.

| Module | Covers |
|--------|--------|
| `stacks/nextjs/` | App Router, Server Components, Middleware, Metadata, Caching |
| `stacks/react-native/` | Expo SDK 54, Metro, Native Modules, OTA Updates |
| `stacks/supabase/` | RLS Policies, Auth Flows, Migrations, Edge Functions, Realtime |
| `stacks/prisma/` | Schema Design, Migrations, Query Optimization, Relations |
| `stacks/tailwind/` | Config Patterns, Custom Plugins, Responsive, Dark Mode |
| `stacks/docker/` | Dockerfile Patterns, Compose, Multi-stage, Healthchecks |

## Hooks

Pre-configured Claude Code hooks for safety and quality.

| Hook | Trigger | What It Does |
|------|---------|-------------|
| `secret-scan.sh` | PreToolUse (Write/Edit) | Scans for API keys, tokens, passwords before writing files |
| `build-check.sh` | PostToolUse (Bash) | Reports build success/failure after npm run build |
| `session-log.sh` | PostToolUse (Bash) | Logs significant operations for session history |

## MCP Server Recommendations

See `mcp-guide/README.md` for detailed setup instructions. Quick overview:

| Server | Priority | Why |
|--------|----------|-----|
| **memory** | Essential | Persistent knowledge graph across sessions |
| **filesystem** | Essential | Read/write/search files |
| **github** | Essential | PR, issue, and repo operations |
| **sequential-thinking** | Recommended | Extended reasoning for complex problems |
| **context7** | Recommended | Library documentation lookup |
| **google-workspace** | Optional | Calendar, Gmail, Docs integration |
| **puppeteer** | Optional | Browser automation and testing |

## Skill Architecture

All skills follow a consistent 4-phase pattern optimized for Opus 4.6:

```
Phase 1: CONTEXT (parallel)
  Load memory graph, read project CLAUDE.md, gather relevant data
  → Multiple tool calls simultaneously

Phase 2: EXECUTE
  Do the actual work with full context loaded

Phase 3: MEMORY
  Update knowledge graph, topic files, per-project CLAUDE.md

Phase 4: CHAIN
  Suggest the next logical skill in the workflow
  /review → /test → /sync → /pr → /deploy
```

## Self-Healing Protocol

The system maintains itself:

1. **On sight** — When Claude notices stale data, it fixes it immediately
2. **After work** — After significant changes, Claude updates topic files and memory graph
3. **Weekly** — Run `/audit` to verify all paths, entities, and observations
4. **On error** — When a build fails for a known pattern, check debugging.md first
5. **On prune** — When MEMORY.md exceeds 180 lines, remove least important items

## File Structure

```
claude-code-power-pack/
├── README.md                           # This file
├── init.sh                             # Setup script (macOS/Linux)
├── init.ps1                            # Setup script (Windows)
├── LICENSE                             # MIT License
├── templates/
│   ├── CLAUDE.md                       # Root config template
│   ├── MEMORY.md                       # Brain boot sequence template
│   ├── project-CLAUDE.md               # Per-project template
│   └── topic-files/
│       ├── projects-status.md
│       ├── debugging.md
│       ├── tech-stack.md
│       └── workflows.md
├── skills/
│   ├── core/                           # Essential skills
│   │   ├── boot/SKILL.md
│   │   ├── audit/SKILL.md
│   │   ├── status/SKILL.md
│   │   ├── sync/SKILL.md
│   │   ├── deploy/SKILL.md
│   │   ├── review/SKILL.md
│   │   ├── scaffold/SKILL.md
│   │   └── setup/SKILL.md
│   ├── workflow/                        # Dev workflow skills
│   │   ├── pr/SKILL.md
│   │   ├── test/SKILL.md
│   │   ├── debug/SKILL.md
│   │   ├── security/SKILL.md
│   │   ├── migrate/SKILL.md
│   │   ├── doc/SKILL.md
│   │   └── perf/SKILL.md
│   └── productivity/                    # Business/content skills
│       ├── social/SKILL.md
│       ├── leads/SKILL.md
│       ├── gtm/SKILL.md
│       ├── research/SKILL.md
│       └── briefing/SKILL.md
├── stacks/                              # Framework-specific modules
│   ├── nextjs/README.md
│   ├── react-native/README.md
│   ├── supabase/README.md
│   ├── prisma/README.md
│   ├── tailwind/README.md
│   └── docker/README.md
├── hooks/                               # Claude Code hooks
│   ├── secret-scan.sh
│   ├── build-check.sh
│   └── session-log.sh
├── keybindings.json                     # Keyboard shortcuts
└── mcp-guide/
    └── README.md                        # MCP setup instructions
```

## Customization

### Adding Your Own Skills
Create a new directory in `~/.claude/skills/` with a `SKILL.md` file:
```
~/.claude/skills/my-skill/SKILL.md
```

Frontmatter format:
```yaml
---
name: my-skill
description: What this skill does (shown in /slash menu)
---
```

### Adding Stack Modules
Copy the relevant stack module content into your `debugging.md` and `tech-stack.md` topic files.

### Modifying the Boot Sequence
Edit `MEMORY.md` to include your specific projects, priorities, and environment details. Stay under 200 lines.

## Contributing

PRs welcome. If you've built useful skills, stack modules, or error patterns, share them:

1. Fork the repo
2. Add your contribution to the relevant directory
3. Keep skills generic (no personal info, API keys, or project-specific details)
4. Submit a PR with a description of what it does and why it's useful

## License

MIT License. Use it, modify it, ship it.

---

Built with Claude Code (Opus 4.6) by [Modern Mustard Seed](https://modernmustardseed.com).

---
name: sync
description: Safe, intelligent commit and push workflow. Generates descriptive commit messages, stages specific files (never blind git add), enforces safety rules, and supports single-project or sweep-all modes.
---

# Sync - Safe Commit and Push

## Purpose

Commit and push changes safely and intelligently. This skill replaces the risky habit of `git add -A && git commit -m "update" && git push` with a thoughtful, secure workflow that generates meaningful commit messages and never commits secrets.

## Usage

```
/sync                # Sync current working directory project
/sync all            # Sync all projects with uncommitted changes
/sync [project]      # Sync a specific project by name
/sync --dry-run      # Show what would be committed without doing it
```

## Safety Rules (non-negotiable)

These rules are HARD constraints. Violating them is never acceptable.

1. **Never use `git add -A` or `git add .`** — Always stage specific files by name
2. **Never force push** — No `--force`, no `--force-with-lease` unless explicitly requested
3. **Never commit secrets** — Scan for API keys, tokens, passwords, .env files before staging
4. **Never commit to main/master without confirmation** — Always ask first
5. **Never skip hooks** — No `--no-verify` unless explicitly requested
6. **Never amend commits** — Create new commits; amending rewrites history
7. **Never commit generated files** — Skip node_modules, .next, dist, build, __pycache__, etc.
8. **Always create new commits** — Even after a hook failure, fix and make a NEW commit

## Execution Strategy

### Phase 1: Memory Load

```
Action: mcp__memory__read_graph
Purpose: Get project context for better commit messages. Understand what the developer
         has been working on to generate semantically meaningful descriptions.
```

### Phase 2: Discover What Needs Syncing

#### Single Project Mode (`/sync` or `/sync [name]`)

```bash
# Identify the project
git -C <path> rev-parse --show-toplevel
git -C <path> status --porcelain
git -C <path> diff --stat
git -C <path> diff --cached --stat
```

#### All Projects Mode (`/sync all`)

Run in parallel for every tracked project:

```bash
git -C <path> status --porcelain 2>/dev/null
```

Filter to only projects with changes. Present the list and ask for confirmation before proceeding.

### Phase 3: Pre-Commit Security Scan

For each file that would be staged, check for secrets:

```bash
# Files to scan: all modified and untracked files
git -C <path> diff --name-only
git -C <path> ls-files --others --exclude-standard
```

**Block staging if any file matches these patterns:**

| Pattern | Risk |
|---------|------|
| `.env`, `.env.*` | Environment secrets |
| `*.pem`, `*.key`, `*.p12` | Certificates and keys |
| `credentials.*`, `secrets.*` | Credential files |
| `*_rsa`, `*_dsa`, `*_ecdsa` | SSH keys |
| Files containing `PRIVATE KEY` | Embedded private keys |
| Files containing `sk-`, `sk_live`, `pk_live` | API keys |
| Files containing strings matching `[A-Za-z0-9]{32,}` near keywords like `key`, `secret`, `token`, `password` | Potential secrets |

If a secret is detected:
1. Report which file and what was found
2. Do NOT stage the file
3. Suggest adding it to `.gitignore`
4. Continue with remaining safe files

**Always skip these paths:**

```
node_modules/    .next/         dist/           build/
__pycache__/     .cache/        .turbo/         .vercel/
coverage/        .nyc_output/   *.log           .DS_Store
```

### Phase 4: Intelligent Staging

Group changed files by type and purpose:

```
Analyze the changes:
1. Read the diff for each file
2. Group related changes (e.g., component + its test + its styles)
3. Determine if changes should be one commit or multiple
```

**Single commit** when:
- All changes relate to one feature, fix, or task
- Total changed files < 10
- Changes are in closely related files

**Multiple commits** when:
- Changes span unrelated features
- Mix of bug fixes and new features
- Changes to config files are separate from code changes

Stage files explicitly:

```bash
git -C <path> add <file1> <file2> <file3>
```

### Phase 5: Generate Commit Message

Analyze the staged diff to generate a descriptive commit message:

```bash
git -C <path> diff --cached
```

**Commit message format:**

```
<type>(<scope>): <short description>

<body — what changed and why>

Co-Authored-By: Claude <noreply@anthropic.com>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code restructuring without behavior change
- `docs`: Documentation only
- `style`: Formatting, whitespace (no code change)
- `test`: Adding or updating tests
- `chore`: Build config, dependencies, tooling
- `perf`: Performance improvement

**Rules for good messages:**
- Short description is imperative mood ("add", not "added" or "adds")
- Under 72 characters for the first line
- Body explains WHY, not just WHAT
- Reference issue numbers if known from memory graph

### Phase 6: Commit

```bash
git -C <path> commit -m "<message>"
```

If the commit fails due to pre-commit hooks:
1. Read the hook output
2. Fix the issue (formatting, linting, etc.)
3. Re-stage the fixed files
4. Create a NEW commit (never amend)

### Phase 7: Push

Before pushing, verify:

```bash
# Check current branch
git -C <path> rev-parse --abbrev-ref HEAD

# Check if branch tracks a remote
git -C <path> rev-parse --abbrev-ref @{upstream} 2>/dev/null

# Check for divergence
git -C <path> fetch --dry-run 2>&1
```

**Push rules:**
- If on main/master: ASK before pushing
- If branch has no upstream: use `git push -u origin <branch>`
- If branch has diverged: STOP and report — do not auto-resolve
- If remote is ahead: STOP and suggest pulling first
- Otherwise: `git push`

### Phase 8: Post-Sync Report

```
## Sync Complete — [Date]

### [Project Name]
- Branch: feature/auth
- Commits: 2 new
- Files: 7 changed, 2 new, 1 deleted
- Pushed: Yes, to origin/feature/auth

### Commit Summary
1. feat(auth): add JWT token refresh logic
   - src/auth/refresh.ts (new)
   - src/auth/middleware.ts (modified)
   - src/auth/types.ts (modified)

2. test(auth): add refresh token test suite
   - tests/auth/refresh.test.ts (new)
   - tests/auth/fixtures.ts (modified)

### Skipped
- .env.local (secret file — not committed)
- node_modules/ (generated)
```

### Phase 9: Memory Update

```
Action: mcp__memory__add_observations
Purpose: Record what was synced — project, branch, commit hashes, summary
```

## Dry Run Mode

When `--dry-run` is specified, execute Phases 1-5 but stop before committing. Show:

- Files that would be staged (grouped)
- Files that would be skipped (and why)
- Generated commit message(s)
- Whether push would happen and to where

## Sweep All Mode

When `/sync all` is used:

1. Run Phase 2 for all projects in parallel
2. Present a summary table of what would be synced
3. Ask for confirmation: "Sync all N projects?" or "Select which to sync"
4. Process each project sequentially (to avoid git conflicts)
5. Present a combined report at the end

## Cross-Skill Chaining

- Before sync: `/status` to see full picture
- After sync: `/deploy` if changes are ready for production
- If conflicts found: `/review` to understand the conflicting code
- After syncing all: `/status` to verify everything is clean

## Notes

- Commit messages should be useful to Future You reading `git log` in 6 months.
- When in doubt about whether to commit something, ask. It is better to ask than to commit a secret.
- If the developer provides a commit message, use it — do not override their intent.
- For monorepos with workspaces, consider per-workspace commits if changes span packages.

---
name: review
description: Security-first, multi-layer code review. Analyzes diffs, files, or pull requests through Security (OWASP), Bugs, Performance, and Patterns layers. Outputs prioritized findings as Critical/Warning/Suggestion/Summary.
---

# Review - Security-First Code Review

## Purpose

Perform thorough, opinionated code review that catches security vulnerabilities, bugs, performance issues, and anti-patterns. Security is always the first lens. The output is structured for quick triage: fix the critical stuff now, address warnings soon, consider suggestions later.

## Usage

```
/review                  # Review uncommitted changes (git diff)
/review [file]           # Review a specific file
/review [dir]            # Review all files in a directory
/review pr [number]      # Review a GitHub pull request
/review pr [url]         # Review a PR by URL
/review --security-only  # Only run the security layer
```

## Execution Strategy

### Phase 1: Context Load (blocking)

```
Action: mcp__memory__read_graph
Purpose: Understand project context, tech stack, known security concerns,
         previous review findings, and coding standards
Extract:
  - Tech stack and framework (affects which checks apply)
  - Known vulnerabilities or security notes
  - Coding standards or patterns established for this project
  - Previous review findings (to check for regression)
```

### Phase 2: Gather Code to Review

#### Diff Mode (`/review`)

```bash
# Get both staged and unstaged changes
git diff HEAD
git diff --name-only HEAD
```

If no changes, check for staged changes:
```bash
git diff --cached
```

If still nothing, report "No changes to review."

#### File Mode (`/review [file]`)

Read the entire file. Also get the recent diff for that file if available:

```bash
git log -5 --format="%h %s" -- <file>
git diff HEAD~5..HEAD -- <file>
```

#### Directory Mode (`/review [dir]`)

```bash
# Get all source files (skip generated/vendor)
find <dir> -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" -o -name "*.py" -o -name "*.go" -o -name "*.rs" \) \
  -not -path "*/node_modules/*" -not -path "*/.next/*" -not -path "*/dist/*"
```

Read each file. Prioritize recently modified files.

#### PR Mode (`/review pr [number]`)

```
Action: mcp__github__get_pull_request (number)
Action: mcp__github__get_pull_request_files (number)
```

Or via CLI:
```bash
gh pr view <number> --json title,body,additions,deletions,changedFiles
gh pr diff <number>
```

### Phase 3: Multi-Layer Review (sequential — each layer informs the next)

#### Layer 1: Security (OWASP-informed)

This layer runs FIRST and is non-negotiable. Check for:

**Injection Flaws**
- SQL injection: Raw SQL queries with string concatenation/interpolation
- NoSQL injection: Unsanitized MongoDB queries
- XSS: Unescaped user input rendered in HTML/JSX (`dangerouslySetInnerHTML`, `v-html`)
- Command injection: User input passed to `exec`, `spawn`, `system`
- Template injection: User input in template strings sent to engines
- Path traversal: User input in file paths without sanitization

**Authentication and Session**
- Hardcoded credentials, API keys, tokens, passwords
- Missing authentication on API routes
- Weak password requirements
- Session fixation vulnerabilities
- JWT issues: no expiry, weak signing, secrets in code

**Authorization**
- Missing authorization checks (authenticated != authorized)
- IDOR: Object references without ownership verification
- Privilege escalation: Role checks that can be bypassed
- Missing CORS configuration or overly permissive CORS

**Data Exposure**
- Sensitive data in logs (passwords, tokens, PII)
- Sensitive data in error messages returned to client
- Missing rate limiting on sensitive endpoints
- Exposed stack traces in production error handling
- Secrets in client-side code or bundles

**Dependencies**
- Known vulnerable packages (check versions against CVE databases)
- Packages with suspicious permissions or install scripts
- Outdated dependencies with known security patches

**Crypto**
- Weak hashing (MD5, SHA1 for passwords)
- Hardcoded IVs or salts
- Custom crypto implementations (always flag)
- Insecure random number generation for security contexts

#### Layer 2: Bugs and Correctness

- **Null/undefined**: Missing null checks, optional chaining where needed
- **Type errors**: TypeScript `any` overuse, type assertions hiding bugs
- **Race conditions**: Async operations without proper coordination
- **Resource leaks**: Unclosed connections, streams, file handles
- **Error handling**: Swallowed errors, missing catch blocks, generic catches
- **Edge cases**: Empty arrays, zero values, empty strings, boundary conditions
- **Logic errors**: Off-by-one, inverted conditions, unreachable code
- **State management**: Stale closures, missing dependency arrays in hooks
- **Async issues**: Missing await, unhandled promise rejections, async in loops

#### Layer 3: Performance

- **N+1 queries**: Database calls inside loops
- **Missing indexes**: Queries on unindexed fields (if schema is available)
- **Large payloads**: Fetching more data than needed, missing pagination
- **Unnecessary re-renders**: Missing React.memo, unstable references in deps
- **Blocking operations**: Sync file I/O, CPU-heavy work on main thread
- **Memory leaks**: Growing arrays, missing cleanup in useEffect, event listener accumulation
- **Bundle size**: Large imports that could be tree-shaken or lazy-loaded
- **Caching**: Missing cache headers, repeated identical API calls

#### Layer 4: Patterns and Quality

- **Consistency**: Does the code follow the project's established patterns?
- **DRY violations**: Duplicated logic that should be extracted
- **Naming**: Unclear variable/function names, misleading names
- **Complexity**: Functions over 50 lines, deeply nested conditionals
- **Dead code**: Unused imports, unreachable branches, commented-out code
- **TODOs**: Unaddressed TODO/FIXME/HACK comments
- **Testing**: Missing tests for critical paths, untested error cases
- **Documentation**: Public APIs without JSDoc/docstrings, complex logic without comments

### Phase 4: Synthesize Findings

Categorize every finding into exactly one severity level:

| Severity | Meaning | Action |
|----------|---------|--------|
| CRITICAL | Security vulnerability, data loss risk, or crash-inducing bug | Must fix before merge/deploy |
| WARNING | Bug, performance issue, or code that will cause problems | Should fix soon |
| SUGGESTION | Improvement that would make code better | Consider for future |
| INFO | Observation, not necessarily a problem | Awareness only |

### Phase 5: Output Report

```
## Code Review — [Project/PR] — [Date]

### Summary
- Files reviewed: N
- Lines changed: +X / -Y
- Findings: N critical, N warnings, N suggestions

### Critical Issues

#### [CRITICAL] SQL Injection in user search endpoint
**File:** `src/api/users.ts:42`
**Code:**
\`\`\`typescript
const users = await db.query(`SELECT * FROM users WHERE name = '${req.query.name}'`);
\`\`\`
**Risk:** Attacker can execute arbitrary SQL via the `name` parameter.
**Fix:**
\`\`\`typescript
const users = await db.query('SELECT * FROM users WHERE name = $1', [req.query.name]);
\`\`\`

---

### Warnings

#### [WARNING] Missing error boundary around async operation
**File:** `src/components/Dashboard.tsx:88`
**Issue:** Promise rejection in `fetchData` will crash the component tree.
**Fix:** Wrap in try/catch or add an Error Boundary component.

---

### Suggestions

#### [SUGGESTION] Extract repeated validation logic
**Files:** `src/api/users.ts:15`, `src/api/teams.ts:22`
**Issue:** Email validation is duplicated in two routes.
**Fix:** Create a shared `validateEmail` utility.

---

### What Looks Good
- [Positive observation — always include at least one]
- [Acknowledge good patterns, clean code, thorough error handling]

### Review Metadata
- Reviewed by: Claude (automated)
- Review depth: Full (Security + Bugs + Performance + Patterns)
- Time: ~Xs
```

### Phase 6: Memory Update

```
Action: mcp__memory__add_observations
Purpose: Record review findings, especially security issues and patterns.
Data:
  - Project name and scope reviewed
  - Count of findings by severity
  - Any critical issues (brief description)
  - Patterns noticed (positive and negative)
```

## PR Review Mode Specifics

When reviewing a pull request, also check:

- **PR description**: Does it explain what and why?
- **Scope**: Is the PR doing too many things? Should it be split?
- **Breaking changes**: Are they documented?
- **Migration**: Does the PR include necessary migrations?
- **Rollback**: Can this be safely reverted if needed?

After review, offer to post the review as a GitHub PR review:

```
Action: mcp__github__create_pull_request_review
Parameters:
  - Pull request number
  - Review body (the formatted findings)
  - Event: COMMENT (findings only) or REQUEST_CHANGES (if critical issues)
```

## Security-Only Mode

When `--security-only` is specified, run only Layer 1 but in extra depth:

- Check all files, not just changed ones
- Cross-reference with OWASP Top 10 explicitly
- Check dependency versions against known CVE databases
- Verify security headers in middleware/server config
- Check for common misconfigurations (debug mode, verbose errors, open CORS)

## Cross-Skill Chaining

- Critical security finding -> immediate `/sync` to fix and commit the patch
- Build/test failures in review -> `/status --build` to verify
- PR review completed -> developer merges -> `/deploy` to ship
- Patterns/quality issues -> `/scaffold` to generate missing tests or utilities
- New codebase being reviewed -> `/setup` first for full context

## Notes

- Always find something positive to say. Reviews that are purely negative are demoralizing and less effective.
- Be specific. "This is bad" is not useful. "This allows SQL injection because..." is useful.
- Provide fix examples, not just problem descriptions. The goal is to help, not just criticize.
- Calibrate severity honestly. Not everything is critical. Overusing CRITICAL dilutes its meaning.
- For PR reviews, focus on the diff. Do not review unchanged code unless it is directly affected.
- When in doubt about severity, ask: "Could this cause a security breach, data loss, or outage?" If yes, it is CRITICAL. If no, it is WARNING or below.

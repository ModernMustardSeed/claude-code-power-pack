---
name: security
description: Comprehensive security audit — dependency vulnerabilities, exposed secrets, .gitignore coverage, auth/authz review, and OWASP Top 10 checklist with prioritized findings.
---

# Security Audit Skill

## Trigger

Activated by `/security` or when the user asks for a security review, vulnerability check, or audit.

## Modes

| Command | Behavior |
|---------|----------|
| `/security` | Full security audit (all checks) |
| `/security secrets` | Scan for exposed secrets and credentials only |
| `/security deps` | Dependency vulnerability audit only |
| `/security auth` | Authentication and authorization review only |
| `/security owasp` | OWASP Top 10 focused review |
| `/security [file or dir]` | Targeted audit on specific code |

## Execution Strategy

### Phase 1 — Scan (parallel)

Run all of these simultaneously for a comprehensive first pass:

**1. Dependency Vulnerabilities**
- Node.js: `npm audit` or `yarn audit` or `pnpm audit`
- Python: `pip audit` or check `safety` if available; otherwise scan `requirements.txt` against known CVE databases
- Go: `go vuln check` if available
- Parse output for Critical and High severity items.
- Check for outdated major versions: `npm outdated` / `pip list --outdated`

**2. Exposed Secrets and Credentials**
Grep the codebase for patterns that indicate leaked secrets:
```
# API keys and tokens
pattern: (api[_-]?key|api[_-]?secret|access[_-]?token|auth[_-]?token)\s*[:=]\s*['"][^'"]{8,}
# AWS credentials
pattern: (AKIA[0-9A-Z]{16}|aws[_-]?secret)
# Private keys
pattern: -----BEGIN (RSA |EC |DSA )?PRIVATE KEY-----
# Connection strings
pattern: (mongodb|postgres|mysql|redis)://[^\s'"]+
# Generic high-entropy strings assigned to secret-looking variables
pattern: (password|secret|token|key)\s*[:=]\s*['"][A-Za-z0-9+/=]{20,}
```
- Exclude `node_modules/`, `.git/`, `dist/`, `build/`, lock files, and test fixtures.
- Check `.env.example` and `.env.local.example` to ensure they contain only placeholder values.

**3. .gitignore Coverage**
- Verify these are listed in `.gitignore`:
  - `.env`, `.env.local`, `.env.production`, `.env.*` (except examples)
  - `*.pem`, `*.key`, `*.p12`, `*.pfx`
  - `credentials.json`, `service-account.json`, `secrets/`
  - `node_modules/`, `dist/`, `build/`, `.next/`, `__pycache__/`
  - IDE configs (`.vscode/settings.json` with potential secrets, `.idea/`)
- Check `git ls-files` for any tracked files that should be ignored.
- Verify no `.env` file is committed in git history: `git log --all --full-history -- '*.env*'`

**4. Auth/Authz Flow Review**
- Locate authentication code: search for `login`, `signup`, `authenticate`, `jwt`, `session`, `oauth`, `passport`, `nextauth`, `supabase.auth`, `clerk`.
- Check for:
  - Password hashing (bcrypt/scrypt/argon2 — not MD5/SHA1)
  - JWT validation (signature verification, expiry checks, audience validation)
  - Session management (httpOnly cookies, secure flag, SameSite)
  - CSRF protection on state-changing endpoints
  - Rate limiting on auth endpoints
  - Authorization checks on protected routes (not just authentication)
  - Role-based access control consistency

**5. OWASP Top 10 Checklist**

| # | Category | What to Check |
|---|----------|---------------|
| A01 | Broken Access Control | Missing auth middleware on routes, IDOR vulnerabilities, directory traversal |
| A02 | Cryptographic Failures | Weak hashing, plaintext secrets, missing TLS, weak random generation |
| A03 | Injection | SQL injection (raw queries without parameterization), XSS (unescaped user input in HTML), command injection |
| A04 | Insecure Design | Missing rate limits, no account lockout, predictable resource IDs |
| A05 | Security Misconfiguration | Default credentials, verbose error messages in production, unnecessary open ports, CORS set to `*` |
| A06 | Vulnerable Components | Known CVEs in dependencies (from Phase 1 dep audit) |
| A07 | Auth Failures | Weak passwords allowed, missing MFA, session fixation |
| A08 | Data Integrity Failures | Missing integrity checks on CI/CD pipelines, unsigned packages, deserialization of untrusted data |
| A09 | Logging Failures | Missing security event logging, sensitive data in logs, no audit trail |
| A10 | SSRF | User-controlled URLs passed to fetch/axios without validation, internal network exposure |

### Phase 2 — Analyze and Classify

Categorize all findings by severity:

| Severity | Criteria | Examples |
|----------|----------|----------|
| **Critical** | Active exploitation risk, data breach imminent | Exposed production API keys in repo, SQL injection, no auth on admin routes |
| **High** | Significant vulnerability, exploitation plausible | Known CVE with exploit in dependency, weak password hashing, missing CSRF |
| **Medium** | Vulnerability exists but exploitation requires specific conditions | Outdated dependency without known exploit, missing rate limiting, verbose errors |
| **Low** | Best practice violation, minimal direct risk | Missing security headers, .gitignore gaps for non-sensitive files, console.log of non-sensitive data |

### Phase 3 — Report

Present findings in a structured format:

```
Security Audit Report
=====================
Date: YYYY-MM-DD
Scope: [Full project / specific files]

Critical (X findings)
---------------------
1. [Finding title]
   Location: path/to/file.ts:42
   Description: What the vulnerability is.
   Impact: What an attacker could do.
   Remediation: How to fix it, with code example.

High (X findings)
-----------------
[Same format]

Medium (X findings)
-------------------
[Same format]

Low (X findings)
----------------
[Same format]

Summary
-------
- Total findings: X
- Immediate action required: X Critical, X High
- Recommended improvements: X Medium, X Low
```

### Phase 4 — Remediate (if requested)

When the user asks to fix findings:
1. Fix Critical issues first, then High.
2. For each fix, explain what changed and why.
3. Re-run the relevant scan to confirm the fix.
4. Never introduce new functionality during remediation — keep changes minimal and security-focused.

## Framework-Specific Checks

### Next.js / React
- Verify `dangerouslySetInnerHTML` usage is sanitized.
- Check API routes for missing authentication middleware.
- Verify environment variables with `NEXT_PUBLIC_` prefix do not contain secrets.
- Check `next.config.js` for exposed `serverRuntimeConfig` in `publicRuntimeConfig`.

### Express / Node APIs
- Check for `helmet` or equivalent security headers.
- Verify `cors` configuration is not set to `origin: '*'` in production.
- Check for `express-rate-limit` or similar on auth routes.
- Verify `cookie-parser` settings include `httpOnly`, `secure`, `sameSite`.

### Supabase
- Check Row Level Security (RLS) is enabled on all tables.
- Verify policies are not overly permissive (`using (true)` without conditions).
- Check that `service_role` key is never exposed to the client.
- Verify anon key permissions are appropriately scoped.

### Prisma / ORMs
- Check for raw queries that might be vulnerable to injection.
- Verify no `$queryRaw` or `$executeRaw` with string interpolation (should use parameterized queries).

## Memory Integration

- Store audit results in the memory graph with date and severity counts.
- Track remediation progress across sessions.
- Build a project security profile over time (recurring issues, resolved vulnerabilities).

## Cross-Skill Chaining

| Trigger | Chain to |
|---------|----------|
| Vulnerabilities found in code | Chain to `/review` for code-level fixes and refactoring guidance |
| Dependency updates needed | Chain to `/test` to verify nothing breaks after updating |
| Auth issues require schema changes | Chain to `/migrate` for database-level fixes |
| Fixes are ready | Chain to `/pr` to submit security patches |
| Performance impact of security changes | Chain to `/perf` to benchmark |

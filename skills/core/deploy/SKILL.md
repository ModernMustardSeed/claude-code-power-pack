---
name: deploy
description: Pre-flight checks, platform-aware deployment, and post-deploy verification. Supports Vercel, Railway, Netlify, Fly.io, and custom platforms with automatic detection.
---

# Deploy - Safe Deployment Pipeline

## Purpose

Deploy projects safely by running pre-flight checks, detecting the target platform, executing the deployment, verifying it succeeded, and recording the result. This is the "ship it with confidence" skill.

## Usage

```
/deploy                  # Deploy current project to detected platform
/deploy [project]        # Deploy a specific project
/deploy [project] prod   # Deploy to production (extra confirmation required)
/deploy --check-only     # Run pre-flight checks without deploying
```

## Execution Strategy

### Phase 1: Memory and Context Load (blocking)

```
Action: mcp__memory__read_graph
Purpose: Get project context, previous deploy history, known issues, environment details
Extract:
  - Target platform for this project
  - Previous deploy outcomes (success/failure)
  - Known environment variables needed
  - Any deploy-specific notes or warnings
```

### Phase 2: Parallel Pre-Flight Checks

Run ALL of the following simultaneously. ALL must pass before deployment proceeds.

#### 2A: Git Status

```bash
git -C <path> status --porcelain
git -C <path> rev-parse --abbrev-ref HEAD
git -C <path> log -1 --format="%H %s"
git -C <path> diff --stat HEAD..@{upstream} 2>/dev/null
```

**Gate conditions:**
- FAIL if there are uncommitted changes (suggest `/sync` first)
- FAIL if local is behind remote (suggest `git pull` first)
- WARN if not on main/master and deploying to production
- WARN if local is ahead of remote (unpushed commits)

#### 2B: Build Verification

```bash
# Detect and run the build
cd <path>

# Node.js
if [ -f "package.json" ]; then
    npm run build 2>&1
fi

# Rust
if [ -f "Cargo.toml" ]; then
    cargo build --release 2>&1
fi

# Go
if [ -f "go.mod" ]; then
    go build ./... 2>&1
fi

# Python
if [ -f "pyproject.toml" ]; then
    python -m build 2>&1
fi
```

**Gate conditions:**
- FAIL if build fails (show error output)
- WARN if build has warnings

#### 2C: Environment Variable Check

```bash
# Check for required env vars based on platform and project
# Read from .env.example, .env.template, or project config

if [ -f "<path>/.env.example" ]; then
    # Extract variable names from .env.example
    # Check each one exists in current environment or platform config
fi

# Platform-specific env checks
# Vercel: check vercel env ls
# Railway: check railway variables
# Netlify: check netlify env:list
```

**Gate conditions:**
- FAIL if required env vars are missing
- WARN if optional env vars are missing
- INFO list of env vars that will be used

#### 2D: Test Suite (if exists)

```bash
cd <path>

# Detect and run tests
if [ -f "package.json" ]; then
    npm test 2>&1
elif [ -f "Cargo.toml" ]; then
    cargo test 2>&1
elif [ -f "pyproject.toml" ]; then
    python -m pytest 2>&1
fi
```

**Gate conditions:**
- FAIL if tests fail
- WARN if no test suite found
- PASS with test count if all pass

### Phase 3: Pre-Flight Report

Present results before proceeding:

```
## Pre-Flight Check — [Project]

| Check | Status | Details |
|-------|--------|---------|
| Git | PASS | Clean, on main, synced with remote |
| Build | PASS | Built in 45s, no warnings |
| Env Vars | PASS | 12/12 required vars present |
| Tests | PASS | 47 tests passed |

Deploying: [project] -> [platform] ([environment])
Branch: main
Commit: abc1234 "feat: add payment processing"

Proceed with deployment? [Y/n]
```

If ANY check is FAIL, do not offer to proceed. Show what needs fixing.

If `--check-only` was specified, stop here.

### Phase 4: Platform Detection and Deploy

Auto-detect the platform from project configuration:

| File/Directory | Platform |
|----------------|----------|
| `vercel.json` or `.vercel/` | Vercel |
| `railway.json` or `railway.toml` | Railway |
| `netlify.toml` or `.netlify/` | Netlify |
| `fly.toml` | Fly.io |
| `Dockerfile` + no other config | Docker (ask target) |
| `render.yaml` | Render |
| `app.yaml` (GCP) | Google Cloud |

If detection is ambiguous or no config found, ask the developer.

#### Vercel Deployment

```bash
cd <path>

# Preview deploy
npx vercel 2>&1

# Production deploy (only if explicitly requested)
npx vercel --prod 2>&1
```

#### Railway Deployment

```bash
cd <path>
railway up 2>&1
```

#### Netlify Deployment

```bash
cd <path>

# Build and deploy draft
npx netlify deploy --build 2>&1

# Production (only if explicitly requested)
npx netlify deploy --build --prod 2>&1
```

#### Fly.io Deployment

```bash
cd <path>
fly deploy 2>&1
```

**Production deploy safety:**
- If the user said `prod` or `production`, deploy to production
- Otherwise, deploy to preview/staging
- Always confirm before production deploys
- Never deploy to production on Friday afternoons (warn and require double confirmation)

### Phase 5: Post-Deploy Verification

After deployment completes, verify it actually worked:

#### 5A: Platform Status Check

```bash
# Vercel
npx vercel ls --limit 1

# Railway
railway status

# Netlify
npx netlify status

# Fly.io
fly status
```

#### 5B: HTTP Health Check

If a URL is available from the deploy output:

```bash
# Basic health check
curl -s -o /dev/null -w "%{http_code}" <deploy_url>

# Check for common issues
curl -s -o /dev/null -w "%{http_code}" <deploy_url>/api/health
```

Expected: 200 OK. Flag anything else.

#### 5C: Quick Smoke Test

```
Action: mcp__puppeteer__puppeteer_navigate (if available)
URL: <deploy_url>
Check:
  - Page loads without errors
  - No console errors in browser
  - Key elements are visible
```

### Phase 6: Deploy Report

```
## Deploy Report — [Date]

### Summary
- Project: [name]
- Platform: [Vercel/Railway/etc.]
- Environment: [preview/production]
- Branch: main (commit abc1234)
- Duration: 2m 15s
- Status: SUCCESS

### URLs
- Deploy URL: https://project-abc123.vercel.app
- Production URL: https://project.com (if production deploy)

### Verification
| Check | Result |
|-------|--------|
| Platform status | Healthy |
| HTTP 200 | PASS |
| Page loads | PASS |

### Previous Deploy
- Last deploy: 3 days ago
- Last status: SUCCESS
```

### Phase 7: Memory Update

```
Action: mcp__memory__add_observations
Purpose: Record deploy outcome
Data:
  - Project name and platform
  - Commit hash deployed
  - Environment (preview/production)
  - Success/failure
  - Deploy URL
  - Timestamp
  - Any issues encountered
```

## Rollback Support

If post-deploy verification fails:

1. Report the failure clearly
2. Provide the rollback command for the platform:
   - Vercel: `npx vercel rollback`
   - Railway: `railway rollback`
   - Netlify: link to deploy dashboard for instant rollback
   - Fly.io: `fly releases`, `fly deploy --image <previous>`
3. Ask if the developer wants to rollback
4. If yes, execute and verify the rollback
5. Record the rollback in memory

## Cross-Skill Chaining

- Uncommitted changes -> `/sync` first, then retry `/deploy`
- Build failure -> `/review` to analyze the errors
- After successful deploy -> update project status in memory
- Deploy to new platform -> `/setup` to configure the project
- Tests failing -> fix tests before retrying

## Notes

- Deployments are inherently risky. Always err on the side of caution.
- Preview/staging deploys are low risk. Production deploys are high risk. The UX should reflect this.
- Capture and store deploy URLs — they are useful for testing and sharing.
- If deployment takes longer than 5 minutes, check platform status pages for outages.
- Never store deploy tokens or platform credentials in memory or commits.
- If the developer has a CI/CD pipeline, suggest using it instead of direct deploys.

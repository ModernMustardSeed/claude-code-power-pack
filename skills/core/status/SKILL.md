---
name: status
description: Parallel git status sweep across all tracked projects. Reports a summary table with branch, changes, staleness, and remote sync state. Supports default (git), build, and deep modes.
---

# Status - Multi-Project Status Dashboard

## Purpose

Answer "what's the state of everything?" in one command. Sweeps all tracked projects in parallel and presents a single table showing git status, build health, and staleness across the entire workspace.

## Usage

```
/status              # Default: git status only (fast)
/status build        # Git status + verify each project builds
/status deep         # Git + build + dependency audit + remote sync
/status [project]    # Single project, deep mode automatically
```

## Execution Strategy

### Phase 1: Discover Projects (blocking)

Gather the list of projects to check from multiple sources, in priority order:

1. **Memory graph**: Query for all project entities with paths
2. **CLAUDE.md**: Parse the active projects table if memory is unavailable
3. **Filesystem scan**: Fall back to scanning home directory for `.git` directories

```
Action: mcp__memory__read_graph
Extract: All entities of type "project" with their recorded paths
```

Deduplicate paths. Skip any that are clearly not project directories.

### Phase 2: Parallel Git Sweep

For ALL discovered projects simultaneously:

```bash
# Core status (always collected)
git -C <path> rev-parse --abbrev-ref HEAD 2>/dev/null
git -C <path> status --porcelain 2>/dev/null
git -C <path> log -1 --format="%cr|%s" 2>/dev/null
git -C <path> stash list 2>/dev/null | wc -l
```

Parse results into:
- **Branch**: Current branch name
- **Modified**: Count of modified files (`M` in porcelain)
- **Untracked**: Count of untracked files (`??` in porcelain)
- **Staged**: Count of staged files (`A`, `M` in index column)
- **Last Commit**: Relative time and message
- **Stashes**: Count of stashed changes

### Phase 3: Remote Sync Check (default mode includes this)

For each project, also run in parallel:

```bash
# Fetch without modifying anything
git -C <path> fetch --dry-run 2>&1
git -C <path> rev-list --count HEAD..@{upstream} 2>/dev/null  # behind
git -C <path> rev-list --count @{upstream}..HEAD 2>/dev/null  # ahead
```

Parse into:
- **Behind**: Number of commits behind remote
- **Ahead**: Number of commits ahead of remote
- **Tracking**: Whether branch tracks a remote (yes/no)

### Phase 4: Build Check (build and deep modes only)

For each project in parallel:

```bash
# Detect build system and run appropriate check
if [ -f "<path>/package.json" ]; then
    # Check if build script exists
    node -e "const p=require('<path>/package.json'); process.exit(p.scripts?.build ? 0 : 1)"
    # Run build (with timeout)
    cd <path> && npm run build 2>&1 | tail -20
elif [ -f "<path>/Cargo.toml" ]; then
    cd <path> && cargo check 2>&1 | tail -20
elif [ -f "<path>/go.mod" ]; then
    cd <path> && go build ./... 2>&1 | tail -20
elif [ -f "<path>/pyproject.toml" ] || [ -f "<path>/setup.py" ]; then
    cd <path> && python -m py_compile $(find . -name "*.py" -maxdepth 2) 2>&1 | tail -20
fi
```

Timeout: 120 seconds per project. Record pass/fail/timeout/no-build-script.

### Phase 5: Dependency Audit (deep mode only)

For each project in parallel:

```bash
# Node projects
cd <path> && npm audit --json 2>/dev/null | node -e "
  const d=require('fs').readFileSync('/dev/stdin','utf8');
  const j=JSON.parse(d);
  console.log(JSON.stringify({critical:j.metadata?.vulnerabilities?.critical||0,high:j.metadata?.vulnerabilities?.high||0}))
"

# Check for outdated lockfile
git -C <path> diff --name-only HEAD -- package-lock.json yarn.lock pnpm-lock.yaml
```

### Phase 6: Present Results

#### Default Mode Output

```
## Project Status — [Date]

| Project | Branch | Changes | Last Commit | Remote |
|---------|--------|---------|-------------|--------|
| name    | main   | 3M 1U   | 2h ago      | +2/-0  |
| name2   | feat/x | clean   | 3d ago      | +0/-5  |

Legend: M=modified, U=untracked, S=staged, +ahead/-behind

### Alerts
- [project]: 5 commits behind remote — consider pulling
- [project]: Uncommitted changes for 3 days
- [project]: On non-default branch for 2 weeks
- [project]: 4 stashed changes
```

#### Build Mode Output

Adds a Build column:

```
| Project | Branch | Changes | Last Commit | Remote | Build |
|---------|--------|---------|-------------|--------|-------|
| name    | main   | clean   | 2h ago      | synced | PASS  |
| name2   | feat/x | 3M      | 3d ago      | +0/-5  | FAIL  |
```

With build failure details below the table.

#### Deep Mode Output

Adds Build + Deps columns:

```
| Project | Branch | Changes | Remote | Build | Deps |
|---------|--------|---------|--------|-------|------|
| name    | main   | clean   | synced | PASS  | 0C 2H |
| name2   | feat/x | 3M      | +0/-5  | FAIL  | 1C 0H |

Legend: C=critical vulns, H=high vulns
```

### Phase 7: Memory Update

```
Action: mcp__memory__add_observations
Purpose: Record status snapshot — date, per-project summary, any alerts
```

This enables trend tracking ("last 3 status checks show project X consistently dirty").

## Staleness Detection

Flag projects based on last commit age:

| Age | Label | Action |
|-----|-------|--------|
| < 24h | Active | No flag |
| 1-7 days | Recent | No flag |
| 7-30 days | Quiet | Note in report |
| 30-90 days | Stale | Flag as warning |
| 90+ days | Dormant | Flag prominently, suggest archiving |

## Alert Thresholds

These conditions are always flagged, regardless of mode:

- Uncommitted changes older than 48 hours
- Branch behind remote by 5+ commits
- Non-default branch active for 14+ days
- 3+ stashed changes
- Detached HEAD state
- Merge conflicts present (UU in porcelain output)

## Single Project Mode

When invoked with a project name (`/status myproject`), automatically use deep mode and add:

- Full list of changed files (not just counts)
- Recent commit log (last 10 commits)
- Branch list with last activity
- Remote URL and tracking info

## Cross-Skill Chaining

Based on status findings, suggest:

- Dirty projects -> `/sync` or `/sync [project]`
- Build failures -> `/review [project]` to investigate
- Far behind remote -> manual `git pull` (never auto-pull)
- Dormant projects -> `/audit` to check if they should be archived
- No CLAUDE.md detected -> `/setup` to onboard the project

## Notes

- Never modify any project during status checks. This is strictly read-only.
- Use `git fetch --dry-run` to check remote state without actually fetching.
- If a project path does not exist, report it as MISSING, do not error out.
- Keep the table compact. Developers scan, they do not read paragraphs.
- For projects with monorepo structure (workspaces), report the root status only in the table, with a note about workspace count.

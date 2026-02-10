---
name: boot
description: Full session startup - loads memory, checks project health, calendar, email, and GitHub activity in parallel, then presents a compact operational briefing.
---

# Boot - Session Startup Sequence

## Purpose

Initialize a productive session by gathering all relevant context in parallel and presenting a single, actionable briefing. This is the "cold start to fully operational" skill.

## Trigger

Invoke at the start of any session, or when context has gone stale after a long gap.

## Execution Strategy

### Phase 1: Memory Load (blocking)

Load the persistent knowledge graph to understand current state before doing anything else.

```
Action: mcp__memory__read_graph
Purpose: Retrieve all entities, relations, and observations from the knowledge graph.
Extract:
  - Active project list (names, paths, tech stacks)
  - Current priorities and in-progress tasks
  - Known blockers or issues from previous sessions
  - Recent decisions and their rationale
```

If no memory graph exists or it is empty, note this and proceed — the session briefing will flag it as a setup task.

### Phase 2: Parallel Reconnaissance

Run ALL of the following simultaneously. Do not wait for one before starting another.

#### 2A: Project Git Health

For each project path found in the memory graph (or in CLAUDE.md if no graph):

```bash
# For each project directory that exists:
git -C <project_path> status --porcelain
git -C <project_path> log --oneline -3
git -C <project_path> rev-parse --abbrev-ref HEAD
```

Collect:
- Current branch per project
- Uncommitted changes (count of modified/untracked files)
- Last 3 commit messages and how recent they are

#### 2B: Calendar Check

```
Action: mcp__google-workspace__get_events
Parameters: today's date, next 24 hours
Extract:
  - Meetings in the next 4 hours (urgent)
  - All meetings today (awareness)
  - Any scheduling conflicts
```

If Google Workspace MCP is unavailable, skip gracefully and note it.

#### 2C: Email Triage

```
Action: mcp__google-workspace__get_messages
Parameters: unread, last 24 hours
Extract:
  - Count of unread emails
  - Any flagged/starred messages
  - Emails from known contacts or containing project keywords
```

If unavailable, skip gracefully and note it.

#### 2D: GitHub Activity

```
Action: mcp__github__list_issues (per active repo, state=open)
Action: mcp__github__list_pull_requests (per active repo, state=open)
Extract:
  - Open PRs needing review
  - Issues assigned to user
  - Any failed CI checks on recent PRs
```

If GitHub MCP is unavailable, fall back to `gh` CLI if available.

### Phase 3: Synthesis and Briefing

Compile all results into a compact briefing using this format:

```
## Session Briefing — [Date, Time]

### Priorities
- [Top priority from memory graph]
- [Second priority]
- [Any new urgent items detected]

### Projects
| Project | Branch | Status | Last Commit |
|---------|--------|--------|-------------|
| name    | branch | clean/dirty (N files) | relative time |

### Attention Needed
- [Uncommitted work older than 24h]
- [Open PRs with failing checks]
- [Stale branches]
- [Meetings in next 4 hours]

### Quick Stats
- Unread emails: N (K flagged)
- Open PRs: N across M repos
- Open issues assigned: N

### Suggested First Action
[Based on priorities, urgency, and current state — suggest what to do first]
```

### Phase 4: Memory Update

```
Action: mcp__memory__add_observations
Purpose: Record session start time and any new findings (e.g., discovered stale branches, new issues)
```

## Flags and Alerts

Automatically flag these as unusual and call them out prominently:

- Any project with uncommitted changes older than 48 hours
- Projects where local branch is behind remote by 5+ commits
- Open PRs older than 7 days with no activity
- Calendar conflicts in the next 4 hours
- Emails from unknown senders containing keywords: "urgent", "invoice", "payment", "deadline"
- Memory graph entities with no observations (zombie nodes)

## Graceful Degradation

Not all MCPs may be available. The skill should work with whatever is accessible:

| Available | Behavior |
|-----------|----------|
| Memory only | Load context, skip external checks, note limitations |
| Memory + Git | Full project status, skip calendar/email |
| Memory + Git + GitHub | Full dev briefing, skip personal calendar/email |
| Everything | Complete operational briefing |

Always tell the user what was checked and what was skipped.

## Cross-Skill Chaining

After boot completes, suggest relevant follow-ups based on findings:

- Uncommitted changes detected -> suggest `/sync`
- Stale memory or missing projects -> suggest `/audit`
- PR needs review -> suggest `/review pr [num]`
- Project missing CLAUDE.md -> suggest `/setup` or `/scaffold`
- Build issues mentioned in memory -> suggest `/status --build`

## Notes

- Keep the briefing compact. Developers want signal, not noise.
- Use relative times ("2 hours ago", "yesterday") not absolute timestamps.
- If everything is clean and there are no alerts, say so clearly — that is valuable information.
- Never fabricate data. If a check fails, report the failure, not a guess.

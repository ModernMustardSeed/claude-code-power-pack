---
name: briefing
description: Daily briefing combining calendar, email, git activity, and GitHub notifications into a scannable summary
---

# Daily Briefing Skill

## Purpose

Generate a comprehensive daily briefing by pulling from calendar, email, git repositories, and GitHub notifications in parallel, then compiling into a scannable bullet-point format.

## Trigger

User asks for a briefing, morning update, daily summary, or "what's on my plate today."

## Execution Strategy

### Phase 0: Memory Load (Sequential)

1. **Read the knowledge graph** to get context on active projects, priorities, and recent activity:
   ```
   Use mcp__memory__read_graph to load full context
   ```
2. **Identify active project paths** from memory entities of type "Project"
3. **Note any flagged priorities** or deadlines from previous sessions

### Phase 1: Data Gathering (Parallel)

Run ALL of these simultaneously:

- **Calendar** — Fetch today's events (and tomorrow's if after 3pm):
  ```
  Use mcp__google-workspace__get_events with today's date range
  ```
- **Email** — Get recent unread/important messages:
  ```
  Use mcp__google-workspace__search_gmail_messages with query "is:unread" or "is:important newer_than:1d"
  ```
- **Git Status** — For each active project directory, run:
  ```bash
  git -C /path/to/project log --oneline --since="yesterday" --all 2>/dev/null
  git -C /path/to/project status --short 2>/dev/null
  ```
- **GitHub Notifications** — Check for PR reviews, issues, mentions:
  ```bash
  gh api notifications --jq '.[].subject | {title, type, url}' 2>/dev/null
  ```
- **GitHub PRs** — Check open PRs across repos:
  ```bash
  gh pr list --state open --json title,url,updatedAt --limit 10 2>/dev/null
  ```

### Phase 2: Email Detail Fetch (Parallel, Conditional)

For any emails flagged as important or action-required in Phase 1:

- **Fetch message content** for top 5 most relevant:
  ```
  Use mcp__google-workspace__get_gmail_message_content for each message ID
  ```

### Phase 3: Compile Briefing (Sequential)

Assemble all data into the output format below. Apply these rules:

1. **Prioritize** — Put time-sensitive items first
2. **Flag blockers** — Anything preventing progress on active priorities
3. **Surface patterns** — Note if multiple emails/notifications relate to the same project
4. **Suggest actions** — Add a recommended next action for each section

### Phase 4: Memory Update (Sequential)

Store briefing context:
```
Use mcp__memory__add_observations to update relevant project entities with today's status
```

## Output Format

```markdown
# Daily Briefing — [Day, Month Date, Year]

## Schedule
- **[Time]** — [Event name] ([Location/Link])
- **[Time]** — [Event name] ([Location/Link])
- [No meetings today / X meetings, Y hours blocked]

## Email Highlights
- **[Sender]** — [Subject]: [1-line summary + action needed]
- **[Sender]** — [Subject]: [1-line summary + action needed]
- [X unread, Y need response]

## Project Pulse

| Project | Last Commit | Open PRs | Status |
|---------|------------|----------|--------|
| [Name] | [Time ago] — [Message] | [Count] | [Active/Stale/Blocked] |
| [Name] | [Time ago] — [Message] | [Count] | [Active/Stale/Blocked] |

## GitHub Activity
- [PR/Issue title] — [Action needed: review, respond, merge]
- [PR/Issue title] — [Action needed: review, respond, merge]

## Priorities for Today
1. **[Priority]** — [Why now + suggested first step]
2. **[Priority]** — [Why now + suggested first step]
3. **[Priority]** — [Why now + suggested first step]

## Heads Up
- [Anything upcoming: deadlines, meetings tomorrow, expiring trials, etc.]
```

## Cross-Skill Chaining

- **To research:** If briefing surfaces a question or unknown, suggest triggering the research skill
- **To social:** If schedule includes content deadlines, chain to social skill for drafting
- **To leads:** If emails contain inbound leads, chain to leads skill for qualification
- **From memory:** Briefing always starts by loading the knowledge graph for context

## Customization

Users can configure briefing scope in their project CLAUDE.md:

```markdown
## Briefing Config
- projects: [list of project paths to monitor]
- email_filter: "is:unread" or custom Gmail query
- calendar_lookahead: 1 (days)
- include_github: true
- quiet_hours: 22:00-07:00
```

## Error Handling

- If a service is unavailable (no Google Workspace MCP, no gh CLI), skip that section and note it
- If a project directory doesn't exist, skip it and flag as "Project path not found"
- If no events/emails/commits are found, say so explicitly rather than omitting the section
- Always produce output even if some data sources fail

## Quality Checklist

- [ ] All time-sensitive items surfaced first
- [ ] Each email highlight includes the action needed (reply, read, ignore)
- [ ] Project pulse covers all configured projects
- [ ] Priorities are specific and actionable (not vague)
- [ ] Output is scannable in under 60 seconds

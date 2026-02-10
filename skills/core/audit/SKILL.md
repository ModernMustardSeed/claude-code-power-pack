---
name: audit
description: Self-healing system audit - verifies project directories, validates memory graph, cross-references topic files, checks CLAUDE.md configs, auto-fixes issues, and outputs a health report card with letter grade.
---

# Audit - Self-Healing System Scan

## Purpose

Detect and repair drift between the actual filesystem, the memory graph, project configurations, and topic files. Produce a graded health report card so the developer knows exactly where things stand.

## Trigger

Run periodically (weekly recommended), after major changes, or when something feels "off" — memory seems stale, projects are missing, or configurations have diverged.

## Execution Strategy

### Phase 1: Memory Load (blocking)

```
Action: mcp__memory__read_graph
Purpose: Get the full knowledge graph as the baseline for all validation checks.
Extract:
  - All project entities (names, paths, tech stacks, statuses)
  - Relations between entities
  - Observations with timestamps
  - Any entities marked as archived or deprecated
```

### Phase 2: Parallel Validation Sweeps

Run ALL of the following simultaneously.

#### 2A: Filesystem Verification

For every project path recorded in the memory graph:

```bash
# Check directory exists
test -d "<project_path>" && echo "EXISTS" || echo "MISSING"

# If exists, check for key files
test -f "<project_path>/package.json" && echo "HAS_PACKAGE_JSON"
test -f "<project_path>/CLAUDE.md" && echo "HAS_CLAUDE_MD"
test -d "<project_path>/.git" && echo "HAS_GIT"
```

Record:
- PASS: Directory exists with expected structure
- WARN: Directory exists but missing expected files
- FAIL: Directory does not exist at recorded path

Also scan for projects on the filesystem that are NOT in the memory graph:

```bash
# Look for directories with .git that aren't tracked
# Check common project locations: ~/, ~/projects/, ~/repos/
```

#### 2B: Memory Graph Integrity

Validate the knowledge graph itself:

- **Orphan entities**: Entities with no relations to anything else
- **Stale observations**: Observations older than 30 days with no updates
- **Broken relations**: Relations pointing to entities that no longer exist
- **Duplicate entities**: Multiple entities referring to the same project/concept
- **Empty entities**: Entities with a name but zero observations
- **Contradictions**: Observations that conflict with each other (e.g., "uses React" and "uses Vue" on the same project)

#### 2C: Topic File Cross-Reference

If a topic files directory exists (e.g., `templates/topic-files/` or similar):

```
For each topic file:
  - Verify the project/topic it describes still exists
  - Check if the content matches current memory graph state
  - Flag files that reference deleted or renamed projects
  - Flag topics in memory that have no corresponding file
```

#### 2D: Per-Project CLAUDE.md Validation

For each project that has a CLAUDE.md:

```
Read the CLAUDE.md and verify:
  - Project name matches memory graph
  - Tech stack description matches what package.json shows
  - Listed scripts/commands actually work
  - Referenced file paths actually exist
  - No secrets or credentials accidentally included
  - No references to people/orgs that should not be in an open-source context
```

### Phase 3: Auto-Fix (with confirmation)

For each issue found, categorize as auto-fixable or requires-human:

#### Auto-Fix (safe to do without asking):

- **Remove orphan entities** from memory graph (no relations, no observations)
- **Update stale timestamps** on observations that are verified still accurate
- **Delete broken relations** pointing to nonexistent entities
- **Deduplicate entities** (merge observations into the canonical one)

#### Requires Confirmation:

- Removing a project entity whose directory no longer exists
- Updating a CLAUDE.md to match current state
- Adding newly discovered projects to the memory graph
- Resolving contradictory observations

Present fixes in a clear list and ask before executing destructive changes.

### Phase 4: Health Report Card

Generate a structured report:

```
## System Health Report — [Date]

### Overall Grade: [A/B/C/D/F]

### Category Scores

| Category | Score | Issues |
|----------|-------|--------|
| Filesystem Integrity | A/B/C/D/F | N issues |
| Memory Graph Health  | A/B/C/D/F | N issues |
| Topic File Sync      | A/B/C/D/F | N issues |
| Project Configs      | A/B/C/D/F | N issues |

### Grading Rubric
- A: No issues found
- B: Minor issues only (cosmetic, stale data)
- C: Some issues that should be addressed soon
- D: Significant issues affecting reliability
- F: Critical issues — data loss risk or major drift

### Issues Found

#### Critical (fix now)
- [issue description + auto-fix applied or action needed]

#### Warnings (fix soon)
- [issue description + recommendation]

#### Info (awareness only)
- [observation that is not a problem but worth noting]

### Auto-Fixes Applied
- [list of changes made automatically]

### Recommended Actions
1. [Most important manual fix needed]
2. [Second most important]
3. [etc.]

### Stats
- Projects tracked: N
- Projects verified: N
- Memory entities: N
- Memory relations: N
- Observations: N (oldest: date, newest: date)
```

### Phase 5: Memory Update

```
Action: mcp__memory__add_observations
Purpose: Record audit results — date, grade, issues found, fixes applied
Entity: "system-health" or equivalent
```

## Grading Algorithm

Calculate the overall grade as a weighted average:

| Category | Weight |
|----------|--------|
| Filesystem Integrity | 30% |
| Memory Graph Health | 30% |
| Topic File Sync | 15% |
| Project Configs | 25% |

Per category, score 0-100:
- Start at 100
- Critical issue: -25 each
- Warning: -10 each
- Info: -2 each

Map to letter: A >= 90, B >= 80, C >= 70, D >= 60, F < 60

## Cross-Skill Chaining

Based on audit findings, suggest:

- Missing CLAUDE.md in a project -> `/setup` to generate one
- Uncommitted changes found -> `/sync` to commit safely
- New project discovered on filesystem -> `/scaffold` to initialize properly
- Stale project not touched in 30+ days -> Ask if it should be archived
- Memory graph was mostly empty -> `/boot` to repopulate from current state

## Notes

- Never delete data without confirmation. The auto-fix scope is limited to clearly safe operations.
- If the memory graph is completely empty, treat this as a first-run scenario and offer to populate it.
- Report should be scannable in under 30 seconds. Use tables and bullet points, not paragraphs.
- Track audit history in memory so you can report trends ("Grade improved from C to B since last audit").

---
name: debug
description: Systematic debugging workflow — reproduce, isolate, hypothesize, fix, verify, and document. Uses sequential-thinking for complex bugs and checks known patterns first.
---

# Debug Skill

## Trigger

Activated by `/debug` or when the user reports a bug, error, or unexpected behavior.

## Modes

| Command | Behavior |
|---------|----------|
| `/debug` | Start interactive debugging from the user's description |
| `/debug [error message]` | Start from a specific error message |
| `/debug [file:line]` | Start investigation at a specific location |
| `/debug known` | List all known patterns from debugging.md |

## Execution Strategy

### Phase 0 — Check Known Patterns (first, before anything else)

1. Search for a `debugging.md`, `DEBUGGING.md`, or `docs/debugging.md` file in the project root.
2. If it exists, read it and compare the reported symptom against documented patterns.
3. If a match is found, present the known solution immediately and ask the user if it resolves the issue before doing deeper investigation.
4. Also query the memory graph for previously encountered bugs with similar symptoms.

### Phase 1 — Reproduce (parallel)

Gather all available context simultaneously:

1. Get the exact error message, stack trace, or description from the user.
2. `git log --oneline -10` — check recent changes that may have introduced the bug.
3. `git diff HEAD~3 --stat` — what files changed recently.
4. Read the file(s) mentioned in the stack trace or error.
5. Check for related log files, error outputs, or crash reports.
6. Identify the reproduction steps — ask the user if unclear.

Goal: Confirm the bug is reproducible and understand exactly what happens vs. what should happen.

### Phase 2 — Isolate

Narrow the problem to the smallest possible scope:

1. **Trace the call chain.** Start from the error location and walk backward through the call stack. Read each file in the chain.
2. **Check inputs.** What data flows into the failing function? Log the arguments if possible.
3. **Check recent changes.** Use `git log -p --follow <file>` on the affected file to see what changed recently. Use `git bisect` mentally (or actually) to identify the breaking commit.
4. **Eliminate variables.** Determine if the bug is:
   - Data-dependent (specific input triggers it)
   - Environment-dependent (works locally, fails in CI/prod)
   - Timing-dependent (race condition, async issue)
   - State-dependent (only after certain user actions)
5. **Narrow to a single function or expression** if possible.

### Phase 3 — Hypothesize

Form and rank hypotheses about the root cause:

1. List 2-5 possible causes based on the evidence gathered.
2. Rank them by likelihood.
3. For each hypothesis, identify what evidence would confirm or refute it.
4. **For complex bugs** (multiple interacting systems, race conditions, non-obvious causes), use the `sequential-thinking` MCP tool to work through the reasoning step by step. This prevents jumping to conclusions on subtle issues.
5. Test the most likely hypothesis first.

When to use sequential-thinking:
- The bug involves multiple services or files interacting
- The stack trace does not directly point to the root cause
- Initial investigation produced contradictory evidence
- The bug is intermittent or timing-dependent
- State management or caching may be involved

### Phase 4 — Fix

1. Implement the fix for the confirmed root cause.
2. Keep the fix minimal and focused. Do not refactor unrelated code.
3. Add a code comment if the fix is non-obvious, explaining **why** this change is needed.
4. If the fix involves a workaround rather than a proper solution, note this clearly and explain what the proper fix would look like.
5. Handle edge cases revealed during investigation.

### Phase 5 — Verify

1. Run the specific test(s) related to the fixed code. If none exist, write one that would have caught this bug.
2. Run the broader test suite to check for regressions.
3. If the bug was reported with specific reproduction steps, walk through those steps to confirm the fix.
4. Check that the fix does not introduce new type errors, lint warnings, or build failures.

### Phase 6 — Document

1. If the bug represents a new pattern (likely to recur or affect other developers), add it to `debugging.md`:
   ```markdown
   ## [Short description of the bug]
   **Symptom:** What the user sees or what the error message says.
   **Root cause:** Why it happens.
   **Solution:** How to fix it.
   **Files involved:** List of relevant files.
   **Date discovered:** YYYY-MM-DD
   ```
2. If `debugging.md` does not exist and the pattern is significant, suggest creating one.
3. Update the memory graph with the bug pattern for future reference.

## Debugging Techniques Reference

### Common Patterns to Check

| Pattern | What to look for |
|---------|-----------------|
| Off-by-one | Array bounds, loop conditions, pagination offsets |
| Null/undefined | Missing optional chaining, uninitialized state, API returning null |
| Async ordering | Missing await, race conditions, stale closures |
| Import errors | Circular dependencies, wrong path, missing extension |
| Type mismatch | String vs number, date formats, JSON parse issues |
| Environment | Missing env vars, wrong API URLs, CORS, different Node versions |
| Caching | Stale data, build cache, CDN cache, memoization with wrong deps |
| State mutation | Direct array/object mutation in React, shared references |

### Reading Stack Traces

1. Start from the **bottom** of the stack trace (the originating call).
2. Focus on frames that reference **project code** (not node_modules or framework internals).
3. The first project-code frame is usually where the bug manifests, but the root cause may be higher up.
4. For async stack traces, look for `async` boundaries where context may be lost.

### Binary Search Debugging

When the cause is unclear:
1. Add a log/breakpoint at the midpoint of the suspected code path.
2. Determine if the bug occurs before or after that point.
3. Repeat, halving the search space each time.
4. Remove all debug logs after finding the cause.

## Memory Integration

- Before investigating, query the memory graph for this project's known issues and past debugging sessions.
- After resolving, store the bug pattern (symptom, cause, fix) in the memory graph.
- Track recurring bugs to identify systemic issues that need architectural fixes.

## Cross-Skill Chaining

| Trigger | Chain to |
|---------|----------|
| Fix is ready and verified | Chain to `/test write` to add a regression test |
| Fix is ready for review | Chain to `/pr` to open a pull request |
| Bug is in a dependency | Chain to `/security` to check for known vulnerabilities |
| Bug is performance-related | Chain to `/perf` for deeper analysis |
| Bug involved a database issue | Chain to `/migrate` if schema changes are needed |

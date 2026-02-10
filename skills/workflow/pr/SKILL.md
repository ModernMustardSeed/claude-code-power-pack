---
name: pr
description: Full pull request workflow — branch creation, conventional commits, push, and PR opening via gh CLI with auto-generated title, body, and linked issues.
---

# PR Workflow Skill

## Trigger

Activated by `/pr` or when the user asks to create a pull request, open a PR, or submit changes for review.

## Modes

| Command | Behavior |
|---------|----------|
| `/pr` | Full workflow: branch, commit, push, open PR |
| `/pr commit` | Stage and commit only (no push/PR) |
| `/pr push` | Push current branch with `-u` and open PR |
| `/pr draft` | Open PR as draft |
| `/pr [issue-number]` | Link PR to a specific GitHub issue |

## Execution Strategy

### Phase 1 — Assess (parallel)

Run all of these simultaneously to understand the current state:

1. `git status` — check working tree for staged/unstaged/untracked changes
2. `git branch --show-current` — get current branch name
3. `git log --oneline -5` — recent commit style for message consistency
4. `git remote -v` — confirm remote is set
5. `git diff --stat` — summary of what changed
6. Check for a `.github/PULL_REQUEST_TEMPLATE.md` — use it if present

### Phase 2 — Branch

- If on `main` or `master`, create a new branch before any commits.
- Branch naming convention derived from the change type:
  - `feat/<short-description>` — new features
  - `fix/<short-description>` — bug fixes
  - `chore/<short-description>` — maintenance, deps, config
  - `docs/<short-description>` — documentation only
  - `refactor/<short-description>` — code restructuring
  - `test/<short-description>` — adding or fixing tests
- Use lowercase kebab-case for the description segment.
- Command: `git checkout -b <branch-name>`

### Phase 3 — Commit

- Stage changes selectively by file name. Never use `git add -A` or `git add .` unless the user explicitly requests it. Review untracked files and skip anything that looks like secrets, env files, or build artifacts.
- Write a conventional commit message:
  - Format: `type(scope): description`
  - Types: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `perf`, `ci`
  - Scope is optional but preferred (e.g., `feat(auth): add OAuth2 flow`)
  - Body should explain **why**, not **what**
  - Footer: reference issues with `Closes #123` or `Refs #456`
- Use a HEREDOC to pass the message:
  ```bash
  git commit -m "$(cat <<'EOF'
  feat(auth): add OAuth2 login flow

  Users needed social login to reduce signup friction.
  This adds Google and GitHub OAuth2 providers.

  Closes #42
  EOF
  )"
  ```

### Phase 4 — Push

- Push with upstream tracking: `git push -u origin <branch-name>`
- **SAFETY: Never push directly to `main` or `master`.** If the current branch is main/master, abort and warn the user.
- If push is rejected, pull with rebase first: `git pull --rebase origin <branch-name>`

### Phase 5 — Open PR

- Use `gh pr create` with structured title and body.
- Auto-generate the title from the branch name or most recent commit.
- Auto-generate the body with:
  - **Summary** — 1-3 bullet points describing the changes
  - **Test plan** — checklist of how to verify
  - **Linked issues** — reference any mentioned issue numbers
- Format:
  ```bash
  gh pr create --title "feat(auth): add OAuth2 login flow" --body "$(cat <<'EOF'
  ## Summary
  - Added Google and GitHub OAuth2 providers
  - New callback routes handle token exchange
  - Session persistence via httpOnly cookies

  ## Test plan
  - [ ] Sign in with Google OAuth
  - [ ] Sign in with GitHub OAuth
  - [ ] Verify session persists across page reload
  - [ ] Verify logout clears session

  Closes #42
  EOF
  )"
  ```
- If `/pr draft` was used, add `--draft` flag.
- If a PR template exists, incorporate its structure into the body.

### Phase 6 — Report

- Output the PR URL so the user can click through.
- Summarize: branch name, commit count, files changed, PR status (draft/ready).

## Safety Rules

1. **Never push to main/master.** Always create a feature branch first.
2. **Never force push** unless the user explicitly requests it.
3. **Never skip hooks** (no `--no-verify`) unless the user explicitly requests it.
4. **Never stage secrets.** Skip `.env`, credentials, API keys, and similar files. Warn the user if they are in the changeset.
5. **Never amend commits** unless explicitly requested. If a pre-commit hook fails, fix the issue and create a new commit.
6. **Ask before destructive actions** — branch deletion, force push, reset.

## Memory Integration

- After opening a PR, store the PR number, branch name, and linked issues in the memory graph so subsequent sessions can reference them.
- Query memory for recent PRs when the user asks about open work or status.

## Cross-Skill Chaining

| Trigger | Chain to |
|---------|----------|
| Tests should pass before PR | Run `/test` before Phase 4 (push) |
| User requests review context | Run `/review` skill on the diff |
| Security-sensitive changes detected | Suggest `/security` audit before merge |
| Changes include DB migrations | Note and suggest `/migrate` verification |

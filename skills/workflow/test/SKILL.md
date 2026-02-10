---
name: test
description: Auto-detect test framework, run tests, report results, generate missing test coverage, and produce coverage reports.
---

# Test Skill

## Trigger

Activated by `/test` or when the user asks to run tests, write tests, or check coverage.

## Modes

| Command | Behavior |
|---------|----------|
| `/test` | Run the full test suite |
| `/test [file or pattern]` | Run tests for a specific file or glob |
| `/test write` | Generate missing tests for recent changes |
| `/test write [file]` | Generate tests for a specific source file |
| `/test coverage` | Run tests with coverage and report results |
| `/test failing` | Re-run only previously failing tests |

## Execution Strategy

### Phase 1 — Detect (parallel)

Run all of these simultaneously to identify the test stack:

1. Check `package.json` for test scripts and devDependencies:
   - `jest`, `@jest/core` — Jest
   - `vitest` — Vitest
   - `playwright`, `@playwright/test` — Playwright
   - `cypress` — Cypress
   - `mocha` — Mocha
   - `pytest` in `requirements.txt` or `pyproject.toml` — pytest
   - `go test` patterns in Go files — Go testing
2. Look for config files: `jest.config.*`, `vitest.config.*`, `playwright.config.*`, `cypress.config.*`, `pytest.ini`, `pyproject.toml`, `.mocharc.*`
3. Scan for existing test directories: `__tests__/`, `tests/`, `test/`, `spec/`, `e2e/`, `*.test.*`, `*.spec.*`
4. Check for CI test commands in `.github/workflows/*.yml` or similar CI configs
5. `git diff --name-only HEAD~3` — identify recently changed files that may need tests

### Phase 2 — Run

Based on the detected framework, execute the appropriate command:

| Framework | Run All | Run Specific | Coverage |
|-----------|---------|-------------|----------|
| Jest | `npx jest` | `npx jest <path>` | `npx jest --coverage` |
| Vitest | `npx vitest run` | `npx vitest run <path>` | `npx vitest run --coverage` |
| Playwright | `npx playwright test` | `npx playwright test <path>` | N/A (use report) |
| Cypress | `npx cypress run` | `npx cypress run --spec <path>` | N/A |
| pytest | `python -m pytest` | `python -m pytest <path>` | `python -m pytest --cov` |
| Go | `go test ./...` | `go test <package>` | `go test -cover ./...` |

- Prefer the project's own test script (`npm test`, `yarn test`) if it exists and wraps the framework.
- Respect any existing configuration (custom test roots, transform settings, etc.).
- Set a reasonable timeout (5 minutes for unit tests, 10 minutes for e2e).

### Phase 3 — Report

Parse the test output and present a structured report:

```
Test Results
============
Framework: Vitest
Total:     84
Passed:    81
Failed:    2
Skipped:   1
Duration:  3.2s

Failures:
1. src/utils/format.test.ts > formatCurrency > handles negative values
   Expected: "-$5.00"
   Received: "$-5.00"

2. src/api/auth.test.ts > login > rejects expired tokens
   Error: Timeout after 5000ms
```

- For failures, include the test name, expected vs. received, and the file path.
- For coverage mode, include a summary table of coverage percentages by directory.

### Phase 4 — Write Missing Tests (when `/test write` is used)

1. Identify source files that lack corresponding test files.
2. For recently changed files (from git diff), prioritize generating tests for those.
3. When writing tests:
   - Match the project's existing test style (describe/it vs. test, assertion library, etc.)
   - Import the actual module under test
   - Cover: happy path, edge cases, error handling, boundary values
   - Use descriptive test names that explain the expected behavior
   - Mock external dependencies (API calls, database, file system)
   - Place test files according to project convention (co-located vs. `__tests__/` directory)
4. Run the generated tests to verify they pass.
5. If a test fails, fix it before presenting to the user.

### Phase 5 — Coverage Analysis (when `/test coverage` is used)

1. Run tests with coverage enabled.
2. Parse the coverage output and present:
   - Overall coverage percentage (statements, branches, functions, lines)
   - Files with lowest coverage, sorted by percentage
   - Uncovered lines for critical files
3. Suggest specific areas that need tests, prioritized by:
   - Business logic with zero coverage
   - Recently changed code without tests
   - Error handling paths
   - Edge cases in utility functions

## Framework-Specific Notes

### Jest
- Check for `moduleNameMapper` and `transform` settings that affect imports.
- Respect `testPathIgnorePatterns` and `coveragePathIgnorePatterns`.
- Use `--forceExit` if tests hang due to open handles.

### Vitest
- Check for workspace configurations in monorepos.
- Supports in-source testing via `if (import.meta.vitest)` blocks.

### Playwright
- Tests may need a dev server running. Check `webServer` config in `playwright.config.ts`.
- Use `--reporter=list` for parseable output.

### pytest
- Check for `conftest.py` fixtures that tests depend on.
- Use `-v` for verbose output with individual test results.

## Memory Integration

- Store test results (pass/fail counts, failing test names) in memory after each run so trends can be tracked across sessions.
- When writing tests, query memory for previously identified testing patterns or project-specific conventions.

## Cross-Skill Chaining

| Trigger | Chain to |
|---------|----------|
| All tests pass, user wants to ship | Chain to `/pr` to open a pull request |
| Test failure points to a bug | Chain to `/debug` for systematic investigation |
| Coverage report shows gaps in auth code | Suggest `/security` audit on uncovered paths |
| Tests reveal performance regression | Suggest `/perf` audit |

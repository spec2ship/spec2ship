---
description: Run integration tests on s2s plugin. Tests session validation (VAL-RT-*), resume capability (RES-*) and edge cases (EDGE-*).
allowed-tools: Bash(pwd:*), Bash(ls:*), Bash(mkdir:*), Bash(rm:*), Read, Write, Glob, Task
argument-hint: [--validate] [--resume] [--edge] [--all] [--session <path>] [--cleanup]
---

# Development Test

> **NOT SHIPPED**: This command is excluded from the published plugin.
>
> **Note**: `--validate` works on any s2s project (validates session files).
> `--resume` and `--edge` require the spec2ship repository (synthetic fixtures).

## Context

- Current directory: !`pwd`
- Directory contents: !`ls -la`

## Interpret Context

Based on the context output above, determine:

- **Is s2s repo**: If `commands/` and `agents/` and `.claude-plugin/` appear → "yes"
- **Is s2s project**: If `.s2s/` directory appears → "yes"

---

## Instructions

### Parse Arguments

Extract from $ARGUMENTS:
- **--validate**: Run VAL-RT-* checks on a session file
- **--resume**: Run RES-* tests only
- **--edge**: Run EDGE-* tests only
- **--all** (default if no flag): Run all tests (VAL-RT-* + RES-* + EDGE-*)
- **--session**: Session file path (required for --validate)
- **--cleanup**: Remove test artifacts after run

Determine categories to run:

| Flag | Categories |
|------|------------|
| --validate | ["VAL-RT"] |
| --resume | ["RES"] |
| --edge | ["EDGE"] |
| --all (or none) | ["VAL-RT", "RES", "EDGE"] |

**Note**: If --validate or --all, and --session not provided, auto-detect most recent session:
```bash
ls -t .s2s/sessions/*.yaml 2>/dev/null | head -1
```

**Security**: Validate session path before use:
- Must be under `.s2s/sessions/`
- Must end with `.yaml`
- Must exist as a file
- Reject paths with `;`, `|`, `$`, backticks

### Validate Context

**IF** categories include RES or EDGE (synthetic fixture tests):

  **IF** NOT s2s repo:

      Error: --resume and --edge tests require the spec2ship repository.
      These tests create synthetic fixtures and are for plugin development only.

      For session validation on any s2s project, use: /s2s:dev:test --validate

**ELSE** (only VAL-RT):

  **IF** NOT s2s project (no .s2s/ directory):

      Error: Not an s2s project. No .s2s/ directory found.
      Initialize with /s2s:init first.

### Display Header

    S2S Development Test
    ═══════════════════════════════════════

    Mode: {validate | resume | edge | all}
    Categories: {list}
    Session: {session_path or "N/A"}
    Cleanup: {yes | no}

    Setting up test environment...

---

## Test Architecture

| Category | Target | Where it runs | Purpose |
|----------|--------|---------------|---------|
| VAL-RT-* | `.s2s/sessions/*.yaml` | Any s2s project | Validate REAL session files |
| RES-* | `.s2s-test/sessions/` | s2s repo only | Test resume with SYNTHETIC fixtures |
| EDGE-* | `.s2s-test/sessions/` | s2s repo only | Test edge cases with SYNTHETIC fixtures |

**Key distinction**:
- `--validate` operates on **real** sessions in any s2s project
- `--resume` and `--edge` create **synthetic** fixtures in `.s2s-test/` (s2s repo only)

---

## Setup Test Environment

**IF** categories include RES or EDGE (need synthetic fixtures):

**YOU MUST use Bash tool NOW** to create test directory:

```bash
mkdir -p .s2s-test/sessions
```

Display: "Test environment ready: .s2s-test/"

**ELSE** (only VAL-RT):

Display: "Validating existing sessions (no test fixtures needed)"

---

## Invoke dev-validator Agent

**Use the dev-validator agent** with this input:

```yaml
mode: "test"
categories:
  - "VAL-RT"  # Include if --validate or --all
  - "RES"     # Include if --resume or --all
  - "EDGE"    # Include if --edge or --all
test_dir: ".s2s-test"              # Only used by RES-*, EDGE-*
session_path: "{session_path}"     # Required for VAL-RT-*, from --session or auto-detect
```

**WAIT** for the agent to complete and return results.

---

## Display Results

Based on dev-validator agent response:

    TEST RESULTS
    ═══════════════════════════════════════

    {FOR each category in results}

    {category} ({category_name}):
    ───────────────────────────────────────
    {FOR each test in category}
    {status_icon} {test}: {name}
       {IF evidence}
       Evidence: {evidence_summary}
       {/IF}
       {IF notes}
       Notes: {notes}
       {/IF}
    {/FOR}

    {/FOR}

    Summary
    ───────────────────────────────────────
    Total:    {total}
    Passed:   {passed}
    Failed:   {failed}
    Warnings: {warnings}
    Skipped:  {skipped}

    {IF critical_findings}
    Critical Findings
    ───────────────────────────────────────
    {FOR each finding}
    ✗ {finding}
    {/FOR}
    {/IF}

    {IF recommendations}
    Recommendations
    ───────────────────────────────────────
    {FOR each recommendation}
    → {recommendation}
    {/FOR}
    {/IF}

    ─────────────────────────────────────
    RESULT: {PASS | WARN | FAIL}

### Status Icons

| Status | Icon |
|--------|------|
| pass | ✓ |
| fail | ✗ |
| warn | ⚠ |
| skip | ○ |

---

## Cleanup

**IF** .s2s-test was created (RES or EDGE tests ran):

  **IF** --cleanup was specified:

  **YOU MUST use Bash tool NOW**:

  ```bash
  rm -rf .s2s-test
  ```

  Display: "Test artifacts cleaned up."

  **ELSE**:

  Display: "Test artifacts preserved in .s2s-test/ (use --cleanup to remove)"

**ELSE** (only VAL-RT ran):

Display: "No test artifacts to clean (validation only)"

---

## Reference

Test definitions: `skills/dev-testing/references/`
- `check-registry.md` - Master list
- `roundtable-tests.md` - VAL-RT-*, RES-RT-*, EDGE-RT-* test cases
- `res-checks.md` - RES-* definitions
- `edge-scenarios.md` - EDGE-* scenarios

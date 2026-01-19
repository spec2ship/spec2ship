---
description: Run integration tests on s2s plugin. Tests resume capability (RES-*) and edge cases (EDGE-*).
allowed-tools: Bash(pwd:*), Bash(ls:*), Bash(mkdir:*), Bash(rm:*), Read, Write, Glob, Task
argument-hint: [--resume] [--edge] [--all] [--cleanup]
---

# Development Test

> **NOT SHIPPED**: This command is for s2s contributors only.
> It is excluded from the published plugin.

## Context

- Current directory: !`pwd`
- Directory contents: !`ls -la`

## Interpret Context

Based on the context output above, determine:

- **Is s2s repo**: If `commands/` and `agents/` and `.claude-plugin/` appear → "yes"

If NOT s2s repo:

    Error: This command must be run from the spec2ship repository root.
    It is a development tool, not for end users.

---

## Instructions

### Parse Arguments

Extract from $ARGUMENTS:
- **--resume**: Run RES-* tests only
- **--edge**: Run EDGE-* tests only
- **--all** (default if no flag): Run all tests (RES-* + EDGE-*)
- **--cleanup**: Remove test artifacts after run

Determine categories to run:

| Flag | Categories |
|------|------------|
| --resume | ["RES"] |
| --edge | ["EDGE"] |
| --all (or none) | ["RES", "EDGE"] |

### Display Header

    S2S Development Test
    ═══════════════════════════════════════

    Mode: {resume | edge | all}
    Categories: {list}
    Cleanup: {yes | no}

    Setting up test environment...

---

## Setup Test Environment

**YOU MUST use Bash tool NOW** to create test directory:

```bash
mkdir -p .s2s-test/sessions
```

Display: "Test environment ready: .s2s-test/"

---

## Invoke dev-validator Agent

**Use the dev-validator agent** with this input:

```yaml
mode: "test"
categories:
  - "RES"     # Include if --resume or --all
  - "EDGE"    # Include if --edge or --all
test_dir: ".s2s-test"
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

**IF** --cleanup was specified:

**YOU MUST use Bash tool NOW**:

```bash
rm -rf .s2s-test
```

Display: "Test artifacts cleaned up."

**ELSE**:

Display: "Test artifacts preserved in .s2s-test/ (use --cleanup to remove)"

---

## Reference

Test definitions: `skills/dev-testing/references/`
- `check-registry.md` - Master list
- `res-checks.md` - RES-* definitions
- `edge-scenarios.md` - EDGE-* scenarios

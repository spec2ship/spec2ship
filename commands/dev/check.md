---
description: Run development checks on s2s plugin code. Verifies instruction quality (INST-*) and cross-command consistency (CONS-*).
allowed-tools: Bash(pwd:*), Bash(ls:*), Read, Glob, Grep, Task
argument-hint: [--instructions] [--consistency] [--all]
---

# Development Check

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
- **--instructions**: Run INST-* checks only
- **--consistency**: Run CONS-* checks only
- **--all** (default if no flag): Run all checks (INST-* + CONS-*)

Determine categories to run:

| Flag | Categories |
|------|------------|
| --instructions | ["INST"] |
| --consistency | ["CONS"] |
| --all (or none) | ["INST", "CONS"] |

### Display Header

    S2S Development Check
    ═══════════════════════════════════════

    Mode: {instructions | consistency | all}
    Categories: {list}
    Target: commands/, agents/

    Loading check definitions...

---

## Invoke dev-validator Agent

**Use the dev-validator agent** with this input:

```yaml
mode: "check"
categories:
  - "INST"    # Include if --instructions or --all
  - "CONS"    # Include if --consistency or --all
```

**WAIT** for the agent to complete and return results.

---

## Display Results

Based on dev-validator agent response:

    CHECK RESULTS
    ═══════════════════════════════════════

    {FOR each category in results}

    {category} ({category_name}):
    ───────────────────────────────────────
    {FOR each check in category}
    {status_icon} {check}: {name}
       {IF issues}
       {FOR each issue}
         → {file}:{line} - {issue}
       {/FOR}
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

### Result Determination

| Condition | Result |
|-----------|--------|
| All checks passed | PASS |
| No failures but warnings | WARN |
| At least one failure | FAIL |

---

## Reference

Check definitions: `skills/dev-testing/references/`
- `check-registry.md` - Master list
- `inst-checks.md` - INST-* definitions
- `cons-checks.md` - CONS-* definitions

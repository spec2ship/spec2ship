---
name: dev-testing
description: "This skill should be used when developing or maintaining s2s plugin code. Provides check definitions for instruction quality, consistency, resume capability, and edge cases. NOT SHIPPED with plugin."
version: 0.1.0
---

# Development Testing Skill

> **NOT SHIPPED**: This skill is for s2s contributors only.

This skill provides check and test definitions for validating s2s plugin code quality. It is used by the `dev-validator` agent.

## Purpose

Centralized definitions for all development checks and tests:
- **INST-***: Instruction quality (commands/agents follow patterns)
- **CONS-***: Consistency across commands
- **RES-***: Resume capability verification
- **EDGE-***: Edge case scenarios

## When to Use

This skill is automatically loaded when:
- Running `/s2s:dev:check`
- Running `/s2s:dev:test`
- Asking about "development checks", "plugin validation", "test s2s code"

## Check Categories

| Category | Purpose | Count | Severity Range |
|----------|---------|-------|----------------|
| INST-* | Instruction quality | 11 | medium-critical |
| CONS-* | Cross-command consistency | 7 | medium-high |
| RES-* | Resume capability | 7 | high-critical |
| EDGE-* | Edge case handling | 7 | medium-high |

Total: **32 checks**

## References

| File | Content |
|------|---------|
| `check-registry.md` | Master list of all checks with metadata |
| `inst-checks.md` | INST-* check definitions |
| `cons-checks.md` | CONS-* check definitions |
| `res-checks.md` | RES-* check definitions |
| `edge-scenarios.md` | EDGE-* scenario definitions |
| `roundtable-tests.md` | Test baseline for TECH-002 refactoring |
| `extension-guide.md` | How to add new checks (templates included) |
| `dogfood-e2e.md` | End-of-cycle dogfood procedure: fixture rules, runbook template, piloted-tmux driving mechanics, verification sources (TECH-014) |

## Integration

```
/s2s:dev:check
    └── dev-validator agent
            └── reads from this skill's references/

/s2s:dev:test
    └── dev-validator agent
            └── reads from this skill's references/
```

## Adding New Checks

**Read `extension-guide.md`** for complete instructions with templates.

Quick overview:
1. Choose category (INST/CONS/RES/EDGE)
2. Add entry to `check-registry.md`
3. Add full definition using template from `extension-guide.md`
4. Update count in this file
5. Test with `/s2s:dev:check --all` or `/s2s:dev:test --all`

# ADR-0012: Output generation as unified skill with references

**Status**: accepted
**Date**: 2026-01-21
**Context**: TECH-002 Phase 1

## Context

Workflow commands (specs.md, design.md, brainstorm.md) each contained ~100-150 lines of inline output generation logic. This created:
- Duplication of common patterns (merge mode, CONTEXT.md update)
- Difficulty maintaining format templates
- Large command files (~1600+ lines each)

As part of TECH-002 (roundtable command unification), we needed to extract and centralize output generation.

## Decision

Create a single `output-generation` skill with format-specific references:

```
skills/output-generation/
  ├── SKILL.md                   # Common logic (~200 words)
  │   ├── Format dispatch
  │   ├── Merge vs override
  │   ├── CONTEXT.md update
  │   └── Output summary
  └── references/
      ├── specs-srs.md           # SRS pseudo-code
      ├── design-arc42.md        # Architecture + ADR pseudo-code
      └── brainstorm.md          # Summary + ideas pseudo-code
```

## Options Considered

### Option A: Three separate skills
```
skills/output-specs/SKILL.md
skills/output-design/SKILL.md
skills/output-brainstorm/SKILL.md
```
- Pros: Clear separation
- Cons: Duplicated common logic, 3 trigger descriptions, inconsistent

### Option B: One skill with references (CHOSEN)
- Pros: DRY common logic, single entry point, follows roundtable-strategies pattern
- Cons: Two-level indirection (SKILL.md → reference)

### Option C: Use templates/ with placeholders
- Pros: Consistent with existing templates
- Cons: Output needs pseudo-code logic, not simple placeholder replacement

### Option D: Embedded in roundtable-execution
- Pros: Everything in one place
- Cons: Makes roundtable-execution too large, violates single responsibility

## Rationale

1. **Pattern consistency**: Follows same structure as `roundtable-strategies` (SKILL.md + references/)
2. **Token efficiency**: Claude loads ~400 words vs ~800 words inline
3. **Extensibility**: New formats added as reference files without touching SKILL.md
4. **Maintainability**: Common logic in one place, format logic isolated

## Key insight: Templates vs pseudo-code

Files in `templates/` use simple placeholders (`{project-name}`) for Read → Replace → Write pattern.

Output generation uses **pseudo-code** with dynamic logic:
- Loops: `{for each ID, artifact in artifacts.requirements...}`
- Conditionals: `{IF merge mode}`
- Complex operations: ID assignment, filtering

This is Read → Interpret → Generate, not template substitution.

## Consequences

### Positive
- Commands reduced by ~100-140 lines each
- Single source of truth for output formats
- Easy to add new formats (e.g., specs-srs-lite, design-c4)
- Consistent with existing skill patterns

### Negative
- One additional hop (command → SKILL.md → reference)
- Requires understanding of skill + reference pattern

## Implementation

Commands reference:
```markdown
Read the file at `${CLAUDE_PLUGIN_ROOT}/skills/output-generation/SKILL.md`
and follow the instructions for workflow_type="{type}"
```

SKILL.md dispatches to correct reference based on workflow_type.

## Related

- ADR-0005: Skills progressive disclosure
- ADR-0011: Roundtable command unification
- TECH-002: Roundtable command unification (backlog)

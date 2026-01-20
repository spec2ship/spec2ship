# ADR-0011: Roundtable command unification

**Status**: proposed
**Date**: 2026-01-20
**Deciders**: s2s development team

## Context

The roundtable workflow is implemented in multiple commands with significant code duplication:

| Command | Lines | Purpose |
|---------|-------|---------|
| specs.md | ~1740 | Requirements gathering |
| design.md | ~1628 | Architecture design |
| brainstorm.md | ~1625 | Creative ideation |
| roundtable.md | ~366 | Generic roundtable |

### Current problems

1. **Paradox**: Commands declare `skills: roundtable-execution` and say "Follow skill EXACTLY", but implement everything inline (and better than the skill)

2. **Skill is incomplete**: roundtable-execution (803 lines) lacks:
   - Resume capability (agent_id tracking, Task resume)
   - Validation step (2.6b)
   - Diagnostic step (2.6c, 3.0)

3. **Commands diverge**: While structurally similar, specs/design/brainstorm have:
   - Different artifact types (REQ/BR vs ARCH/COMP vs IDEA/RISK)
   - Different output formats (SRS vs architecture+ADR vs ideas.md)
   - Different prerequisites (CONTEXT.md vs requirements.md)
   - Slightly different facilitator prompts

4. **Token waste**: ~800 tokens for skill that's largely ignored

5. **roundtable.md is underpowered**: Relies on skill but skill is incomplete

### Analyzed components

| Component | Lines/cmd | Extractable | Method | Token savings |
|-----------|-----------|-------------|--------|---------------|
| Resume | ~150 | Partial | Document pattern | Low |
| Validation (2.6b) | ~40 | Yes | session-qa agent | Medium |
| Diagnostic (2.6c, 3.0) | ~80 | Already done | session-observer agent | N/A |
| Output generation | ~150-200 | Yes | Skill per workflow | High |
| Artifact schemas | ~100 | Partial | Reference file | Medium |
| Facilitator prompts | ~200 | Difficult | Workflow-specific | N/A |

## Decision

Adopt a **hybrid approach**:

1. **Commands remain authoritative** for execution
2. **roundtable-execution becomes reference library** (not execution guide)
3. **Output generation extracted** to on-demand skills
4. **Validation uses session-qa agent**
5. **Progressive unification** in phases

### Architecture target

```
specs.md / design.md / brainstorm.md (~600-800 lines)
├── Prerequisite check (workflow-specific)
├── Configuration + parameters
├── Shared execution structure (Phase 2)
└── Reference to output skill (Phase 3)

roundtable.md (~400-500 lines)
├── Generic roundtable
└── Same execution structure

SKILLS (loaded on-demand via Read):
├── roundtable-core/ - Overview only (slim)
├── output-specs/ - SRS pseudo-code
├── output-design/ - Architecture + ADR pseudo-code
└── output-brainstorm/ - Ideas.md pseudo-code

AGENTS (called via Task when flags present):
├── session-qa - Validation
└── session-observer - Diagnostic
```

### Implementation phases

**Phase 0: Test baseline**
- Location: `skills/dev-testing/references/roundtable-tests.md`
- Create acceptance criteria for each command
- Document expected behavior
- Prerequisite for all other phases

**Phase 1: Output extraction** (linked to IDEA-010)
- Create `skills/output-specs/`, `output-design/`, `output-brainstorm/`
- Commands read skill via `Read` tool (not frontmatter)
- ~450 lines removed from commands

**Phase 2: Validation consolidation**
- Verify session-qa can do Step 2.6b checks
- Commands call `Task(session-qa)` instead of inline
- ~120 lines simplified

**Phase 3: Phase 2 uniformization**
- Map all differences between commands
- Eliminate accidental divergences
- Parameterize necessary differences

**Phase 4: roundtable.md alignment**
- Add missing features to roundtable.md
- Verify `--workflow-type` produces correct output
- Simplify workflow commands to wrappers

**Phase 5: Skill cleanup** (linked to DEBT-001)
- Decide skill role: documentation vs execution
- Slim to overview + references
- Target: under 2000 words

### Priority matrix

| Phase | Impact | Risk | Order |
|-------|--------|------|-------|
| 0 | - | - | Required first |
| 5 | Low | Low | 1st (unblocks DEBT-001) |
| 1 | High | Medium | 2nd |
| 2 | Medium | Medium | 3rd |
| 3 | High | Medium | 4th |
| 4 | Medium | High | Last |

## Consequences

### Positive

- Reduced code duplication (~40% fewer lines in commands)
- Single source of truth for execution logic
- Easier maintenance (change once, affects all)
- roundtable.md gains full capabilities
- Clear separation: commands = what, skills = reference

### Negative

- Refactoring risk (must not break current behavior)
- Requires comprehensive test suite first
- Phased approach means temporary inconsistency

### Risks

| Risk | Mitigation |
|------|------------|
| Breaking existing commands | Phase 0 test suite |
| Token regression | Measure before/after each phase |
| Incomplete extraction | Small incremental changes |

## Related

- **IDEA-008**: Reduce code duplication in workflow commands (this ADR promotes it)
- **IDEA-010**: Unified export command (Phase 1 prepares for this)
- **DEBT-001**: Reduce roundtable-execution word count (Phase 5)
- **TEST-003**: Session resilience verification (Phase 0 extends this)

## Notes

This analysis was performed by comparing:
- `skills/roundtable-execution/SKILL.md` (803 lines)
- `commands/specs.md` (1740 lines)
- `commands/design.md` (1628 lines)
- `commands/brainstorm.md` (1625 lines)
- `commands/roundtable.md` (366 lines)

Key finding: Commands have MORE features than the skill they claim to follow.

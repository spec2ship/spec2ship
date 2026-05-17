# ADR-0011: Roundtable command unification

**Status**: accepted (2026-05-17 — after Phase 7B regression replay passed)
**Date**: 2026-01-20 (proposed); 2026-05-17 (accepted)
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

---

## Phase 7B addendum (2026-05-17)

Phase 7B "deep extraction" landed on branch `feature/TECH-002-phase7b-deep-extraction`. The original ADR proposed a "Core Inline + Skill Reference" hybrid; Phase 7B realized it concretely via the **executable-skill-reference pattern**:

### Pattern: executable skill reference

A command Reads a skill reference document (`skills/X/references/Y.md`) and follows its step-by-step instructions, with workflow-specific values supplied by a profile YAML loaded into conversation context as `PROFILE`. The skill reference doc is **profile-aware** (uses `{{profile.X}}` placeholders + `IF profile.X == "..."` conditional sections) so a single document executes correctly across multiple workflows.

For TECH-002 Phase 7B, this was applied to Phase 2 Round Execution Loop:
- Single source: `skills/roundtable-execution/references/phase-2-core.md` (executable, ~870 lines).
- Profile YAMLs: `skills/roundtable-execution/profiles/{specs,design,brainstorm}.yaml`.
- Caller pattern: ~28-line invocation in each command (load profile → set runtime context → Read+follow phase-2-core.md).
- Sub-references: `artifact-schemas/{type}.md` (12 files), `disney-phase-machine.md`, `strategy-hooks.md`.

### Line count impact (vs original ADR analysis)

| File | Original (Jan 2026) | After Phase 6 | After Phase 7B (this) | After Phase 8 (target) |
|------|---------------------|----------------|------------------------|------------------------|
| specs.md | 1740 | 1727 | **600** (-1127) | ~150 |
| design.md | 1628 | 1607 | **536** (-1071) | ~150 |
| brainstorm.md | 1625 | 1575 | **482** (-1093) | ~150 |
| roundtable.md | 366 | 437 | 437 (unchanged; Phase 4) | ~600 (master) |
| SKILL.md | 803 | 1002 | **178** (-824) | ~178 (unchanged in Phase 8) |
| phase-2-core.md | n/a | n/a (descriptive only) | **871** (new executable) | unchanged |
| Total commands+SKILL | 6162 | 6348 | 2233 (-65%) | ~1228 |

### Decisions resolved by Phase 7B

- **Extraction contract** (`phase-2-core.md` §3 + plan `Appendix C`): profile-load + read+follow pattern with named runtime variables in caller scope. Validated via 7B.3.5 feasibility prototype on Step 2.1.
- **FIX-S1 (BUG-013)**: persist session-observer output to `rounds/{NNN}-04-session-observer.yaml`. Anchors LLM commitment to Step 2.6c. Verified across all 3 workflows in 7B.7.
- **Strategy hooks contract** (`strategy-hooks.md`): inventory of strategy-specific variations (debate_role, debate_phase for debate; phase machine for disney; hat_role/hat_phase deferred for six-hats). Hooks are additive; wiring deferred to Phase 7.
- **SKILL.md role**: thin overview pointing to phase-2-core.md as authoritative execution source. Phase 1 (init) and Phase 3 (close) remain inline in each command — out of scope for 7B; thin-launcher conversion deferred to Phase 8.

### Regression coverage

Phase 7B introduced regression tests via dogfood: `.s2s/test-baselines/exp43-*` (pre-7B baselines) and `.s2s/test-baselines/exp44-*-post-phase7b.md` (post-7B verification). All 3 workflows verified for schema invariants. Side-effect noted: post-FIX-S1 sessions tend to run 0-2 more rounds than baselines (observer "Continue" feedback extends sessions); classified as non-regression.

### Remaining phases

Phase 7 (strategy skill consolidation), Phase 4 (roundtable.md as master), Phase 8 (thin launchers) remain. Until those land, do not release v0.4.0 → main: the architectural promise of TECH-002 is only ~⅔ delivered by 7B.

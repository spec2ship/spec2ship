# Spec2Ship Backlog

**Updated**: 2026-01-20
**Format**: Work items for active development

---

## ID conventions

| Prefix | Category | Example |
|--------|----------|---------|
| FEAT | Features | FEAT-001 |
| BUG | Bug fixes | BUG-001 |
| TECH | Technical tasks | TECH-001 |
| DEBT | Technical debt | DEBT-001 |

**Status values**: `planned` | `in_progress` | `blocked` | `completed`

> **Note**: Ideas and proposals are in `ideas.md`. Requirements are in `requirements.md`.

---

## In progress

### QUAL-001: Development tools suite (/s2s:dev:*)

**Status**: in_progress | **Created**: 2026-01-11 | **Updated**: 2026-01-19

**Context**: S2S development requires consistent adherence to patterns and ability to test resume/resilience. Development tools are in the plugin but excluded from release.

**Structure**:
```
skills/dev-testing/          # Check definitions
agents/dev/dev-validator.md  # Unified agent
commands/dev/check.md        # /s2s:dev:check
commands/dev/test.md         # /s2s:dev:test
```

**Check categories**:
- INST-* (10): Instruction quality
- CONS-* (7): Consistency between commands
- RES-* (7): Resume capability
- EDGE-* (7): Edge cases

**Tasks**:
- [x] Create dev-testing skill with check definitions
- [x] Create dev-validator agent
- [x] Create check.md and test.md commands
- [x] Document in s2s-development.md
- [ ] Add release exclusion in .github/
- [ ] Implement actual check logic in dev-validator

**Acceptance criteria**:
- [ ] `/s2s:dev:check` runs INST-* and CONS-* checks
- [ ] `/s2s:dev:test` runs RES-* and EDGE-* tests
- [ ] Tools NOT included in shipped plugin

---

### TEST-003: Session resilience verification

**Status**: in_progress | **Created**: 2026-01-18 | **Updated**: 2026-01-20 | **Linked to**: TECH-002 Phase 0

**Context**: Roundtable sessions can be interrupted at various points. Need verification that resume works correctly.

**Note**: This task is foundational for TECH-002. Test cases created here become the baseline for validating refactoring does not cause regression.

**Tasks**:
- [ ] Align roundtable.md resume logic with inline commands
- [ ] Add TRANS-* checks to session-qa (state transitions)
- [ ] Add CTX-* checks to session-qa (context propagation)
- [ ] Enhance error-handling.md with mid-write recovery
- [ ] Run manual end-to-end resume tests
- [ ] Create `skills/dev-testing/references/roundtable-tests.md` (for TECH-002)

**Acceptance criteria**:
- [ ] Resume works from all 7 critical interruption points
- [ ] STR-*, TRANS-*, CTX-* checks in session-qa
- [ ] Baseline tests documented for TECH-002

---

## Planned

### FEAT-001: Decision propagation (workspace)

**Status**: planned | **Created**: 2026-01-17 | **Depends on**: REQ-051

**Context**: Workspace-level decisions should propagate to affected components as backlog items.

**Tasks**:
- [ ] Add `affects: [components]` field to ADR template
- [ ] Session close suggests creating component backlog items
- [ ] Backlog items reference originating workspace decision
- [ ] workspace.yaml tracks propagation status

**Acceptance criteria**:
- [ ] Decisions with `affects` trigger propagation prompt
- [ ] Component backlog items reference workspace ADR

---

### FEAT-002: Dependency graph (workspace)

**Status**: planned | **Created**: 2026-01-17 | **Depends on**: REQ-052

**Context**: Auto-detect and maintain component dependencies in workspaces.

**Tasks**:
- [ ] Scan imports during init to detect dependencies
- [ ] Update workspace.yaml with depends_on
- [ ] `/s2s:init --update-deps` command
- [ ] Plan command considers dependency order

**Acceptance criteria**:
- [ ] Dependencies auto-detected during init
- [ ] Plan considers dependency order

---

### TECH-001: Plan command ADR integration

**Status**: planned | **Created**: 2026-01-16 | **Updated**: 2026-01-19

**Context**: The `/s2s:plan` command should read decisions/ to inform plan generation.

**Tasks**:
- [ ] plan.md reads .s2s/decisions/*.md
- [ ] ADRs influence task breakdown
- [ ] Reference relevant ADRs in plan output

**Acceptance criteria**:
- [ ] Plan considers decisions/ content
- [ ] Previous phases inform plan tasks

---

### TECH-002: Roundtable command unification

**Status**: planned | **Created**: 2026-01-20 | **Origin**: IDEA-008
**ADR**: [0011-roundtable-command-unification](decisions/0011-roundtable-command-unification.md)

**Context**: specs.md, design.md, brainstorm.md have ~60% code duplication (~1600+ lines each). They claim to follow `roundtable-execution` skill but implement everything inline (and better). roundtable.md is underpowered in comparison.

**Goal**: Unify execution logic, reduce duplication, align roundtable.md capabilities.

**Phases**:

| Phase | Description | Depends on | Links to |
|-------|-------------|------------|----------|
| 0 | Test baseline | - | TEST-003 |
| 1 | Output extraction | Phase 0 | IDEA-010 |
| 2 | Validation in agent | Phase 0 | session-qa |
| 3 | Phase 2 uniformization | Phase 1, 2 | - |
| 4 | roundtable.md alignment | Phase 3 | - |
| 5 | Skill cleanup | Phase 0 | DEBT-001 |

**Phase 0: Test baseline**
- [ ] Create `skills/dev-testing/references/roundtable-tests.md` with test cases
- [ ] Document acceptance criteria for specs, design, brainstorm, roundtable
- [ ] Run baseline tests and document current behavior

**Phase 1: Output extraction** (~450 lines saved)
- [ ] Create `skills/output-specs/SKILL.md` with SRS pseudo-code
- [ ] Create `skills/output-design/SKILL.md` with architecture + ADR pseudo-code
- [ ] Create `skills/output-brainstorm/SKILL.md` with ideas.md pseudo-code
- [ ] Modify commands to `Read` skill instead of inline
- [ ] Test: output identical to current

**Phase 2: Validation consolidation** (~120 lines simplified)
- [ ] Verify session-qa can perform Step 2.6b checks
- [ ] Modify commands to call `Task(session-qa)` for validation
- [ ] Remove inline validation from commands
- [ ] Test: same warnings produced

**Phase 3: Phase 2 uniformization**
- [ ] Map ALL differences between commands in Phase 2
- [ ] Classify: necessary (workflow-specific) vs accidental
- [ ] Eliminate accidental divergences
- [ ] Parameterize necessary differences
- [ ] Test: all workflows function correctly

**Phase 4: roundtable.md alignment**
- [ ] Add resume/validation/diagnostic to roundtable.md
- [ ] Verify `--workflow-type specs/design/brainstorm` produces correct output
- [ ] Simplify workflow commands to wrappers
- [ ] Test: identical behavior via roundtable.md

**Phase 5: Skill cleanup** (linked to DEBT-001)
- [ ] Decide skill role: documentation only
- [ ] Slim SKILL.md to overview + references
- [ ] Move verbose content to references/
- [ ] Target: under 2000 words

**Acceptance criteria**:
- [ ] Commands reduced to ~600-800 lines each
- [ ] roundtable.md can execute all workflows
- [ ] No behavioral regression (all tests pass)
- [ ] roundtable-execution skill under 2000 words

**Estimated impact**:
- ~40% reduction in command lines
- Centralized execution logic
- Easier maintenance

---

### DEBT-001: Reduce roundtable-execution word count

**Status**: planned | **Created**: 2026-01-19 | **Updated**: 2026-01-20 | **Part of**: TECH-002 Phase 5

**Context**: `skills/roundtable-execution/SKILL.md` has 2492 words, exceeding the 2000 word limit (INST-010).

**Risk**: High - actively referenced by workflow commands.

**Note**: This task is now part of TECH-002 Phase 5 (Skill cleanup). The approach will be decided as part of that phase, considering the broader command unification goals.

**Tasks**:
- [ ] Extract "Verbose Dump File Format" to references/
- [ ] Extract "Definition of Done Checklist" to references/
- [ ] Evaluate workspace scope extraction
- [ ] Decide skill role: documentation vs execution reference
- [ ] Test all workflow commands after changes
- [ ] Verify word count under 2000

**Acceptance criteria**:
- [ ] SKILL.md under 2000 words
- [ ] All workflow commands still work
- [ ] Skill role clearly defined

---

### DEBT-002: Separate dev tools repository

**Status**: deferred | **Created**: 2026-01-19 | **Trigger**: v1.0 release

**Context**: Development tools in main repo risk accidental inclusion in release.

**Tasks**:
- [ ] Create spec2ship-devkit repository
- [ ] Migrate dev/ folders
- [ ] Configure CI/CD
- [ ] Update documentation

**Trigger conditions**:
- v1.0 release planned
- Release workflow stable
- At least 3 contributors using dev tools

---

## Completed

| ID | Description | Completed |
|----|-------------|-----------|
| FLOW-001 | Ideas and artifact traceability | 2026-01-19 |
| TEST-002 | Progressive disclosure for diagnostic | 2026-01-18 |
| WORK-002 | Roundtable scope awareness | 2026-01-17 |
| WORK-001 | Workspace core structure | 2026-01-17 |
| TEMPL-002 | Workspace template cleanup | 2026-01-17 |
| TEMPL-001 | Template usage model decision | 2026-01-17 |
| EXT-003 | s2s-guide skill | 2026-01-17 |
| INIT-003 | Init template copy refactor | 2026-01-17 |
| PLAN-002 | Plan template alignment | 2026-01-17 |
| DEBT-001 | Config hardcoding removal | 2026-01-16 |
| BACK-001 | Backlog file in init | 2026-01-16 |
| PATH-001 | Consolidate output to .s2s | 2026-01-15 |
| ARCH-001 | Session management simplification | 2026-01-15 |
| OSS-001 | OSS compliance | 2026-01-14 |

---

## Notes

- Ideas and proposals: See `ideas.md`
- Requirements: See `requirements.md`
- Architecture: See `architecture.md`
- Decisions: See `decisions/`

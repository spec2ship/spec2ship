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

**Status**: in_progress | **Created**: 2026-01-11 | **Updated**: 2026-01-20

**Context**: S2S development requires consistent adherence to patterns and ability to test resume/resilience. Development tools are in the plugin but excluded from release.

**Structure**:
```
skills/dev-testing/          # Check definitions + test specs
├── SKILL.md                 # Overview
├── references/
│   ├── check-registry.md    # INST-*, CONS-*, RES-*, EDGE-* definitions
│   └── roundtable-tests.md  # Roundtable-specific test cases (TECH-002)
agents/dev/dev-validator.md  # Unified agent
commands/dev/check.md        # /s2s:dev:check
commands/dev/test.md         # /s2s:dev:test
```

**Check categories** (from check-registry.md):
- ENV-* (7): Environment verification ✓ implemented
- VAL-RT-* (5): Session validation ✓ implemented
- INST-* (10): Instruction quality
- CONS-* (7): Consistency between commands
- RES-* (7): Resume capability
- EDGE-* (7): Edge cases

**Roundtable test categories** (from roundtable-tests.md):
- ENV-* (7): Environment checks - `auto`
- VAL-RT-* (5): Session validation - `auto`
- RES-RT-* (7): Resume tests - `semi`
- DIAG-RT-* (3): Diagnostic tests - `manual`
- EDGE-RT-* (7): Edge cases - mixed
- REG-* (5): Regression tests - `semi`

**Tasks**:
- [x] Create dev-testing skill with check definitions
- [x] Create dev-validator agent
- [x] Create check.md and test.md commands
- [x] Document in s2s-development.md
- [x] Create roundtable-tests.md with test specifications
- [x] Implement ENV-* checks in dev-validator (7 checks, all tested)
- [x] Implement VAL-RT-* checks in dev-validator (5 checks, all tested)
- [ ] Add release exclusion in .github/
- [ ] Implement RES-RT-* state checks in dev-validator (priority 2)

**Acceptance criteria**:
- [~] `/s2s:dev:check` runs INST-*, CONS-*, ENV-* checks (ENV-* done)
- [~] `/s2s:dev:test` runs RES-*, EDGE-*, VAL-RT-* tests (VAL-RT-* done)
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
- [ ] Run manual end-to-end resume tests (partial: environment verified)
- [x] Create `skills/dev-testing/references/roundtable-tests.md` (for TECH-002)

**Acceptance criteria**:
- [ ] Resume works from all 7 critical interruption points
- [ ] STR-*, TRANS-*, CTX-* checks in session-qa
- [x] Baseline tests documented for TECH-002

---

## Planned

### BUG-001: Agent resume fails across Claude sessions

**Status**: planned | **Created**: 2026-01-20 | **Priority**: low

**Context**: When resuming a roundtable session after restarting Claude, the command attempts to resume saved `agent_id` but fails because agent transcripts are session-scoped (not persisted across Claude restarts).

**Error observed**:
```
resuming aaf0f99
Error: No transcript found for agent ID: aaf0f99
```

**Root cause**: Agent IDs and transcripts exist only within a single Claude CLI session. When Claude is restarted, the transcripts are lost but the session file still contains the old agent_id.

**Possible solutions**:
- [ ] Detect if transcript exists before attempting resume (official method TBD)
- [ ] Clear agent_id on session load if Claude session is new
- [ ] Accept the error and continue with fresh agent (current behavior after error)

**Tasks**:
- [ ] Research official method to check transcript existence
- [ ] Implement pre-check before resume attempt
- [ ] Update session resume logic in workflow commands

**Acceptance criteria**:
- [ ] No failed resume attempts when Claude is restarted
- [ ] Session continues smoothly with fresh agents

---

### BUG-002: Consensus threshold 0.67 rejects exact 2/3 majority

**Status**: planned | **Created**: 2026-01-20 | **Priority**: medium

**Context**: The threshold for 2/3 majority consensus is set to 0.67 in config files, but 2/3 = 0.6666... which means exact 2/3 votes fail the `>=0.67` check when participants are divisible by 3.

**Affected files**:
- `templates/project/config.yaml:38,55` (threshold: 0.67)
- `.s2s/config.yaml:32,49` (threshold: 0.67)

**Note**: Skill references already use 0.6 (`skills/roundtable-strategies/references/standard.md`, `disney.md`).

**Impact**: With 3, 6, or 9 participants, a 2/3 vote (0.6666...) does NOT pass threshold 0.67.

| Participants | Votes for 2/3 | Proportion | Passes 0.67? |
|--------------|---------------|------------|--------------|
| 3 | 2 | 0.6666 | NO |
| 6 | 4 | 0.6666 | NO |
| 9 | 6 | 0.6666 | NO |

**Fix**: Change threshold from 0.67 to 0.6 for consistency with skill references.

**Tasks**:
- [ ] Update `templates/project/config.yaml` threshold values to 0.6
- [ ] Update `.s2s/config.yaml` threshold values to 0.6
- [ ] Update comment from "2/3 majority" to "60% (ensures 2/3 passes)"

**Acceptance criteria**:
- [ ] All threshold values aligned to 0.6
- [ ] Exact 2/3 votes pass consensus check

---

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

**Status**: in_progress | **Created**: 2026-01-20 | **Updated**: 2026-01-21 | **Origin**: IDEA-008
**ADRs**:
- [0011-roundtable-command-unification](decisions/0011-roundtable-command-unification.md)
- [0012-output-generation-skill](decisions/0012-output-generation-skill.md)

**Context**: specs.md, design.md, brainstorm.md have ~60% code duplication (~1600+ lines each). They claim to follow `roundtable-execution` skill but implement everything inline (and better). roundtable.md is underpowered in comparison.

**Goal**: Unify execution logic, reduce duplication, align roundtable.md capabilities.

**Phases**:

| Phase | Description | Depends on | Links to |
|-------|-------------|------------|----------|
| 0 | Test baseline | - | TEST-003 |
| 1 | Output extraction | Phase 0 | ADR-0012 |
| 2 | Validation in agent | Phase 0 | session-qa |
| 3 | Phase 2 uniformization | Phase 1, 2 | - |
| 4 | roundtable.md alignment | Phase 3 | - |
| 5 | Skill cleanup | Phase 0 | DEBT-001 |

**Phase 0: Test baseline** ✅
- [x] Create `skills/dev-testing/references/roundtable-tests.md` with test cases
- [x] Document acceptance criteria for specs, design, brainstorm, roundtable
- [x] Run baseline tests and document current behavior

**Phase 1: Output extraction** ✅ (~370 lines saved)
- [x] Create unified `skills/output-generation/` with SKILL.md + references/
- [x] Reference files: specs-srs.md, design-arc42.md, brainstorm.md
- [x] Modify commands to `Read` skill instead of inline
- [x] Update roundtable-execution PHASE 3 to use output-generation
- [x] Document in ADR-0012 and s2s-development.md
- [x] Format consolidation review (2026-01-21):
  - Fixed naming convention in verbose-dump-format.md
  - Added `timestamp:`, `key_decisions:` to session-schema.md rounds[]
  - Added `metrics_consistency` to verification checklist
  - Added workflow-specific fields table
  - Added "Authoritative Format References" to s2s-development.md
- [ ] **NEXT**: Test output identical to current (run /s2s:specs, /s2s:design, /s2s:brainstorm)

**Line count after Phase 1**:
- specs.md: 1739 → 1631 (-108)
- design.md: 1627 → 1504 (-123)
- brainstorm.md: 1624 → 1485 (-139)
- Total: 4990 → 4620 (-370)

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

**Phase 5: Skill cleanup** (linked to DEBT-001) ✅
- [x] Decide skill role: execution reference with extracted details
- [x] Slim SKILL.md to overview + references (2492 → 1912 words)
- [x] Move verbose content to references/ (verbose-dump-format.md, definition-of-done.md, workspace-scope.md)
- [x] Target: under 2000 words (achieved: 1912)

**Acceptance criteria**:
- [ ] Commands reduced to ~600-800 lines each
- [ ] roundtable.md can execute all workflows
- [ ] No behavioral regression (all tests pass)
- [ ] roundtable-execution skill under 2000 words

**Estimated impact**:
- ~40% reduction in command lines
- Centralized execution logic
- Easier maintenance

**Current state** (2026-01-21):
- Branch: `feature/TECH-002-roundtable-unification`
- Ready to push: 4 commits (output-generation skill, command refactor, format fixes, docs)
- Next action: Test Phase 1 output, then push

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

### TECH-003: Centralize artifact schemas in session-schema.md

**Status**: planned | **Created**: 2026-01-21 | **Priority**: low | **Origin**: TECH-002 review

**Context**: During TECH-002 format consolidation review, found that `session-schema.md` only contains schemas for specs workflow artifacts (REQ-*, BR-*, NFR-*, EX-*, CONF-*, OQ-*). Schemas for design (ARCH-*, COMP-*) and brainstorm (IDEA-*, RISK-*, MIT-*) are defined inline in their respective commands.

**Current state**:
- specs artifacts: defined in `session-schema.md` ✓
- design artifacts: defined inline in `design.md`
- brainstorm artifacts: defined inline in `brainstorm.md`

**Tasks**:
- [ ] Add ARCH-* schema to session-schema.md
- [ ] Add COMP-* schema to session-schema.md
- [ ] Add IDEA-* schema to session-schema.md
- [ ] Add RISK-* schema to session-schema.md
- [ ] Add MIT-* schema to session-schema.md
- [ ] Update commands to reference centralized schemas

**Acceptance criteria**:
- [ ] All artifact schemas in single reference file
- [ ] Commands reference schemas instead of defining inline

**Note**: Low priority - current inline definitions work, centralization is for maintainability.

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

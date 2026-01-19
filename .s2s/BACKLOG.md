# Spec2Ship Backlog

**Updated**: 2026-01-19
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

**Status**: in_progress | **Created**: 2026-01-18 | **Updated**: 2026-01-19

**Context**: Roundtable sessions can be interrupted at various points. Need verification that resume works correctly.

**Tasks**:
- [ ] Align roundtable.md resume logic with inline commands
- [ ] Add TRANS-* checks to session-qa (state transitions)
- [ ] Add CTX-* checks to session-qa (context propagation)
- [ ] Enhance error-handling.md with mid-write recovery
- [ ] Run manual end-to-end resume tests

**Acceptance criteria**:
- [ ] Resume works from all 7 critical interruption points
- [ ] STR-*, TRANS-*, CTX-* checks in session-qa

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

### DEBT-001: Reduce roundtable-execution word count

**Status**: planned | **Created**: 2026-01-19 | **Priority**: Low

**Context**: `skills/roundtable-execution/SKILL.md` has 2492 words, exceeding the 2000 word limit (INST-010).

**Risk**: High - actively referenced by workflow commands.

**Tasks**:
- [ ] Extract "Verbose Dump File Format" to references/
- [ ] Extract "Definition of Done Checklist" to references/
- [ ] Evaluate workspace scope extraction
- [ ] Test all workflow commands after changes
- [ ] Verify word count under 2000

**Acceptance criteria**:
- [ ] SKILL.md under 2000 words
- [ ] All workflow commands still work

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

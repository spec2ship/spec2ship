# Spec2Ship Development Backlog

**Created**: 2026-01-11
**Last Updated**: 2026-01-11
**Plan Reference**: `/Users/fvadicamo/.claude/plans/atomic-discovering-bonbon.md`

---

## Overview

This folder contains all development proposals for Spec2Ship, organized by category. Each proposal follows a standardized format inspired by MADR (Markdown Any Decision Records) and s2s artifact patterns.

The proposals can be used:
1. As context for s2s roundtable sessions about Spec2Ship development
2. As a structured backlog for implementation planning
3. As documentation of design decisions and trade-offs

---

## Status Legend

| Status | Meaning |
|--------|---------|
| `draft` | Initial proposal, needs refinement |
| `ready` | Fully specified, ready for implementation |
| `in-progress` | Currently being implemented |
| `done` | Implemented and verified |
| `rejected` | Decided not to implement |

---

## Proposals by Priority

### High Priority

| ID | Title | Status | Category |
|----|-------|--------|----------|
| [MISC-001](misc/MISC-001.md) | Release v0.2.5 | ready | Misc |
| [INIT-001](init/INIT-001.md) | Optional Structure Creation | draft | Init |
| [SESS-001](session/SESS-001.md) | Intelligent Auto-Resume | draft | Session |
| [TEST-001](testing/TEST-001.md) | Test Framework with s2s:test | draft | Testing |
| [QUAL-001](quality/QUAL-001.md) | Code Review Agent for s2s | draft | Quality |

### Medium Priority

| ID | Title | Status | Category |
|----|-------|--------|----------|
| [INIT-002](init/INIT-002.md) | Intelligent Project Assessment | draft | Init |
| [RT-001](roundtable/RT-001.md) | Phases for All Workflows | draft | Roundtable |
| [RT-002](roundtable/RT-002.md) | start.md as Central Orchestrator | draft | Roundtable |
| [SESS-002](session/SESS-002.md) | User Hand-Raise Intervention | draft | Session |
| [EXT-001](extensibility/EXT-001.md) | Custom Agents in Project .claude/ | draft | Extensibility |
| [CTX-001](context/CTX-001.md) | Context Reduction Strategies | draft | Context |
| [QUAL-002](quality/QUAL-002.md) | Validate Default to Full | draft | Quality |

### Low Priority

| ID | Title | Status | Category |
|----|-------|--------|----------|
| [RT-003](roundtable/RT-003.md) | Ready-to-Use Roundtable Templates | draft | Roundtable |
| [RT-004](roundtable/RT-004.md) | Context-Aware Roundtable Splitting | draft | Roundtable |
| [SESS-003](session/SESS-003.md) | Product Owner Observer Agent | draft | Session |
| [SESS-004](session/SESS-004.md) | Workflow Configuration Wizard | draft | Session |
| [EXT-002](extensibility/EXT-002.md) | Custom Participants Skill | draft | Extensibility |
| [EXT-003](extensibility/EXT-003.md) | Migrate Command for Templates | draft | Extensibility |
| [TEST-002](testing/TEST-002.md) | Ad-Hoc Test Projects Suite | draft | Testing |
| [OUT-001](output/OUT-001.md) | Parallel Transcriber Agent | draft | Output |
| [OUT-002](output/OUT-002.md) | Export Commands (specs, design) | draft | Output |
| [MISC-002](misc/MISC-002.md) | Rules Folder Best Practices | draft | Misc |
| [MISC-003](misc/MISC-003.md) | File Size Verification | draft | Misc |

---

## Proposals by Category

### Init (Project Initialization)
- [INIT-001](init/INIT-001.md) - Optional Structure Creation
- [INIT-002](init/INIT-002.md) - Intelligent Project Assessment

### Roundtable (Core Roundtable Features)
- [RT-001](roundtable/RT-001.md) - Phases for All Workflows
- [RT-002](roundtable/RT-002.md) - start.md as Central Orchestrator
- [RT-003](roundtable/RT-003.md) - Ready-to-Use Roundtable Templates
- [RT-004](roundtable/RT-004.md) - Context-Aware Roundtable Splitting

### Session (Session Management)
- [SESS-001](session/SESS-001.md) - Intelligent Auto-Resume
- [SESS-002](session/SESS-002.md) - User Hand-Raise Intervention
- [SESS-003](session/SESS-003.md) - Product Owner Observer Agent
- [SESS-004](session/SESS-004.md) - Workflow Configuration Wizard

### Context (Context Optimization)
- [CTX-001](context/CTX-001.md) - Context Reduction Strategies

### Extensibility (Plugin Extension)
- [EXT-001](extensibility/EXT-001.md) - Custom Agents in Project .claude/
- [EXT-002](extensibility/EXT-002.md) - Custom Participants Skill
- [EXT-003](extensibility/EXT-003.md) - Migrate Command for Templates

### Testing (Test Infrastructure)
- [TEST-001](testing/TEST-001.md) - Test Framework with s2s:test
- [TEST-002](testing/TEST-002.md) - Ad-Hoc Test Projects Suite

### Quality (Quality Assurance)
- [QUAL-001](quality/QUAL-001.md) - Code Review Agent for s2s
- [QUAL-002](quality/QUAL-002.md) - Validate Default to Full

### Output (Output Generation)
- [OUT-001](output/OUT-001.md) - Parallel Transcriber Agent
- [OUT-002](output/OUT-002.md) - Export Commands (specs, design)

### Misc (Miscellaneous)
- [MISC-001](misc/MISC-001.md) - Release v0.2.5
- [MISC-002](misc/MISC-002.md) - Rules Folder Best Practices
- [MISC-003](misc/MISC-003.md) - File Size Verification

---

## Implementation Sequence

### Phase 1: Quick Wins
1. MISC-001: Release v0.2.5
2. QUAL-002: Validate default to full
3. MISC-003: File size audit

### Phase 2: Foundation
1. INIT-001: Optional structure creation
2. SESS-001: Intelligent auto-resume
3. EXT-001: Custom agents in .claude/
4. QUAL-001: Code review agent for s2s

### Phase 3: Core Improvements
1. INIT-002: Intelligent project assessment
2. RT-001: Phases for all workflows
3. TEST-001: Test framework

### Phase 4: Advanced Features
1. RT-002: start.md as central orchestrator
2. CTX-001: Context reduction strategies
3. SESS-002: User hand-raise

### Phase 5: Extensibility
1. EXT-002: Custom participants
2. RT-003: Roundtable templates
3. EXT-003: Migrate command

---

## Using with s2s

This backlog can be used as input for s2s roundtable sessions:

```bash
# Brainstorm on a specific proposal
/s2s:brainstorm "SESS-002 User Hand-Raise design options"

# Run specs roundtable for implementation details
/s2s:specs --context ".s2s/backlog/session/SESS-002.md"

# Design session for architecture
/s2s:design "RT-002 start.md centralization"
```

---

## Proposal File Format

Each proposal follows this structure:

```markdown
# {ID}: {Title}

**Status**: draft | ready | in-progress | done | rejected
**Priority**: high | medium | low
**Category**: {category}
**Created**: {date}
**Updated**: {date}

## Context
Why this proposal exists. What problem it solves.

## Proposal
What we propose to do. Implementation approach.

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Related
- Supersedes: {old-id}
- Depends on: {other-id}
- Related to: {other-id}

## Open Questions
- Question 1?
- Question 2?

## Notes
Additional context, links, references.
```

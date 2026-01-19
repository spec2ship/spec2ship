# Plan: Context File Restructure (Opzione E)

**ID**: 20260117-context-restructure
**Status**: ready-for-implementation
**Created**: 2026-01-17
**Related**: ADR-0009 (workspace context cascade), WORK-002

---

## Executive Summary

Ristrutturare i file CONTEXT.md per evitare ambiguità quando workspace e component context sono entrambi in memoria via @ cascade. L'approccio scelto (Opzione E) mantiene CONTEXT.md come file semantico condivisibile, spostando path S2S e comandi in un README.md separato.

---

## Problem Statement

### Problema identificato

Quando Claude esegue da un componente, via @ cascade vengono caricati in memoria:
1. `component/.s2s/CONTEXT.md`
2. `workspace/.s2s/CONTEXT.md` (via @../../CONTEXT.md)

Entrambi i file contengono sezioni con path relative identiche:
- "Backlog: `.s2s/BACKLOG.md`"
- "Decisions: `.s2s/decisions/`"
- "Sessions: `.s2s/sessions/`"

Questo crea **ambiguità**: Claude non sa quale `.s2s/BACKLOG.md` è rilevante.

### Insight chiave

Le path S2S e i comandi servono agli **umani**, non agli **LLM**:
- Gli LLM usano CWD + convenzioni per sapere dove scrivere
- Gli LLM hanno bisogno di **context semantico** (domain, constraints, objectives)
- Le path sono documentazione, non istruzioni operative

---

## Header Naming Convention (Flat Memory Disambiguation)

### Problem

When component CONTEXT.md includes workspace CONTEXT.md via @ cascade, Claude sees both files "flat" in memory. If both have `## Open Questions`, Claude cannot distinguish which belongs to which.

### Solution

Use **prefixed headers** to make each section unambiguous:

| Workspace Header | Component Header | Why |
|------------------|------------------|-----|
| `# ... - Workspace Context` | `# ... - Component Context` | Clear document identity |
| `## System Overview` | `## Component Overview` | "System" = workspace level |
| `## System Objectives` | (none) | Component inherits from workspace |
| `## System Constraints` | `## Component Constraints` | Both may have constraints |
| `## Workspace Open Questions` | `## Component Open Questions` | Most critical disambiguation |

### Principle

- **Workspace headers**: Prefix with "System" or "Workspace"
- **Component headers**: Prefix with "Component"
- **Shared concepts** (like Business Domain, Cross-Cutting): Only in workspace, inherited by component

---

## Decision: Opzione E - CONTEXT.md pulito

### Principio

**CONTEXT.md** = solo informazioni semantiche per LLM (domain, constraints, cross-cutting)
**README.md** = documentazione per umani (path S2S, comandi, how-to)

### Struttura risultante

```
workspace/.s2s/
├── CONTEXT.md           # Domain, objectives, constraints, cross-cutting
│                        # NO path S2S, NO comandi
├── README.md            # Path S2S, comandi, how-to (per umani)
├── workspace.yaml
└── ...

workspace/CLAUDE.md:
  @.s2s/CONTEXT.md       # Solo context semantico

component/.s2s/
├── CONTEXT.md           # Ruolo, stack, specifici
│   └── @../../CONTEXT.md  # Cascade al workspace context
├── README.md            # Path S2S locali (opzionale, convenzioni standard)
└── config.yaml

component/CLAUDE.md:
  @.s2s/CONTEXT.md       # Che cascata include workspace context
```

### Cosa contiene ogni file

#### workspace/.s2s/CONTEXT.md (DOPO)

**IMPORTANT**: Header are prefixed with "System" or "Workspace" to avoid ambiguity when loaded flat in memory alongside component CONTEXT.md via @ cascade.

```markdown
# {workspace-name} - Workspace Context

## System Overview
{description}

## Business Domain
{business-domain}

## System Objectives
- {objective-1}
- {objective-2}

## System Constraints
- {constraint-1}
- {constraint-2}

## Cross-Cutting Concerns
- **Authentication**: {approach}
- **Authorization**: {approach}
- **Logging**: {approach}
- **Monitoring**: {approach}

## Components
| Component | Role |
|-----------|------|
| {name} | {role} |

## Architecture Principles
{High-level principles}

## Workspace Open Questions
- {Question}
```

**RIMOSSO**: S2S Commands, Session Management, Related Documents (path)

**HEADER CHANGES** (to avoid flat memory ambiguity):
- `# ... - Context` → `# ... - Workspace Context`
- `## Overview` → `## System Overview`
- `## Objectives` → `## System Objectives`
- `## Constraints` → `## System Constraints`
- `## Components Overview` → `## Components`
- `## Open Questions` → `## Workspace Open Questions`

#### workspace/.s2s/README.md (NUOVO)

```markdown
# {workspace-name} - S2S Workspace

This workspace uses [Spec2Ship](https://github.com/spec2ship/spec2ship) for specification-driven development.

## Structure

| Path | Purpose |
|------|---------|
| `CONTEXT.md` | Project context (loaded by Claude) |
| `workspace.yaml` | Component registry, roundtable scope |
| `requirements.md` | Functional requirements (from /s2s:specs) |
| `architecture.md` | Technical architecture (from /s2s:design) |
| `decisions/` | Architecture Decision Records (MADR format) |
| `sessions/` | Roundtable session artifacts |
| `BACKLOG.md` | Work items, ideas, technical debt |

## Commands

### Workspace-Level

| Command | Use Case |
|---------|----------|
| `/s2s:init --workspace` | Initialize workspace structure |
| `/s2s:specs "topic"` | Define cross-component requirements |
| `/s2s:design "topic"` | Design system architecture |
| `/s2s:brainstorm "topic"` | Creative exploration |
| `/s2s:plan "feature"` | Plan cross-component implementation |

### Session Management

| Command | Description |
|---------|-------------|
| `/s2s:session:list` | List all sessions |
| `/s2s:session:status` | Current session status |
| `/s2s:session:close` | Close active session |

## Adding a Component

```bash
cd {component-folder}
/s2s:init
# Init detects parent workspace and offers to link
```

## Related

- [Spec2Ship Documentation](https://github.com/spec2ship/spec2ship)
- Workspace context: `CONTEXT.md`
- Component registry: `workspace.yaml`
```

#### component/.s2s/CONTEXT.md (DOPO)

**IMPORTANT**: Header are prefixed with "Component" to avoid ambiguity when workspace CONTEXT.md is loaded via @ cascade.

```markdown
# {component-name} - Component Context

<!--
MEMORY LOADING:
- Imported in CLAUDE.md via @.s2s/CONTEXT.md
- Includes workspace context via @ cascade (max 5 hops)
- Path must be RELATIVE for team portability
-->

## Workspace Context

This component is part of **{workspace-name}** workspace.

**Role**: {component-role-description}

**Workspace path**: `{workspace-path}`

@{workspace-path}/.s2s/CONTEXT.md

---

## Component Overview

{description}

## Technical Stack

<!-- Populated by /s2s:design or manually -->
TBD - run `/s2s:design` to define architecture and stack

## Component Constraints

- {component-constraints}

## Component Open Questions

<!-- Populated during /s2s:specs or /s2s:design sessions -->
- None identified yet

---
*Last updated: {date}*
```

**RIMOSSO**: Project Tracking (path S2S)

**HEADER CHANGES** (to avoid flat memory ambiguity):
- `# ... - Context` → `# ... - Component Context`
- `## Component-Specific Constraints` → `## Component Constraints` (shorter, still clear)
- `## Open Questions` → `## Component Open Questions`

#### component/.s2s/README.md (opzionale)

Per componenti standalone o quando serve documentazione locale:

```markdown
# {component-name} - S2S Component

## Structure

Standard S2S structure. See workspace README for details.

| Path | Purpose |
|------|---------|
| `CONTEXT.md` | Component context (includes workspace context) |
| `config.yaml` | Component configuration |
| `sessions/` | Local roundtable sessions |

## Commands

Run from this directory:

| Command | Use Case |
|---------|----------|
| `/s2s:specs "topic"` | Component-specific requirements |
| `/s2s:design "topic"` | Component architecture |
| `/s2s:plan "feature"` | Implementation plan |
```

---

## Implementation Tasks

### Task 1: Update workspace CONTEXT.md template

**File**: `templates/workspace/CONTEXT.md`

**Changes**:
1. REMOVE sections:
   - "## S2S Commands" (lines 47-57)
   - "### Component Management" (lines 59-66)
   - "### Session Management" (lines 68-75)
   - "## Related Documents" (lines 80-85)
2. KEEP sections:
   - Overview
   - Business Domain
   - Components (tabella semplificata: nome + ruolo, no path)
   - Architecture
   - Cross-Cutting Concerns
   - Open Questions
3. UPDATE header comment to explain @ cascade

### Task 2: Create workspace README.md template

**File**: `templates/workspace/README.md` (NEW)

**Content**: Documentazione S2S per umani (path, comandi, how-to)

See template above.

### Task 3: Update component CONTEXT.md template

**File**: `templates/project/CONTEXT.md`

**Changes**:
1. REMOVE section:
   - "## Project Tracking" (lines 60-64) - path S2S duplicati
2. KEEP sections:
   - Workspace Context (con @ cascade)
   - Overview
   - Business Domain
   - Objectives
   - Scope
   - Constraints
   - Technical Stack
   - Open Questions
3. Ensure header comment explains @ cascade

### Task 4: Create component README.md template

**File**: `templates/project/README.md` (NEW)

**Content**: Minimal, riferisce al workspace README

### Task 5: Update /s2s:init command

**File**: `commands/init.md`

**Changes**:
1. Add step to create README.md from template
2. For workspace: full README.md
3. For component: minimal README.md or skip
4. For standalone: full README.md (same as workspace but without component references)

### Task 6: Update ADR-0009

**File**: `.s2s/decisions/0009-workspace-context-cascade.md`

**Changes**:
Add section documenting Opzione E decision:
- Why CONTEXT.md should be semantic-only
- Why path S2S go in README.md
- Link to this plan

### Task 7: Update roundtable-execution SKILL

**File**: `skills/roundtable-execution/SKILL.md`

**Changes**:
- Verify Step 1.3c is still accurate
- No path S2S references needed (they were never used by LLM)

### Task 8: Cleanup test files

Remove `.s2s/temp/` if still present from earlier tests.

---

## Verification Checklist

After implementation, verify:

### Content checks
- [ ] `templates/workspace/CONTEXT.md` has NO path S2S
- [ ] `templates/workspace/CONTEXT.md` has NO S2S Commands section
- [ ] `templates/workspace/README.md` exists with comandi e path
- [ ] `templates/project/CONTEXT.md` has NO "Project Tracking" section
- [ ] `templates/project/README.md` exists (minimal)
- [ ] `commands/init.md` creates README.md
- [ ] ADR-0009 updated with Opzione E rationale

### Header disambiguation checks
- [ ] Workspace CONTEXT.md title: `# {name} - Workspace Context`
- [ ] Workspace headers use "System" prefix: `## System Overview`, `## System Objectives`, `## System Constraints`
- [ ] Workspace open questions: `## Workspace Open Questions`
- [ ] Component CONTEXT.md title: `# {name} - Component Context`
- [ ] Component headers use "Component" prefix: `## Component Overview`, `## Component Constraints`
- [ ] Component open questions: `## Component Open Questions`
- [ ] No duplicate headers between workspace and component files

## Test Scenario

1. Create test workspace with component
2. Load component in Claude Code
3. Run `/memory` - verify both CONTEXT.md loaded
4. Ask Claude "where is the backlog?" - should answer unambiguously (CWD)
5. Verify no path S2S duplications in memory

---

## Rollback Plan

If issues found:
1. Revert template changes
2. Keep README.md as additional documentation (doesn't break anything)
3. Re-evaluate Opzione A or B

---

## Notes

- This plan can be executed by a new session without prior context
- All file paths are relative to spec2ship plugin root
- Related work: WORK-003 (decision propagation), WORK-004 (dependency graph)

---

## Future investigation: Title Case in headings

**Status**: deferred

**Analysis (2026-01-17)**:

Rilevata inconsistenza negli heading: mix di Title Case e sentence case.

Esempi README.md:
- H2 Title Case: "Quick Start", "Operational Flow", "Supported Standards"
- H3 misti: "Why This Matters" (Title Case) vs "What happens at each phase" (sentence case)

**Evidenze**:
- Molti progetti OSS usano Title Case per heading (React, Vue, Next.js docs)
- Title Case per H2 è convenzione accettata e diffusa
- GitHub stesso usa sentence case, ma non è uno standard universale

**Valutazione**:
- H2 (sezioni principali): Title Case accettabile, non prioritario modificare
- H3 (sottosezioni): potrebbe beneficiare di uniformità a sentence case
- Non è un pattern "anti-LLM" forte come em-dash o hedging language

**Decisione**: rimandare ulteriori approfondimenti. Se si decide di intervenire, partire da H3 per uniformità interna, mantenendo H2 in Title Case.

---

## Future task: ROADMAP.md

**Status**: deferred

**Problema**: README.md riferisce a BACKLOG.md che non è standard OSS. I progetti OSS usano ROADMAP.md per comunicare la visione.

**Azione richiesta**:
1. Creare `ROADMAP.md` con macro-feature (non dettagli implementativi)
2. Aggiornare README.md sezione "Roadmap" per puntare a ROADMAP.md
3. BACKLOG.md rimane interno in `.s2s/` per tracking dettagliato

**Struttura proposta ROADMAP.md**:

```markdown
# Roadmap

## Current (v0.x)
- Workflow: init → brainstorm → specs → design → plan
- 12 specialized agents, 5 facilitation strategies
- Session persistence, standards-based output

## Near-term
- Workspace: decision propagation, dependency graph
- Plan generation enhancements
- Export to Markdown, JSON, HTML

## Mid-term
- Custom agents in project
- Enhanced interactive mode
- Template marketplace

## Exploring
- IDE integration (VS Code)
- CI/CD hooks
- Multi-user sessions
- External integrations (Jira, Linear, Notion)
```

---

*Plan created: 2026-01-17*
*Updated: 2026-01-17 (added Title Case analysis, ROADMAP.md task)*
*Updated: 2026-01-18 (added roundtable command consistency analysis)*

---

## Roundtable Command Consistency Analysis

**Status**: analysis-complete
**Date**: 2026-01-18
**Related**: ADR-0010 (artifact state model)

### Overview

Comparative analysis of the 4 roundtable-based commands (specs, design, brainstorm, roundtable) to verify consistency in execution logic and facilitator management.

### Key Findings

#### 1. Structure Differences

| Aspect | specs | design | brainstorm | roundtable |
|--------|-------|--------|------------|------------|
| **Length** | ~1640 lines | ~1616 lines | ~1579 lines | ~357 lines |
| **Inline logic** | Full | Full | Full | Delegates to skill |
| **Phases** | Phase 1-3 | Phase 1-3 | Phase 1-3 | Phase 0-3 |

**Finding**: `roundtable.md` is much shorter because it delegates everything to `roundtable-execution` skill, while specs/design/brainstorm have all logic inline.

**Recommendation**: Consider whether this delegation is intentional architectural decision or technical debt. If intentional, document it.

#### 2. Disney vs Agenda-based Logic

| Aspect | specs/design | brainstorm |
|--------|--------------|------------|
| **Progress tracking** | `agenda[]` with topics | `phases[]` with Disney phases |
| **Facilitator input** | `agenda` with done_when | `phases_status` + `disney_phase_rules` |
| **next values** | continue/conclude/escalate | continue/**phase**/conclude |
| **Synthesis output** | `agenda_update` | `phase_recommendation` |

**Finding**: brainstorm has Disney-specific logic that is fundamentally different from specs/design.

**Status**: Intentional - Disney strategy requires phase-based progression.

#### 3. Participant Counts in Synthesis

| Command | Participants Listed | In Synthesis Responses |
|---------|---------------------|------------------------|
| specs | 4 (pm, ux, ba, qa) | 4 ✅ |
| design | 4 (arch, sec, tl, devops) | 3 ❌ (missing security-champion) |
| brainstorm | 4 (varies) | 4 ✅ |

**Finding**: ~~design.md was missing security-champion in synthesis responses~~ **FIXED** (commit c3d5b06)

#### 4. Diagnostic Mode

| Command | --diagnostic flag | session-observer | Final report |
|---------|-------------------|------------------|--------------|
| specs | ✅ | ✅ per-round + end-session | ✅ |
| design | ✅ | ✅ per-round + end-session | ✅ |
| brainstorm | ✅ | ✅ per-round + end-session | ✅ |
| roundtable | ❌ Not documented | ❌ | ❌ |

**Finding**: roundtable.md does not document --diagnostic mode.

**Recommendation**: Either:
- Add --diagnostic support to roundtable.md, OR
- Document that roundtable delegates diagnostic to the skill

#### 5. Merge Mode

| Command | Merge mode for output |
|---------|----------------------|
| specs | ✅ Override/Merge |
| design | ✅ Override/Merge |
| brainstorm | ❌ No merge (generates summary) |
| roundtable | ❌ Depends on --output-type |

**Finding**: Only specs and design support merge mode for their output documents.

**Status**: Intentional - brainstorm produces session-specific summaries, not cumulative documents.

### Potential Actions

#### Immediate (high value)

1. ~~**Fix design.md security-champion** - Add missing participant in synthesis~~ ✅ DONE

#### Short-term (consistency)

2. **Add --diagnostic to roundtable.md** - Either document it delegates to skill or add inline support
3. **Document Disney logic differences** - Add note in brainstorm.md explaining why it differs from specs/design
4. **Consider extracting common logic** - specs/design/brainstorm share ~80% of roundtable execution logic

#### Long-term (refactoring)

5. **Evaluate skill delegation** - Decide if roundtable.md pattern (delegate to skill) should be applied to other commands
6. **Create shared execution module** - Extract common Phase 2 logic into roundtable-execution skill, have all commands reference it

### Consistency Matrix

| Area | specs | design | brainstorm | roundtable |
|------|-------|--------|------------|------------|
| Auto-detect sessions | ✅ | ✅ | ✅ | ✅ |
| Session setup | ✅ | ✅ | ✅ | Delegates |
| Facilitator question | ✅ | ✅ | ✅ (Disney) | Delegates |
| Participant responses | ✅ | ✅ | ✅ | Delegates |
| Facilitator synthesis | ✅ | ✅ | ✅ (Disney) | Delegates |
| Agent resume | ✅ | ✅ | ✅ | Delegates |
| Session update | ✅ | ✅ | ✅ | Delegates |
| Verbose dump | ✅ | ✅ | ✅ | Delegates |
| Validation 2.6b | ✅ | ✅ | ✅ | Delegates |
| Diagnostic 2.6c | ✅ | ✅ | ✅ | ❌ Missing |
| Completion | ✅ | ✅ | ✅ | Delegates |

### Related ADRs

- **ADR-0010**: Artifact state model (applied consistently across all commands)
- **ADR-0008**: Validation simplification (referenced in commands)

### Commits from this analysis

- `c3d5b06` fix(design): add missing security-champion in synthesis responses

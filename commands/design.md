---
description: Design technical architecture through a roundtable discussion. Reads requirements.md and produces architecture documentation.
allowed-tools: Bash(pwd:*), Bash(ls:*), Bash(mkdir:*), Bash(date:*), Read, Write, Edit, Glob, Task, AskUserQuestion
argument-hint: [--skip-roundtable] [--focus components|api|deployment] [--strategy standard|debate|disney] [--verbose] [--interactive]
skills: roundtable-execution, roundtable-strategies, arc42-templates, madr-decisions
---

# Design Technical Architecture

## Context

- Current directory: !`pwd`
- Directory contents: !`ls -la`
- Current timestamp: !`date -u +"%Y-%m-%dT%H:%M:%SZ"`

## Interpret Context

Based on the context output above, determine:

- **S2S initialized**: If `.s2s` directory appears → "yes", otherwise → "NOT_S2S"

If S2S is initialized:
- Read `.s2s/CONTEXT.md` for project context
- Read `docs/specifications/requirements.md` if exists
- Check `docs/architecture/` for existing docs
- Read `.s2s/config.yaml` for settings

---

## Instructions

### Validate environment

If S2S initialized is "NOT_S2S":

    Error: Not an s2s project. Run /s2s:init first.

### Check prerequisites

If `docs/specifications/requirements.md` does not exist:

    Warning: No requirements document found.

    Recommended workflow:
    1. /s2s:init     - Initialize project
    2. /s2s:specs    - Define requirements
    3. /s2s:design   - Design architecture (you are here)

    Continue without formal requirements?

Ask using AskUserQuestion:
- Options: "Continue with CONTEXT.md only" / "Run /s2s:specs first"

### Check for existing architecture

Use Glob to find `docs/architecture/*.md` files.

If architecture docs exist:
- Display summary
- Ask: "Architecture docs exist. What would you like to do?"
  - Options: "Refine existing" / "Start fresh" / "Cancel"

### Parse arguments

Extract from $ARGUMENTS:
- **--skip-roundtable**: Skip discussion, generate directly
- **--focus**: Focus area (components|api|deployment)
- **--strategy**: Override strategy. Default: debate (Pro/Con evaluation)

**Boolean flags**: `--verbose` and `--interactive` → parse as `true` if present, `false` if absent.

### Reference Skills

For detailed architecture patterns:
- `arc42-templates` skill: 12 sections, component templates, interface documentation
- `madr-decisions` skill: ADR format, status lifecycle, decision examples

### Display context summary

    Starting architecture design...

    Project Context:
    ────────────────
    {from CONTEXT.md}

    Key Requirements:
    ─────────────────
    {list from requirements.md}

    Constraints:
    ────────────
    {from CONTEXT.md}

### Phase 1: Design Roundtable

If --skip-roundtable is NOT present:

**IMPORTANT: Follow the `roundtable-execution` skill instructions EXACTLY.**
**DO NOT use SlashCommand. Execute the roundtable inline using Task().**

#### Roundtable Configuration

Configure the roundtable with these parameters:
- **topic**: "Architecture design for {project name}"
- **workflow_type**: "design"
- **strategy**: {--strategy argument or "debate"}
- **output_type**: "architecture"
- **participants**: software-architect, technical-lead, devops-engineer (from config)
- **verbose**: {verbose_flag}
- **interactive**: {interactive_flag}

#### Load Agenda

Read `skills/roundtable-execution/references/agenda-design.md` and extract REQUIRED_TOPICS (5 topics: high-level-arch, components, data-flow, tech-choices, integration).

#### Execute Roundtable

**YOU MUST** execute these steps from `roundtable-execution` skill with workflow-specific values:

| Parameter | Value |
|-----------|-------|
| session_id | `{timestamp}-design-{project-slug}` |
| workflow_type | `design` |
| participants | `[software-architect, technical-lead, devops-engineer]` |
| agenda | `REQUIRED_TOPICS` from agenda-design.md |
| critical_topics | `high-level-arch`, `components` |

**PHASE 2 - Session Setup:**
Create session file following `references/session-schema.md`. Update `.s2s/state.yaml`.

**PHASE 3 - Round Execution Loop** (repeat until conclusion):

1. **Step 3.0.5**: Display agenda status to terminal
2. **Step 3.1**: **YOU MUST use Task tool NOW** to call facilitator for question
   - See SKILL.md for full prompt template
3. **Step 3.2**: **YOU MUST launch ALL participant Tasks in SINGLE message**
   - This ensures blind voting (parallel execution)
   - Store responses in `participant_responses` array
4. **Step 3.3**: **YOU MUST use Task tool** for facilitator synthesis
5. **Step 3.4**: **YOU MUST use Write/Edit tool NOW** to update session file
6. **Step 3.5**: Display round recap to terminal
7. **Step 3.6**: Evaluate next_action (continue/phase/conclude/escalate)
   - **min_rounds CHECK**: Override "conclude" if round < 3
   - **Agenda CHECK**: Override "conclude" if critical topics pending

**PHASE 4 - Completion:**
Update session status, generate output based on output_type.

After roundtable completes, extract from session file:
- Architecture decisions (ARCH-001, ARCH-002, etc.)
- Component design consensus
- Technology stack recommendations
- Unresolved conflicts for user review

**If --skip-roundtable IS present:**
- Analyze requirements directly
- Generate basic architecture from patterns
- Ask user for technology preferences

### Phase 2: User Review

Present architecture decisions:

    Architecture Design Summary:
    ═══════════════════════════

    System Overview:
    {high-level description}

    Components:
    ───────────
    1. {Component 1}: {responsibility}
    2. {Component 2}: {responsibility}

    Key Decisions:
    ──────────────
    ARCH-001: {title}
    Decision: {chosen option}
    Rationale: {why}

    ARCH-002: {title}
    ...

    Tech Stack:
    ───────────
    - Backend: {choice}
    - Frontend: {choice}
    - Database: {choice}
    - Infrastructure: {choice}

    Open Questions:
    ───────────────
    - {from conflicts}

Ask using AskUserQuestion:
- "Review architecture. Would you like to:"
  - Options: "Approve and generate docs" / "Refine decisions" / "Discuss specific area"

### Phase 3: Generate Architecture Documentation

Create/update documents:

**docs/architecture/README.md:**
```markdown
# Architecture Overview

**Project**: {name}
**Version**: 1.0
**Date**: {date}
**Phase**: design

## System Context

{high-level description}

## Architecture Principles

1. {principle 1}
2. {principle 2}

## Component Overview

| Component | Responsibility | Technology |
|-----------|---------------|------------|
| {name} | {description} | {tech} |

## Key Decisions

See individual ADRs in `/docs/decisions/`

## Documentation Index

- [Components](./components.md)
- [API Contracts](./api-contracts.md)
- [Deployment](./deployment.md)

---
*Generated by Spec2Ship /s2s:design*
```

**docs/architecture/components.md:**
```markdown
# Component Design

## {Component 1 Name}

### Responsibility
{what this component does}

### Interfaces
- Input: {what it receives}
- Output: {what it produces}

### Dependencies
- {dependency 1}

### Technology
{stack for this component}
```

**docs/architecture/deployment.md:**
```markdown
# Deployment Architecture

## Overview
{deployment approach}

## Environments
| Environment | Purpose | Infrastructure |
|-------------|---------|----------------|
| Development | Local dev | {description} |
| Staging | Testing | {description} |
| Production | Live | {description} |

## Deployment Process
{high-level flow}
```

### Phase 4: Generate ADRs

For each architecture decision, create `docs/decisions/ARCH-{NNN}-{slug}.md`:

```markdown
# ARCH-{NNN}: {Title}

**Status**: accepted
**Date**: {date}
**Participants**: {roundtable participants}

## Context
{why decision was needed}

## Decision
{what was decided}

## Options Considered

### Option 1: {name}
- Pros: {list}
- Cons: {list}

### Option 2: {name}
- Pros: {list}
- Cons: {list}

## Consequences

### Positive
- {benefit}

### Negative
- {trade-off}
```

### Phase 5: Update CONTEXT.md

Update `.s2s/CONTEXT.md`:
- Update phase to "design"
- Add Technical Stack section
- Update "Last updated" date

### Phase 6: Output Summary

    Architecture design complete!

    Documents created:
    - docs/architecture/README.md
    - docs/architecture/components.md
    - docs/architecture/deployment.md
    - docs/decisions/ARCH-*.md ({count} decisions)

    Tech Stack:
    {summary}

    Phase: design (ready for implementation)

    Next steps:
      /s2s:plan              - Generate implementation plans
      /s2s:plan:create "x"   - Create specific plan

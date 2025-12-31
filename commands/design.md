---
description: Design technical architecture through a roundtable discussion. Reads requirements.md and produces architecture documentation.
allowed-tools: Bash(pwd:*), Bash(ls:*), Bash(mkdir:*), Bash(date:*), Read, Write, Edit, Glob, Task, AskUserQuestion, TodoWrite
argument-hint: [--skip-roundtable] [--focus components|api|deployment] [--strategy standard|debate|disney]
---

# Design Technical Architecture

## Context

- Current directory: !`pwd`
- Directory contents: !`ls -la`
- Current timestamp: !`date -u +"%Y-%m-%dT%H:%M:%SZ"`

## Interpret Context

Based on the context output above, determine:

- **S2S initialized**: If `.s2s` directory appears in Directory contents → "yes", otherwise → "NOT_S2S"

If S2S is initialized, use Read tool to:
- Read `.s2s/CONTEXT.md` to get project context and phase
- Read `docs/specifications/requirements.md` if exists
- Check existing architecture docs in `docs/architecture/`
- Read `.s2s/state.yaml` for current state

## Instructions

### Validate environment

If S2S initialized is "NOT_S2S", display this message and stop:

    Error: Not an s2s project. Run /s2s:init first.

### Check prerequisites

Check if requirements have been defined:

If `docs/specifications/requirements.md` does not exist or is empty:

    Warning: No requirements document found.

    Recommended workflow:
    1. /s2s:init     - Initialize project
    2. /s2s:specs    - Define requirements
    3. /s2s:design   - Design architecture (you are here)

    Continue without formal requirements?

Ask user using AskUserQuestion:
- Options: "Continue with CONTEXT.md only" / "Run /s2s:specs first"

### Check for existing architecture

Use Glob to find `docs/architecture/*.md` files.

If architecture docs exist:
- Display summary of existing docs
- Ask user using AskUserQuestion: "Architecture docs exist. What would you like to do?"
  - Options: "Refine existing" / "Start fresh" / "Cancel"

### Parse arguments

Extract from $ARGUMENTS:
- **--skip-roundtable**: Skip discussion, generate from requirements directly
- **--focus**: Focus area for this session
  - `components` - System components and structure
  - `api` - API design and contracts
  - `deployment` - Infrastructure and deployment
- **--strategy**: Roundtable facilitation strategy (optional)
  - Options: standard, debate, disney, consensus-driven, six-hats
  - Default: from config.yaml `roundtable.strategy` or "debate"
  - Note: "debate" is recommended for design decisions (Pro/Con evaluation)

### Load roundtable configuration

Read `.s2s/config.yaml` and extract:
- Strategy: --strategy flag → config.roundtable.strategy → "debate"
- Participants: config.roundtable.participants.by_workflow_type.tech
  - Default: [software-architect, technical-lead, devops-engineer]
- Escalation triggers from config

### Display context summary

    Starting architecture design...

    Project Context:
    ────────────────
    {from CONTEXT.md}

    Key Requirements:
    ─────────────────
    {list core requirements from requirements.md}

    Constraints:
    ────────────
    {technical constraints from CONTEXT.md}

### Phase 1: Design Roundtable

If --skip-roundtable is NOT present:

**Launch roundtable session using the executor pattern from start.md:**

The design workflow invokes roundtable with `workflow_type: "tech"`:

1. **Create session** with:
   - Topic: "Architecture design for {project name}" + focus area if specified
   - Strategy: from config or --strategy flag (default: "debate" for Pro/Con evaluation)
   - Workflow type: "tech"
   - Participants: from config.roundtable.participants.by_workflow_type.tech
   - Expected output: "architecture"

2. **Execute roundtable loop** (as defined in roundtable/start.md):
   - Facilitator generates questions about architectural concerns
   - Participants (software-architect, technical-lead, devops-engineer) respond
   - Debate strategy: Pro/Con evaluation of options
   - Facilitator synthesizes, identifies consensus and conflicts
   - Loop until architecture decisions are made or escalation needed

3. **Focus areas for facilitator**:
   - System boundaries and components
   - Data flow and storage patterns
   - Integration points and APIs
   - Scalability and performance requirements
   - Security considerations
   - Deployment topology

4. **Participant perspectives**:
   - Software Architect: overall structure, patterns, component design
   - Technical Lead: implementation approach, tech stack, code organization
   - DevOps Engineer: deployment, infrastructure, observability

5. **Expected output structure**:
   - ARCH-001, ARCH-002, etc. decision IDs
   - For each decision: context, options, decision, rationale, consequences
   - System components with responsibilities
   - Technology stack recommendations
   - Deployment view
   - Risks and open questions

6. **Session completion** triggers Phase 2 (User Review)

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
    ...

    Key Decisions:
    ──────────────
    ARCH-001: {decision title}
    Decision: {chosen option}
    Rationale: {why}

    ARCH-002: {decision title}
    ...

    Tech Stack:
    ───────────
    - Backend: {choice}
    - Frontend: {choice}
    - Database: {choice}
    - Infrastructure: {choice}

    Open Questions:
    ───────────────
    - {question 1}

Ask user using AskUserQuestion:
- "Review the architecture above. Would you like to:"
  - Options: "Approve and generate docs" / "Refine decisions" / "Discuss specific area"

### Phase 3: Generate Architecture Documentation

Create/update architecture documents:

**docs/architecture/README.md:**
```markdown
# Architecture Overview

**Project**: {name}
**Version**: 1.0
**Date**: {date}
**Phase**: design

## System Context

{high-level description of system and its environment}

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

- [Components](./components.md) - Detailed component design
- [API Contracts](./api-contracts.md) - Interface definitions
- [Deployment](./deployment.md) - Infrastructure and deployment

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

## {Component 2 Name}
...
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

## Infrastructure Components
{from DevOps perspective}

## Deployment Process
{high-level deployment flow}
```

### Phase 4: Generate ADRs

For each architectural decision, create an ADR in `docs/decisions/`:

```markdown
# ARCH-{NNN}: {Title}

**Status**: accepted
**Date**: {date}
**Participants**: {roundtable participants}

## Context
{why this decision was needed}

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

## References
- {related decisions or documents}
```

### Phase 5: Update CONTEXT.md

Update `.s2s/CONTEXT.md`:
- Update phase from "specs" to "design"
- Add Technical Stack section with chosen technologies
- Update "Last updated" date

### Phase 6: Output Summary

    Architecture design complete!

    Documents created:
    - docs/architecture/README.md
    - docs/architecture/components.md
    - docs/architecture/deployment.md
    - docs/decisions/ARCH-*.md ({count} decisions)

    Tech Stack:
    {summary of chosen technologies}

    Project phase: design (ready for implementation)

    Next steps:

    Generate implementation plans:
      /s2s:plan

    Or create a specific plan:
      /s2s:plan:create "feature name"

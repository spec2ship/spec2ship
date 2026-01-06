---
description: Define functional requirements through a roundtable discussion. Reads CONTEXT.md and produces structured requirements.md.
allowed-tools: Bash(pwd:*), Bash(ls:*), Bash(mkdir:*), Bash(date:*), Read, Write, Edit, Glob, Task, AskUserQuestion
argument-hint: [--skip-roundtable] [--format srs|volere|simple] [--strategy standard|disney|consensus-driven] [--verbose] [--interactive]
skills: roundtable-execution, roundtable-strategies, iso25010-requirements
---

# Define Functional Requirements

## Context

- Current directory: !`pwd`
- Directory contents: !`ls -la`
- Current timestamp: !`date -u +"%Y-%m-%dT%H:%M:%SZ"`

## Interpret Context

Based on the context output above, determine:

- **S2S initialized**: If `.s2s` directory appears → "yes", otherwise → "NOT_S2S"

If S2S is initialized:
- Read `.s2s/CONTEXT.md` for project context
- Check if `docs/specifications/requirements.md` exists
- Read `.s2s/config.yaml` for roundtable settings

---

## Instructions

### Validate environment

If S2S initialized is "NOT_S2S":

    Error: Not an s2s project. Run /s2s:init first.

### Check prerequisites

Read `.s2s/CONTEXT.md` and verify it has been populated.

If CONTEXT.md contains placeholder text like "{Project description}":

    Error: Project context not defined.
    Run /s2s:init first to set up the project and gather context.

### Check for existing requirements

If `docs/specifications/requirements.md` exists and has content:
- Display summary of existing requirements
- Ask using AskUserQuestion: "Requirements exist. What would you like to do?"
  - Options: "Refine existing" / "Start fresh" / "Cancel"
- If cancel, stop
- If start fresh, backup existing file

### Parse arguments

Extract from $ARGUMENTS:
- **--skip-roundtable**: Skip discussion, generate from CONTEXT.md directly
- **--format**: Document format (srs|volere|simple). Default: srs
- **--strategy**: Override strategy for roundtable. Default: consensus-driven

**Boolean flags**: `--verbose` and `--interactive` → parse as `true` if present, `false` if absent.

### Reference Skills

For detailed requirement patterns, the `iso25010-requirements` skill provides:
- Quality characteristics (8 main categories, 31 sub-characteristics)
- NFR templates with measurable criteria
- Requirement ID conventions (FR-*, NFR-*)

### Display context summary

    Starting requirements definition...

    Project Context:
    ────────────────
    Overview: {from CONTEXT.md}
    Domain: {from CONTEXT.md}
    Scope: {from CONTEXT.md}

    Objectives:
    {list from CONTEXT.md}

    Constraints:
    {list from CONTEXT.md}

### Phase 1: Gather Requirements via Roundtable

If --skip-roundtable is NOT present:

**IMPORTANT: Follow the `roundtable-execution` skill instructions EXACTLY.**
**DO NOT use SlashCommand. Execute the roundtable inline using Task().**

#### Roundtable Configuration

Configure the roundtable with these parameters:
- **topic**: "Requirements definition for {project name}"
- **workflow_type**: "specs"
- **strategy**: {--strategy argument or "consensus-driven"}
- **output_type**: "requirements"
- **participants**: product-manager, business-analyst, qa-lead (from config)
- **verbose**: {verbose_flag}
- **interactive**: {interactive_flag}

#### Load Agenda

Read `skills/roundtable-execution/references/agenda-specs.md` and extract REQUIRED_TOPICS (4 topics: core-functional, nfr, acceptance-criteria, out-of-scope).

#### Execute Roundtable

**YOU MUST** execute the roundtable following `roundtable-execution` skill (PHASE 2-4) with these workflow-specific values:

| Parameter | Value |
|-----------|-------|
| session_id | `{timestamp}-requirements-{project-slug}` |
| workflow_type | `specs` |
| participants | `[product-manager, business-analyst, qa-lead]` |
| agenda | `REQUIRED_TOPICS` from agenda-specs.md |
| critical_topics | `core-functional`, `nfr` |

**CRITICAL REMINDERS** (pattern reinforcement):
- **Store participant responses** in `participant_responses` array after Step 3.2
- **Write session file per-round** using Write/Edit tool after Step 3.3
- **Display recap ALWAYS** after each round
- **If verbose=true**: Include full `responses[]` in session file round data
- **min_rounds CHECK**: Override "conclude" if round < 3
- **Agenda CHECK**: Override "conclude" if critical topics pending

After roundtable completes, extract from session file:
- Consensus points (these become requirements)
- Unresolved conflicts (flag for user review)
- Participant recommendations

**If --skip-roundtable IS present:**
- Analyze CONTEXT.md directly
- Infer requirements from objectives and scope
- Generate basic requirement list

### Phase 2: User Review

Present gathered requirements:

    Requirements gathered:

    Core Requirements (Must Have):
    ─────────────────────────────
    REQ-001: {title}
    {description}
    Priority: Must | Acceptance: {criteria}

    REQ-002: {title}
    ...

    Extended Requirements (Should/Could):
    ─────────────────────────────────────
    REQ-003: {title}
    ...

    Questions/Ambiguities:
    ──────────────────────
    - {from unresolved conflicts}

Ask using AskUserQuestion:
- "Review requirements. Would you like to:"
  - Options: "Approve and generate document" / "Refine" / "Add more"

If refine or add, gather input and update.

### Phase 3: Generate Requirements Document

Create `docs/specifications/requirements.md`:

**For SRS format (default):**

```markdown
# Software Requirements Specification

**Project**: {name}
**Version**: 1.0
**Date**: {date}
**Phase**: specs

## 1. Introduction

### 1.1 Purpose
{from CONTEXT.md}

### 1.2 Scope
{from CONTEXT.md}

### 1.3 Definitions
{domain terms}

## 2. Overall Description

### 2.1 Product Perspective
{from business domain}

### 2.2 Product Functions
{high-level summary}

### 2.3 Constraints
{from CONTEXT.md}

## 3. Functional Requirements

### 3.1 {Area 1}

#### REQ-001: {Title}
- **Description**: {user story}
- **Priority**: {Must/Should/Could/Won't}
- **Rationale**: {why needed}
- **Acceptance Criteria**:
  - [ ] {criterion 1}
  - [ ] {criterion 2}
- **Dependencies**: {REQ-xxx or None}

## 4. Non-Functional Requirements

{if mentioned in constraints}

## 5. Out of Scope

{explicit exclusions}

---
*Generated by Spec2Ship /s2s:specs*
*Roundtable participants: {list}*
```

### Phase 4: Update CONTEXT.md

Update `.s2s/CONTEXT.md`:
- Update phase to "specs"
- Add reference to requirements document
- Update "Last updated" date

### Phase 5: Output Summary

    Requirements defined successfully!

    Document: docs/specifications/requirements.md
    Format: {format}

    Summary:
    - Core requirements: {count}
    - Extended requirements: {count}
    - Out of scope: {count}

    Phase: specs

    Next steps:
      /s2s:design    - Design architecture
      /s2s:plan      - Generate implementation plans

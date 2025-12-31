---
description: Generate implementation plans. Smart behavior - reads from specs/architecture docs if available, otherwise prompts for topic.
allowed-tools: Bash(pwd:*), Bash(ls:*), Bash(mkdir:*), Bash(date:*), Bash(git:*), Read, Write, Edit, Glob, Task, AskUserQuestion, TodoWrite
argument-hint: [--component <name>] [--all] [--with-branches]
---

# Generate Implementation Plans

Smart command that generates implementation plans based on available documentation.

**Behavior:**
- If specs + architecture exist → analyzes docs and generates plans for work items
- If only CONTEXT.md exists → asks for topic and creates single plan
- Supports generating all plans at once or selecting specific items

## Context

- Current directory: !`pwd`
- Directory contents: !`ls -la`
- Current timestamp: !`date +"%Y%m%d-%H%M%S"`
- ISO timestamp: !`date -u +"%Y-%m-%dT%H:%M:%SZ"`

## Interpret Context

Based on the context output above, determine:

- **S2S initialized**: If `.s2s` directory appears in Directory contents → "yes", otherwise → "NOT_S2S"
- **Is git repo**: If `.git` directory appears in Directory contents → "yes", otherwise → "no"

If S2S is initialized, use Read tool to:
- Read `.s2s/CONTEXT.md` for project context and phase
- Read `docs/specifications/requirements.md` if exists
- Read `docs/architecture/README.md` and `docs/architecture/components.md` if exist
- List existing plans in `.s2s/plans/`

## Instructions

### Validate environment

If S2S initialized is "NOT_S2S", display this message and stop:

    Error: Not an s2s project. Run /s2s:init first.

### Determine Planning Mode

Based on available documentation:

**Full Documentation Mode** (specs + architecture exist):
- requirements.md has content
- architecture docs have content
- → Analyze docs and identify work items

**Basic Mode** (only CONTEXT.md):
- No requirements or architecture docs
- → Ask user for topic, create single plan
- Suggest: "For better planning, consider running /s2s:specs and /s2s:design first"

### Display Status

    Implementation Planning
    ═══════════════════════

    Project: {name}
    Phase: {phase from CONTEXT.md}

    Available inputs:
    ✓ Project context (.s2s/CONTEXT.md)
    {✓ or ✗} Requirements (docs/specifications/requirements.md)
    {✓ or ✗} Architecture (docs/architecture/)

    Mode: {Full Documentation | Basic}

### Parse arguments

Extract from $ARGUMENTS:
- **--component**: Generate plan for specific component only
- **--all**: Generate plans for all identified components/features
- **--with-branches**: Create git branches for each plan

---

## Full Documentation Mode

### Phase 1: Analyze and Identify Work Items

Analyze all available documentation to identify implementation work items:

```
Task(
  subagent_type="general-purpose",
  prompt="Analyze the project documentation and identify implementation work items.

Project Context:
{CONTEXT.md content}

Requirements:
{requirements.md content if available}

Architecture:
{architecture docs content if available}

Your task:
1. Identify distinct implementation units:
   - Features from requirements (user-facing functionality)
   - Components from architecture (system building blocks)
   - Infrastructure items (deployment, CI/CD, monitoring)

2. For each work item, determine:
   - ID: feature-{slug} or component-{slug} or infra-{slug}
   - Name: human-readable title
   - Type: feature | component | infrastructure
   - Description: what needs to be built
   - Dependencies: other work items that must be done first
   - Estimated complexity: small | medium | large
   - Requirements covered: list of REQ-xxx IDs
   - Architecture references: list of ARCH-xxx or component names

3. Order work items by:
   - Dependencies (items with no deps first)
   - Complexity (smaller items first when no dep constraints)
   - Priority (from requirements MoSCoW)

Return a structured list of work items ready for plan generation."
)
```

### Phase 2: Present Work Items

Display identified work items:

    Identified Work Items:
    ══════════════════════

    Features:
    ─────────
    1. feature-{slug}: {name}
       Complexity: {small|medium|large}
       Dependencies: {list or "none"}
       Requirements: {REQ-xxx list}

    2. feature-{slug}: {name}
       ...

    Components:
    ───────────
    1. component-{slug}: {name}
       Complexity: {small|medium|large}
       Dependencies: {list or "none"}

    Infrastructure:
    ───────────────
    1. infra-{slug}: {name}
       ...

    Suggested order: {ordered list of IDs}

### Phase 3: User Selection

If --all is NOT present and --component is NOT specified:

Ask user using AskUserQuestion:
- "Which items would you like to create plans for?"
  - Options: "All items" / "Select specific items" / "Just the first item"

If "Select specific items":
- Present numbered list
- Ask for selection

### Phase 4: Generate Plans

For each selected work item, generate a detailed implementation plan.

Jump to **Plan Generation** section below.

---

## Basic Mode

### Gather Topic

If no requirements/architecture docs:

Ask user using AskUserQuestion:
- "What would you like to plan?"
- Free text input

Display suggestion:

    Tip: For comprehensive planning with work item breakdown, run:
    1. /s2s:specs    - Define requirements
    2. /s2s:design   - Design architecture
    3. /s2s:plan     - Generate all plans

### Generate Single Plan

Use the topic to generate a plan.

Jump to **Plan Generation** section below.

---

## Plan Generation

For each work item or topic, generate a detailed implementation plan:

```
Task(
  subagent_type="general-purpose",
  prompt="Generate a detailed implementation plan for:

Work Item: {id or topic}
Name: {name}
Type: {type}
Description: {description}

Context:
{relevant sections from CONTEXT.md}

Requirements covered (if available):
{relevant requirements from requirements.md}

Architecture references (if available):
{relevant sections from architecture docs}

Dependencies:
{list of prerequisite work items}

Your task:
1. Break down the implementation into concrete tasks
2. Each task should be:
   - Specific and actionable
   - Completable in a reasonable session
   - Testable/verifiable

3. Include tasks for:
   - Setup/scaffolding (if first component)
   - Core implementation
   - Tests (unit, integration as appropriate)
   - Documentation updates
   - Integration with other components

4. Order tasks by implementation sequence

Return the plan in this format:
- Task list with checkboxes
- Acceptance criteria
- Testing approach
- Integration notes"
)
```

Write plan file `.s2s/plans/{timestamp}-{slug}.md`:

```markdown
# Implementation Plan: {Name}

**ID**: {timestamp}-{slug}
**Status**: planning
**Branch**: {branch-name if --with-branches, else N/A}
**Created**: {ISO timestamp}
**Updated**: {ISO timestamp}

## References

### Requirements
{list of REQ-xxx covered, or "N/A"}

### Architecture
{list of ARCH-xxx or component references, or "N/A"}

### Dependencies
{list of other plan IDs that must complete first, or "none"}

## Overview

{description of what this plan implements}

## Tasks

- [ ] {Task 1}
- [ ] {Task 2}
- [ ] {Task 3}
...

## Acceptance Criteria

- [ ] {criterion 1}
- [ ] {criterion 2}

## Testing Approach

{how to verify this implementation}

## Integration Notes

{how this connects to other components}

## Notes

<!-- Progress notes, blockers, decisions -->
```

### Create Git Branches (if --with-branches)

If --with-branches is present and "Is git repo" is "yes":

For each plan created:
1. Determine branch number from existing feature branches
2. Create branch: `git checkout -b feature/F{NN}-{slug}`
3. Checkout back to original branch
4. Update plan file with branch name

### Update State

Update `.s2s/state.yaml`:
- Add all new plans with status "planning"

Update `.s2s/CONTEXT.md`:
- Update phase to "plan"
- Update "Last updated" date

### Output Summary

    Implementation plans created!

    Plans generated: {count}
    ─────────────────────────

    {for each plan}
    • {plan-id}
      Topic: {name}
      Tasks: {count}
      Branch: {branch or "N/A"}

    Suggested execution order:
    1. {first plan id} - {name}
    2. {second plan id} - {name}
    ...

    Next steps:

    Start working on the first plan:
      /s2s:plan:start "{first-plan-id}"

    View all plans:
      /s2s:plan:list

    Create a quick ad-hoc plan:
      /s2s:plan:create "topic"

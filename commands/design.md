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

---

## Phase 1: Session Setup

If --skip-roundtable is NOT present:

### Step 1.1: Generate Session ID

```
{YYYYMMDD}-design-{project-slug}
Example: 20260107-design-elfgiftrush
```

### Step 1.2: Create Session Folder Structure

**YOU MUST use Bash tool NOW**:
```bash
mkdir -p .s2s/sessions/{session-id}
```

If verbose_flag is true:
```bash
mkdir -p .s2s/sessions/{session-id}/rounds
```

### Step 1.3: Create Snapshot Files

**YOU MUST use Write tool NOW** to create `context-snapshot.yaml`:

Read `.s2s/CONTEXT.md` and `docs/specifications/requirements.md`, then write:
```yaml
# Captured: {ISO timestamp}
source: ".s2s/CONTEXT.md"

project_name: "{extracted}"
description: "{extracted}"
objectives: [...]
constraints: [...]

# Key requirements summary (from requirements.md)
requirements_summary:
  core: ["{REQ-001}: {title}", ...]
  nfr: ["{NFR-001}: {title}", ...]
```

**YOU MUST use Write tool NOW** to create `config-snapshot.yaml`:
```yaml
# Captured: {ISO timestamp}
source: ".s2s/config.yaml"

verbose: {verbose_flag}
interactive: {interactive_flag}
strategy: "{strategy or debate}"
limits:
  min_rounds: 3
  max_rounds: 20
escalation:
  max_rounds_per_conflict: 3
  confidence_below: 0.5
  critical_keywords: ["security", "must-have", "blocking", "legal"]
participants:
  - "software-architect"
  - "technical-lead"
  - "devops-engineer"
```

**YOU MUST use Write tool NOW** to create `agenda.yaml`:

Read `skills/roundtable-execution/references/agenda-design.md` and extract topics YAML.

### Step 1.4: Create Session Index File

**YOU MUST use Write tool NOW** to create `.s2s/sessions/{session-id}.yaml`:

```yaml
id: "{session-id}"
topic: "Architecture design for {project name}"
workflow_type: "design"
strategy: "{strategy}"
status: "active"

timing:
  started: "{ISO timestamp}"
  completed: null
  duration_ms: null

artifacts:
  decisions: []
  components: []
  conflicts: []
  open_questions: []

agenda:
  - topic_id: "high-level-arch"
    status: "open"
    coverage: []
  - topic_id: "components"
    status: "open"
    coverage: []
  - topic_id: "data-flow"
    status: "open"
    coverage: []
  - topic_id: "tech-choices"
    status: "open"
    coverage: []
  - topic_id: "integration"
    status: "open"
    coverage: []

rounds: []

metrics:
  rounds: 0
  tasks: 0
  tokens: 0
```

### Step 1.5: Update State File

**YOU MUST use Edit tool NOW** to update `.s2s/state.yaml`:
```yaml
current_session: "{session-id}"
```

---

## Phase 2: Round Execution Loop

**Follow the `roundtable-execution` skill instructions EXACTLY.**

Initialize:
- `round_number = 0`
- `session_folder = ".s2s/sessions/{session-id}/"`

### Round Loop (repeat until conclusion)

#### Step 2.2: Facilitator Question

**YOU MUST use Task tool NOW** to call facilitator:

```yaml
subagent_type: "general-purpose"
prompt: |
  You are the Roundtable Facilitator.
  Read your agent definition from: agents/roundtable/facilitator.md

  === SESSION STATE ===
  Round: {round_number + 1}
  Session folder: {session_folder}

  === ARTIFACT SUMMARY ===
  Decisions: {list IDs}
  Components: {list IDs}
  Conflicts: {list IDs}
  Open questions: {list IDs}

  === AGENDA STATUS ===
  {for each topic}
  [{status}] {topic_id} (CRITICAL if critical)
  {/for}

  === PREVIOUS ROUND ===
  {synthesis from last round or "First round"}

  === ESCALATION CONFIG ===
  min_rounds: 3
  max_rounds: 20
  max_rounds_per_conflict: 3
  confidence_below: 0.5

  CONSTRAINT: Cannot conclude before round 3 (min_rounds enforcement)

  === YOUR TASK ===
  1. DECIDE focus for this round
  2. SELECT context files for participants
  3. GENERATE question + exploration prompt
  4. Include constraints_check in synthesis output (MANDATORY)
```

**IF verbose_flag == true**: Write dump file.

#### Step 2.3: Participant Responses

**YOU MUST launch ALL participant Tasks in SINGLE message**:

For each of: software-architect, technical-lead, devops-engineer

```yaml
subagent_type: "general-purpose"
prompt: |
  You are the {Role} in a roundtable discussion.
  Read your agent definition from: agents/roundtable/{participant-id}.md

  === CONTEXT FILES ===
  Read these files (DO NOT read other session files):
  {for each file in facilitator's context_files}
  - {session_folder}/{file}
  {/for}

  === QUESTION ===
  {facilitator's question}

  === EXPLORATION ===
  {facilitator's exploration prompt}

  === YOUR RESPONSE FORMAT ===
  Return YAML with position, rationale, confidence, concerns, suggestions.
```

**IF verbose_flag == true**: Write dump for each participant.

#### Step 2.4: Facilitator Synthesis

**YOU MUST use Task tool NOW** for synthesis.

**IF verbose_flag == true**: Write dump file.

#### Step 2.5: Process Artifacts

For each `proposed_artifact`:
- Architecture decisions: `ARCH-{NNN}.yaml`
- Component definitions: `COMP-{NNN}.yaml`
- Conflicts: `CONF-{NNN}.yaml`
- Open questions: `OQ-{NNN}.yaml`

#### Step 2.6: Update Session File

**YOU MUST use Edit tool NOW** to append round and update metrics.

#### Step 2.7: Display Round Recap

Show synthesis, new artifacts, resolved conflicts, agenda status.

#### Step 2.8: Handle Interactive Mode

**IF interactive_flag == true**: Ask user to continue, skip, or pause.
**IF interactive_flag == false**: Proceed automatically.

#### Step 2.9: Evaluate Next Action (CRITICAL)

**MANDATORY min_rounds enforcement:**

```
IF round_number < min_rounds (default: 3) AND next == "conclude":
  OVERRIDE next to "continue"
  Display: "⚠️ min_rounds not reached ({round_number}/{min_rounds}), continuing..."
```

Then evaluate based on `next`:
- **continue**: Loop back to Step 2.1
- **conclude**: Proceed to Phase 3
- **escalate**: Ask user with AskUserQuestion, then continue or conclude

---

## Phase 3: Completion

### Step 3.1: Update Session Status

**YOU MUST use Edit tool NOW** to update session file.

### Step 3.2: Clear State

**YOU MUST use Edit tool NOW** to clear current_session.

### Step 3.3: Read Session for Summary

**YOU MUST use Read tool** to read session file and artifact files.

### Step 3.4: User Review

Present architecture decisions:

    Architecture Design Summary:
    ═══════════════════════════

    System Overview:
    {high-level description}

    Components:
    ───────────
    {for each COMP-* artifact}
    - {ID}: {title} - {responsibility}
    {/for}

    Key Decisions:
    ──────────────
    {for each ARCH-* artifact}
    {ID}: {title}
    Decision: {decision}
    Rationale: {rationale}
    {/for}

    Tech Stack:
    ───────────
    - Backend: {choice}
    - Frontend: {choice}
    - Database: {choice}

    Open Questions:
    ───────────────
    {list OQ-* artifacts}

Ask using AskUserQuestion:
- "Review architecture. Would you like to:"
  - Options: "Approve and generate docs" / "Refine decisions" / "Discuss specific area"

### Step 3.5: Generate Architecture Documentation

Create/update documents:

**docs/architecture/README.md:**
```markdown
# Architecture Overview

**Project**: {name}
**Version**: 1.0
**Date**: {date}

## System Context

{high-level description}

## Architecture Principles

{from ARCH-* artifacts where type=principle}

## Component Overview

| Component | Responsibility | Technology |
|-----------|---------------|------------|
{for each COMP-* artifact}
| {title} | {description} | {tech} |
{/for}

## Key Decisions

See individual ADRs in `/docs/decisions/`

---
*Generated by Spec2Ship /s2s:design*
*Session: {session-id}*
```

**docs/architecture/components.md:**
```markdown
# Component Design

{for each COMP-* artifact}
## {title}

### Responsibility
{description}

### Interfaces
{interfaces}

### Dependencies
{dependencies}

### Technology
{technology}
{/for}
```

### Step 3.6: Generate ADRs

For each ARCH-* artifact, create `docs/decisions/ARCH-{NNN}-{slug}.md`:

```markdown
# {ID}: {title}

**Status**: accepted
**Date**: {date}
**Participants**: software-architect, technical-lead, devops-engineer

## Context
{context from artifact}

## Decision
{decision from artifact}

## Options Considered

{for each option in artifact}
### {option.name}
- Pros: {option.pros}
- Cons: {option.cons}
{/for}

## Consequences

### Positive
{positive consequences}

### Negative
{negative consequences}
```

### Step 3.7: Update CONTEXT.md

Update `.s2s/CONTEXT.md`:
- Update phase to "design"
- Add Technical Stack section
- Update "Last updated" date

### Step 3.8: Output Summary

    Architecture design complete!

    Documents created:
    - docs/architecture/README.md
    - docs/architecture/components.md
    - docs/decisions/ARCH-*.md ({count} decisions)

    Tech Stack:
    {summary}

    Session folder: .s2s/sessions/{session-id}/

    Next steps:
      /s2s:plan              - Generate implementation plans
      /s2s:plan:create "x"   - Create specific plan

---

## Skip Roundtable Mode

**If --skip-roundtable IS present:**

1. Analyze requirements directly
2. Generate basic architecture from patterns
3. Ask user for technology preferences
4. Skip session folder creation

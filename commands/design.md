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
  min_rounds: {from config: roundtable.limits.min_rounds, default: 3}
  max_rounds: {from config: roundtable.limits.max_rounds, default: 20}
escalation:
  max_rounds_per_conflict: {from config: roundtable.escalation.triggers.max_rounds_per_conflict, default: 3}
  confidence_below: {from config: roundtable.escalation.triggers.confidence_below, default: 0.5}
  critical_keywords: {from config: roundtable.escalation.triggers.critical_keywords, default: ["security", "must-have", "blocking", "legal"]}
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

**Use the roundtable-facilitator agent** with this input:

```yaml
action: "question"
round: {round_number + 1}
topic: "Architecture design for {project name}"
strategy: "{strategy from config, e.g. debate}"
phase: "design"
workflow_type: "design"

escalation_config:
  min_rounds: {from config-snapshot.yaml: limits.min_rounds}
  max_rounds: {from config-snapshot.yaml: limits.max_rounds}
  max_rounds_per_conflict: {from config-snapshot.yaml: escalation.max_rounds_per_conflict}
  confidence_below: {from config-snapshot.yaml: escalation.confidence_below}

# Project context (from context-snapshot.yaml)
project_context:
  name: "{project name}"
  description: "{project description}"
  domain: "{domain}"
  tech_stack: ["{tech}"]
  constraints: ["{constraint}"]
  requirements_summary:
    core: ["{REQ-001}: {title}", ...]
    nfr: ["{NFR-001}: {title}", ...]

# Current session state (from session file)
session_state:
  artifacts:
    decisions: [{id, title, status, description, ...}]
    components: [{id, title, status, description, ...}]
    conflicts: [{id, title, status, positions, ...}]
    open_questions: [{id, title, status, description, ...}]
  rounds:
    - round: 1
      focus: "{topic_id}"
      synthesis: "{synthesis text}"
    # ... previous rounds

agenda:
  - id: "high-level-arch"
    title: "High-Level Architecture"
    status: "{open|partial|closed}"
    priority: "critical"
    done_when:
      criteria:
        - "System boundaries defined"
        - "External interfaces identified"
      min_requirements: 2
  # ... more topics from agenda.yaml

participants:
  - "software-architect"
  - "technical-lead"
  - "devops-engineer"
```

The facilitator will return:
```yaml
action: "question"
decision:
  focus_type: "{agenda|conflict|open_question}"
  topic_id: "{topic}"
  rationale: "{reason}"
question: "{the question}"
exploration: "{exploration prompt}"
participants: "all"

# Context for participants (they have NO tools)
participant_context:
  shared:
    project_summary: |
      {condensed project info + requirements}
    relevant_artifacts:
      - id: "ARCH-001"
        title: "..."
        # full artifact content
    open_conflicts: [...]
    open_questions: [...]
    recent_rounds:
      - round: 1
        synthesis: "..."
  overrides: null  # or per-participant directives for debate
```

**IF verbose_flag == true**: Write dump to `rounds/{NNN}-01-facilitator-question.yaml`:
```yaml
# Round {N} - Facilitator Question
round: {N}
phase: 1
actor: "facilitator"
action: "question"
started: "{ISO timestamp}"
completed: "{ISO timestamp}"

input: {... the YAML input sent to facilitator ...}

response:
  decision: {focus_type, topic_id, rationale}
  question: "{question}"
  exploration: "{exploration}"
  participant_context:
    shared: {... project_summary, relevant_artifacts, etc ...}
    overrides: {... or null ...}

result:
  status: "completed"

tokens:
  input_estimate: {N}
  output_estimate: {N}
```

#### Step 2.3: Participant Responses

**Launch ALL participant agents in SINGLE message** (parallel execution):

For each of: software-architect, technical-lead, devops-engineer

**Build participant input** by merging:
1. `participant_context.shared` (common to all)
2. `participant_context.overrides[participant-id]` (if present)

**Use the roundtable-{participant-id} agent** with this input:

```yaml
round: {round_number + 1}
topic: "Architecture design for {project name}"
phase: "design"
workflow_type: "design"

question: "{facilitator's question}"

exploration: "{facilitator's exploration prompt}"

# Optional: Include if present in overrides[participant-id]
# facilitator_directive: |
#   {from participant_context.overrides[participant-id].facilitator_directive}

# ALL context inline (participants have NO tools)
context:
  project_summary: |
    {from participant_context.shared.project_summary}

  relevant_artifacts:
    - id: "ARCH-001"
      title: "..."
      status: "consensus"
      description: "..."
      # {from participant_context.shared.relevant_artifacts}

  open_conflicts:
    # {from participant_context.shared.open_conflicts}

  open_questions:
    # {from participant_context.shared.open_questions}

  recent_rounds:
    - round: 1
      synthesis: "..."
    # {from participant_context.shared.recent_rounds}
```

Each participant will return:
```yaml
participant: "{participant-id}"

position: |
  {2-3 sentence position statement}

rationale:
  - "{reason}"

trade_offs:
  optimizing_for: "{priority}"
  accepting_as_cost: "{trade-off}"
  risks:
    - "{risk}"

concerns:
  - "{concern}"

suggestions:
  - "{suggestion}"

confidence: 0.85

references:
  - "{reference}"
```

**IF verbose_flag == true**: Write dump for each participant to `rounds/{NNN}-02-{participant-id}.yaml`:
```yaml
# Round {N} - {Role} Response
round: {N}
phase: 2
actor: "{participant-id}"
action: "response"
started: "{ISO timestamp}"
completed: "{ISO timestamp}"

input: {... the YAML input sent to participant ...}

response:
  participant: "{participant-id}"
  position: "{full response}"
  rationale: [...]
  confidence: {0.0-1.0}
  concerns: [...]
  suggestions: [...]

result:
  status: "completed"

tokens:
  input_estimate: {N}
  output_estimate: {N}
```

#### Step 2.4: Facilitator Synthesis

**Use the roundtable-facilitator agent** with this input:

```yaml
action: "synthesis"
round: {round_number + 1}
topic: "Architecture design for {project name}"
strategy: "{strategy}"
phase: "design"

escalation_config:
  min_rounds: {from config-snapshot.yaml: limits.min_rounds}
  max_rounds: {from config-snapshot.yaml: limits.max_rounds}
  max_rounds_per_conflict: {from config-snapshot.yaml: escalation.max_rounds_per_conflict}
  confidence_below: {from config-snapshot.yaml: escalation.confidence_below}

question_asked: "{facilitator's question from step 2.2}"

responses:
  software-architect:
    position: "{position}"
    rationale: [...]
    concerns: [...]
    suggestions: [...]
    confidence: 0.85
  technical-lead:
    position: "{position}"
    rationale: [...]
    concerns: [...]
    suggestions: [...]
    confidence: 0.8
  devops-engineer:
    position: "{position}"
    rationale: [...]
    concerns: [...]
    suggestions: [...]
    confidence: 0.75

full_agenda:
  - id: "high-level-arch"
    status: "{open|partial|closed}"
    priority: "critical"
  - id: "components"
    status: "{open|partial|closed}"
    priority: "critical"
  - id: "data-flow"
    status: "{open|partial|closed}"
    priority: "normal"
  - id: "tech-choices"
    status: "{open|partial|closed}"
    priority: "normal"
  - id: "integration"
    status: "{open|partial|closed}"
    priority: "normal"
  # NOTE: Include ALL topics with CURRENT status from session file

focus_topic:
  id: "{topic from step 2.2}"
  done_when:
    criteria: [...]
    min_requirements: {N}

open_conflicts: []
artifacts_count: {current count}
```

The facilitator will return:
```yaml
action: "synthesis"

synthesis: "{2-4 sentence summary}"

proposed_artifacts:
  - type: "decision"
    title: "{title}"
    status: "consensus"
    topic_id: "{topic}"
    description: "..."
    options: [...]
    rationale: "..."

resolved_conflicts: []

agenda_update:
  topic_id: "{topic}"
  new_status: "{partial|closed}"
  coverage_added: [...]
  remaining_for_closure: [...]

constraints_check:
  rounds_completed: {N}
  min_rounds: {from config-snapshot.yaml: limits.min_rounds}
  can_conclude: {true|false}
  reason: "{reason}"

next: "{continue|conclude|escalate}"

next_focus:
  type: "{agenda|conflict|open_question}"
  topic_id: "{topic}"
  reason: "{reason}"

escalation_reason: null
```

**IF verbose_flag == true**: Write dump to `rounds/{NNN}-03-facilitator-synthesis.yaml`:
```yaml
# Round {N} - Facilitator Synthesis
round: {N}
phase: 3
actor: "facilitator"
action: "synthesis"
started: "{ISO timestamp}"
completed: "{ISO timestamp}"

input: {... the YAML input sent to facilitator ...}

response:
  synthesis: "{summary}"
  proposed_artifacts: [...]
  resolved_conflicts: [...]
  agenda_update: {...}
  constraints_check: {rounds_completed, min_rounds, can_conclude, reason}
  next: "{continue|conclude|escalate}"

result:
  artifacts_proposed: {count}
  status: "completed"

tokens:
  input_estimate: {N}
  output_estimate: {N}
```

#### Step 2.5: Process Artifacts

For each `proposed_artifact`:
- Architecture decisions: `ARCH-{NNN}.yaml`
- Component definitions: `COMP-{NNN}.yaml`
- Conflicts: `CONF-{NNN}.yaml`
- Open questions: `OQ-{NNN}.yaml`

#### Step 2.6: Update Session File

**YOU MUST use Edit tool NOW** to update session file with:

1. **Append round** to `rounds:` array:
```yaml
rounds:
  - round: {N}
    topic: "{focus topic_id}"
    timestamp: "{ISO timestamp}"
    artifacts_created: ["{ID}", ...]
    consensus_reached: {true|false}
    next_action: "{continue|conclude|escalate}"
```

2. **Update agenda status** from facilitator's `agenda_update`:
```yaml
agenda:
  - topic_id: "{agenda_update.topic_id}"
    status: "{agenda_update.new_status}"  # open → partial → complete
    coverage:
      - "{existing coverage}"
      - "{agenda_update.coverage_added}"  # append new items
```

3. **Update metrics**:
```yaml
metrics:
  rounds: {increment}
  tasks: {increment by participant count + 2}
```

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

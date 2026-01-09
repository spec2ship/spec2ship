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

---

## Phase 1: Session Setup

If --skip-roundtable is NOT present:

### Step 1.1: Generate Session ID

```
{YYYYMMDD}-specs-{project-slug}
Example: 20260107-specs-elfgiftrush
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

Read `.s2s/CONTEXT.md` and extract content, then write:
```yaml
# Captured: {ISO timestamp}
source: ".s2s/CONTEXT.md"

project_name: "{extracted}"
description: "{extracted}"
objectives:
  - "{extracted}"
constraints:
  - "{extracted}"
scope:
  in:
    - "{extracted}"
  out:
    - "{extracted}"
```

**YOU MUST use Write tool NOW** to create `config-snapshot.yaml`:

Read `.s2s/config.yaml` and extract roundtable config, then write:
```yaml
# Captured: {ISO timestamp}
source: ".s2s/config.yaml"

verbose: {verbose_flag}
interactive: {interactive_flag}
strategy: "{strategy or consensus-driven}"
limits:
  min_rounds: {from config: roundtable.limits.min_rounds, default: 3}
  max_rounds: {from config: roundtable.limits.max_rounds, default: 20}
escalation:
  max_rounds_per_conflict: {from config: roundtable.escalation.triggers.max_rounds_per_conflict, default: 3}
  confidence_below: {from config: roundtable.escalation.triggers.confidence_below, default: 0.5}
  critical_keywords: {from config: roundtable.escalation.triggers.critical_keywords, default: ["security", "must-have", "blocking", "legal"]}
participants:
  - "product-manager"
  - "business-analyst"
  - "qa-lead"
```

**YOU MUST use Write tool NOW** to create `agenda.yaml`:

Read `skills/roundtable-execution/references/agenda-specs.md` and extract topics YAML, then write:
```yaml
# Captured: {ISO timestamp}
source: "skills/roundtable-execution/references/agenda-specs.md"
workflow: "specs"

topics:
  - id: "user-workflows"
    name: "User workflows"
    critical: true
    done_when:
      criteria:
        - "Primary user personas identified"
        - "Entry/exit conditions defined"
        - "Happy path documented"
      min_requirements: 2
    exploration: "Are there other workflows we should consider?"
  # ... (copy all topics from agenda-specs.md)
```

### Step 1.4: Create Session Index File

**YOU MUST use Write tool NOW** to create `.s2s/sessions/{session-id}.yaml`:

```yaml
id: "{session-id}"
topic: "Requirements definition for {project name}"
workflow_type: "specs"
strategy: "{strategy}"
status: "active"

timing:
  started: "{ISO timestamp}"
  completed: null
  duration_ms: null

artifacts:
  requirements: []
  business_rules: []
  conflicts: []
  open_questions: []
  exclusions: []

agenda:
  - topic_id: "user-workflows"
    status: "open"
    coverage: []
  - topic_id: "functional-requirements"
    status: "open"
    coverage: []
  - topic_id: "business-rules"
    status: "open"
    coverage: []
  - topic_id: "nfr-measurable"
    status: "open"
    coverage: []
  - topic_id: "acceptance-criteria"
    status: "open"
    coverage: []
  - topic_id: "out-of-scope"
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

#### Step 2.1: Display Round Start

Display agenda status and artifact counts.

#### Step 2.2: Facilitator Question

**Use the roundtable-facilitator agent** with this input:

```yaml
action: "question"
round: {round_number + 1}
topic: "Requirements definition for {project name}"
strategy: "{strategy from config, e.g. consensus-driven}"
phase: "requirements"
workflow_type: "specs"

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

# Current session state (from session file)
session_state:
  artifacts:
    requirements: [{id, title, status, description, ...}]
    conflicts: [{id, title, status, positions, ...}]
    open_questions: [{id, title, status, description, ...}]
  rounds:
    - round: 1
      focus: "{topic_id}"
      synthesis: "{synthesis text}"
    # ... previous rounds

agenda:
  - id: "user-workflows"
    title: "User Workflows"
    status: "{open|partial|closed}"
    priority: "critical"
    done_when:
      criteria:
        - "Primary user personas identified"
        - "Entry/exit conditions defined"
      min_requirements: 2
  # ... more topics from agenda.yaml

participants:
  - "product-manager"
  - "business-analyst"
  - "qa-lead"
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
      {condensed project info}
    relevant_artifacts:
      - id: "REQ-001"
        title: "..."
        # full artifact content
    open_conflicts: [...]
    open_questions: [...]
    recent_rounds:
      - round: 1
        synthesis: "..."
  overrides: null  # or per-participant directives for debate/six-hats
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
  decision:
    focus_type: "{agenda|conflict|open_question}"
    topic_id: "{topic}"
    rationale: "{reason}"
  question: "{the question}"
  exploration: "{exploration prompt}"
  participant_context:
    shared: {... project_summary, relevant_artifacts, etc ...}
    overrides: {... or null ...}
  participants: "{all or list}"

result:
  status: "completed"

tokens:
  input_estimate: {estimated input tokens}
  output_estimate: {estimated output tokens}
```

#### Step 2.3: Participant Responses

**Launch ALL participant agents in SINGLE message** (parallel execution):

For each of: product-manager, business-analyst, qa-lead

**Build participant input** by merging:
1. `participant_context.shared` (common to all)
2. `participant_context.overrides[participant-id]` (if present)

**Use the roundtable-{participant-id} agent** with this input:

```yaml
round: {round_number + 1}
topic: "Requirements definition for {project name}"
phase: "requirements"
workflow_type: "specs"

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
    - id: "REQ-001"
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

**Store responses** for synthesis and verbose dump.

**IF verbose_flag == true**: Write dump for each participant to `rounds/{NNN}-02-{participant-id}.yaml`:
```yaml
# Round {N} - {Participant Role} Response
round: {N}
phase: 2
actor: "{participant-id}"
action: "response"
started: "{ISO timestamp}"
completed: "{ISO timestamp}"

input: {... the YAML input sent to participant ...}

response:
  participant: "{participant-id}"
  position: "{position}"
  rationale: [...]
  confidence: {0.0-1.0}
  concerns: [...]
  suggestions: [...]

result:
  status: "completed"

tokens:
  input_estimate: {estimated input tokens}
  output_estimate: {estimated output tokens}
```

#### Step 2.4: Facilitator Synthesis

**Use the roundtable-facilitator agent** with this input:

```yaml
action: "synthesis"
round: {round_number + 1}
topic: "Requirements definition for {project name}"
strategy: "{strategy}"
phase: "requirements"

escalation_config:
  min_rounds: {from config-snapshot.yaml: limits.min_rounds}
  max_rounds: {from config-snapshot.yaml: limits.max_rounds}
  max_rounds_per_conflict: {from config-snapshot.yaml: escalation.max_rounds_per_conflict}
  confidence_below: {from config-snapshot.yaml: escalation.confidence_below}

question_asked: "{facilitator's question from step 2.2}"

responses:
  product-manager:
    position: "{position}"
    rationale: [...]
    concerns: [...]
    suggestions: [...]
    confidence: 0.85
  business-analyst:
    position: "{position}"
    rationale: [...]
    concerns: [...]
    suggestions: [...]
    confidence: 0.8
  qa-lead:
    position: "{position}"
    rationale: [...]
    concerns: [...]
    suggestions: [...]
    confidence: 0.75

full_agenda:
  - id: "user-workflows"
    status: "{open|partial|closed}"
    priority: "critical"
  - id: "functional-requirements"
    status: "{open|partial|closed}"
    priority: "critical"
  - id: "business-rules"
    status: "{open|partial|closed}"
    priority: "normal"
  - id: "nfr-measurable"
    status: "{open|partial|closed}"
    priority: "normal"
  - id: "acceptance-criteria"
    status: "{open|partial|closed}"
    priority: "critical"
  - id: "out-of-scope"
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
  - type: "requirement"
    title: "{title}"
    status: "consensus"
    topic_id: "{topic}"
    description: "..."
    acceptance: [...]
    priority: "must"

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
  synthesis: "{2-4 sentence summary}"
  proposed_artifacts: [...]
  resolved_conflicts: [...]
  agenda_update: {...}
  constraints_check: {...}
  next: "{continue|conclude|escalate}"
  next_focus: {...}

result:
  artifacts_proposed: {count}
  conflicts_resolved: {count}
  status: "completed"

tokens:
  input_estimate: {estimated input tokens}
  output_estimate: {estimated output tokens}
```

#### Step 2.5: Process Artifacts

For each `proposed_artifact` from facilitator:

1. **Count existing**: Read session file registry
2. **Assign ID**: Next available (REQ-001, REQ-002, etc.)
3. **Write artifact file**: `{session_folder}/{ID}.yaml`
4. **Update registry**: Add ID to appropriate list in session file

For each `resolved_conflict`:
1. **Read conflict file**: `{session_folder}/{conflict_id}.yaml`
2. **Update with resolution**: Add resolved_round, resolution fields
3. **Write updated file**

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

#### Step 2.9: Evaluate Next Action

- If `round_number < 3` AND `next == "conclude"`: Override to "continue"
- Based on `next`: continue loop, conclude, or handle escalation

---

## Phase 3: Completion

### Step 3.1: Update Session Status

**YOU MUST use Edit tool NOW** to update session file:
```yaml
status: "completed"
timing:
  completed: "{ISO timestamp}"
  duration_ms: {calculated}
```

### Step 3.2: Clear State

**YOU MUST use Edit tool NOW** to set `current_session: null` in `.s2s/state.yaml`.

### Step 3.3: Read Session for Summary

**YOU MUST use Read tool** to read the completed session file.

Extract from session file (Single Source of Truth):
- All artifact IDs from registry
- Read each artifact file for content
- Aggregate by status (consensus, conflict, draft)

### Step 3.4: User Review

Present gathered requirements:

    Requirements gathered:

    Core Requirements (Must Have):
    ─────────────────────────────
    {for each REQ where priority=must}
    {ID}: {title}
    {description}
    Priority: Must | Acceptance: {criteria}
    {/for}

    Extended Requirements (Should/Could):
    {for each REQ where priority != must}
    ...
    {/for}

    Open Questions:
    {list OQ-* artifacts}

Ask using AskUserQuestion:
- "Review requirements. Would you like to:"
  - Options: "Approve and generate document" / "Refine" / "Add more"

### Step 3.5: Generate Requirements Document

Create `docs/specifications/requirements.md` reading from artifact files:

**For SRS format (default):**

```markdown
# Software Requirements Specification

**Project**: {from context-snapshot.yaml}
**Version**: 1.0
**Date**: {date}

## 1. Introduction

### 1.1 Purpose
{from context-snapshot.yaml}

### 1.2 Scope
{from context-snapshot.yaml}

## 2. Functional Requirements

{for each REQ-* artifact file}
### {ID}: {title}
- **Description**: {description}
- **Priority**: {priority}
- **Acceptance Criteria**:
  {for each criterion}
  - [ ] {criterion}
  {/for}
{/for}

## 3. Business Rules

{for each BR-* artifact file}
### {ID}: {title}
{description}
{/for}

## 4. Non-Functional Requirements

{for each NFR-* artifact file}
### {ID}: {title}
- **Target**: {target}
- **Minimum**: {minimum}
{/for}

## 5. Out of Scope

{for each EX-* artifact file}
- **{ID}**: {title} - {rationale}
{/for}

---
*Generated by Spec2Ship /s2s:specs*
*Session: {session-id}*
```

### Step 3.6: Update CONTEXT.md

Update `.s2s/CONTEXT.md`:
- Update phase to "specs"
- Add reference to requirements document
- Update "Last updated" date

### Step 3.7: Output Summary

    Requirements defined successfully!

    Document: docs/specifications/requirements.md
    Format: {format}

    Summary:
    - Core requirements: {count}
    - Extended requirements: {count}
    - Business rules: {count}
    - Out of scope: {count}

    Session folder: .s2s/sessions/{session-id}/

    Next steps:
      /s2s:design    - Design architecture
      /s2s:plan      - Generate implementation plans

---

## Skip Roundtable Mode

**If --skip-roundtable IS present:**

1. Read CONTEXT.md directly
2. Infer requirements from objectives and scope
3. Generate basic requirement list without discussion
4. Skip session folder creation
5. Proceed to document generation

---
description: Creative brainstorming session using the Disney strategy (Dreamer → Realist → Critic). Use for ideation and exploring new ideas without constraints.
allowed-tools: Bash(pwd:*), Bash(ls:*), Bash(mkdir:*), Bash(date:*), Read, Write, Edit, Glob, Task, AskUserQuestion
argument-hint: "topic" [--participants <list>] [--verbose] [--interactive]
skills: roundtable-execution, roundtable-strategies
---

# Brainstorm Session

Launches a creative brainstorming roundtable using the **Disney strategy** (Dreamer → Realist → Critic).

This strategy separates creative thinking from critical evaluation:
1. **Dreamer phase**: Think big, no constraints, what would be ideal?
2. **Realist phase**: What's feasible? How would we implement this?
3. **Critic phase**: What could go wrong? What risks should we address?

## Context

- Current directory: !`pwd`
- Directory contents: !`ls -la`
- Timestamp: !`date +"%Y%m%d-%H%M%S"`

---

## Interpret Context

Based on the Directory contents output, determine:

- **S2S initialized**: If `.s2s` directory appears → "yes", otherwise → "no"
- **Directory name**: Extract the last segment from pwd

---

## Instructions

### Parse Arguments

Extract from $ARGUMENTS:
- **topic**: Required. The subject for brainstorming (first quoted argument)
- **--participants**: Optional. Comma-separated list to override defaults

**Boolean flags**: `--verbose` and `--interactive` → parse as `true` if present, `false` if absent.

If topic is missing, ask using AskUserQuestion:
- "What would you like to brainstorm?"

### Validate Environment

If S2S initialized is "no":
- Display: "Warning: Not an s2s project. Results displayed but not saved to project structure."
- Continue anyway (brainstorm can work without full s2s setup)

### Determine Participants

Default participants for brainstorming:
- product-manager (user needs, business value)
- software-architect (structure, patterns)
- technical-lead (implementation, feasibility)
- devops-engineer (operations, deployment)

If --participants specified, use that list instead.

### Display Introduction

    Brainstorm Session Starting
    ═══════════════════════════

    Topic: {topic}
    Strategy: Disney (Dreamer → Realist → Critic)
    Participants: {list}

    Phase 1 (Dreamer): Think BIG, no constraints!
    Phase 2 (Realist): What's feasible? How to implement?
    Phase 3 (Critic): What could go wrong? What risks?

    Starting discussion...

---

## Phase 1: Session Setup

### Step 1.1: Generate Session ID

```
{YYYYMMDD}-brainstorm-{topic-slug}
Example: 20260107-brainstorm-mobile-app-idea
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

If S2S initialized, read `.s2s/CONTEXT.md`. Otherwise, create minimal context:
```yaml
# Captured: {ISO timestamp}
source: "{.s2s/CONTEXT.md or 'user-provided'}"

project_name: "{from CONTEXT.md or directory name}"
description: "{from CONTEXT.md or topic}"
brainstorm_topic: "{topic}"
```

**YOU MUST use Write tool NOW** to create `config-snapshot.yaml`:
```yaml
# Captured: {ISO timestamp}
source: ".s2s/config.yaml"

verbose: {verbose_flag}
interactive: {interactive_flag}
strategy: "disney"
limits:
  min_rounds: {from config: roundtable.limits.min_rounds, default: 3}
  max_rounds: {from config: roundtable.limits.max_rounds, default: 20}
escalation:
  max_rounds_per_conflict: {from config: roundtable.escalation.triggers.max_rounds_per_conflict, default: 3}
  confidence_below: {from config: roundtable.escalation.triggers.confidence_below, default: 0.5}
  critical_keywords: {from config: roundtable.escalation.triggers.critical_keywords, default: ["security", "must-have", "blocking", "legal"]}
participants:
  - "product-manager"
  - "software-architect"
  - "technical-lead"
  - "devops-engineer"
```

**Note**: Brainstorm uses Disney strategy with phases, no formal agenda.

### Step 1.4: Create Session Index File

**YOU MUST use Write tool NOW** to create `.s2s/sessions/{session-id}.yaml`:

```yaml
id: "{session-id}"
topic: "{topic}"
workflow_type: "brainstorm"
strategy: "disney"
status: "active"

timing:
  started: "{ISO timestamp}"
  completed: null
  duration_ms: null

artifacts:
  ideas: []
  risks: []
  mitigations: []
  conflicts: []
  open_questions: []

# Disney phases (no formal agenda)
current_phase: "dreamer"
phases:
  - name: "dreamer"
    status: "active"
    rounds: []
  - name: "realist"
    status: "pending"
    rounds: []
  - name: "critic"
    status: "pending"
    rounds: []

rounds: []

metrics:
  rounds: 0
  tasks: 0
  tokens: 0
```

### Step 1.5: Update State File

If S2S initialized:
**YOU MUST use Edit tool NOW** to update `.s2s/state.yaml`:
```yaml
current_session: "{session-id}"
```

---

## Phase 2: Round Execution Loop (Disney Strategy)

**Follow the `roundtable-execution` skill instructions with Disney strategy phases.**

Initialize:
- `round_number = 0`
- `current_phase = "dreamer"`
- `session_folder = ".s2s/sessions/{session-id}/"`

### Round Loop (cycle through Disney phases)

#### Step 2.1: Display Phase Status

```
═══════════════════════════════════════════════════════════════
BRAINSTORM: {topic}
Strategy: Disney | Phase: {current_phase} | Round: {round_number + 1}
═══════════════════════════════════════════════════════════════

{if current_phase == "dreamer"}
DREAMER PHASE: Think BIG! No constraints, wild ideas welcome.
{/if}
{if current_phase == "realist"}
REALIST PHASE: Evaluate feasibility. How would we implement?
{/if}
{if current_phase == "critic"}
CRITIC PHASE: Identify risks. What could go wrong?
{/if}

ARTIFACTS: {count} ideas, {count} risks, {count} mitigations
```

#### Step 2.2: Facilitator Question

**Use the roundtable-facilitator agent** with this input:

```yaml
action: "question"
round: {round_number + 1}
topic: "{brainstorm topic}"
strategy: "disney"
phase: "{current_phase}"  # dreamer | realist | critic
workflow_type: "brainstorm"

escalation_config:
  min_rounds: {from config-snapshot.yaml: limits.min_rounds}
  max_rounds: {from config-snapshot.yaml: limits.max_rounds}
  max_rounds_per_conflict: {from config-snapshot.yaml: escalation.max_rounds_per_conflict}
  confidence_below: {from config-snapshot.yaml: escalation.confidence_below}

# Project context (from context-snapshot.yaml)
project_context:
  name: "{from CONTEXT.md or directory name}"
  description: "{from CONTEXT.md or topic}"
  brainstorm_topic: "{topic}"

# Current session state (from session file)
session_state:
  artifacts:
    ideas: [{id, title, status, description, ...}]
    risks: [{id, title, status, description, severity, ...}]
    mitigations: [{id, title, risk_id, description, ...}]
    conflicts: [{id, title, status, positions, ...}]
    open_questions: [{id, title, status, description, ...}]
  rounds:
    - round: 1
      focus: "{phase}"
      synthesis: "{synthesis text}"
    # ... previous rounds

disney_phase_rules:
  dreamer: "Generate creative ideas without constraints. NO criticism. Wild, ambitious thinking."
  realist: "Evaluate feasibility. Focus on 'how to' thinking. Practical implementation paths."
  critic: "Identify risks. What could go wrong? Propose mitigations. Challenge assumptions."

participants:
  - "product-manager"
  - "software-architect"
  - "technical-lead"
  - "devops-engineer"
```

The facilitator will return:
```yaml
action: "question"
decision:
  focus_type: "disney_phase"
  phase: "{dreamer|realist|critic}"
  rationale: "{reason}"
question: "{the question}"
exploration: "{exploration prompt}"
participants: "all"

# Context for participants (they have NO tools)
participant_context:
  shared:
    project_summary: |
      {condensed project/topic info}
    relevant_artifacts:
      - id: "IDEA-001"
        title: "..."
        # full artifact content
    open_conflicts: [...]
    open_questions: [...]
    recent_rounds:
      - round: 1
        synthesis: "..."
  overrides: null  # typically null for brainstorm
```

**IF verbose_flag == true**: Write dump to `rounds/{NNN}-01-facilitator-question.yaml`:
```yaml
# Round {N} - Facilitator Question ({phase} phase)
round: {N}
phase: 1
actor: "facilitator"
action: "question"
disney_phase: "{dreamer|realist|critic}"
started: "{ISO timestamp}"
completed: "{ISO timestamp}"

input: {... the YAML input sent to facilitator ...}

response:
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

For each of: product-manager, software-architect, technical-lead, devops-engineer

**Build participant input** by merging:
1. `participant_context.shared` (common to all)
2. `participant_context.overrides[participant-id]` (if present, rare for brainstorm)

**Use the roundtable-{participant-id} agent** with this input:

```yaml
round: {round_number + 1}
topic: "{brainstorm topic}"
phase: "{current_phase}"  # dreamer | realist | critic
workflow_type: "brainstorm"

disney_phase_instructions:
  dreamer: "Think BIG! No constraints. What would be IDEAL? NO criticism of ideas."
  realist: "Evaluate feasibility. How would we BUILD this? Be practical but constructive."
  critic: "Identify risks. What could go WRONG? Propose mitigations for each risk."

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
    - id: "IDEA-001"
      title: "..."
      status: "draft"
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
  {2-3 sentence contribution}

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

# Phase-specific fields:
ideas: [...]       # dreamer phase
risks: [...]       # critic phase
mitigations: [...]  # critic phase

confidence: 0.85

references:
  - "{reference}"
```

**IF verbose_flag == true**: Write dump for each participant to `rounds/{NNN}-02-{participant-id}.yaml`:
```yaml
# Round {N} - {Role} Response ({disney_phase} phase)
round: {N}
phase: 2
actor: "{participant-id}"
action: "response"
disney_phase: "{dreamer|realist|critic}"
started: "{ISO timestamp}"
completed: "{ISO timestamp}"

input: {... the YAML input sent to participant ...}

response:
  participant: "{participant-id}"
  position: "{full response}"
  confidence: {0.0-1.0}
  ideas: [...]
  risks: [...]
  mitigations: [...]

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
topic: "{brainstorm topic}"
strategy: "disney"
phase: "{current_phase}"  # dreamer | realist | critic

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
    ideas: [...]
    risks: [...]
    mitigations: [...]
    confidence: 0.85
  software-architect:
    position: "{position}"
    rationale: [...]
    ideas: [...]
    risks: [...]
    mitigations: [...]
    confidence: 0.8
  # ... all participant responses

phases_status:
  - name: "dreamer"
    status: "{active|completed|pending}"
    rounds_completed: {N}
  - name: "realist"
    status: "{active|completed|pending}"
    rounds_completed: {N}
  - name: "critic"
    status: "{active|completed|pending}"
    rounds_completed: {N}
  # NOTE: Include ALL phases with CURRENT status from session file
  # Facilitator can only conclude when in critic phase AND all phases explored

current_phase: "{dreamer|realist|critic}"

artifacts_summary:
  ideas: []  # current IDEA-* list
  risks: []  # current RISK-* list
  mitigations: []  # current MIT-* list

open_conflicts: []
artifacts_count: {current count}
```

The facilitator will return:
```yaml
action: "synthesis"

synthesis: "{2-4 sentence summary of phase contributions}"

proposed_artifacts:
  - type: "idea"       # dreamer phase
    title: "{title}"
    status: "draft"
    description: "..."
  - type: "risk"       # critic phase
    title: "{title}"
    status: "identified"
    description: "..."
    severity: "{high|medium|low}"
  - type: "mitigation"  # critic phase
    title: "{title}"
    risk_id: "{RISK-NNN to mitigate}"
    description: "..."

resolved_conflicts: []

phase_recommendation: "{stay|advance|conclude}"

constraints_check:
  rounds_completed: {N}
  min_rounds: {from config-snapshot.yaml: limits.min_rounds}
  can_conclude: {true|false}
  reason: "{reason}"

next: "{continue|phase|conclude}"  # "phase" = advance to next Disney phase

next_focus:
  type: "disney_phase"
  phase: "{dreamer|realist|critic}"
  reason: "{reason}"

escalation_reason: null
```

**Phase-specific artifact extraction:**
- **Dreamer**: Extract ideas as IDEA-* artifacts
- **Realist**: Assess feasibility, categorize ideas
- **Critic**: Extract risks as RISK-*, mitigations as MIT-*

**IF verbose_flag == true**: Write dump to `rounds/{NNN}-03-facilitator-synthesis.yaml`:
```yaml
# Round {N} - Facilitator Synthesis ({disney_phase} phase)
round: {N}
phase: 3
actor: "facilitator"
action: "synthesis"
disney_phase: "{dreamer|realist|critic}"
started: "{ISO timestamp}"
completed: "{ISO timestamp}"

input: {... the YAML input sent to facilitator ...}

response:
  synthesis: "{summary}"
  proposed_artifacts: [...]
  phase_recommendation: "{stay|advance|conclude}"
  constraints_check: {rounds_completed, min_rounds, can_conclude, reason}
  next: "{continue|phase|conclude}"

result:
  artifacts_proposed: {count}
  status: "completed"

tokens:
  input_estimate: {N}
  output_estimate: {N}
```

#### Step 2.5: Process Artifacts

For each `proposed_artifact`:
- Ideas: `IDEA-{NNN}.yaml`
- Risks: `RISK-{NNN}.yaml`
- Mitigations: `MIT-{NNN}.yaml`
- Conflicts: `CONF-{NNN}.yaml`
- Open questions: `OQ-{NNN}.yaml`

#### Step 2.6: Phase Transition

Disney strategy phase progression:
- **dreamer**: 1+ rounds until facilitator recommends phase transition
- **realist**: 1+ rounds
- **critic**: 1+ rounds, then conclude

When facilitator returns `next: "phase"`:
- Advance `current_phase` (dreamer → realist → critic)
- Update phase status in session file

When in `critic` phase and facilitator returns `next: "conclude"`:
- Exit loop, proceed to completion

#### Step 2.7: Display Round Recap

Show synthesis, new artifacts, phase progress.

#### Step 2.8: Handle Interactive Mode

**IF interactive_flag == true**: Ask user to continue, skip phase, or pause.
**IF interactive_flag == false**: Proceed automatically.

#### Step 2.9: Evaluate Next Action (CRITICAL)

**MANDATORY min_rounds enforcement:**

```
IF round_number < min_rounds (default: 3) AND next == "conclude":
  OVERRIDE next to "continue"
  Display: "⚠️ min_rounds not reached ({round_number}/{min_rounds}), continuing..."
```

Then evaluate based on `next`:
- **continue**: Loop back to Step 2.1 (same phase)
- **phase**: Advance to next Disney phase (dreamer → realist → critic)
- **conclude**: Only valid in critic phase AND round_number >= min_rounds
- **escalate**: Ask user with AskUserQuestion

---

## Phase 3: Completion

### Step 3.1: Update Session Status

**YOU MUST use Edit tool NOW** to update session file.

### Step 3.2: Clear State

If S2S initialized:
**YOU MUST use Edit tool NOW** to clear current_session.

### Step 3.3: Read Session for Summary

**YOU MUST use Read tool** to read session file and artifact files.

Extract from each Disney phase:
- **Dreamer phase**: All IDEA-* artifacts
- **Realist phase**: Feasibility assessments
- **Critic phase**: All RISK-* and MIT-* artifacts

### Step 3.4: Process Results

Categorize ideas by feasibility:
- **Immediately feasible**: Ready to implement
- **Requires more work**: Needs further analysis
- **Long-term/aspirational**: Future consideration

Pair risks with mitigations.

### Step 3.5: Save Summary

**YOU MUST use Write tool NOW** to create `.s2s/sessions/{session-id}-summary.md`:

```markdown
# Brainstorm: {Topic}

**Session**: {session-id}
**Date**: {date}
**Strategy**: Disney (Dreamer → Realist → Critic)
**Participants**: {list}

## Dreamer Phase Ideas

{for each IDEA-* artifact}
### {ID}: {title}
{description}
{/for}

## Realist Assessment

### Immediately Feasible
{list ideas marked feasible}

### Requires More Work
{list ideas needing analysis}

### Long-term Vision
{list aspirational ideas}

## Critic Risks

| Risk | Mitigation |
|------|------------|
{for each RISK-* artifact}
| {title} | {matching MIT-* or "TBD"} |
{/for}

## Recommended Next Steps

1. {step based on top feasible ideas}
2. {step}
3. {step}

## Unresolved Questions

{for each OQ-* artifact}
- {question}
{/for}

---
*Generated by Spec2Ship /s2s:brainstorm*
*Session: {session-id}*
```

### Step 3.6: Output Summary

    Brainstorm Complete!
    ════════════════════

    Topic: {topic}
    Strategy: Disney (Dreamer → Realist → Critic)
    Participants: {count}
    Rounds: {count per phase}

    Top Ideas:
    ──────────
    1. {idea 1}
    2. {idea 2}
    3. {idea 3}

    Feasibility:
    ────────────
    Ready now: {count} items
    Needs work: {count} items
    Long-term: {count} items

    Key Risks:
    ──────────
    - {risk 1}
    - {risk 2}

    Session folder: .s2s/sessions/{session-id}/
    Summary: .s2s/sessions/{session-id}-summary.md

    Next steps:
    ───────────
    To define requirements from these ideas:
      /s2s:specs

    To design architecture:
      /s2s:design

    To create a plan for top idea:
      /s2s:plan:create "{top idea}"

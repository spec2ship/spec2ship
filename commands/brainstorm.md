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

**IMPORTANT**: Save FULL content, not just keys or placeholders.

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
    shared:
      # SAVE FULL CONTENT of each field
      project_summary: |
        {FULL project summary from facilitator response}
      relevant_artifacts:
        # For EACH artifact: save COMPLETE content
        - id: "IDEA-001"
          title: "{full title}"
          status: "{status}"
          description: |
            {full description}
        # ... all artifacts with full content
      open_conflicts:
        - id: "CONF-001"
          title: "{full title}"
          positions: [...]
      open_questions:
        - id: "OQ-001"
          title: "{full title}"
          description: "{full description}"
      recent_rounds:
        - round: 1
          focus: "{phase}"
          synthesis: |
            {FULL synthesis text}
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

# VERIFICATION CHECKLIST - for automated checking
verification:
  # Artifact files that MUST exist after Step 2.5
  expected_artifact_files:
    - "{ID}.yaml"  # for each proposed_artifact
  # Session file updates that MUST be present after Step 2.6
  session_file_updates:
    artifacts_registry:
      # Check each artifact type that was proposed this round
      - field: "artifacts.ideas"
        expected_ids: ["{IDEA-*}", ...]
      - field: "artifacts.risks"
        expected_ids: ["{RISK-*}", ...]
      - field: "artifacts.mitigations"
        expected_ids: ["{MIT-*}", ...]
      - field: "artifacts.open_questions"
        expected_ids: ["{OQ-*}", ...]
      - field: "artifacts.conflicts"
        expected_ids: ["{CONF-*}", ...]
    rounds_array:
      expected_round: {N}
      expected_fields: ["disney_phase", "timestamp", "artifacts_created", "next_action"]
    phases_status:
      current_phase: "{dreamer|realist|critic}"
      expected_status: "{active|completed}"
  # Context propagation check for next round
  context_propagation:
    participant_context_keys:
      - "project_summary"
      - "relevant_artifacts"
      - "open_conflicts"
      - "open_questions"
      - "recent_rounds"
```

#### Step 2.5: Process Artifacts

**YOU MUST use Write tool NOW** to create individual artifact files.

For each `proposed_artifact` from facilitator:

1. **Count existing**: Read session file registry for artifact type
2. **Assign ID**: Next available (IDEA-001, RISK-001, MIT-001, CONF-001, OQ-001)
3. **Write artifact file**: `{session_folder}/{ID}.yaml`

**Artifact file template** (ideas - dreamer phase):
```yaml
# {session_folder}/IDEA-001.yaml
id: "IDEA-001"
type: "idea"
title: "{title from proposed_artifact}"
status: "{draft|refined|feasible|aspirational}"
created_round: {N}
disney_phase: "dreamer"

description: |
  {description from proposed_artifact}

potential_value: |
  {why this idea is valuable}

# Added during realist phase
feasibility: null
implementation_notes: null

# Traceability
proposed_by: "{participant}"
supported_by:
  - "{participant who agreed}"
```

**Artifact file template** (risks - critic phase):
```yaml
# {session_folder}/RISK-001.yaml
id: "RISK-001"
type: "risk"
title: "{title}"
status: "identified"
created_round: {N}
disney_phase: "critic"

description: |
  {what could go wrong}

severity: "{high|medium|low}"
likelihood: "{high|medium|low}"

affected_ideas:
  - "{IDEA-NNN}"

mitigation_id: null  # linked when MIT-* created

raised_by: "{participant}"
```

**Artifact file template** (mitigations - critic phase):
```yaml
# {session_folder}/MIT-001.yaml
id: "MIT-001"
type: "mitigation"
title: "{title}"
status: "proposed"
created_round: {N}
disney_phase: "critic"

risk_id: "{RISK-NNN to mitigate}"

description: |
  {how to mitigate the risk}

effort: "{high|medium|low}"
effectiveness: "{high|medium|low}"

proposed_by: "{participant}"
```

**Artifact file template** (open questions):
```yaml
# {session_folder}/OQ-001.yaml
id: "OQ-001"
type: "open_question"
title: "{title}"
status: "open"
created_round: {N}
disney_phase: "{dreamer|realist|critic}"

description: |
  {question or uncertainty}

raised_by: "{participant}"
blocking: {true|false}
```

**Artifact file template** (conflicts):
```yaml
# {session_folder}/CONF-001.yaml
id: "CONF-001"
type: "conflict"
title: "{title}"
status: "open"
created_round: {N}
disney_phase: "{dreamer|realist|critic}"

positions:
  - participant: "{participant-id}"
    stance: "{position summary}"
    rationale: "{reason}"
  - participant: "{participant-id}"
    stance: "{position summary}"
    rationale: "{reason}"

resolution: null
resolved_round: null
```

For each `resolved_conflict`:
1. **Read conflict file**: `{session_folder}/{conflict_id}.yaml`
2. **Update with resolution**: Add resolved_round, resolution fields
3. **Write updated file** with Edit tool

#### Step 2.6: Update Session File

**YOU MUST use Edit tool NOW** to update session file with:

1. **Update artifacts registry** - add new IDs to appropriate arrays:
```yaml
artifacts:
  ideas:
    - "IDEA-001"  # existing
    - "IDEA-002"  # NEW - added this round
  risks:
    - "RISK-001"  # NEW if created (critic phase)
  mitigations:
    - "MIT-001"   # NEW if created (critic phase)
  conflicts:
    - "CONF-001"  # NEW if created
  open_questions:
    - "OQ-001"    # NEW if created
```

2. **Append round** to `rounds:` array:
```yaml
rounds:
  - round: {N}
    disney_phase: "{dreamer|realist|critic}"
    timestamp: "{ISO timestamp}"
    artifacts_created: ["{ID}", ...]
    next_action: "{continue|phase|conclude}"
```

3. **Update phase status** in `phases:` array:
```yaml
phases:
  - name: "dreamer"
    status: "{active|completed}"
    rounds: [{round numbers in this phase}]
  - name: "realist"
    status: "{pending|active|completed}"
    rounds: [{round numbers}]
  - name: "critic"
    status: "{pending|active|completed}"
    rounds: [{round numbers}]
```

4. **Update metrics**:
```yaml
metrics:
  rounds: {increment}
  tasks: {increment by participant count + 2}
```

#### Step 2.6b: Validate Round Output

**Non-blocking validation** - display warnings but continue execution.

1. **Verify session file updated**:
   - Check `rounds[]` contains current round N
   - Check `artifacts.{type}[]` contains new IDs from this round
   - Check `phases[current_phase].status` is correct

2. **Verify artifact files exist**:
   - For each ID in `proposed_artifacts`: check `{session_folder}/{ID}.yaml` exists
   - Use Glob tool: `{session_folder}/*.yaml`

3. **Verify verbose dumps** (if --verbose):
   - Check `rounds/{NNN}-*.yaml` files exist for this round
   - Expected files: `{NNN}-01-facilitator-question.yaml`, `{NNN}-02-{participant}.yaml` (×4), `{NNN}-03-facilitator-synthesis.yaml`

4. **If validation fails**:
   ```
   ⚠️ Round {N} Validation Warning:
   Missing:
   - {list of missing items}

   Continuing execution...
   ```
   - Log to session file: `validation_warnings: [{round, items}]`
   - Continue to next step (non-blocking)

#### Step 2.6c: Phase Transition

Disney strategy phase progression:
- **dreamer**: 1+ rounds until facilitator recommends phase transition
- **realist**: 1+ rounds
- **critic**: 1+ rounds, then conclude

When facilitator returns `next: "phase"`:
- Advance `current_phase` (dreamer → realist → critic)
- Mark previous phase as "completed" in session file
- Mark new phase as "active"

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

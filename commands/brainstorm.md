---
description: Creative brainstorming session using the Disney strategy (Dreamer → Realist → Critic). Use for ideation and exploring new ideas without constraints. Auto-detects active sessions.
allowed-tools: Bash(pwd:*), Bash(ls:*), Bash(mkdir:*), Bash(date:*), Bash(grep:*), Read, Write, Edit, Glob, Task, AskUserQuestion
argument-hint: "topic" [--participants <list>] [--verbose] [--interactive] [--diagnostic] [--new] [--session <id>]
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

### Parse flags for session handling

Extract from $ARGUMENTS:
- **--new**: Force create new session (skip auto-detect)
- **--session**: Resume specific session by ID

### Auto-detect active sessions

**IF** --session flag is present:
- Verify session exists: `.s2s/sessions/{session-id}.yaml`
- If exists, jump to **Phase 2: Round Execution Loop** (resume session)
- If not exists, display error and list available sessions

**IF** --new flag is present:
- Skip auto-detect
- Continue to parse arguments

**OTHERWISE** check for active brainstorm sessions:

**Use Bash tool** to find active brainstorm sessions:

```bash
grep -l 'workflow_type: brainstorm' .s2s/sessions/*.yaml 2>/dev/null | xargs grep -l 'status: active' 2>/dev/null
```

**IF** no active brainstorm sessions found:
- Continue to parse arguments (create new session)

**IF** active brainstorm sessions found:

1. Read each session file to extract:
   - `id`
   - `topic`
   - `metrics.rounds_completed`

2. Display list:

```
Active brainstorm sessions found:
══════════════════════════════════

1. {session-id}
   Topic: {topic}
   Progress: Round {rounds_completed}

2. {session-id}
   ...

[n] Start new session

Which would you like to continue?
```

3. Ask using AskUserQuestion with options:
   - For each session: "{session-id}"
   - "Start new session"

4. Based on user choice:
   - If existing session selected → Jump to **Phase 2** (resume)
   - If "Start new session" → Continue to parse arguments

---

### Parse Arguments

Extract from $ARGUMENTS:
- **topic**: Required (unless resuming). The subject for brainstorming (first quoted argument)
- **--participants**: Optional. Comma-separated list to override defaults

**Boolean flags**: `--verbose`, `--interactive`, and `--diagnostic` → parse as `true` if present, `false` if absent.

**IF --diagnostic is true**: Force `verbose_flag = true` (diagnostic mode requires verbose dumps for analysis).

If topic is missing, ask using AskUserQuestion:
- "What would you like to brainstorm?"

### Validate Environment

If S2S initialized is "no":

    Error: Not an s2s project. Run /s2s:init first.

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
diagnostic: {diagnostic_flag}
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

### Step 1.4: Create Session File

**YOU MUST use Write tool NOW** to create `.s2s/sessions/{session-id}.yaml`:

```yaml
# Session file - Single Source of Truth
# All artifacts are EMBEDDED (no separate files)

id: "{session-id}"
topic: "{topic}"
workflow_type: "brainstorm"
strategy: "disney"
status: "active"

timing:
  started_at: "{ISO timestamp}"
  updated_at: "{ISO timestamp}"
  closed_at: null

# Agent state (for resume capability)
# Stores agent IDs to enable resuming agents across rounds
agent_state:
  facilitator:
    agent_id: null      # agentId from last facilitator call
    last_round: 0       # round number of last call
    last_action: null   # "question" or "synthesis"
  participants: {}      # {participant-id}: {agent_id, last_round}

# ARTIFACTS - embedded with full content (NOT just IDs)
# Each artifact type is a map keyed by ID
artifacts:
  ideas: {}             # IDEA-*: {status, title, description, ...}
  risks: {}             # RISK-*: {status, title, severity, ...}
  mitigations: {}       # MIT-*: {status, title, risk_id, ...}
  open_questions: {}    # OQ-*: {status, title, description, ...}
  conflicts: {}         # CONF-*: {status, title, positions, ...}

# Disney phases (replaces formal agenda)
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

# Rounds with summary for audit (no verbose needed for basic review)
rounds: []

# Metrics
metrics:
  rounds_completed: 0
  artifacts:
    total: 0
    by_type: {}
    by_status: {}
  phases:
    dreamer: 0
    realist: 0
    critic: 0
  consensus_rate: 0.0
  tokens:
    estimated_total: 0
    by_round: []

# Validation state
validation:
  last_check: null
  status: null
  warnings: []
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

**Check for resume capability:**

Read `agent_state.facilitator` from session file.

**IF** `agent_state.facilitator.agent_id` is NOT null AND this is a continuation (not first round of new session):

**Resume the roundtable-facilitator agent** using Task tool with `resume` parameter set to `"{agent_state.facilitator.agent_id}"`, passing this prompt:

```yaml
action: "question"
round: {round_number + 1}
resume: true
topic: "{brainstorm topic}"
strategy: "disney"
phase: "{current_phase}"  # dreamer | realist | critic
workflow_type: "brainstorm"

# Delta since last round (what changed)
updates_since_last_round:
  new_artifacts: ["{IDs of artifacts created last round}"]
  resolved_conflicts: ["{IDs of conflicts resolved}"]
  resolved_questions: ["{IDs of questions resolved}"]
  phase_changes:
    old_phase: "{previous phase if changed}"
    new_phase: "{current_phase}"

escalation_config:
  min_rounds: {from config-snapshot.yaml: limits.min_rounds}
  max_rounds: {from config-snapshot.yaml: limits.max_rounds}
  max_rounds_per_conflict: {from config-snapshot.yaml: escalation.max_rounds_per_conflict}
  confidence_below: {from config-snapshot.yaml: escalation.confidence_below}

# Project context (from context-snapshot.yaml)
project_context:
  name: "{from CONTEXT.md}"
  description: "{from CONTEXT.md}"
  brainstorm_topic: "{topic}"

# Current full state for reference
session_state:
  artifacts:
    ideas: [{id, title, status, description, ...}]
    risks: [{id, title, status, description, severity, ...}]
    mitigations: [{id, title, risk_id, description, ...}]
    conflicts: [{id, title, status, positions, ...}]
    open_questions: [{id, title, status, description, ...}]
  rounds:
    - round: {N}
      focus: "{phase}"
      synthesis: "{synthesis text}"

disney_phase_rules:
  dreamer: "Generate creative ideas without constraints. NO criticism. Wild, ambitious thinking."
  realist: "Evaluate feasibility. Focus on 'how to' thinking. Practical implementation paths."
  critic: "Identify risks. What could go wrong? Propose mitigations. Challenge assumptions."

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

participants:
  - "product-manager"
  - "software-architect"
  - "technical-lead"
  - "devops-engineer"
```

**ELSE** (fresh invocation - first round or no saved agent_id):

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
  name: "{from CONTEXT.md}"
  description: "{from CONTEXT.md}"
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
started_at: "{ISO timestamp}"
completed_at: "{ISO timestamp}"

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
  status: "closed"

tokens:
  input_estimate: {N}
  output_estimate: {N}
```

**Save facilitator agent_id for resume:**

The facilitator agent returns an `agentId` in its response. **YOU MUST** update the session file:

```yaml
agent_state:
  facilitator:
    agent_id: "{agentId from facilitator response}"
    last_round: {round_number + 1}
    last_action: "question"
```

#### Step 2.3: Participant Responses

**Launch ALL participant agents in SINGLE message** (parallel execution):

For each of: product-manager, software-architect, technical-lead, devops-engineer

**CRITICAL - Context Passing Rules**:

Participants have `tools: []` - they CANNOT read files. They base ALL their reasoning on the context you provide. **YOU MUST**:

1. **Copy `participant_context.shared` VERBATIM** - do NOT summarize, paraphrase, or truncate
2. **Include ALL fields of each artifact** - not just id/title/status, but description, potential_value, severity, etc.
3. **Preserve full text** - if facilitator provided a 10-line description, pass all 10 lines
4. **Never omit fields** - if an artifact has `affected_ideas: [...]`, include the full array

**If you pass incomplete context, participants will INFER (hallucinate) information, degrading quality.**

**Check for resume capability:**

For each participant, read `agent_state.participants.{participant-id}` from session file.

**IF** participant has saved `agent_id` AND this is a continuation:

**Resume the roundtable-{participant-id} agent** using Task tool with `resume` parameter set to `"{agent_state.participants.{participant-id}.agent_id}"`, passing this prompt:

```yaml
round: {round_number + 1}
resume: true
topic: "{brainstorm topic}"
phase: "{current_phase}"  # dreamer | realist | critic
workflow_type: "brainstorm"

question: "{facilitator's NEW question for this round}"
exploration: "{facilitator's exploration prompt}"

# Optional: Include if present in overrides[participant-id]
# facilitator_directive: |
#   {from participant_context.overrides[participant-id].facilitator_directive}

disney_phase_instructions:
  dreamer: "Think BIG! No constraints. What would be IDEAL? NO criticism of ideas."
  realist: "Evaluate feasibility. How would we BUILD this? Be practical but constructive."
  critic: "Identify risks. What could go WRONG? Propose mitigations for each risk."

# Delta since last round (what changed)
context_update:
  new_artifacts_since_last: ["{IDs}"]
  resolved_conflicts_since_last: ["{IDs}"]
  resolved_questions_since_last: ["{IDs}"]
  your_last_position_summary: "{from previous round participant_positions}"

# CRITICAL: Participants have tools: [] - they CANNOT read files
# Full context MUST be provided inline even in resume mode
# YOU MUST COPY VERBATIM from participant_context.shared - NO summarizing
context:
  # COPY EXACTLY from participant_context.shared.project_summary
  project_summary: |
    {COPY VERBATIM from participant_context.shared.project_summary}

  # COPY ALL artifacts with ALL their fields - do NOT truncate
  relevant_artifacts:
    # For EACH artifact in participant_context.shared.relevant_artifacts:
    # Copy ALL fields: id, title, status, description, potential_value, severity, etc.
    - id: "IDEA-001"
      title: "{copy full title}"
      status: "{copy status}"
      description: |
        {copy FULL description - do NOT summarize}
      potential_value: |
        {copy if present}
      # ... copy ALL other fields present in the artifact

  # COPY ALL conflicts with FULL positions
  open_conflicts:
    # Copy from participant_context.shared.open_conflicts with ALL fields

  # COPY ALL open questions with FULL descriptions
  open_questions:
    # Copy from participant_context.shared.open_questions with ALL fields

  # COPY ALL recent rounds with FULL synthesis text
  recent_rounds:
    - round: 1
      synthesis: |
        {copy FULL synthesis text - do NOT truncate}
    # Copy from participant_context.shared.recent_rounds
```

**ELSE** (fresh invocation):

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
# YOU MUST COPY VERBATIM from participant_context.shared - NO summarizing
context:
  # COPY EXACTLY from participant_context.shared.project_summary
  project_summary: |
    {COPY VERBATIM from participant_context.shared.project_summary}

  # COPY ALL artifacts with ALL their fields - do NOT truncate
  relevant_artifacts:
    # For EACH artifact in participant_context.shared.relevant_artifacts:
    # Copy ALL fields: id, title, status, description, potential_value, severity, etc.
    - id: "IDEA-001"
      title: "{copy full title}"
      status: "{copy status}"
      description: |
        {copy FULL description - do NOT summarize}
      potential_value: |
        {copy if present}
      # ... copy ALL other fields present in the artifact

  # COPY ALL conflicts with FULL positions
  open_conflicts:
    # Copy from participant_context.shared.open_conflicts with ALL fields

  # COPY ALL open questions with FULL descriptions
  open_questions:
    # Copy from participant_context.shared.open_questions with ALL fields

  # COPY ALL recent rounds with FULL synthesis text
  recent_rounds:
    - round: 1
      synthesis: |
        {copy FULL synthesis text - do NOT truncate}
    # Copy from participant_context.shared.recent_rounds
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
started_at: "{ISO timestamp}"
completed_at: "{ISO timestamp}"

input: {... the YAML input sent to participant ...}

response:
  participant: "{participant-id}"
  position: "{full response}"
  confidence: {0.0-1.0}
  ideas: [...]
  risks: [...]
  mitigations: [...]

result:
  status: "closed"

tokens:
  input_estimate: {N}
  output_estimate: {N}
```

**Save participant agent_ids for resume:**

Each participant agent returns an `agentId` in its response. **YOU MUST** update the session file:

```yaml
agent_state:
  participants:
    product-manager:
      agent_id: "{agentId from product-manager response}"
      last_round: {round_number + 1}
    software-architect:
      agent_id: "{agentId from software-architect response}"
      last_round: {round_number + 1}
    technical-lead:
      agent_id: "{agentId from technical-lead response}"
      last_round: {round_number + 1}
    devops-engineer:
      agent_id: "{agentId from devops-engineer response}"
      last_round: {round_number + 1}
```

#### Step 2.4: Facilitator Synthesis

**Check for resume capability:**

Read `agent_state.facilitator` from session file.

**IF** `agent_state.facilitator.agent_id` is NOT null (same facilitator from question phase):

**Resume the roundtable-facilitator agent** using Task tool with `resume` parameter set to `"{agent_state.facilitator.agent_id}"`, passing this prompt:

```yaml
action: "synthesis"
round: {round_number + 1}
resume: true
topic: "{brainstorm topic}"
strategy: "disney"
phase: "{current_phase}"  # dreamer | realist | critic

escalation_config:
  min_rounds: {from config-snapshot.yaml: limits.min_rounds}
  max_rounds: {from config-snapshot.yaml: limits.max_rounds}
  max_rounds_per_conflict: {from config-snapshot.yaml: escalation.max_rounds_per_conflict}
  confidence_below: {from config-snapshot.yaml: escalation.confidence_below}

question_asked: "{facilitator's question from step 2.2}"

# Participant responses to synthesize (full content for decision-making)
responses:
  product-manager:
    position: "{position}"
    rationale: [...]
    ideas: [...]
    risks: [...]
    mitigations: [...]
    confidence: {0.0-1.0}
  software-architect:
    position: "{position}"
    rationale: [...]
    ideas: [...]
    risks: [...]
    mitigations: [...]
    confidence: {0.0-1.0}
  technical-lead:
    position: "{position}"
    rationale: [...]
    ideas: [...]
    risks: [...]
    mitigations: [...]
    confidence: {0.0-1.0}
  devops-engineer:
    position: "{position}"
    rationale: [...]
    ideas: [...]
    risks: [...]
    mitigations: [...]
    confidence: {0.0-1.0}

# Current phases state (ALL phases with status)
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

**ELSE** (fresh invocation):

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

resolved_questions: []

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
started_at: "{ISO timestamp}"
completed_at: "{ISO timestamp}"

input: {... the YAML input sent to facilitator ...}

response:
  synthesis: "{summary}"
  proposed_artifacts: [...]
  phase_recommendation: "{stay|advance|conclude}"
  constraints_check: {rounds_completed, min_rounds, can_conclude, reason}
  next: "{continue|phase|conclude}"

result:
  artifacts_proposed: {count}
  status: "closed"

tokens:
  input_estimate: {N}
  output_estimate: {N}

# VERIFICATION CHECKLIST - for automated checking
verification:
  # Embedded artifacts that MUST exist in session file after Step 2.5
  expected_artifacts:
    # For each proposed_artifact, verify key exists in artifacts.{type}
    - map: "artifacts.ideas"
      expected_keys: ["{IDEA-*}", ...]
    - map: "artifacts.risks"
      expected_keys: ["{RISK-*}", ...]
    - map: "artifacts.mitigations"
      expected_keys: ["{MIT-*}", ...]
    - map: "artifacts.open_questions"
      expected_keys: ["{OQ-*}", ...]
    - map: "artifacts.conflicts"
      expected_keys: ["{CONF-*}", ...]
  # Round summary that MUST be present after Step 2.6
  round_summary:
    expected_round: {N}
    required_fields:
      - "timestamp"
      - "disney_phase"
      - "facilitator_question"
      - "synthesis_summary"
      - "participant_positions"
      - "artifacts_created"
      - "next_action"
  # Phases status update
  phases_status:
    current_phase: "{dreamer|realist|critic}"
    expected_status: "{active|completed}"
  # Metrics consistency
  metrics_consistency:
    rounds_completed: {N}
    artifacts_total: {sum of all artifact maps}
  # Context propagation check for next round
  context_propagation:
    participant_context_keys:
      - "project_summary"
      - "relevant_artifacts"
      - "open_conflicts"
      - "open_questions"
      - "recent_rounds"
```

**Update facilitator agent_id after synthesis:**

The facilitator synthesis may return a new `agentId` (or same if resumed). **YOU MUST** update the session file to ensure latest agent_id is saved:

```yaml
agent_state:
  facilitator:
    agent_id: "{agentId from synthesis response}"
    last_round: {round_number + 1}
    last_action: "synthesis"
```

#### Step 2.5: Process Artifacts

**YOU MUST use Edit tool NOW** to add artifacts to the session file.

For each `proposed_artifact` from facilitator:

1. **Count existing**: Count keys in `artifacts.{type}` in session file
2. **Assign ID**: Next available (IDEA-001, RISK-001, MIT-001, CONF-001, OQ-001)
3. **Add to session file**: Edit `artifacts.{type}` to add new artifact with full content

**IMPORTANT**: Artifacts are EMBEDDED in session file, NOT separate files.

**Artifact schema** (ideas - add to `artifacts.ideas`):
```yaml
artifacts:
  ideas:
    IDEA-001:
      status: "active"           # Always "active" for standard artifacts
      agreement: "draft"         # From synthesis: consensus|draft|conflict
      created_round: {N}
      disney_phase: "dreamer"
      title: "{title}"
      description: |
        {description}
      potential_value: |
        {why this idea is valuable}
      feasibility: null         # Added during realist phase
      implementation_notes: null
      related_to: []            # Optional: IDs of related artifacts
      proposed_by: "{participant}"
      supported_by: ["{participant}"]
```

**Note**: Map facilitator's `proposed_artifact.status` → `agreement` field.
Lifecycle `status` is always `"active"` for new artifacts.
`related_to` is optional - include only if artifact relates to existing ones.

**Artifact schema** (risks - add to `artifacts.risks`):
```yaml
artifacts:
  risks:
    RISK-001:
      status: "active"
      agreement: "consensus"
      created_round: {N}
      disney_phase: "critic"
      title: "{title}"
      description: |
        {what could go wrong}
      severity: "{high|medium|low}"
      likelihood: "{high|medium|low}"
      affected_ideas: ["{IDEA-NNN}"]  # Domain-specific relation
      mitigation_id: null       # Linked when MIT-* created
      related_to: []            # Optional: other related artifacts
      raised_by: "{participant}"
```

**Artifact schema** (mitigations - add to `artifacts.mitigations`):
```yaml
artifacts:
  mitigations:
    MIT-001:
      status: "active"
      agreement: "consensus"
      created_round: {N}
      disney_phase: "critic"
      title: "{title}"
      risk_id: "{RISK-NNN to mitigate}"  # Domain-specific relation
      description: |
        {how to mitigate the risk}
      effort: "{high|medium|low}"
      effectiveness: "{high|medium|low}"
      proposed_by: "{participant}"
```

**Note**: Mitigations use `risk_id` for the primary relation; `related_to` not needed.

**Artifact schema** (open questions - add to `artifacts.open_questions`):
```yaml
artifacts:
  open_questions:
    OQ-001:
      status: "open"            # open|resolved
      created_round: {N}
      disney_phase: "{dreamer|realist|critic}"
      title: "{title}"
      description: |
        {question or uncertainty}
      raised_by: "{participant}"
      blocking: {true|false}
      related_to: []            # Optional: IDs of artifacts this question is about
      resolution: null          # Filled when resolved
      resolved_round: null
```

**Artifact schema** (conflicts - add to `artifacts.conflicts`):
```yaml
artifacts:
  conflicts:
    CONF-001:
      status: "open"            # open|resolved
      created_round: {N}
      disney_phase: "{dreamer|realist|critic}"
      title: "{title}"
      related_to: []            # Optional: IDs of artifacts in conflict
      positions:
        - participant: "{participant-id}"
          stance: "{position summary}"
          rationale: "{reason}"
      resolution: null
      resolved_round: null
```

**For resolved conflicts**:
Edit the existing conflict in session file to add:
```yaml
artifacts:
  conflicts:
    CONF-001:
      status: "resolved"
      resolution: "{resolution summary}"
      resolved_round: {N}
```

#### Step 2.6: Update Session File

**YOU MUST use Edit tool NOW** to update session file with:

1. **Append round summary** to `rounds:` array (for audit without verbose):
```yaml
rounds:
  - round: {N}
    timestamp: "{ISO timestamp}"
    disney_phase: "{dreamer|realist|critic}"

    # Facilitator question (for audit)
    facilitator_question: |
      {the question asked}

    # Synthesis summary (for audit)
    synthesis_summary: |
      {2-4 sentence synthesis from facilitator}

    # Participant positions (condensed for audit)
    participant_positions:
      product-manager: |
        {1-2 sentence position summary}
      software-architect: |
        {1-2 sentence position summary}
      technical-lead: |
        {1-2 sentence position summary}
      devops-engineer: |
        {1-2 sentence position summary}

    # Key outcomes
    key_decisions:
      - "{decision 1}"
      - "{decision 2}"
    artifacts_created: ["{ID}", ...]
    conflicts_resolved: ["{ID}", ...]
    questions_resolved: ["{ID}", ...]
    consensus_reached: {true|false}
    next_action: "{continue|phase|conclude}"
```

2. **Update timing**:
```yaml
timing:
  updated_at: "{ISO timestamp}"
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

4. **Update metrics** (comprehensive):
```yaml
metrics:
  rounds_completed: {N}
  artifacts:
    total: {count all keys in artifacts.*}
    by_type:
      ideas: {count keys in artifacts.ideas}
      risks: {count keys in artifacts.risks}
      mitigations: {count keys in artifacts.mitigations}
      open_questions: {count keys in artifacts.open_questions}
      conflicts: {count keys in artifacts.conflicts}
    by_status:
      active: {count where status=active}
      open: {count where status=open}
      resolved: {count where status=resolved}
  phases:
    dreamer: {rounds in dreamer phase}
    realist: {rounds in realist phase}
    critic: {rounds in critic phase}
  consensus_rate: {consensus_reached rounds / total rounds}
  tokens:
    estimated_total: {update}
    by_round:
      - round: {N}
        tokens: {estimated for this round}
```

#### Step 2.6b: Validate Round Output

**Non-blocking validation** - display warnings but continue execution.

1. **Verify session file structure** (Read session file):
   - Check `rounds[]` contains entry for round N
   - Check `rounds[N]` has required fields: `timestamp`, `disney_phase`, `synthesis_summary`, `artifacts_created`
   - Check all IDs in `artifacts_created` exist in `artifacts.{type}` maps
   - Check `phases[current_phase].status` is correct

2. **Verify embedded artifacts**:
   - For each ID in `proposed_artifacts`: verify key exists in `artifacts.{type}`
   - Verify artifact has required fields: `status`, `title`, `description`, `created_round`
   - Verify `created_round` matches current round N

3. **Verify metrics consistency**:
   - `metrics.rounds_completed` equals length of `rounds[]`
   - `metrics.artifacts.total` equals sum of all artifact maps
   - Phase round counts match

4. **Verify verbose dumps** (if --verbose):
   - Check `rounds/{NNN}-*.yaml` files exist for this round
   - Expected: `{NNN}-01-facilitator-question.yaml`, `{NNN}-02-{participant}.yaml` (×4), `{NNN}-03-facilitator-synthesis.yaml`

5. **If validation fails**:
   ```
   ⚠️ VALIDATION WARNING
   Round {N} issues found:
   - {list of issues}

   Continuing execution...
   ```
   - Update session file `validation.warnings[]` with issue details
   - Continue to next step (non-blocking)

#### Step 2.6c: Diagnostic Observation (IF --diagnostic)

**IF** diagnostic_flag == true:

**Use the session-observer agent** with this input:

```yaml
mode: "per-round"
session_path: ".s2s/sessions/{session-id}"
round: {round_number + 1}
workflow_type: "brainstorm"
strategy: "disney"
```

The observer will return:
```yaml
round: {N}
status: "ok" | "warning" | "anomaly"
findings: [...]
recommendation: "Continue" | "Review findings" | "Stop for investigation"
```

**Display observer result**:
```
[DIAGNOSTIC] Round {N}: {status}
{IF findings not empty}
Findings:
- {for each finding: type, detail, severity}
{/IF}
Recommendation: {recommendation}
```

**IF** recommendation == "Stop for investigation":
- Display warning and pause for user review
- Ask using AskUserQuestion: "Diagnostic observer recommends stopping. What would you like to do?"
  - Options: "Investigate now" / "Continue anyway" / "Abort session"

**ELSE**: Continue to next step.

#### Step 2.6d: Phase Transition

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

**IF interactive_flag == true**: Ask user to continue, skip phase, or exit.
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

### Step 3.0: Final Diagnostic Report (IF --diagnostic)

**IF** diagnostic_flag == true:

**Use the session-observer agent** with this input:

```yaml
mode: "end-session"
session_path: ".s2s/sessions/{session-id}"
workflow_type: "brainstorm"
strategy: "disney"
```

The observer will return a final diagnostic summary.

**Display final diagnostic report**:
```
╔════════════════════════════════════════════════════════════╗
║                    DIAGNOSTIC REPORT                        ║
╠════════════════════════════════════════════════════════════╣
║ Session: {session-id}                                       ║
║ Workflow: brainstorm | Strategy: disney | Rounds: {N}       ║
╠════════════════════════════════════════════════════════════╣
{for each round's diagnostic result}
║ Round {N}: {status} {findings count if > 0}                ║
{/for}
╠════════════════════════════════════════════════════════════╣
║ Session-level findings:                                     ║
{list session-level findings from end-session mode}
╠════════════════════════════════════════════════════════════╣
║ RESULT: {PASS|PASS with warnings|NEEDS REVIEW}             ║
╚════════════════════════════════════════════════════════════╝
```

### Step 3.1: Update Session Status

**YOU MUST use Edit tool NOW** to update session file:
```yaml
status: "closed"
timing:
  closed_at: "{ISO timestamp}"
```

### Step 3.2: Read Session for Summary

**YOU MUST use Read tool** to read the completed session file.

Extract from session file (Single Source of Truth - ALL artifacts are embedded):
- `artifacts.ideas` - map of IDEA-* with full content
- `artifacts.risks` - map of RISK-* with full content
- `artifacts.mitigations` - map of MIT-* with full content
- `artifacts.open_questions` - map of OQ-* with full content
- `artifacts.conflicts` - map of CONF-* with full content
- Aggregate counts from `metrics.artifacts.by_type` and `metrics.artifacts.by_status`

Categorize artifacts by Disney phase:
- **Dreamer phase**: IDEA-* where `disney_phase == "dreamer"`
- **Realist phase**: IDEA-* with feasibility assessments
- **Critic phase**: RISK-* and MIT-* artifacts

### Step 3.4: Process Results

Categorize ideas by feasibility:
- **Immediately feasible**: Ready to implement
- **Requires more work**: Needs further analysis
- **Long-term/aspirational**: Future consideration

Pair risks with mitigations.

### Step 3.5: Save Summary

**YOU MUST use Write tool NOW** to create `.s2s/sessions/{session-id}-summary.md`:

```markdown
<!-- WARNING: IMMUTABLE - Generated by /s2s:brainstorm. Manual edits will be lost. -->

# Brainstorm: {Topic}

**Session**: {session-id}
**Date**: {date}
**Strategy**: Disney (Dreamer → Realist → Critic)
**Participants**: {list}

## Dreamer Phase Ideas

{for each ID, artifact in artifacts.ideas}
### {ID}: {artifact.title}
{artifact.description}

**Status**: {artifact.agreement}
{/for}

## Realist Assessment

### Immediately Feasible
{list ideas marked feasible}

### Requires More Work
{list ideas needing analysis}

### Long-term Vision
{list aspirational ideas}

## Critic Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
{for each ID, artifact in artifacts.risks}
| {artifact.title} | {artifact.severity} | {lookup artifacts.mitigations where risk_id=ID or "TBD"} |
{/for}

## Recommended Next Steps

1. {step based on top feasible ideas}
2. {step}
3. {step}

## Unresolved Questions

{for each ID, artifact in artifacts.open_questions where artifact.status == "open"}
- **{ID}**: {artifact.title}
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
      /s2s:plan --new "{top idea}"

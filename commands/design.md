---
description: Design technical architecture through a roundtable discussion. Reads requirements.md and produces architecture documentation. Auto-detects active sessions.
allowed-tools: Bash(pwd:*), Bash(ls:*), Bash(mkdir:*), Bash(date:*), Bash(grep:*), Read, Write, Edit, Glob, Task, AskUserQuestion
argument-hint: [--skip-roundtable] [--focus components|api|deployment] [--strategy debate|standard|consensus-driven] [--verbose] [--interactive] [--diagnostic] [--new] [--session <id>]
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
- Read `.s2s/requirements.md` if exists
- Check if `.s2s/architecture.md` exists
- Read `.s2s/config.yaml` for settings

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
- Continue to validation

**OTHERWISE** check for active design sessions:

**Use Bash tool** to find active design sessions:

```bash
grep -l 'workflow_type: design' .s2s/sessions/*.yaml 2>/dev/null | xargs grep -l 'status: active' 2>/dev/null
```

**IF** no active design sessions found:
- Continue to validation (create new session)

**IF** active design sessions found:

1. Read each session file to extract:
   - `id`
   - `topic`
   - `metrics.rounds_completed`

2. Display list:

```
Active design sessions found:
═════════════════════════════

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
   - If "Start new session" → Continue to validation

---

### Validate environment

If S2S initialized is "NOT_S2S":

    Error: Not an s2s project. Run /s2s:init first.

### Check prerequisites

If `.s2s/requirements.md` does not exist:

    Warning: No requirements document found.

    Recommended workflow:
    1. /s2s:init     - Initialize project
    2. /s2s:specs    - Define requirements
    3. /s2s:design   - Design architecture (you are here)

    Continue without formal requirements?

Ask using AskUserQuestion:
- Options: "Continue with CONTEXT.md only" / "Run /s2s:specs first"

### Check for existing architecture

Check if `.s2s/architecture.md` exists.

If architecture doc exists:
- Display summary (count components, decisions)
- Ask: "Architecture doc exists. What would you like to do?"
  - Options: "Override (replace all)" / "Merge (add new)" / "Cancel"
- If cancel, stop
- If override, will replace entire file at end
- If merge, will append new components/decisions with incremented IDs

### Parse arguments

Extract from $ARGUMENTS:
- **--skip-roundtable**: Skip discussion, generate directly
- **--focus**: Focus area (components|api|deployment)
- **--strategy**: Override strategy (optional)

**Boolean flags**: `--verbose`, `--interactive`, and `--diagnostic` → parse as `true` if present, `false` if absent.

**IF --diagnostic is true**: Force `verbose_flag = true` (diagnostic mode requires verbose dumps for analysis).

### Determine strategy

Read `.s2s/config.yaml` and determine the strategy to use:

1. **IF --strategy argument provided**: Use that value
2. **ELSE**: Read `roundtable.strategy.by_workflow_type.design` from config
3. **FALLBACK**: If not found in config, use `"debate"`

Store as **strategy_to_use** and use this value throughout the command.

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

Read `.s2s/CONTEXT.md` and `.s2s/requirements.md`, then write:
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
diagnostic: {diagnostic_flag}
strategy: "{strategy_to_use}"
limits:
  min_rounds: {from config: roundtable.limits.min_rounds, default: 3}
  max_rounds: {from config: roundtable.limits.max_rounds, default: 20}
escalation:
  max_rounds_per_conflict: {from config: roundtable.escalation.triggers.max_rounds_per_conflict, default: 3}
  confidence_below: {from config: roundtable.escalation.triggers.confidence_below, default: 0.5}
  critical_keywords: {from config: roundtable.escalation.triggers.critical_keywords, default: ["security", "must-have", "blocking", "legal"]}
participants:
  - "software-architect"
  - "security-champion"
  - "technical-lead"
  - "devops-engineer"
```

**YOU MUST use Write tool NOW** to create `agenda.yaml`:

Read `skills/roundtable-execution/references/agenda-design.md` and extract topics YAML.

### Step 1.4: Create Session File

**YOU MUST use Write tool NOW** to create `.s2s/sessions/{session-id}.yaml`:

```yaml
# Session file - Single Source of Truth
# All artifacts are EMBEDDED (no separate files)

id: "{session-id}"
topic: "Architecture design for {project name}"
workflow_type: "design"
strategy: "{strategy_to_use}"
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
  architecture_decisions: {}  # ARCH-*: {status, title, decision, options, ...}
  components: {}              # COMP-*: {status, title, responsibility, ...}
  interfaces: {}              # INT-*: {status, title, provides, requires, ...}
  open_questions: {}          # OQ-*: {status, title, description, ...}
  conflicts: {}               # CONF-*: {status, title, positions, ...}

# Agenda topics with status
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

# Rounds with summary for audit (no verbose needed for basic review)
rounds: []

# Metrics
metrics:
  rounds_completed: 0
  artifacts:
    total: 0
    by_type: {}
    by_status: {}
  topics:
    total: 5
    closed: 0
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

## Phase 2: Round Execution Loop

**Follow the `roundtable-execution` skill instructions EXACTLY.**

Initialize:
- `round_number = 0`
- `session_folder = ".s2s/sessions/{session-id}/"`

### Round Loop (repeat until conclusion)

#### Step 2.1: Display Round Start

Display agenda status and artifact counts.

#### Step 2.2: Facilitator Question

**Check for resume capability:**

Read `agent_state.facilitator` from session file.

**IF** `agent_state.facilitator.agent_id` is NOT null AND this is a continuation (not first round of new session):

**Resume the roundtable-facilitator agent** using Task tool with `resume` parameter set to `"{agent_state.facilitator.agent_id}"`, passing this prompt:

```yaml
action: "question"
round: {round_number + 1}
resume: true
topic: "Architecture design for {project name}"
strategy: "{strategy_to_use}"
phase: "design"
workflow_type: "design"

# Delta since last round (what changed)
updates_since_last_round:
  new_artifacts: ["{IDs of artifacts created last round}"]
  resolved_conflicts: ["{IDs of conflicts resolved}"]
  agenda_changes:
    - topic_id: "{topic}"
      old_status: "{previous}"
      new_status: "{current}"

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

# Current full state for reference
session_state:
  artifacts:
    architecture_decisions: [{id, title, status, description, ...}]
    components: [{id, title, status, description, ...}]
    conflicts: [{id, title, status, positions, ...}]
    open_questions: [{id, title, status, description, ...}]
  rounds:
    - round: {N}
      focus: "{topic_id}"
      synthesis: "{synthesis text}"

agenda:
  # Current agenda with updated statuses and done_when criteria
  - id: "{topic}"
    title: "{title}"
    status: "{current status}"
    priority: "{priority}"
    done_when:
      criteria: [...]
      min_requirements: {N}
  # ... all topics from agenda.yaml

participants:
  - "software-architect"
  - "security-champion"
  - "technical-lead"
  - "devops-engineer"
```

**ELSE** (fresh invocation - first round or no saved agent_id):

**Use the roundtable-facilitator agent** with this input:

```yaml
action: "question"
round: {round_number + 1}
topic: "Architecture design for {project name}"
strategy: "{strategy_to_use}"
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
    architecture_decisions: [{id, title, status, description, ...}]
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
  - "security-champion"
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

**CRITICAL - ALL fields below are REQUIRED**:
- Save FULL content, not just keys or placeholders
- You MUST save `response.participant_context.shared` with ALL sub-fields
- ALL fields are REQUIRED regardless of resume mode

```yaml
# Round {N} - Facilitator Question
round: {N}
phase: 1
actor: "facilitator"
action: "question"
started_at: "{ISO timestamp}"
completed_at: "{ISO timestamp}"

input: {... the YAML input sent to facilitator ...}

response:
  decision:
    focus_type: "{agenda|conflict|open_question}"
    topic_id: "{topic}"
    rationale: "{reason}"
  question: "{question}"
  exploration: "{exploration}"
  participant_context:
    shared:
      # SAVE FULL CONTENT of each field
      project_summary: |
        {FULL project summary from facilitator response}
      relevant_artifacts:
        # For EACH artifact: save COMPLETE content
        - id: "ARCH-001"
          title: "{full title}"
          status: "{status}"
          description: |
            {full description}
          options: [...]
          rationale: "{rationale}"
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
          focus: "{topic_id}"
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

For each of: software-architect, security-champion, technical-lead, devops-engineer

**CRITICAL - Context Passing Rules**:

Participants have `tools: []` - they CANNOT read files. They base ALL their reasoning on the context you provide. **YOU MUST**:

1. **Copy `participant_context.shared` VERBATIM** - do NOT summarize, paraphrase, or truncate
2. **Include ALL fields of each artifact** - not just id/title/status, but description, options, rationale, etc.
3. **Preserve full text** - if facilitator provided a 10-line description, pass all 10 lines
4. **Never omit fields** - if an artifact has `consequences: {...}`, include the full object

**If you pass incomplete context, participants will INFER (hallucinate) information, degrading quality.**

**Check for resume capability:**

For each participant, read `agent_state.participants.{participant-id}` from session file.

**IF** participant has saved `agent_id` AND this is a continuation:

**Resume the roundtable-{participant-id} agent** using Task tool with `resume` parameter set to `"{agent_state.participants.{participant-id}.agent_id}"`, passing this prompt:

```yaml
round: {round_number + 1}
resume: true
topic: "Architecture design for {project name}"
phase: "design"
workflow_type: "design"

question: "{facilitator's NEW question for this round}"
exploration: "{facilitator's exploration prompt}"

# Optional: Include if present in overrides[participant-id]
# facilitator_directive: |
#   {from participant_context.overrides[participant-id].facilitator_directive}

# Delta since last round (what changed)
context_update:
  new_artifacts_since_last: ["{IDs}"]
  resolved_conflicts_since_last: ["{IDs}"]
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
    # Copy ALL fields: id, title, status, description, options, rationale, consequences, etc.
    - id: "ARCH-001"
      title: "{copy full title}"
      status: "{copy status}"
      description: |
        {copy FULL description - do NOT summarize}
      options: [...]  # copy full array
      rationale: |
        {copy FULL rationale}
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
# YOU MUST COPY VERBATIM from participant_context.shared - NO summarizing
context:
  # COPY EXACTLY from participant_context.shared.project_summary
  project_summary: |
    {COPY VERBATIM from participant_context.shared.project_summary}

  # COPY ALL artifacts with ALL their fields - do NOT truncate
  relevant_artifacts:
    # For EACH artifact in participant_context.shared.relevant_artifacts:
    # Copy ALL fields: id, title, status, description, options, rationale, consequences, etc.
    - id: "ARCH-001"
      title: "{copy full title}"
      status: "{copy status}"
      description: |
        {copy FULL description - do NOT summarize}
      options: [...]  # copy full array
      rationale: |
        {copy FULL rationale}
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

**CRITICAL - ALL fields below are REQUIRED** (including in resume mode):

```yaml
# Round {N} - {Role} Response
round: {N}
phase: 2
actor: "{participant-id}"
action: "response"
started_at: "{ISO timestamp}"
completed_at: "{ISO timestamp}"

input:
  question: "{the question}"
  context: {... context sent ...}

response:
  participant: "{participant-id}"
  position: "{full response}"
  rationale: [...]
  confidence: {0.0-1.0}
  concerns: [...]
  suggestions: [...]

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
    software-architect:
      agent_id: "{agentId from software-architect response}"
      last_round: {round_number + 1}
    security-champion:
      agent_id: "{agentId from security-champion response}"
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
topic: "Architecture design for {project name}"
strategy: "{strategy_to_use}"
phase: "design"

escalation_config:
  min_rounds: {from config-snapshot.yaml: limits.min_rounds}
  max_rounds: {from config-snapshot.yaml: limits.max_rounds}
  max_rounds_per_conflict: {from config-snapshot.yaml: escalation.max_rounds_per_conflict}
  confidence_below: {from config-snapshot.yaml: escalation.confidence_below}

question_asked: "{facilitator's question from step 2.2}"

# Participant responses to synthesize (full content for decision-making)
responses:
  software-architect:
    position: "{position}"
    rationale: [...]
    concerns: [...]
    suggestions: [...]
    confidence: {0.0-1.0}
  technical-lead:
    position: "{position}"
    rationale: [...]
    concerns: [...]
    suggestions: [...]
    confidence: {0.0-1.0}
  devops-engineer:
    position: "{position}"
    rationale: [...]
    concerns: [...]
    suggestions: [...]
    confidence: {0.0-1.0}

# Current agenda state (ALL topics with current status)
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

focus_topic:
  id: "{topic from step 2.2}"
  done_when:
    criteria: [...]
    min_requirements: {N}

open_conflicts: [{id, title, status, positions, ...}]
artifacts_count: {current count from metrics}
```

**ELSE** (fresh invocation):

**Use the roundtable-facilitator agent** with this input:

```yaml
action: "synthesis"
round: {round_number + 1}
topic: "Architecture design for {project name}"
strategy: "{strategy_to_use}"
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
started_at: "{ISO timestamp}"
completed_at: "{ISO timestamp}"

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
  status: "closed"

tokens:
  input_estimate: {N}
  output_estimate: {N}

# VERIFICATION CHECKLIST - for automated checking
verification:
  # Session file updates that MUST be present after Step 2.5/2.6
  # Note: Artifacts are EMBEDDED in session file (no separate files)
  session_file_updates:
    artifacts_embedded:
      # Check each artifact type that was proposed this round
      - field: "artifacts.architecture_decisions"
        expected_ids: ["{ARCH-*}", ...]
      - field: "artifacts.components"
        expected_ids: ["{COMP-*}", ...]
      - field: "artifacts.interfaces"
        expected_ids: ["{INT-*}", ...]
      - field: "artifacts.open_questions"
        expected_ids: ["{OQ-*}", ...]
      - field: "artifacts.conflicts"
        expected_ids: ["{CONF-*}", ...]
    rounds_array:
      expected_round: {N}
      expected_fields: ["topic", "timestamp", "artifacts_created", "next_action"]
    agenda_status:
      topic_id: "{agenda_update.topic_id}"
      expected_status: "{agenda_update.new_status}"
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
2. **Assign ID**: Next available (ARCH-001, ARCH-002, COMP-001, INT-001, OQ-001)
3. **Add to session file**: Edit `artifacts.{type}` to add new artifact with full content

**IMPORTANT**: Artifacts are EMBEDDED in session file, NOT separate files.

**Artifact schema** (architecture decisions - add to `artifacts.architecture_decisions`):
```yaml
artifacts:
  architecture_decisions:
    ARCH-001:
      status: "active"    # Lifecycle: active|amended|superseded|withdrawn
      agreement: "consensus"  # From synthesis: consensus|draft|conflict
      created_round: {N}
      topic_id: "{topic}"
      title: "{title}"
      context: |
        {context/problem statement}
      decision: |
        {the decision made}
      options:
        - name: "{option 1}"
          pros: ["{pro}"]
          cons: ["{con}"]
        - name: "{option 2}"
          pros: ["{pro}"]
          cons: ["{con}"]
      rationale: |
        {why this option was chosen}
      consequences:
        positive: ["{positive outcome}"]
        negative: ["{trade-off accepted}"]
      proposed_by: "facilitator"
      supported_by: ["{participant}"]
      amendments: []
```

**Note**: Map facilitator's `proposed_artifact.status` → `agreement` field.
Lifecycle `status` is always `"active"` for new artifacts.

**Artifact schema** (components - add to `artifacts.components`):
```yaml
artifacts:
  components:
    COMP-001:
      status: "active"
      agreement: "consensus"
      created_round: {N}
      topic_id: "{topic}"
      title: "{title}"
      responsibility: |
        {what this component does}
      interfaces:
        provides: ["{interface provided}"]
        requires: ["{interface required}"]
      dependencies: ["{dependency}"]
      technology: "{technology choice}"
      amendments: []
```

**Artifact schema** (interfaces - add to `artifacts.interfaces`):
```yaml
artifacts:
  interfaces:
    INT-001:
      status: "active"
      agreement: "consensus"
      created_round: {N}
      topic_id: "{topic}"
      title: "{title}"
      type: "{REST|GraphQL|gRPC|message|file}"
      description: |
        {what this interface provides}
      endpoints: [...]
      amendments: []
```

**Artifact schema** (open questions - add to `artifacts.open_questions`):
```yaml
artifacts:
  open_questions:
    OQ-001:
      status: "open"      # open|resolved
      created_round: {N}
      topic_id: "{topic}"
      title: "{title}"
      description: |
        {question or uncertainty}
      raised_by: "{participant}"
      blocking: {true|false}
      resolution: null    # Filled when resolved
      resolved_round: null
```

**Artifact schema** (conflicts - add to `artifacts.conflicts`):
```yaml
artifacts:
  conflicts:
    CONF-001:
      status: "open"      # open|resolved
      created_round: {N}
      topic_id: "{topic}"
      title: "{title}"
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
    topic_id: "{focus topic_id}"
    debate_phase: "{opening|rebuttal|closing|synthesis}"  # Include for debate strategy

    # Facilitator question (for audit)
    facilitator_question: |
      {the question asked}

    # Synthesis summary (for audit)
    synthesis_summary: |
      {2-4 sentence synthesis from facilitator}

    # Participant positions (condensed for audit)
    participant_positions:
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
    artifacts_amended: []    # IDs of modified artifacts
    consensus_reached: {true|false}
    next_action: "{continue|conclude|escalate}"
```

2. **Update timing**:
```yaml
timing:
  updated_at: "{ISO timestamp}"
```

3. **Update agenda status** from facilitator's `agenda_update`:
```yaml
agenda:
  - topic_id: "{agenda_update.topic_id}"
    status: "{agenda_update.new_status}"  # open → partial → closed
    coverage:
      - "{existing coverage}"
      - "{agenda_update.coverage_added}"  # append new items
```

4. **Update metrics**:
```yaml
metrics:
  rounds_completed: {increment}
  artifacts:
    total: {count all keys in artifacts.*}
    by_type:
      architecture_decisions: {count keys in artifacts.architecture_decisions}
      components: {count keys in artifacts.components}
      interfaces: {count keys in artifacts.interfaces}
      open_questions: {count keys in artifacts.open_questions}
      conflicts: {count keys in artifacts.conflicts}
    by_status:
      active: {count where status=active}
      open: {count where status=open}
      resolved: {count where status=resolved}
  topics:
    total: 5
    closed: {count agenda items with status=closed}
  consensus_rate: {consensus_reached rounds / total rounds}
  tokens:
    estimated_total: {update}
    by_round:
      - round: {N}
        tokens: {estimated for this round}
```

#### Step 2.6b: Validate Round Output

**Non-blocking validation** - display warnings but continue execution.

1. **Verify session file updated**:
   - Check `rounds[]` contains current round N with all required fields
   - Check `artifacts.{type}.{ID}` exists for each artifact created this round
   - Check `agenda[topic_id].status` matches expected from `agenda_update`
   - Check `metrics.rounds_completed` equals `length(rounds[])`

2. **Verify artifact embedding**:
   - For each ID in `proposed_artifacts`: check `artifacts.{type}.{ID}` key exists in session file
   - Verify each artifact has required fields: `status`, `agreement`, `created_round`, `title`

3. **Verify verbose dumps** (if --verbose):
   - Check `rounds/{NNN}-*.yaml` files exist for this round
   - Expected files: `{NNN}-01-facilitator-question.yaml`, `{NNN}-02-{participant}.yaml` (×3), `{NNN}-03-facilitator-synthesis.yaml`

4. **If validation fails**:
   ```
   ⚠️ VALIDATION WARNING
   Round {N} issues found:
   - {list of missing items}

   Continuing execution...
   ```
   - Log to session file: `validation.warnings: [{round, check, message}]`
   - Continue to next step (non-blocking)

#### Step 2.6c: Diagnostic Observation (IF --diagnostic)

**IF** diagnostic_flag == true:

**Use the session-observer agent** with this input:

```yaml
mode: "per-round"
session_path: ".s2s/sessions/{session-id}"
round: {round_number + 1}
workflow_type: "design"
strategy: "{strategy_to_use}"
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

#### Step 2.7: Display Round Recap

Show synthesis, new artifacts, resolved conflicts, agenda status.

#### Step 2.8: Handle Interactive Mode

**IF interactive_flag == true**: Ask user to continue, skip, or exit.
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

### Step 3.0: Final Diagnostic Report (IF --diagnostic)

**IF** diagnostic_flag == true:

**Use the session-observer agent** with this input:

```yaml
mode: "end-session"
session_path: ".s2s/sessions/{session-id}"
workflow_type: "design"
strategy: "{strategy_to_use}"
```

The observer will return a final diagnostic summary.

**Display final diagnostic report**:
```
╔════════════════════════════════════════════════════════════╗
║                    DIAGNOSTIC REPORT                        ║
╠════════════════════════════════════════════════════════════╣
║ Session: {session-id}                                       ║
║ Workflow: design | Strategy: {strategy_to_use} | Rounds: {N} ║
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

Extract from session file (Single Source of Truth):
- All artifacts from `artifacts.architecture_decisions`, `artifacts.components`, etc.
- Aggregate by status (active, open, resolved)
- Get round summaries for recap

### Step 3.4: User Review

Present architecture decisions:

    Architecture Design Summary:
    ═══════════════════════════

    System Overview:
    {high-level description from first ARCH-* or synthesis}

    Components:
    ───────────
    {for each ID, artifact in artifacts.components}
    - {ID}: {artifact.title} - {artifact.responsibility}
    {/for}

    Key Decisions:
    ──────────────
    {for each ID, artifact in artifacts.architecture_decisions}
    {ID}: {artifact.title}
    Decision: {artifact.decision}
    Rationale: {artifact.rationale}
    {/for}

    Interfaces:
    ───────────
    {for each ID, artifact in artifacts.interfaces}
    - {ID}: {artifact.title} ({artifact.type})
    {/for}

    Open Questions:
    ───────────────
    {for each ID, artifact in artifacts.open_questions where status=open}
    - {ID}: {artifact.title}
    {/for}

Ask using AskUserQuestion:
- "Review architecture. Would you like to:"
  - Options: "Approve and generate docs" / "Refine decisions" / "Discuss specific area"

### Step 3.5: Generate Architecture Documentation

**IF merge mode** (user selected "Merge" earlier):
1. Read existing `.s2s/architecture.md`
2. Find highest existing COMP-* and ARCH-* IDs
3. Renumber new artifacts starting from next IDs
4. Append new sections to existing document
5. Update metadata (date, session reference)

**IF override mode** (user selected "Override" or file doesn't exist):
Create `.s2s/architecture.md` reading from **embedded artifacts in session file**:

```markdown
<!-- Generated by /s2s:design - Source: session file is the single source of truth -->

# Architecture

**Project**: {name from context-snapshot.yaml}
**Version**: 1.0
**Date**: {date}
**Session**: {session-id}

## System Context

{high-level description from synthesis or first ARCH-*}

## Architecture Principles

{for each ID, artifact in artifacts.architecture_decisions}
- **{artifact.title}**: {artifact.decision summary}
{/for}

## Components

| Component | Responsibility | Technology |
|-----------|---------------|------------|
{for each ID, artifact in artifacts.components}
| {artifact.title} | {artifact.responsibility} | {artifact.technology} |
{/for}

{for each ID, artifact in artifacts.components}
### {ID}: {artifact.title}

**Responsibility**: {artifact.responsibility}

**Interfaces**:
- Provides: {artifact.interfaces.provides}
- Requires: {artifact.interfaces.requires}

**Dependencies**: {artifact.dependencies}

**Technology**: {artifact.technology}
{/for}

## Interfaces

{for each ID, artifact in artifacts.interfaces}
- **{artifact.title}** ({artifact.type}): {artifact.description}
{/for}

## Key Decisions

See ADRs in `.s2s/decisions/`

---
*Generated by Spec2Ship /s2s:design*
```

### Step 3.6: Generate ADRs

For each ARCH-* in `artifacts.architecture_decisions`, create `.s2s/decisions/ADR-{NNN}-{slug}.md`:

```markdown
<!-- Generated by /s2s:design - Source: session file is the single source of truth -->

# ADR-{NNN}: {artifact.title}

**Status**: accepted
**Date**: {date}
**Session**: {session-id}
**Participants**: software-architect, technical-lead, devops-engineer

## Context
{artifact.context}

## Decision
{artifact.decision}

## Options Considered

{for each option in artifact.options}
### {option.name}
- Pros: {option.pros}
- Cons: {option.cons}
{/for}

## Consequences

### Positive
{artifact.consequences.positive}

### Negative
{artifact.consequences.negative}
```

### Step 3.7: Update CONTEXT.md

Update `.s2s/CONTEXT.md`:
- Update phase to "design"
- Add Technical Stack section
- Update "Last updated" date

### Step 3.8: Output Summary

    Architecture design complete!

    Document: .s2s/architecture.md
    Mode: {override | merge}

    Decisions: .s2s/decisions/
    - ADR-{NNN}-*.md ({count} decisions)

    Tech Stack:
    {summary}

    Session: .s2s/sessions/{session-id}.yaml

    Next steps:
      /s2s:plan              - Generate implementation plans
      /s2s:plan --new   - Create specific plan

---

## Skip Roundtable Mode

**If --skip-roundtable IS present:**

1. Analyze requirements directly
2. Generate basic architecture from patterns
3. Ask user for technology preferences
4. Skip session folder creation

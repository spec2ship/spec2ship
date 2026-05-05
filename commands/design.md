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

**FAST PATH: Check state.json** (immediate resume suggestion):

**IF** `.s2s/state.json` exists:
1. Read the file and check `active_session`
2. **IF** `active_session` is not null AND `active_session.workflow_type == "design"`:
   - Extract session_id from `active_session.id`
   - Verify session file exists: `.s2s/sessions/{session_id}.yaml`
   - Read session file and check `status`
   - **IF** session status is "active":
     - Display:
       ```
       Resume active design session?
       ═══════════════════════════════

       Session: {session_id}
       Topic: {active_session topic from session file}
       Progress: Round {rounds_completed from session file} completed
       ```
     - Ask using AskUserQuestion:
       - "Resume this session" (recommended)
       - "Start new session"
       - "Show all sessions"
     - **IF** "Resume" → Jump to **Phase 2** (resume)
     - **IF** "Start new" → Continue to validation
     - **IF** "Show all" → Fall through to grep scan below
   - **IF** session status is NOT "active" (stale state.json):
     - Clear `active_session` in state.json (write null)
     - Fall through to grep scan

**FALLBACK: Grep scan** for active design sessions:

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
   Progress: Round {rounds_completed} completed

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
  min_rounds: {from config: roundtable.limits.min_rounds}
  max_rounds: {from config: roundtable.limits.max_rounds}
escalation:
  max_rounds_per_conflict: {from config: roundtable.escalation.triggers.max_rounds_per_conflict}
  confidence_below: {from config: roundtable.escalation.triggers.confidence_below}
  critical_keywords: {from config: roundtable.escalation.triggers.critical_keywords}
participants:
  - "software-architect"
  - "security-champion"
  - "technical-lead"
  - "devops-engineer"
```

**YOU MUST use Write tool NOW** to create `agenda.yaml`:

Read the file at `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/agenda-design.md` and extract topics YAML.

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
# Per ADR-0010: artifacts use single 'state' field
artifacts:
  architecture_decisions: {}  # ARCH-*: {state, title, decision, options, ...}
  components: {}              # COMP-*: {state, title, responsibility, ...}
  interfaces: {}              # INT-*: {state, title, provides, requires, ...}
  open_questions: {}          # OQ-*: {state, title, description, ...}
  conflicts: {}               # CONF-*: {state, title, positions, ...}

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
    by_state: {}
  topics:
    total: 5
    closed: 0
  consensus_rate: 0.0
  tokens:
    total: 0        # TECH-009
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
- `round_number = metrics.rounds_completed` (from session file, 0 for new session)
- `session_folder = ".s2s/sessions/{session-id}/"`

**On resume**: Immediately update state.json to align with session file:
```json
{
  "active_session": {
    "id": "{session-id}",
    "workflow_type": "design",
    "round": {round_number}
  },
  "last_activity": {
    "action": "session_resumed"
  }
}
```

### Round Loop (repeat until conclusion)

#### Step 2.0: Context Capacity Check

**TOKEN TRACKING** (always active - executes every round, including resume):

1. Read `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/token-tracking.md`
2. **ALWAYS** execute "Script Location" section (verify script exists, store path as TOKEN_SCRIPT)
3. Execute "Context Capacity Check" section (every round, checks SHOULD_STOP/SHOULD_WARN)

**TOKEN TRACKING CHECKPOINTS** (after Step 2.0 setup is complete):

- **Step 2.0**: TOKEN TRACKING SETUP - Read token-tracking.md, execute "Script Location" to get TOKEN_SCRIPT
- **After Step 2.2**: Execute "Capture T1" from token-tracking.md
- **After Step 2.3**: Execute "Capture T2" from token-tracking.md
- **After Step 2.4**: Execute "Capture T3" from token-tracking.md
- **Step 2.7**: Execute "Round Recap" and display token section in round recap
- **At Step 3.1**: Execute "Session Complete" from token-tracking.md

#### Step 2.1: Display Round Start

Display agenda status and artifact counts.

**CORE: Update state.json** (for resume suggestion and statusline display)

**IF `.s2s/state.json` exists**: Read it first to get current `active_plan` value.

**IMMEDIATELY** use Write tool to write `.s2s/state.json`:
```json
{
  "active_session": {
    "id": "{session-id}",
    "workflow_type": "design",
    "strategy": "{strategy_to_use}",
    "phase": "design",
    "round": {round_number + 1},
    "participants_count": 4
  },
  "active_plan": {existing active_plan value OR null if file didn't exist},
  "last_activity": {
    "timestamp": "{ISO timestamp}",
    "action": "round_started",
    "session_id": "{session-id}"
  }
}
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
topic: "Architecture design for {project name}"
strategy: "{strategy_to_use}"
phase: "design"
workflow_type: "design"

# Delta since last round (what changed)
updates_since_last_round:
  new_artifacts: ["{IDs of artifacts created last round}"]
  resolved_conflicts: ["{IDs of conflicts resolved}"]
  resolved_questions: ["{IDs of questions answered}"]
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
    architecture_decisions: [{id, title, state, description, ...}]
    components: [{id, title, state, description, ...}]
    conflicts: [{id, title, state, positions, ...}]
    open_questions: [{id, title, state, description, ...}]
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

# Project scope (for workspace awareness)
project_scope:
  type: {from config-snapshot.yaml: project.type}  # standalone | workspace | component
  workspace_path: {from config-snapshot.yaml: project.workspace_path}

# Workspace scope (from config-snapshot.yaml, null if standalone)
workspace_scope: {from config-snapshot.yaml: workspace_scope}

# Cross-cutting decisions (from config-snapshot.yaml, null if not workspace)
cross_cutting_decisions: {from config-snapshot.yaml: cross_cutting_decisions}

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
    architecture_decisions: [{id, title, state, description, ...}]
    components: [{id, title, state, description, ...}]
    conflicts: [{id, title, state, positions, ...}]
    open_questions: [{id, title, state, description, ...}]
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
          state: "{state}"
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

→ **Token checkpoint T1** (MANDATORY): `bash "<TOKEN_SCRIPT>" capture "{session-id}" T1`

#### Step 2.3: Participant Responses

**Launch ALL participant agents in SINGLE message** (parallel execution):

For each of: software-architect, security-champion, technical-lead, devops-engineer

**CRITICAL - Context Passing Rules**:

Participants have `tools: []` - they CANNOT read files. They base ALL their reasoning on the context you provide. **YOU MUST**:

1. **Copy `participant_context.shared` VERBATIM** - do NOT summarize, paraphrase, or truncate
2. **Include ALL fields of each artifact** - not just id/title/state, but description, options, rationale, etc.
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
    # Copy ALL fields: id, title, state, description, options, rationale, consequences, etc.
    - id: "ARCH-001"
      title: "{copy full title}"
      state: "{copy state}"
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
    # Copy ALL fields: id, title, state, description, options, rationale, consequences, etc.
    - id: "ARCH-001"
      title: "{copy full title}"
      state: "{copy state}"
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

→ **Token checkpoint T2** (MANDATORY): `bash "<TOKEN_SCRIPT>" capture "{session-id}" T2`

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
  security-champion:
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

open_conflicts: [{id, title, state, positions, ...}]
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
  security-champion:
    position: "{position}"
    rationale: [...]
    concerns: [...]
    suggestions: [...]
    confidence: 0.8
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
    state: "accepted"  # ADR-0010: single state field
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
  conflicts_resolved: {count}
  status: "closed"

tokens:
  input_estimate: {N}
  output_estimate: {N}

# VERIFICATION CHECKLIST - for automated checking
verification:
  # Embedded artifacts that MUST exist in session file after Step 2.5
  expected_artifacts:
    - map: "artifacts.architecture_decisions"
      expected_keys: ["{ARCH-*}", ...]
    - map: "artifacts.components"
      expected_keys: ["{COMP-*}", ...]
    - map: "artifacts.interfaces"
      expected_keys: ["{INT-*}", ...]
    - map: "artifacts.open_questions"
      expected_keys: ["{OQ-*}", ...]
    - map: "artifacts.conflicts"
      expected_keys: ["{CONF-*}", ...]
  # Round summary that MUST be present after Step 2.6
  round_summary:
    expected_round: {N}
    required_fields:
      - "timestamp"
      - "topic_id"
      - "facilitator_question"
      - "synthesis_summary"
      - "participant_positions"
      - "artifacts_created"
      - "next_action"
  # Agenda status update
  agenda_status:
    topic_id: "{agenda_update.topic_id}"
    expected_status: "{agenda_update.new_status}"
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

→ **Token checkpoint T3** (MANDATORY): `bash "<TOKEN_SCRIPT>" capture "{session-id}" T3`

#### Step 2.5: Process Artifacts

**YOU MUST use Edit tool NOW** to add artifacts to the session file.

For each `proposed_artifact` from facilitator:

1. **Count existing**: Count keys in `artifacts.{type}` in session file
2. **Assign ID**: Next available (ARCH-001, ARCH-002, COMP-001, INT-001, OQ-001)
3. **Add to session file**: Edit `artifacts.{type}` to add new artifact with full content

**IMPORTANT**: Artifacts are EMBEDDED in session file, NOT separate files.

**Per ADR-0010**: Artifacts use single `state` field. State transitions are audited in `rounds[].artifacts_transitioned`.

**Artifact schema** (architecture decisions - add to `artifacts.architecture_decisions`):
```yaml
artifacts:
  architecture_decisions:
    ARCH-001:
      state: "accepted"   # ADR-0010: draft|in_progress|accepted|rejected|deferred
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
      related_to: []
```

**Artifact schema** (components - add to `artifacts.components`):
```yaml
artifacts:
  components:
    COMP-001:
      state: "accepted"
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
      related_to: []
```

**Artifact schema** (interfaces - add to `artifacts.interfaces`):
```yaml
artifacts:
  interfaces:
    INT-001:
      state: "accepted"
      created_round: {N}
      topic_id: "{topic}"
      title: "{title}"
      type: "{REST|GraphQL|gRPC|message|file}"
      description: |
        {what this interface provides}
      endpoints: [...]
      related_to: []
```

**Artifact schema** (open questions - add to `artifacts.open_questions`):
```yaml
artifacts:
  open_questions:
    OQ-001:
      state: "in_progress"  # ADR-0010: draft|in_progress|blocked|resolved|deferred
      created_round: {N}
      topic_id: "{topic}"
      title: "{title}"
      description: |
        {question or uncertainty}
      raised_by: "{participant}"
      blocking: {true|false}
      resolution: null    # Free text when resolved
```

**Artifact schema** (conflicts - add to `artifacts.conflicts`):
```yaml
artifacts:
  conflicts:
    CONF-001:
      state: "in_progress"  # ADR-0010: in_progress|blocked|resolved
      created_round: {N}
      topic_id: "{topic}"
      title: "{title}"
      positions:
        - participant: "{participant-id}"
          stance: "{position summary}"
          rationale: "{reason}"
      resolution: null
```

**For resolved conflicts**:
Edit the existing conflict in session file:
```yaml
artifacts:
  conflicts:
    CONF-001:
      state: "resolved"
      resolution: "{resolution summary}"
```

And add to `rounds[].artifacts_transitioned` for audit:
```yaml
artifacts_transitioned:
  - id: "CONF-001"
    from: "in_progress"
    to: "resolved"
    reason: "{resolution method}"
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
    resolved_conflicts:      # Conflicts resolved this round
      - conflict_id: "{CONF-NNN}"
        resolution: "{how resolved}"
        method: "{consensus|facilitator|user_decision}"
    resolved_questions:      # Questions answered this round
      - question_id: "{OQ-NNN}"
        answer: "{the answer}"
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
    by_state:
      draft: {count where state=draft}
      in_progress: {count where state=in_progress}
      accepted: {count where state=accepted}  # Terminal for ARCH, COMP, INT
      resolved: {count where state=resolved}  # Terminal for OQ, CONF
  topics:
    total: 5
    closed: {count agenda items with status=closed}
  consensus_rate: {consensus_reached rounds / total rounds}
  tokens:
    total: {update from summary}
    by_round:
      - round: {N}
        estimate: {ROUND_TOKENS_ESTIMATE}  # From recap output
        actual: null                        # Updated next round
        source: "estimated"
```

#### Step 2.6b: Validate Round Output

**Read** `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/round-validation.md` and execute the checks.

Non-blocking - display warnings but continue execution.

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
> **"Proceed automatically" means**: Do NOT stop, do NOT ask confirmation, do NOT display status messages asking if user wants to continue. After Step 2.7 recap, immediately proceed to Step 2.1 for next round.
>
> **The ONLY stop conditions are**: `SHOULD_STOP == true` (context), `round_number >= max_rounds`, `next == "escalate"`, or `interactive_flag == true`.

#### Step 2.9: Evaluate Next Action (CRITICAL)

**MANDATORY min_rounds enforcement:**

```
IF round_number < min_rounds (from config) AND next == "conclude":
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

→ **Token tracking**: Execute "Session Complete" section from token-tracking.md (updates `metrics.tokens.total`)

**YOU MUST use Edit tool NOW** to update session file:

```yaml
status: "closed"
timing:
  closed_at: "{ISO timestamp}"
```

**CORE: Clear active_session from state.json**

**IF `.s2s/state.json` exists**: Read it first to get current `active_plan` value.

**IMMEDIATELY** use Write tool to write `.s2s/state.json`:
```json
{
  "active_session": null,
  "active_plan": {existing active_plan value OR null if file didn't exist},
  "last_activity": {
    "timestamp": "{ISO timestamp}",
    "action": "session_closed",
    "session_id": "{session-id}"
  }
}
```

### Step 3.2: Read Session for Summary

**YOU MUST use Read tool** to read the completed session file.

Extract from session file (Single Source of Truth):
- All artifacts from `artifacts.architecture_decisions`, `artifacts.components`, etc.
- Aggregate by state (draft, in_progress, accepted, resolved)
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
    {for each ID, artifact in artifacts.open_questions where state=in_progress}
    - {ID}: {artifact.title}
    {/for}

Ask using AskUserQuestion:
- "Review architecture. Would you like to:"
  - Options: "Approve and generate docs" / "Refine decisions" / "Discuss specific area"

### Step 3.5-3.8: Generate Output

Read the file at `${CLAUDE_PLUGIN_ROOT}/skills/output-generation/SKILL.md` and follow the instructions for workflow_type="design":
1. Generate `.s2s/architecture.md` (merge or override mode based on earlier choice)
2. Generate `.s2s/decisions/ADR-*.md` for each architecture decision
3. Update `.s2s/CONTEXT.md`
4. Display output summary

---

## Skip Roundtable Mode

**If --skip-roundtable IS present:**

1. Analyze requirements directly
2. Generate basic architecture from patterns
3. Ask user for technology preferences
4. Skip session folder creation

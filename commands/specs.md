---
description: Define functional requirements through a roundtable discussion. Reads CONTEXT.md and produces structured requirements.md. Auto-detects active sessions.
allowed-tools: Bash(pwd:*), Bash(ls:*), Bash(mkdir:*), Bash(date:*), Bash(grep:*), Read, Write, Edit, Glob, Task, AskUserQuestion
argument-hint: [--skip-roundtable] [--format srs|volere|simple] [--strategy standard|disney|consensus-driven] [--verbose] [--interactive] [--diagnostic] [--new] [--session <id>]
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

**OTHERWISE** check for active specs sessions:

**Use Bash tool** to find active specs sessions:

```bash
grep -l 'workflow_type: specs' .s2s/sessions/*.yaml 2>/dev/null | xargs grep -l 'status: active' 2>/dev/null
```

**IF** no active specs sessions found:
- Continue to validation (create new session)

**IF** active specs sessions found:

1. Read each session file to extract:
   - `id`
   - `topic`
   - `metrics.rounds_completed`

2. Display list:

```
Active specs sessions found:
════════════════════════════

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

**Boolean flags**: `--verbose`, `--interactive`, and `--diagnostic` → parse as `true` if present, `false` if absent.

**IF --diagnostic is true**: Force `verbose_flag = true` (diagnostic mode requires verbose dumps for analysis).

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
diagnostic: {diagnostic_flag}
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
  - "ux-researcher"
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

### Step 1.4: Create Session File

**YOU MUST use Write tool NOW** to create `.s2s/sessions/{session-id}.yaml`:

```yaml
# Session file - Single Source of Truth
# All artifacts are EMBEDDED (no separate files)

id: "{session-id}"
topic: "Requirements definition for {project name}"
workflow_type: "specs"
strategy: "{strategy}"
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
  requirements: {}      # REQ-*: {status, title, description, acceptance, ...}
  business_rules: {}    # BR-*: {status, title, description, conditions, ...}
  nfr: {}               # NFR-*: {status, title, category, target, ...}
  exclusions: {}        # EX-*: {status, title, description, rationale, ...}
  open_questions: {}    # OQ-*: {status, title, description, raised_by, ...}
  conflicts: {}         # CONF-*: {status, title, positions, resolution, ...}

# Agenda topics with status
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
    total: 6
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
topic: "Requirements definition for {project name}"
strategy: "{strategy from config}"
phase: "requirements"
workflow_type: "specs"

# Delta since last round (what changed)
updates_since_last_round:
  new_artifacts: ["{IDs of artifacts created last round}"]
  resolved_conflicts: ["{IDs of conflicts resolved}"]
  resolved_questions: ["{IDs of questions resolved}"]
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

# Current full state for reference
session_state:
  artifacts:
    requirements: [{id, title, status, description, ...}]
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
  - "product-manager"
  - "ux-researcher"
  - "business-analyst"
  - "qa-lead"
```

**ELSE** (fresh invocation - first round or no saved agent_id):

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
  - "ux-researcher"
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

**IMPORTANT**: Save FULL content, not just keys or placeholders.

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
  question: "{the question}"
  exploration: "{exploration prompt}"
  participant_context:
    shared:
      # SAVE FULL CONTENT of each field
      project_summary: |
        {FULL project summary from facilitator response}
      relevant_artifacts:
        # For EACH artifact: save COMPLETE content
        - id: "REQ-001"
          title: "{full title}"
          status: "{status}"
          description: |
            {full description}
          acceptance:
            - "{criterion 1}"
            - "{criterion 2}"
          priority: "{priority}"
        # ... all artifacts with full content
      open_conflicts:
        - id: "CONF-001"
          title: "{full title}"
          positions: [...]
          # full conflict content
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
  participants: "{all or list}"

result:
  status: "closed"

tokens:
  input_estimate: {estimated input tokens}
  output_estimate: {estimated output tokens}
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

For each of: product-manager, ux-researcher, business-analyst, qa-lead

**CRITICAL - Context Passing Rules**:

Participants have `tools: []` - they CANNOT read files. They base ALL their reasoning on the context you provide. **YOU MUST**:

1. **Copy `participant_context.shared` VERBATIM** - do NOT summarize, paraphrase, or truncate
2. **Include ALL fields of each artifact** - not just id/title/status, but description, acceptance criteria, priority, etc.
3. **Preserve full text** - if facilitator provided a 10-line description, pass all 10 lines
4. **Never omit fields** - if an artifact has `acceptance: [...]`, include the full array

**If you pass incomplete context, participants will INFER (hallucinate) information, degrading quality.**

**Check for resume capability:**

For each participant, read `agent_state.participants.{participant-id}` from session file.

**IF** participant has saved `agent_id` AND this is a continuation:

**Resume the roundtable-{participant-id} agent** using Task tool with `resume` parameter set to `"{agent_state.participants.{participant-id}.agent_id}"`, passing this prompt:

```yaml
round: {round_number + 1}
resume: true
topic: "Requirements definition for {project name}"
phase: "requirements"
workflow_type: "specs"

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
    # Copy ALL fields: id, title, status, description, acceptance, priority, etc.
    - id: "REQ-001"
      title: "{copy full title}"
      status: "{copy status}"
      description: |
        {copy FULL description - do NOT summarize}
      acceptance:
        - "{copy each criterion}"
      priority: "{copy priority}"
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
topic: "Requirements definition for {project name}"
phase: "requirements"
workflow_type: "specs"

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
    # Copy ALL fields: id, title, status, description, acceptance, priority, etc.
    - id: "REQ-001"
      title: "{copy full title}"
      status: "{copy status}"
      description: |
        {copy FULL description - do NOT summarize}
      acceptance:
        - "{copy each criterion}"
      priority: "{copy priority}"
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
```yaml
# Round {N} - {Participant Role} Response
round: {N}
phase: 2
actor: "{participant-id}"
action: "response"
started_at: "{ISO timestamp}"
completed_at: "{ISO timestamp}"

input: {... the YAML input sent to participant ...}

response:
  participant: "{participant-id}"
  position: "{position}"
  rationale: [...]
  confidence: {0.0-1.0}
  concerns: [...]
  suggestions: [...]

result:
  status: "closed"

tokens:
  input_estimate: {estimated input tokens}
  output_estimate: {estimated output tokens}
```

**Save participant agent_ids for resume:**

Each participant agent returns an `agentId` in its response. **YOU MUST** update the session file:

```yaml
agent_state:
  participants:
    product-manager:
      agent_id: "{agentId from product-manager response}"
      last_round: {round_number + 1}
    ux-researcher:
      agent_id: "{agentId from ux-researcher response}"
      last_round: {round_number + 1}
    business-analyst:
      agent_id: "{agentId from business-analyst response}"
      last_round: {round_number + 1}
    qa-lead:
      agent_id: "{agentId from qa-lead response}"
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
topic: "Requirements definition for {project name}"
strategy: "{strategy}"
phase: "requirements"

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
    concerns: [...]
    suggestions: [...]
    confidence: {0.0-1.0}
  business-analyst:
    position: "{position}"
    rationale: [...]
    concerns: [...]
    suggestions: [...]
    confidence: {0.0-1.0}
  qa-lead:
    position: "{position}"
    rationale: [...]
    concerns: [...]
    suggestions: [...]
    confidence: {0.0-1.0}

# Current agenda state (ALL topics with current status)
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

resolved_questions: []

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
  synthesis: "{2-4 sentence summary}"
  proposed_artifacts: [...]
  resolved_conflicts: [...]
  resolved_questions: [...]
  agenda_update: {...}
  constraints_check: {...}
  next: "{continue|conclude|escalate}"
  next_focus: {...}

result:
  artifacts_proposed: {count}
  conflicts_resolved: {count}
  questions_resolved: {count}
  status: "closed"

tokens:
  input_estimate: {estimated input tokens}
  output_estimate: {estimated output tokens}

# VERIFICATION CHECKLIST - for automated checking
verification:
  # Embedded artifacts that MUST exist in session file after Step 2.5
  expected_artifacts:
    # For each proposed_artifact, verify key exists in artifacts.{type}
    - map: "artifacts.requirements"
      expected_keys: ["{REQ-*}", ...]
    - map: "artifacts.business_rules"
      expected_keys: ["{BR-*}", ...]
    - map: "artifacts.nfr"
      expected_keys: ["{NFR-*}", ...]
    - map: "artifacts.exclusions"
      expected_keys: ["{EX-*}", ...]
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

#### Step 2.5: Process Artifacts

**YOU MUST use Edit tool NOW** to add artifacts to the session file.

For each `proposed_artifact` from facilitator:

1. **Count existing**: Count keys in `artifacts.{type}` in session file
2. **Assign ID**: Next available (REQ-001, REQ-002, BR-001, NFR-001, OQ-001, EX-001)
3. **Add to session file**: Edit `artifacts.{type}` to add new artifact with full content

**IMPORTANT**: Artifacts are EMBEDDED in session file, NOT separate files.

**Artifact schema** (requirements - add to `artifacts.requirements`):
```yaml
artifacts:
  requirements:
    REQ-001:
      status: "active"           # Always "active" for standard artifacts
      agreement: "consensus"     # From synthesis: consensus|draft|conflict
      created_round: {N}
      topic_id: "{topic}"
      title: "{title}"
      priority: "{must|should|could|wont}"
      description: |
        {description}
      acceptance:
        - "{criterion 1}"
        - "{criterion 2}"
      proposed_by: "facilitator"
      supported_by:
        - "{participant}"
```

**Note**: Map facilitator's `proposed_artifact.status` → `agreement` field.
Lifecycle `status` is always `"active"` for new artifacts.

**Artifact schema** (business rules - add to `artifacts.business_rules`):
```yaml
artifacts:
  business_rules:
    BR-001:
      status: "active"
      agreement: "consensus"
      created_round: {N}
      topic_id: "{topic}"
      title: "{title}"
      description: |
        {description}
      conditions: |
        {when this rule applies}
      actions: |
        {what happens}
```

**Artifact schema** (NFR - add to `artifacts.nfr`):
```yaml
artifacts:
  nfr:
    NFR-001:
      status: "active"
      agreement: "consensus"
      created_round: {N}
      topic_id: "nfr-measurable"
      title: "{title}"
      category: "{performance|security|usability|reliability|scalability}"
      description: |
        {description}
      target: "{measurable target}"
      minimum: "{minimum acceptable}"
      measurement: "{how to measure}"
```

**Artifact schema** (exclusions - add to `artifacts.exclusions`):
```yaml
artifacts:
  exclusions:
    EX-001:
      status: "active"
      agreement: "consensus"
      created_round: {N}
      topic_id: "out-of-scope"
      title: "{title}"
      description: |
        {what is excluded}
      rationale: |
        {why out of scope}
      future_consideration: {true|false}
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
      resolution:
        summary: "{resolution summary}"
        method: "consensus"  # consensus | facilitator | user_decision
      resolved_round: {N}
```

**For resolved questions**:
Edit the existing open question in session file to add:
```yaml
artifacts:
  open_questions:
    OQ-001:
      status: "resolved"
      resolution: "{answer/decision}"
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
      business-analyst: |
        {1-2 sentence position summary}
      qa-lead: |
        {1-2 sentence position summary}

    # Key outcomes
    key_decisions:
      - "{decision 1}"
      - "{decision 2}"
    artifacts_created: ["{ID}", ...]
    conflicts_resolved: ["{ID}", ...]
    questions_resolved: ["{ID}", ...]
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

4. **Update metrics** (comprehensive):
```yaml
metrics:
  rounds_completed: {N}
  artifacts:
    total: {count all artifacts}
    by_type:
      requirements: {count}
      business_rules: {count}
      nfr: {count}
      exclusions: {count}
      open_questions: {count}
      conflicts: {count}
    by_status:
      active: {count}      # Standard artifacts (REQ, BR, NFR, EX)
      open: {count}        # For OQ, CONF
      resolved: {count}    # For OQ, CONF
  topics:
    total: 6
    closed: {count closed topics}
  consensus_rate: {artifacts with consensus / total}
  tokens:
    estimated_total: {sum of all rounds}
    by_round:
      - round: {N}
        tokens: {estimated for this round}
```

#### Step 2.6b: Validate Round Output

**Non-blocking validation** - display warnings but continue execution.

1. **Verify session file structure** (Read session file):
   - Check `rounds[]` contains entry for round N
   - Check `rounds[N]` has required fields: `timestamp`, `topic_id`, `synthesis_summary`, `artifacts_created`
   - Check all IDs in `artifacts_created` exist in `artifacts.{type}` maps
   - Check `agenda[topic_id].status` matches expected from `agenda_update`

2. **Verify embedded artifacts**:
   - For each ID in `proposed_artifacts`: verify key exists in `artifacts.{type}`
   - Verify artifact has required fields: `status`, `title`, `description`, `created_round`
   - Verify `created_round` matches current round N

3. **Verify metrics consistency**:
   - `metrics.rounds_completed` equals length of `rounds[]`
   - `metrics.artifacts.total` equals sum of all artifact maps
   - `metrics.topics.closed` equals count of agenda items with `status: "closed"`

4. **Verify verbose dumps** (if --verbose):
   - Check `rounds/{NNN}-*.yaml` files exist for this round
   - Expected: `{NNN}-01-facilitator-question.yaml`, `{NNN}-02-{participant}.yaml` (×3), `{NNN}-03-facilitator-synthesis.yaml`

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
workflow_type: "specs"
strategy: "{strategy}"
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

#### Step 2.9: Evaluate Next Action

- If `round_number < 3` AND `next == "conclude"`: Override to "continue"
- Based on `next`: continue loop, conclude, or handle escalation

---

## Phase 3: Completion

### Step 3.0: Final Diagnostic Report (IF --diagnostic)

**IF** diagnostic_flag == true:

**Use the session-observer agent** with this input:

```yaml
mode: "end-session"
session_path: ".s2s/sessions/{session-id}"
workflow_type: "specs"
strategy: "{strategy}"
```

The observer will return a final diagnostic summary.

**Display final diagnostic report**:
```
╔════════════════════════════════════════════════════════════╗
║                    DIAGNOSTIC REPORT                        ║
╠════════════════════════════════════════════════════════════╣
║ Session: {session-id}                                       ║
║ Workflow: specs | Strategy: {strategy} | Rounds: {N}        ║
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
- `artifacts.requirements` - map of REQ-* with full content
- `artifacts.business_rules` - map of BR-* with full content
- `artifacts.nfr` - map of NFR-* with full content
- `artifacts.exclusions` - map of EX-* with full content
- `artifacts.open_questions` - map of OQ-* with full content
- `artifacts.conflicts` - map of CONF-* with full content
- Aggregate counts from `metrics.artifacts.by_type` and `metrics.artifacts.by_status`

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

Create `docs/specifications/requirements.md` reading from **embedded artifacts in session file**:

**For SRS format (default):**

```markdown
<!-- WARNING: IMMUTABLE - Generated by /s2s:specs. Manual edits will be lost. -->

# Software Requirements Specification

**Project**: {from context-snapshot.yaml: project_name}
**Version**: 1.0
**Date**: {date}
**Session**: {session-id}

## 1. Introduction

### 1.1 Purpose
{from context-snapshot.yaml: description}

### 1.2 Scope
{from context-snapshot.yaml: scope}

### 1.3 Constraints
{from context-snapshot.yaml: constraints}

## 2. Functional Requirements

{for each ID, artifact in session.artifacts.requirements where artifact.status == "active"}
### {ID}: {artifact.title}
- **Priority**: {artifact.priority}
- **Description**: {artifact.description}
- **Acceptance Criteria**:
  {for each criterion in artifact.acceptance}
  - [ ] {criterion}
  {/for}
{/for}

## 3. Business Rules

{for each ID, artifact in session.artifacts.business_rules where artifact.status == "active"}
### {ID}: {artifact.title}
{artifact.description}

**Conditions**: {artifact.conditions}
**Actions**: {artifact.actions}
{/for}

## 4. Non-Functional Requirements

{for each ID, artifact in session.artifacts.nfr where artifact.status == "active"}
### {ID}: {artifact.title}
- **Category**: {artifact.category}
- **Target**: {artifact.target}
- **Minimum**: {artifact.minimum}
- **Measurement**: {artifact.measurement}
{/for}

## 5. Out of Scope

{for each ID, artifact in session.artifacts.exclusions where artifact.status == "active"}
- **{ID}**: {artifact.title} - {artifact.rationale}
{/for}

## 6. Open Questions

{for each ID, artifact in session.artifacts.open_questions where artifact.status == "open"}
- **{ID}**: {artifact.title}
  - {artifact.description}
  - Raised by: {artifact.raised_by}
  - Blocking: {artifact.blocking}
{/for}

---
*Generated by Spec2Ship /s2s:specs*
*Session: {session-id}*
*Artifacts: {metrics.artifacts.total} ({metrics.artifacts.by_status.active} active)*
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

---
description: Start a roundtable discussion with AI expert participants. Use for technical decisions, architecture reviews, or requirements refinement.
allowed-tools: Bash(pwd:*), Bash(ls:*), Bash(mkdir:*), Bash(date:*), Read, Write, Edit, Glob, Task, AskUserQuestion, TodoWrite
argument-hint: "topic" [--strategy standard|disney|debate] [--participants list] [--workflow-type specs|tech|brainstorm]
---

# Start Roundtable Discussion

## Context

- Current directory: !`pwd`
- Directory contents: !`ls -la`
- Current timestamp: !`date +"%Y%m%d-%H%M%S"`
- ISO timestamp: !`date -u +"%Y-%m-%dT%H:%M:%SZ"`

## Interpret Context

Based on the context output above, determine:

- **S2S initialized**: If `.s2s` directory appears in Directory contents → "yes", otherwise → "NOT_S2S"

If S2S is initialized, use Read tool to:
- Read `.s2s/CONTEXT.md` for project context
- Read `.s2s/config.yaml` for roundtable configuration
- Read `.s2s/state.yaml` to check for active session

## Instructions

### Validate environment

If S2S initialized is "NOT_S2S", display this message and stop:

    Error: Not an s2s project. Run /s2s:init first.

### Parse arguments

Extract from $ARGUMENTS:
- **Topic**: The discussion topic (required) - first quoted string or unquoted words
- **--strategy**: Facilitation strategy (optional)
  - Options: standard, disney, debate, consensus-driven, six-hats
  - Default: from config.yaml `roundtable.strategy`
- **--participants**: Comma-separated list of participants (optional)
  - Default: from config.yaml based on workflow_type
- **--workflow-type**: Type of workflow invoking roundtable (optional)
  - Options: discover, specs, tech, brainstorm
  - Default: "brainstorm" (for direct invocation)

If no topic is provided, ask using AskUserQuestion.

### Load configuration

Read `.s2s/config.yaml` and extract roundtable settings:

```yaml
# Expected structure
roundtable:
  strategy: "standard"
  participants:
    default: [software-architect, technical-lead]
    by_workflow_type:
      specs: [product-manager, software-architect, qa-lead]
      tech: [software-architect, technical-lead, devops-engineer]
  escalation:
    enabled: true
    triggers:
      no_consensus_after_attempts: 3
      confidence_below: 0.5
      critical_keywords: [security, must-have, blocking, legal]
```

Merge command arguments with config:
1. Strategy: --strategy flag → config.roundtable.strategy
2. Participants: --participants flag → config.participants.by_workflow_type[workflow_type] → config.participants.default

### Check for active session

Read `.s2s/state.yaml` and check `current_session`.

If active session exists:
- Display: "A roundtable session is already active: {session-id}"
- Ask using AskUserQuestion: "Start new or resume existing?"
  - Options: "Start new (archive current)" / "Resume existing"
- If resume, redirect to `/s2s:roundtable:resume`

### Load strategy skill

Read the strategy skill from `skills/roundtable-strategies/references/{strategy}.md`.

If strategy conflicts with config overrides, display warning:

    Warning: Strategy '{strategy}' recommends {participation} participation,
    but config overrides to {override}. Proceeding with override.

### Prepare session

1. Create sessions directory: `mkdir -p .s2s/sessions`

2. Generate session ID: `{timestamp}-{topic-slug}`
   - Slug: lowercase, spaces to hyphens, max 30 chars

3. Determine initial phase from strategy:
   - standard: "discussion"
   - disney: "dreamer"
   - debate: "opening"
   - consensus-driven: "proposal"
   - six-hats: "blue-hat-opening"

### Create session file

Write `.s2s/sessions/{session-id}.yaml`:

```yaml
id: "{session-id}"
topic: "{topic}"
workflow_type: "{workflow-type}"
strategy: "{strategy}"
status: "active"
started: "{ISO timestamp}"

config_snapshot:
  participation: "{parallel|sequential}"
  consensus:
    policy: "{from strategy/config}"
    threshold: 0.6
  escalation:
    enabled: true
    triggers: {...}

participants:
  - id: software-architect
    agent_file: "agents/roundtable/software-architect.md"
  - id: technical-lead
    agent_file: "agents/roundtable/technical-lead.md"

phases:
  - name: "{initial phase}"
    status: "active"
    rounds: []

current_phase: "{initial phase}"
consensus: []
conflicts: []
outcome: null
```

### Update state

Update `.s2s/state.yaml`:
- Set `current_session` to new session ID

### Display session start

    Roundtable Session Started
    ═══════════════════════════

    Session: {session-id}
    Topic: {topic}
    Strategy: {strategy}
    Participants: {list}
    Workflow: {workflow-type}

    Starting discussion...

### Execute roundtable loop

The command acts as EXECUTOR. The facilitator agent DECIDES what to do.

**Loop structure:**

```
WHILE session not concluded:
    1. Call facilitator to generate question
    2. Execute participant Tasks based on facilitator decision
    3. Call facilitator to synthesize responses
    4. Batch write to session file
    5. Check escalation triggers
    6. Evaluate: continue, next phase, conclude, or escalate
```

**Step 1: Generate question**

Launch facilitator agent:

```
Task(
  subagent_type="general-purpose",
  prompt="You are the Roundtable Facilitator.

Read the facilitator agent definition from: agents/roundtable/facilitator.md

Session Input:
```yaml
session:
  id: \"{session-id}\"
  topic: \"{topic}\"
  workflow_type: \"{workflow-type}\"

strategy:
  name: \"{strategy}\"
  current_phase: \"{current-phase}\"
  phases_remaining: [{remaining phases}]

participants:
  {participant list with roles}

history:
  rounds_completed: {count}
  consensus: {current consensus points}
  conflicts: {current conflicts}
  previous_synthesis: \"{last synthesis}\"

context:
  project: \"{CONTEXT.md content}\"
  relevant_docs: \"{related documentation excerpts}\"
```

Generate the next question for this phase.
Respond with structured YAML as specified in the facilitator agent definition."
)
```

Parse facilitator response to extract:
- question
- relevant_participants
- prompt_additions

**Step 2: Execute participant Tasks**

Based on participation mode (parallel or sequential):

**For parallel participation:**
Launch ALL participant Tasks in a SINGLE message (multiple tool calls):

```
Task(
  subagent_type="general-purpose",
  prompt="You are the Software Architect in a roundtable discussion.

Read your agent definition from: agents/roundtable/software-architect.md

Topic: {topic}
Question: {facilitator's question}

Context:
{project context + relevant docs}

Previous synthesis: {if any}
Current consensus: {list}
Open conflicts: {list}

{prompt_additions from facilitator}

Provide your perspective. Include:
1. Your position (clear statement)
2. Rationale
3. Confidence (0.0-1.0)
4. Dependencies"
),
Task(
  subagent_type="general-purpose",
  prompt="You are the Technical Lead..."
),
Task(
  subagent_type="general-purpose",
  prompt="You are the QA Lead..."
)
```

**For sequential participation:**
Launch Tasks ONE AT A TIME, passing previous responses to each subsequent participant.

**Step 3: Synthesize responses**

After ALL participants respond, call facilitator to synthesize:

```
Task(
  subagent_type="general-purpose",
  prompt="You are the Roundtable Facilitator.

Read agents/roundtable/facilitator.md

Participant Responses for Round {N}:

Software Architect:
{response}

Technical Lead:
{response}

QA Lead:
{response}

Synthesize these responses.
Identify consensus points and conflicts.
Determine next action: continue_round, next_phase, conclude, or escalate.
Respond with structured YAML."
)
```

Parse facilitator synthesis to extract:
- synthesis
- new_consensus
- new_conflicts
- next_action
- next_focus or escalation_reason

**Step 4: Batch write to session file**

Update `.s2s/sessions/{session-id}.yaml`:
- Add round to current phase
- Update consensus list
- Update conflicts list
- Update phase status if changing

**Step 5: Check escalation triggers**

Evaluate escalation conditions:
1. Conflict persists after max_attempts_per_conflict rounds
2. Any participant confidence below threshold
3. Critical keywords detected in topic or responses
4. Facilitator explicitly recommends escalation

If escalation triggered:
- Display all positions with rationale
- Show facilitator recommendation
- Ask user for decision using AskUserQuestion

**Step 6: Evaluate next action**

Based on facilitator's next_action:
- **continue_round**: Loop back to Step 1 with new focus
- **next_phase**: Move to next phase, reset round counter
- **conclude**: Exit loop, proceed to completion
- **escalate**: Pause for user input, then continue or conclude

### Handle completion

When facilitator returns `action: "conclude"`:

1. Parse final output:
   - final_consensus
   - unresolved conflicts
   - recommendation
   - output_type

2. Generate output document based on type:

**For ADR output:**
Write to `docs/decisions/{timestamp}-{slug}.md`:

```markdown
# ADR: {Topic}

**Status**: proposed
**Date**: {date}
**Session**: {session-id}
**Participants**: {list}

## Context

{from discussion and context}

## Decision

{final consensus}

## Consequences

### Positive
{benefits from discussion}

### Negative
{trade-offs acknowledged}

## Alternatives Considered

{from conflicts/debates}

---
*Generated by Spec2Ship Roundtable*
```

**For requirements output:**
Append to `docs/specifications/requirements.md` or create new section.

**For architecture output:**
Update relevant files in `docs/architecture/`.

**For summary output:**
Write to `.s2s/sessions/{session-id}-summary.md`.

3. Update session file:
   - Set status to "completed"
   - Set completed timestamp
   - Set outcome with file path

4. Update state.yaml:
   - Clear current_session

5. Display completion summary:

    Roundtable Complete!
    ════════════════════

    Session: {session-id}
    Topic: {topic}
    Strategy: {strategy}
    Rounds: {total rounds across phases}

    Consensus Reached:
    {list of consensus points}

    {If unresolved conflicts}
    Unresolved (noted for follow-up):
    {list}

    Output: {file path}

    Next steps:
    {based on workflow_type and output}

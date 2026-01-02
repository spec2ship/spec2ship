---
description: Start a roundtable discussion with AI expert participants. Use for technical decisions, architecture reviews, or requirements refinement.
allowed-tools: Bash(pwd:*), Bash(ls:*), Bash(mkdir:*), Bash(date:*), Read, Write, Edit, Glob, Task, AskUserQuestion
argument-hint: "topic" [--strategy standard|disney|debate|consensus-driven|six-hats] [--participants list] [--workflow-type specs|tech|brainstorm] [--output-type adr|requirements|architecture|summary]
---

# Start Roundtable Discussion

## Context

- Current directory: !`pwd`
- Directory contents: !`ls -la`
- Timestamp: !`date +"%Y%m%d-%H%M%S"`
- ISO timestamp: !`date -u +"%Y-%m-%dT%H:%M:%SZ"`

## Interpret Context

Based on the context output above, determine:

- **S2S initialized**: If `.s2s` directory appears → "yes", otherwise → "NOT_S2S"

If S2S is initialized:
- Read `.s2s/CONTEXT.md` for project context
- Read `.s2s/config.yaml` for roundtable configuration
- Read `.s2s/state.yaml` to check for active session

---

## Instructions

### Validate environment

If S2S initialized is "NOT_S2S":

    Error: Not an s2s project. Run /s2s:init first.

### Parse arguments

Extract from $ARGUMENTS:
- **Topic**: Required. First quoted string or unquoted words
- **--strategy**: Optional. Facilitation strategy
- **--participants**: Optional. Comma-separated list
- **--workflow-type**: Optional (specs|tech|brainstorm). Default: "brainstorm"
- **--output-type**: Optional (adr|requirements|architecture|summary). Default: based on workflow

If no topic provided, ask using AskUserQuestion.

### Load configuration

Read `.s2s/config.yaml` and extract:
- Default strategy: `roundtable.strategy`
- Default participants: `roundtable.participants.by_workflow_type[workflow_type]`
- Escalation settings: `roundtable.escalation`

### Auto-detect strategy (if not specified)

If --strategy not provided:

1. Analyze topic for keywords:
   | Keywords | Recommended Strategy | Reason |
   |----------|---------------------|--------|
   | creative, innovation, new, brainstorm | disney | Creative ideation |
   | vs, compare, evaluate, choose, decide | debate | Evaluating alternatives |
   | urgent, fast, quick, asap | consensus-driven | Speed priority |
   | comprehensive, thorough, all angles, deep | six-hats | Deep analysis |
   | *default* | standard | Balanced approach |

2. If keyword match found, ask using AskUserQuestion:
   "Recommended strategy: **{strategy}**
   Reason: Topic contains '{keyword}'

   Options:
   - Use {strategy} (recommended)
   - Use config default ({config_default})
   - Choose manually"

3. If "Choose manually", present all 5 strategies with descriptions

### Check for active session

Read `.s2s/state.yaml` and check `current_session`.

If active session exists:
- Display: "A roundtable session is already active: {session-id}"
- Ask: "Start new (archive current) / Resume existing"
- If resume, redirect to `/s2s:roundtable:resume`

### Create session

1. Create sessions directory: `mkdir -p .s2s/sessions`

2. Generate session ID: `{timestamp}-{topic-slug}`
   - Slug: lowercase, spaces to hyphens, max 30 chars

3. Determine initial phase from strategy:
   - standard: "discussion"
   - disney: "dreamer"
   - debate: "opening"
   - consensus-driven: "proposal"
   - six-hats: "blue-hat-opening"

4. Write `.s2s/sessions/{session-id}.yaml`:

```yaml
id: "{session-id}"
topic: "{topic}"
workflow_type: "{workflow-type}"
strategy: "{strategy}"
status: "active"
started: "{ISO timestamp}"

config_snapshot:
  participation: "parallel"
  consensus:
    policy: "weighted_majority"
    threshold: 0.6
  escalation: {from config}

participants:
  - id: {participant-1}
    agent_file: "agents/roundtable/{participant-1}.md"

phases:
  - name: "{initial phase}"
    status: "active"
    rounds: []

current_phase: "{initial phase}"
consensus: []
conflicts: []
outcome: null
```

5. Update `.s2s/state.yaml`: Set `current_session: "{session-id}"`

### Display session start

    Roundtable Session Started
    ═══════════════════════════

    Session: {session-id}
    Topic: {topic}
    Strategy: {strategy}
    Participants: {list}
    Workflow: {workflow-type}

    Starting discussion...

### Launch orchestrator

Launch the roundtable-orchestrator agent to manage the discussion loop:

```
Task(
  subagent_type="general-purpose",
  prompt="You are the Roundtable Orchestrator.

Read your agent definition from: agents/roundtable/orchestrator.md

Session context:
```yaml
session:
  id: '{session-id}'
  topic: '{topic}'
  workflow_type: '{workflow-type}'
  strategy: '{strategy}'

strategy_config:
  participation: 'parallel'
  phases: {phases from strategy}
  consensus:
    policy: 'weighted_majority'
    threshold: 0.6

participants:
  {participant list}

current_state:
  phase: '{initial phase}'
  rounds_completed: 0
  consensus: []
  conflicts: []

context:
  project: '{CONTEXT.md content}'

max_rounds: 10
escalation_triggers:
  no_consensus_after_attempts: 3
  confidence_below: 0.5
  critical_keywords: [security, must-have, blocking, legal]
```

Execute the roundtable discussion.
Return structured YAML with round data after each round.
Continue until conclusion or escalation."
)
```

### Process orchestrator results

After each round returned by orchestrator:

1. **Batch write** to session file:
   - Add round to current phase's rounds array
   - Update consensus list
   - Update conflicts list
   - Update phase status if transitioning

2. **Check status**:
   - `round_complete`: Continue, wait for next round
   - `phase_complete`: Update session file, continue
   - `escalation_needed`: Display positions, ask user, continue or conclude
   - `concluded`: Proceed to completion

### Handle escalation

If orchestrator returns escalation_needed:

1. Display all positions with rationale
2. Display facilitator recommendation
3. Ask user using AskUserQuestion:
   "Escalation: {reason}

   Options:
   - Accept recommendation
   - Override with specific decision
   - Continue discussion"

4. Based on user choice, either conclude or continue

### Complete session

When orchestrator returns concluded:

1. Update session file:
   - Set `status: "completed"`
   - Set `completed: "{ISO timestamp}"`
   - Add final consensus and unresolved conflicts

2. Generate output based on output_type:
   - **adr**: Write `docs/decisions/{timestamp}-{slug}.md`
   - **requirements**: Append to `docs/specifications/requirements.md`
   - **architecture**: Update `docs/architecture/` files
   - **summary**: Write `.s2s/sessions/{session-id}-summary.md`

3. Update session file: Set `outcome: "{output file path}"`

4. Clear state: Set `current_session: null` in state.yaml

5. Display completion:

    Roundtable Complete!
    ════════════════════

    Session: {session-id}
    Topic: {topic}
    Strategy: {strategy}
    Rounds: {total}

    Consensus Reached:
    {list}

    {If unresolved}
    Unresolved (noted for follow-up):
    {list}

    Output: {file path}

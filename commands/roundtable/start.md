---
description: Start a roundtable discussion with AI expert participants. Use for technical decisions, architecture reviews, or requirements refinement.
allowed-tools: Bash(pwd:*), Bash(ls:*), Bash(mkdir:*), Bash(date:*), Read, Write, Edit, Glob, Task, AskUserQuestion
argument-hint: "topic" [--strategy standard|disney|debate|consensus-driven|six-hats] [--participants list] [--workflow-type specs|design|brainstorm] [--output-type adr|requirements|architecture|summary] [--verbose] [--interactive] [--pro list] [--con list]
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

# PHASE 1: SETUP

## Validate environment

If S2S initialized is "NOT_S2S":

    Error: Not an s2s project. Run /s2s:init first.

## Parse arguments

Extract from $ARGUMENTS:
- **Topic**: Required. First quoted string or unquoted words
- **--strategy**: Optional. Facilitation strategy
- **--participants**: Optional. Comma-separated list
- **--workflow-type**: Optional (specs|design|brainstorm). Default: "brainstorm"
- **--output-type**: Optional (adr|requirements|architecture|summary). Default: based on workflow
- **--verbose**: Optional. Include full participant responses in session file
- **--interactive**: Optional. Ask user after each round
- **--pro**: Optional (debate only). Comma-separated list of participant IDs for Pro side
- **--con**: Optional (debate only). Comma-separated list of participant IDs for Con side

If no topic provided, ask using AskUserQuestion.

## Load configuration

Read `.s2s/config.yaml` and extract:
- Default strategy: `roundtable.strategy`
- Default participants: `roundtable.participants.by_workflow_type[workflow_type]`
- Escalation settings: `roundtable.escalation`
- Max rounds per conflict: `roundtable.escalation.max_rounds_per_conflict` (default: 3)

## Auto-detect strategy (if not specified)

> **Note**: Strategy auto-detection is performed by the **command** (start.md),
> NOT by the facilitator agent. The command analyzes topic keywords before
> launching any agents.

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

## Get strategy configuration

Load strategy phases from `skills/roundtable-strategies/references/{strategy}.md`:
- **standard**: phases: ["discussion"]
- **disney**: phases: ["dreamer", "realist", "critic"]
- **debate**: phases: ["opening", "rebuttal", "closing"]
- **consensus-driven**: phases: ["proposal", "discussion", "resolution"]
- **six-hats**: phases: ["blue-opening", "white", "red", "black", "yellow", "green", "blue-closing"]

Each phase has:
- `name`: phase identifier
- `min_rounds`: minimum rounds before advancing (default: 1)
- `goal`: what the phase should achieve

## Handle debate strategy

If strategy is "debate":

1. Check if --pro and --con flags provided
2. If NOT provided, ask facilitator to assign sides:

```
Task(
  subagent_type="general-purpose",
  prompt="You are the Facilitator for a Debate roundtable.

Assign participants to Pro and Con sides based on:
- Proposal: {topic}
- Participants: {participant list with roles}

Consider typical perspectives of each role.
Assign roughly equal numbers to each side.

Return YAML:
```yaml
pro: [list of participant ids]
con: [list of participant ids]
```"
)
```

3. Store debate_sides in session file

## Check for active session

Read `.s2s/state.yaml` and check `current_session`.

If active session exists:
- Display: "A roundtable session is already active: {session-id}"
- Ask: "Start new (archive current) / Resume existing"
- If resume, redirect to `/s2s:roundtable:resume`

## Create session

1. Create sessions directory: `mkdir -p .s2s/sessions`

2. Generate session ID: `{timestamp}-{topic-slug}`
   - Slug: lowercase, spaces to hyphens, max 30 chars

3. Determine initial phase from strategy phases[0]

4. Write `.s2s/sessions/{session-id}.yaml`:

```yaml
# === IDENTIFICATION ===
id: "{session-id}"
topic: "{topic}"
workflow_type: "{workflow-type}"
strategy: "{strategy}"
status: "active"

# === TIMESTAMPS ===
started: "{ISO timestamp}"
paused_at: null
completed_at: null

# === PARTICIPANTS ===
participants:
  - id: "{participant-1}"
    name: "{Participant 1 Display Name}"
  - id: "{participant-2}"
    name: "{Participant 2 Display Name}"

# === DEBATE ONLY ===
# (Only include if strategy = debate)
debate_sides:
  pro: ["{participant-ids}"]
  con: ["{participant-ids}"]
  proposal: "{topic}"

# === EXECUTION STATE ===
current_phase: "{initial phase}"
total_rounds: 0

# === ROUNDS (Single Source of Truth) ===
rounds: []

# === ESCALATIONS ===
escalations: []

# === OUTPUT ===
outcome: null
```

5. Update `.s2s/state.yaml`: Set `current_session: "{session-id}"`

## Display session start

    Roundtable Session Started
    ═══════════════════════════

    Session: {session-id}
    Topic: {topic}
    Strategy: {strategy}
    Participants: {list}
    Workflow: {workflow-type}

    Starting discussion...

---

# PHASE 2: DISCUSSION LOOP

Execute rounds until conclusion. This loop runs INLINE in the command.

## Initialize loop state

- current_phase = first phase from strategy
- rounds_in_phase = 0
- round_number = 0
- max_rounds = 20 (safety limit)

## Round execution

For each round until conclusion or max_rounds:

### Step 1: Read current session state

Read `.s2s/sessions/{session-id}.yaml` and extract:
- current_phase
- total_rounds
- All previous rounds (for history)

Calculate from rounds:
- current_consensus: all consensus items from all rounds (deduplicated)
- open_conflicts: conflicts introduced but not resolved
- previous_synthesis: last round's synthesis

### Step 2: Generate question (Facilitator Task)

```
Task(
  subagent_type="general-purpose",
  prompt="You are the Roundtable Facilitator.

Read your agent definition from: agents/roundtable/facilitator.md

=== SESSION STATE ===
Topic: {topic}
Strategy: {strategy}
Current Phase: {current_phase}
Round: {round_number + 1}
Rounds in this phase: {rounds_in_phase}
Min rounds for phase: {phase.min_rounds}
Phase goal: {phase.goal}

=== HISTORY ===
Previous synthesis: {previous_synthesis or 'First round'}
Current consensus: {current_consensus or 'None yet'}
Open conflicts: {open_conflicts or 'None'}

=== ESCALATION CONFIG ===
max_rounds_per_conflict: {from config}
confidence_threshold: {from config}
critical_keywords: {from config}

=== TASK ===
Generate the next question for this phase.

Return YAML:
```yaml
action: 'question'
question: '{the question to ask}'
participants: 'all'  # or specific list
focus: '{focus area}'
```"
)
```

Parse facilitator response. If YAML invalid, use fallback:
```yaml
action: "question"
question: "What are the key considerations for {topic}?"
participants: "all"
focus: "Core requirements"
```

### Step 3: Collect participant responses (PARALLEL)

Launch ALL participant Tasks in a SINGLE message (blind voting):

For EACH participant in participant_list:
```
Task(
  subagent_type="general-purpose",
  prompt="You are the {Participant Role} in a roundtable discussion.

Read your agent definition from: agents/roundtable/{participant-id}.md

=== DISCUSSION ===
Topic: {topic}
Question: {facilitator's question}
Focus: {facilitator's focus}

=== CONTEXT ===
Project: {CONTEXT.md content}
Strategy: {strategy}
Phase: {current_phase}

=== PREVIOUS ROUND ===
Synthesis: {previous_synthesis or 'First round'}
Consensus so far: {current_consensus or 'None yet'}

=== YOUR TASK ===
Provide your perspective on the question.

Return YAML:
```yaml
position: '{your position statement}'
rationale:
  - '{reason 1}'
  - '{reason 2}'
confidence: 0.8  # 0.0 to 1.0
concerns:
  - '{any concerns}'
```"
)
```

Note: Participants do NOT see each other's responses (blind voting).
Note: Participants do NOT have access to session file.

Collect all responses.

### Step 4: Synthesize responses (Facilitator Task)

```
Task(
  subagent_type="general-purpose",
  prompt="You are the Roundtable Facilitator.

Read agents/roundtable/facilitator.md

=== ROUND {round_number + 1} RESPONSES ===

{For each participant}
**{Participant Role}** (confidence: {confidence}):
Position: {position}
Rationale: {rationale}
Concerns: {concerns}

{End for each}

=== SESSION STATE ===
Topic: {topic}
Strategy: {strategy}
Phase: {current_phase}
Rounds in phase: {rounds_in_phase}
Min rounds for phase: {phase.min_rounds}
Phase goal: {phase.goal}

=== ESCALATION CONFIG ===
max_rounds_per_conflict: {from config}
confidence_threshold: {from config}
critical_keywords: {from config}

=== CURRENT STATE ===
Consensus so far: {current_consensus}
Open conflicts: {open_conflicts with round counts}

=== TASK ===
Synthesize these responses.
Identify new consensus points and conflicts.
Determine next action.

Return YAML:
```yaml
action: 'synthesis'
synthesis: '{summary of this round}'
consensus:
  - '{new agreed point}'
conflicts:
  - id: '{slug-id}'
    description: '{what the conflict is about}'
    positions:
      {participant-id}: '{their position}'
resolved:
  - conflict_id: '{previously open conflict now resolved}'
    resolution: '{how it was resolved}'
    resolution_type: 'consensus'  # consensus|facilitator|user
next_action: 'continue'  # continue|phase|conclude|escalate
next_focus: '{if continue, what to focus on}'
escalation_reason: null  # if escalate
recommendation: null  # if conclude
output_type: null  # if conclude: adr|requirements|architecture|summary
```"
)
```

Parse facilitator response. If YAML invalid, use fallback:
```yaml
action: "synthesis"
synthesis: "Discussion continues on {topic}."
consensus: []
conflicts: []
resolved: []
next_action: "continue"
```

### Step 5: Update session file (Batch Write)

Create round data:
```yaml
- number: {round_number + 1}
  phase: "{current_phase}"
  timestamp: "{ISO timestamp}"
  question: "{facilitator's question}"
  # responses: ONLY included if --verbose flag (see below)
  synthesis: "{facilitator's synthesis}"
  consensus: {new consensus from this round}
  conflicts: {new conflicts from this round}
  resolved: {conflicts resolved this round}
```

**If --verbose flag is present**, also include `responses`:
```yaml
  responses:
    - participant: "{id}"
      position: "{full position text}"
      rationale:
        - "{reason 1}"
        - "{reason 2}"
      concerns:
        - "{concern 1}"
      confidence: 0.8
```

**Rationale**: The `synthesis` from the facilitator IS the summary of the round.
Full participant responses are only needed for detailed audit trail.

Update session file:
- Append round to `rounds[]`
- Update `total_rounds`
- Update `current_phase` if advancing

### Step 6: Handle --interactive mode

If --interactive flag was provided:
- Display round summary to user
- Ask using AskUserQuestion:
  "Round {round_number + 1} complete.

  Synthesis: {facilitator's synthesis}

  How would you like to proceed?

  Options:
  - Continue discussion
  - Skip to conclusion
  - Pause session"

- If "Pause session":
  - Set `status: "paused"` and `paused_at: {timestamp}`
  - Exit loop
- If "Skip to conclusion":
  - Force `next_action: "conclude"`

### Step 7: Handle next action

Based on facilitator's `next_action`:

**If "continue"**:
- Increment rounds_in_phase
- Loop back to Step 1

**If "phase"**:
- Advance to next phase in strategy phases list
- Reset rounds_in_phase = 0
- Loop back to Step 1

**If "conclude"**:
- Break loop
- Proceed to PHASE 3

**If "escalate"**:
- Record escalation in session file
- Display positions to user:

      ⚠️ Escalation Required
      ════════════════════════

      Reason: {escalation_reason}

      Positions:
      {for each position}
      - {Participant}: {position}

      Facilitator Recommendation: {recommendation}

- Ask user using AskUserQuestion:
  "How would you like to proceed?

  Options:
  - Accept facilitator recommendation
  - Provide your own decision
  - Continue discussion for {N} more rounds"

- Record user decision in escalations[]
- If user provides decision, treat as resolved conflict
- Continue loop or conclude based on user choice

### Step 8: Check safety limits

If round_number >= max_rounds:
- Force conclude with summary
- Note in session: "Reached maximum rounds limit"

---

# PHASE 3: COMPLETION

When discussion concludes:

## Update session file

Set:
- `status: "completed"`
- `completed_at: "{ISO timestamp}"`

## Generate output

Based on output_type from facilitator (or --output-type flag):

### Common steps for all output types

1. Read `config.docs` paths from `.s2s/config.yaml`
2. Generate timestamp using `config.naming.timestamp_format`
3. Create parent directory if needed using Bash: `mkdir -p {dir}`
4. Write file using Write tool
5. Update session: `outcome.file: "{output file path}"`

### adr

**Path**: `{config.docs.decisions}/{timestamp}-{slug}.md`
**Tool**: Write
**Template**: Reference `skills/madr-decisions` for ADR format

Content structure:
```markdown
# {Title from topic}

## Status
Accepted

## Context
{Summary of discussion topic and why decision was needed}

## Decision
{Final consensus from roundtable}

## Options Considered
{List major alternatives discussed, including conflicts}

## Consequences
{Positive and negative implications}
```

### requirements

**Path**: `{config.docs.specifications}/requirements.md`
**Tool**: Edit (append) or Write (create new)

If file exists, append new requirements.
If file doesn't exist, create with header.

Content structure:
```markdown
## Requirements from Roundtable: {topic}

### Functional Requirements
{From consensus items}

### Non-Functional Requirements
{Quality attributes discussed}

### Constraints
{From conflicts/escalations}
```

### architecture

**Path**: `{config.docs.architecture}/{component-slug}-{timestamp}.md`
**Tool**: Write
**Template**: Reference `skills/arc42-templates` for structure

Content structure:
```markdown
# {Component/Topic}

## Overview
{Summary from synthesis}

## Decisions
{Consensus points}

## Open Questions
{Unresolved conflicts}
```

### summary

**Path**: `.s2s/sessions/{session-id}-summary.md`
**Tool**: Write

Content structure:
```markdown
# Roundtable Summary: {topic}

**Session**: {session-id}
**Strategy**: {strategy}
**Rounds**: {total_rounds}

## Key Decisions
{All consensus items}

## Unresolved Items
{Open conflicts for follow-up}

## Participants
{List with confidence levels}
```

## Clear state

Set `current_session: null` in `.s2s/state.yaml`

## Display completion

Calculate final consensus from all rounds.
Calculate unresolved conflicts.

    Roundtable Complete!
    ════════════════════

    Session: {session-id}
    Topic: {topic}
    Strategy: {strategy}
    Total Rounds: {total_rounds}

    Consensus Reached:
    {for each consensus item}
    ✓ {item}

    {if unresolved conflicts}
    Unresolved (noted for follow-up):
    {for each conflict}
    ⚠ {description}

    Output: {output file path}

    Next steps:
      /s2s:roundtable:list   - View all sessions
      /s2s:plan              - Generate implementation plans

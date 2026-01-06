---
description: Start a roundtable discussion with AI expert participants. Use for technical decisions, architecture reviews, or requirements refinement.
allowed-tools: Bash(pwd:*), Bash(ls:*), Bash(mkdir:*), Bash(date:*), Read, Write, Edit, Glob, Task, AskUserQuestion
argument-hint: "topic" [--strategy standard|disney|debate|consensus-driven|six-hats] [--participants list] [--workflow-type specs|design|brainstorm] [--output-type adr|requirements|architecture|summary] [--verbose] [--interactive] [--pro list] [--con list]
skills: roundtable-execution, roundtable-strategies
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

**Boolean flags** (convert to true/false):

| Argument | Type | Parsed Value |
|----------|------|--------------|
| `--verbose` | boolean | present in $ARGUMENTS → `true`, absent → `false` |
| `--interactive` | boolean | present in $ARGUMENTS → `true`, absent → `false` |

Store as:
- **verbose_flag**: true or false
- **interactive_flag**: true or false

Other optional arguments:
- **--pro**: Optional (debate only). Comma-separated list of participant IDs for Pro side
- **--con**: Optional (debate only). Comma-separated list of participant IDs for Con side

If no topic provided, ask using AskUserQuestion.

## Load configuration

Read `.s2s/config.yaml` and extract:
- Default strategy: `roundtable.strategy`
- Default participants: `roundtable.participants.by_workflow_type[workflow_type]`
- Escalation settings: `roundtable.escalation`
- Max rounds per conflict: `roundtable.escalation.triggers.max_rounds_per_conflict` (default: 3)

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

**IMPORTANT: Follow the `roundtable-execution` skill instructions EXACTLY.**

The roundtable-execution skill provides detailed step-by-step instructions for:
- Round execution loop (facilitator → participants → synthesis)
- Session file updates
- Escalation handling
- Completion and output generation

## Configuration for this session

Pass these values to the skill execution:
- **topic**: {parsed topic}
- **workflow_type**: {--workflow-type or "brainstorm"}
- **strategy**: {selected strategy}
- **output_type**: {--output-type or based on workflow}
- **participants**: {selected participant list}
- **verbose**: {verbose_flag}
- **interactive**: {interactive_flag}

## Load Agenda

Based on workflow_type, load agenda if available:
- If workflow_type == "specs": Read `skills/roundtable-execution/references/agenda-specs.md`
- If workflow_type == "design": Read `skills/roundtable-execution/references/agenda-design.md`
- If workflow_type == "brainstorm": No agenda (free-form)

Extract REQUIRED_TOPICS list and track coverage status.

## Execute roundtable

**YOU MUST** now execute the roundtable following the `roundtable-execution` skill.

**DO NOT improvise.** Follow the skill instructions step-by-step:

1. PHASE 3 of skill: Round Execution Loop
   - Step 3.1: Facilitator Question (use Task tool)
     - Include `min_rounds: 3` and `REQUIRED_TOPICS` in prompt
   - Step 3.2: Participant Responses (use Task tool, ALL in parallel)
   - Step 3.3: Facilitator Synthesis (use Task tool)
   - Step 3.4: Update Session File (include agenda_coverage)
   - Step 3.5: Handle --interactive mode (if enabled)
   - Step 3.6: Evaluate Next Action:
     - **min_rounds CHECK**: If round < 3 AND "conclude" → OVERRIDE to "continue"
     - **Agenda CHECK**: If critical topics pending → OVERRIDE to "continue"
   - REPEAT until: next_action == "conclude" AND round >= 3 AND critical topics covered

2. PHASE 4 of skill: Completion
   - Update session status to "completed"
   - Generate output file (based on output_type)
   - Clear state
   - Display completion summary

**CRITICAL REMINDERS:**

- **YOU MUST use the Task tool** for facilitator and participants - do NOT simulate their responses
- **Launch ALL participant Tasks in a SINGLE message** to ensure blind voting
- **WAIT for Task responses** before proceeding to next step
- **Update session file after EACH round** - do NOT batch updates
- **Check Definition of Done** after each step before proceeding
- **Minimum 3 rounds** - do NOT conclude before round 3
- **Maximum 20 rounds** - force conclude if reached

**ADDITIONAL REMINDERS:**

- **Store participant responses**: After Step 3.2, keep responses in `participant_responses` array
- **Write session file per-round**: After Step 3.3, IMMEDIATELY write to session file using Write/Edit tool
- **Display recap ALWAYS**: After Step 3.4, show round summary to terminal (not just interactive mode)
- **If verbose=true**: Include full `responses[]` in session file round data

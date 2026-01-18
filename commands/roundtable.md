---
description: Start or resume a roundtable discussion with AI expert participants. Use for technical decisions, architecture reviews, or requirements refinement.
allowed-tools: Bash(pwd:*), Bash(ls:*), Bash(mkdir:*), Bash(date:*), Bash(grep:*), Read, Write, Edit, Glob, Task, AskUserQuestion
argument-hint: "topic" [--strategy standard|disney|debate|consensus-driven|six-hats] [--participants list] [--workflow-type specs|design|brainstorm] [--output-type adr|requirements|architecture|summary] [--verbose] [--interactive] [--pro list] [--con list] [--new] [--session <id>]
skills: roundtable-execution, roundtable-strategies
---

# Roundtable Discussion

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

---

# PHASE 0: AUTO-DETECT ACTIVE SESSIONS

## Validate environment

If S2S initialized is "NOT_S2S":

    Error: Not an s2s project. Run /s2s:init first.

## Parse arguments

Extract from $ARGUMENTS:
- **Topic**: First quoted string or unquoted words (required unless resuming)
- **--strategy**: Optional. Facilitation strategy
- **--participants**: Optional. Comma-separated list
- **--workflow-type**: Optional (specs|design|brainstorm|roundtable). Default: "roundtable"
- **--output-type**: Optional (adr|requirements|architecture|summary). Default: based on workflow
- **--verbose**: Optional. Include full participant responses in session file
- **--interactive**: Optional. Ask user after each round
- **--new**: Optional. Force create new session (skip auto-detect)
- **--session**: Optional. Resume specific session by ID

**Boolean flags**: `--verbose` and `--interactive` → parse as `true` if present, `false` if absent.

Other optional arguments:
- **--pro**: Optional (debate only). Comma-separated list of participant IDs for Pro side
- **--con**: Optional (debate only). Comma-separated list of participant IDs for Con side

## Check for --session flag

**IF** --session flag is present:
- Verify session exists: `.s2s/sessions/{session-id}.yaml`
- If exists, jump to **PHASE 2: RESUME SESSION**
- If not exists, display error and list available sessions

## Check for --new flag

**IF** --new flag is present:
- Skip auto-detect
- Jump to **PHASE 1: SETUP**

## Auto-detect active sessions

**YOU MUST use Bash tool** to find active roundtable sessions:

```bash
grep -l 'workflow_type: roundtable' .s2s/sessions/*.yaml 2>/dev/null | xargs grep -l 'status: active' 2>/dev/null
```

**IF** no active sessions found:
- Jump to **PHASE 1: SETUP** (create new session)

**IF** active sessions found:

1. Read each session file to extract:
   - `id`
   - `topic`
   - `strategy`
   - `metrics.rounds_completed`

2. Display list:

```
Active roundtable sessions found:
══════════════════════════════════

1. {session-id}
   Topic: {topic}
   Strategy: {strategy}
   Progress: Round {rounds_completed}

2. {session-id}
   ...

[n] Start new session

Which would you like to continue?
```

3. Ask using AskUserQuestion with options:
   - For each session: "{session-id} - {topic}"
   - "Start new session"

4. Based on user choice:
   - If existing session selected → Jump to **PHASE 2: RESUME SESSION**
   - If "Start new session" → Jump to **PHASE 1: SETUP**

---

# PHASE 1: SETUP

## Validate topic

If no topic provided and not resuming, ask using AskUserQuestion.

## Load configuration

Read `.s2s/config.yaml` and extract:
- Default strategy: `roundtable.strategy.default`
- Workflow strategy: `roundtable.strategy.by_workflow_type[workflow_type]` (if workflow_type specified)
- Default participants: `roundtable.participants.by_workflow_type[workflow_type]`
- Escalation settings: `roundtable.escalation`
- Max rounds per conflict: `roundtable.escalation.triggers.max_rounds_per_conflict`

## Auto-detect strategy (if not specified)

> **Note**: Strategy auto-detection is performed by the **command** (roundtable.md),
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

**Use the roundtable-facilitator agent** with this input:
```yaml
action: "assign_debate_sides"
topic: "{topic}"
participants:
  - id: "{participant-1}"
    role: "{role-1}"
  - id: "{participant-2}"
    role: "{role-2}"
  # ... all participants
```

The facilitator will return:
```yaml
pro: [list of participant ids]
con: [list of participant ids]
rationale: "Assignment reasoning"
```

3. Store debate_sides in session file

## Create session

1. Create sessions directory: `mkdir -p .s2s/sessions`
2. Generate session ID: `{timestamp}-roundtable-{topic-slug}` (slug: lowercase, hyphens, max 30 chars)
3. Determine initial phase from strategy phases[0]
4. Create session file `.s2s/sessions/{session-id}.yaml`:

```yaml
# Session file - Single Source of Truth
id: "{session-id}"
workflow_type: "roundtable"
topic: "{topic}"
strategy: "{strategy}"
status: "active"

timing:
  started_at: "{ISO timestamp}"
  updated_at: "{ISO timestamp}"
  closed_at: null

participants: ["{list}"]

# Agent state (for resume capability)
agent_state:
  facilitator:
    agent_id: null
    last_round: 0
    last_action: null
  participants: {}

# Artifacts embedded
artifacts:
  decisions: {}
  open_questions: {}
  conflicts: {}

# Agenda (for roundtable, typically single topic)
agenda:
  - topic_id: "main"
    status: "open"
    coverage: []

# Rounds with summary
rounds: []

# Metrics
metrics:
  rounds_completed: 0
  artifacts:
    total: 0
    by_type: {}
  consensus_rate: 0.0

# Linked sessions (optional)
linked_sessions: {}
```

   - If strategy="debate", include `debate_sides` with pro/con participant assignments

## Display session start

    Roundtable Session Started
    ═══════════════════════════

    Session: {session-id}
    Topic: {topic}
    Strategy: {strategy}
    Participants: {list}
    Workflow: roundtable

    Starting discussion...

---

# PHASE 2: RESUME SESSION

Read the session file `.s2s/sessions/{session-id}.yaml` and extract:
- `topic`
- `strategy`
- `metrics.rounds_completed`
- `agent_state` (for resume capability)
- Current state of artifacts and agenda

Display:

    Resuming Roundtable Session
    ═══════════════════════════

    Session: {session-id}
    Topic: {topic}
    Strategy: {strategy}
    Progress: Round {rounds_completed}

    Continuing discussion...

---

# PHASE 3: DISCUSSION LOOP

**IMPORTANT: Follow the `roundtable-execution` skill instructions EXACTLY.**

The roundtable-execution skill provides detailed step-by-step instructions for:
- Round execution loop (facilitator → participants → synthesis)
- Session file updates
- Escalation handling
- Completion and output generation

## Configuration for this session

Pass these values to the skill execution:
- **topic**: {parsed topic}
- **workflow_type**: "roundtable"
- **strategy**: {selected strategy}
- **output_type**: {--output-type or "summary"}
- **participants**: {selected participant list}
- **verbose**: {verbose_flag}
- **interactive**: {interactive_flag}

## Execute roundtable

**YOU MUST** now execute the roundtable following the `roundtable-execution` skill.

**DO NOT improvise.** Follow the skill instructions step-by-step:

1. PHASE 3 of skill: Round Execution Loop
   - Step 3.1: Facilitator Question (use Task tool)
   - Step 3.2: Participant Responses (use Task tool, ALL in parallel)
   - Step 3.3: Facilitator Synthesis (use Task tool)
   - Step 3.4: Update Session File
   - Step 3.5: Handle --interactive mode (if enabled)
   - Step 3.6: Evaluate Next Action
   - REPEAT until: next_action == "conclude" AND round >= min_rounds

2. PHASE 4 of skill: Completion
   - Update session status to "closed"
   - Set `closed_at` timestamp
   - Generate output file (based on output_type)
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

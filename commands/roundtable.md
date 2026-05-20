---
description: Start or resume a roundtable discussion with AI expert participants. Use for technical decisions, architecture reviews, or requirements refinement.
allowed-tools: Bash(pwd:*), Bash(ls:*), Bash(mkdir:*), Bash(date:*), Bash(grep:*), Read, Write, Edit, Glob, Task, AskUserQuestion
argument-hint: "topic" [--strategy standard|disney|debate|consensus-driven|six-hats] [--participants list] [--workflow-type specs|design|brainstorm] [--output-type adr|requirements|architecture|summary] [--verbose] [--interactive] [--diagnostic] [--pro list] [--con list] [--new] [--session <id>]
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

**Boolean flags**: `--verbose`, `--interactive`, `--diagnostic` → parse as `true` if present, `false` if absent.

**IF --diagnostic is true**: Force `verbose_flag = true` (diagnostic mode requires verbose dumps for analysis).

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

## Fast path: Check state.json

**IF** `.s2s/state.json` exists:
1. Read the file and check `active_session`
2. **IF** `active_session` is not null AND `active_session.workflow_type IN ["roundtable", "specs", "design", "brainstorm"]`:
   - Per TECH-002 Phase 4 §4.3 step 4: master path now supports resuming sessions of any workflow_type (was restricted to "roundtable" only pre-Phase-4).
   - Extract session_id from `active_session.id`
   - Verify session file exists: `.s2s/sessions/{session_id}.yaml`
   - Read session file and check `status`
   - **IF** session status is "active":
     - Display:
       ```
       Resume active {workflow_type} session?
       ═══════════════════════════════════════

       Session: {session_id}
       Workflow: {workflow_type}
       Topic: {topic from session file}
       Strategy: {strategy from session file}
       Progress: Round {rounds_completed from session file} completed
       ```
     - Ask using AskUserQuestion:
       - "Resume this session" (recommended)
       - "Start new session"
       - "Show all sessions"
     - **IF** "Resume" → Jump to **PHASE 2: RESUME SESSION**
     - **IF** "Start new" → Jump to **PHASE 1: SETUP**
     - **IF** "Show all" → Fall through to grep scan below
   - **IF** session status is NOT "active" (stale state.json):
     - Clear `active_session` in state.json (write null)
     - Fall through to grep scan

## Fallback: Grep scan for active sessions

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
   Progress: Round {rounds_completed} completed

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

Read the file at `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-strategies/references/{strategy}.md` and load strategy phases:
- **standard**: phases: ["discussion"]
- **disney**: phases: ["dreamer", "realist", "critic"]
- **debate**: phases: ["opening", "rebuttal", "closing"]
- **consensus-driven**: phases: ["proposal", "discussion", "resolution"]
- **six-hats**: phases: ["blue-opening", "white", "red", "black", "yellow", "green", "blue-closing"]

Each phase has:
- `name`: phase identifier
- `min_rounds`: minimum rounds before advancing (default: 1)
- `goal`: what the phase should achieve

## Resolve strategy hooks (Option B parser, TECH-002 Phase 4)

Deterministic resolution of per-strategy hook overrides. Reads the strategy doc's `## Strategy hooks` opening line, matches against the fixture, produces `strategy_hook_overrides` dict for persistence in session.yaml at `agent_state.facilitator.hook_overrides`.

**Read** `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/strategy-hook-resolution.md` and load the anchor table.

**Extract** the first non-empty line of the `## Strategy hooks` section from the strategy doc already read above.

**Match** the opening line against each regex in the anchor table; first match wins. Produce `HOOK_OVERRIDES` per the matching row:
- `standard` / `consensus-driven`: `{skip: true}` (Branch 1)
- `disney` / `six-hats`: `{skip: true}` (Branch 1)
- `debate`: `{participant_response_field: "debate_role", round_summary_field: "debate_phase", policy: "facilitator_emergent"}` (Branch 2)

If no regex matches, display error to user: `"Strategy doc opening line did not match any anchor in strategy-hook-resolution.md. Edit the doc or update the fixture."` Stop session creation.

Store `HOOK_OVERRIDES` for inclusion in `session.yaml.agent_state.facilitator.hook_overrides` at session creation (Phase 1 step "Create session"). `phase-2-core.md` Step 2.2c reads this field per round and dispatches via 3-branch logic (skip / policy / absent). See `strategy-hook-resolution.md` for full details.

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
2. Generate session ID: `{timestamp}-{workflow_type}-{topic-slug}` (slug: lowercase, hyphens, max 30 chars). Per TECH-002 Phase 4 §4.3 step 2: prefix uses `workflow_type` (one of specs/design/brainstorm/roundtable), NOT command name. So `/s2s:roundtable "topic"` (default workflow_type=roundtable) → `{ts}-roundtable-{slug}` (unchanged); `/s2s:roundtable "topic" --workflow-type specs` → `{ts}-specs-{slug}` (consistent with `/s2s:specs` and Phase 8 thin launchers).
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
    hook_overrides: {HOOK_OVERRIDES from "Resolve strategy hooks" step above}  # Option B (TECH-002 Phase 4)
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
  # TECH-009: Token tracking
  tokens:
    total: 0        # TECH-009
    by_round: []

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

**Immediately update state.json** to align with session file:

**IF `.s2s/state.json` exists**: Read it first to get current `active_plan` value.

Use Write tool to write `.s2s/state.json`:
```json
{
  "active_session": {
    "id": "{session-id}",
    "workflow_type": "roundtable",
    "strategy": "{strategy}",
    "phase": "discussion",
    "round": {rounds_completed},
    "participants_count": {participants count from session}
  },
  "active_plan": {existing active_plan value OR null},
  "last_activity": {
    "timestamp": "{ISO timestamp}",
    "action": "session_resumed",
    "session_id": "{session-id}"
  }
}
```

Display:

    Resuming Roundtable Session
    ═══════════════════════════

    Session: {session-id}
    Topic: {topic}
    Strategy: {strategy}
    Progress: Round {rounds_completed} completed

    Continuing discussion...

---

# PHASE 3: Round Execution Loop

Per TECH-002 Phase 4 §4.3: roundtable.md is now master for all 4 workflow types (specs/design/brainstorm/roundtable). Uniform dispatch via `phase-2-core.md` after loading the workflow-appropriate profile. Pattern mirrors `commands/{specs,design,brainstorm}.md` Phase 2.

## Profile loading and context setup

**Read** `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/profiles/{workflow_type}.yaml` and store the parsed YAML object as `PROFILE`. All 4 workflow_types are supported post Phase 4 (`profiles/roundtable.yaml` added in §4.1). This provides workflow-specific values (artifact types, participants, agenda axis, default strategy, phase transition gating) consumed throughout Phase 2 of the skill.

Make the following variables available in conversation context for the algorithm:

- `STRATEGY` = `{strategy_to_use}` (resolved earlier in this command per the resolution hierarchy: CLI → config.yaml → profile fallback; see `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/strategy-resolution.md`)
- `SESSION_ID` = the session id created in Phase 1 (workflow_type-prefixed per §4.3 step 2)
- `ROUND_NUMBER` = `session.yaml.metrics.rounds_completed` (0 for fresh sessions, N for resume)
- `VERBOSE_FLAG` = `{verbose_flag}` parsed earlier
- `DIAGNOSTIC_FLAG` = `{diagnostic_flag}` parsed earlier
- `INTERACTIVE_FLAG` = `{interactive_flag}` parsed earlier
- `TOKEN_SCRIPT` = will be resolved by phase-2-core.md Step 2.0 (reads from `references/token-tracking.md`)

## Execute the canonical algorithm

**Read** `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/phase-2-core.md` and follow §2 (Round Loop algorithm). The algorithm internally loops Steps 2.0 → 2.9 until terminal dispatch (`conclude`, `escalate` resolved to exit, `max_rounds`, or context capacity). Step 2.10 (Phase Transition) is invoked when `PROFILE.has_phase_transition == true` (currently only brainstorm) and facilitator returns `next: "phase"`.

Strategy hook overrides at Step 2.2c are dispatched per 3-branch logic (Option B, TECH-002 Phase 4) using `session.yaml.agent_state.facilitator.hook_overrides` populated by the "Resolve strategy hooks" parser in Phase 1. See `phase-2-core.md` Step 2.2c for branch details.

After phase-2-core.md returns control, proceed to PHASE 4 below.

---

# PHASE 4: Completion

## Step 4.0: Final Diagnostic Report (IF --diagnostic)

**IF** `diagnostic_flag == true`:

**Use the session-observer agent** with this input:

```yaml
mode: "end-session"
session_path: ".s2s/sessions/{session-id}"
workflow_type: "{workflow_type}"
strategy: "{strategy_to_use}"
```

The observer will return a final diagnostic summary. Display it in a banner per the same format used by `commands/design.md` Step 3.0 (workflow / strategy / rounds / per-round status / session-level findings / RESULT verdict).

## Step 4.1: Update Session Status

→ **Token tracking**: Execute "Session Complete" section from `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/token-tracking.md` (updates `metrics.tokens.total`).

**YOU MUST use Edit tool** to update session file:

```yaml
status: "closed"
timing:
  closed_at: "{ISO timestamp}"
```

**Clear active_session from state.json**:

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

## Step 4.2: Read Session for Summary

**YOU MUST use Read tool** to read the completed session file. Extract all artifacts and round summaries per workflow_type:

- specs: `artifacts.requirements`, `artifacts.business_rules`, `artifacts.nfr`, etc. (see `profiles/specs.yaml` artifact_types)
- design: `artifacts.architecture_decisions`, `artifacts.components`, `artifacts.interfaces`, etc.
- brainstorm: `artifacts.ideas`, `artifacts.risks`, `artifacts.mitigations`, etc.
- roundtable: `artifacts.decisions`, `artifacts.open_questions`, `artifacts.conflicts` (per `profiles/roundtable.yaml`)

## Step 4.3: Generate Output

**Determine output type** (default per workflow_type, override via `--output-type`):

| workflow_type | default output_type | output file(s) |
|---------------|---------------------|----------------|
| specs | requirements | `.s2s/requirements.md` |
| design | architecture | `.s2s/architecture.md` + `.s2s/decisions/ADR-*.md` |
| brainstorm | summary | `.s2s/sessions/{id}-summary.md` + `.s2s/ideas.md` |
| roundtable | summary | `.s2s/sessions/{id}-summary.md` (no persistent project file) |

**Read** `${CLAUDE_PLUGIN_ROOT}/skills/output-generation/SKILL.md` and follow the dispatch instructions for the detected workflow_type. The skill routes to the appropriate reference template (`references/{specs-srs,design-arc42,brainstorm,roundtable-summary}.md`).

## CRITICAL REMINDERS

- **YOU MUST use the Task tool** for facilitator and participants (per phase-2-core.md); do NOT simulate responses.
- **Launch ALL participant Tasks in a SINGLE message** to ensure blind voting (Step 2.3).
- **Update session file after EACH round** (Step 2.6); do NOT batch updates.
- **Minimum 3 rounds** before conclude (per config `roundtable.limits.min_rounds`).
- **Maximum 20 rounds** force conclude (per config `roundtable.limits.max_rounds`).
- **state.json updates**: Step 2.1 writes `active_session`; Step 4.1 clears it. Token tracking checkpoints per `references/token-tracking.md`.

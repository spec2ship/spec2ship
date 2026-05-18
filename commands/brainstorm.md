---
description: Creative brainstorming session using the Disney strategy (Dreamer → Realist → Critic). Use for ideation and exploring new ideas without constraints. Auto-detects active sessions.
allowed-tools: Bash(pwd:*), Bash(ls:*), Bash(mkdir:*), Bash(date:*), Bash(grep:*), Read, Write, Edit, Glob, Task, AskUserQuestion
argument-hint: "topic" [--strategy disney|six-hats|standard] [--participants <list>] [--verbose] [--interactive] [--diagnostic] [--new] [--session <id>]
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

**FAST PATH: Check state.json** (immediate resume suggestion):

**IF** `.s2s/state.json` exists:
1. Read the file and check `active_session`
2. **IF** `active_session` is not null AND `active_session.workflow_type == "brainstorm"`:
   - Extract session_id from `active_session.id`
   - Verify session file exists: `.s2s/sessions/{session_id}.yaml`
   - Read session file and check `status`
   - **IF** session status is "active":
     - Display:
       ```
       Resume active brainstorm session?
       ═══════════════════════════════════

       Session: {session_id}
       Topic: {active_session topic from session file}
       Progress: Round {rounds_completed from session file} completed
       ```
     - Ask using AskUserQuestion:
       - "Resume this session" (recommended)
       - "Start new session"
       - "Show all sessions"
     - **IF** "Resume" → Jump to **Phase 2** (resume)
     - **IF** "Start new" → Continue to parse arguments
     - **IF** "Show all" → Fall through to grep scan below
   - **IF** session status is NOT "active" (stale state.json):
     - Clear `active_session` in state.json (write null)
     - Fall through to grep scan

**FALLBACK: Grep scan** for active brainstorm sessions:

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
   - If "Start new session" → Continue to parse arguments

---

### Parse Arguments

Extract from $ARGUMENTS:
- **topic**: Required (unless resuming). The subject for brainstorming (first quoted argument)
- **--strategy**: Override strategy (optional)
- **--participants**: Optional. Comma-separated list to override defaults

**Boolean flags**: `--verbose`, `--interactive`, and `--diagnostic` → parse as `true` if present, `false` if absent.

**IF --diagnostic is true**: Force `verbose_flag = true` (diagnostic mode requires verbose dumps for analysis).

If topic is missing, ask using AskUserQuestion:
- "What would you like to brainstorm?"

### Determine strategy

Read `.s2s/config.yaml` and determine the strategy to use:

1. **IF --strategy argument provided**: Use that value
2. **ELSE**: Read `roundtable.strategy.by_workflow_type.brainstorm` from config
3. **FALLBACK**: If not found in config, use `"disney"`

Store as **strategy_to_use** and use this value throughout the command.

**Note**: Brainstorm is optimized for Disney strategy (Dreamer → Realist → Critic phases). Other strategies will work but without phase-based structure.

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

If --skip-roundtable is NOT present:

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
strategy: "{strategy_to_use}"
limits:
  min_rounds: {from config: roundtable.limits.min_rounds}
  max_rounds: {from config: roundtable.limits.max_rounds}
escalation:
  max_rounds_per_conflict: {from config: roundtable.escalation.triggers.max_rounds_per_conflict}
  confidence_below: {from config: roundtable.escalation.triggers.confidence_below}
  critical_keywords: {from config: roundtable.escalation.triggers.critical_keywords}
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
  ideas: {}             # IDEA-*: {state, title, description, ...}
  risks: {}             # RISK-*: {state, title, severity, ...}
  mitigations: {}       # MIT-*: {state, title, risk_id, ...}
  open_questions: {}    # OQ-*: {state, title, description, ...}
  conflicts: {}         # CONF-*: {state, title, positions, ...}

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
    by_state: {}
  phases:
    dreamer: 0
    realist: 0
    critic: 0
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

## Phase 2: Round Execution Loop (Disney Strategy)

If --skip-roundtable is NOT present:

The Phase 2 Round Loop is the canonical, profile-aware algorithm defined in `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/phase-2-core.md`. Brainstorm uses the **Disney strategy** (forced — non-overridable) with three sequential phases: `dreamer → realist → critic`. The Disney phase machine is invoked at Step 2.10 when the facilitator returns `next: "phase"`. This command delegates execution to phase-2-core.md after loading the brainstorm profile.

### Profile loading and context setup

**Read** `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/profiles/brainstorm.yaml` and store the parsed YAML object as `PROFILE`. This provides workflow-specific values (artifact types IDEA/RISK/MIT, disney_phase axis, forced disney strategy, rich display block) consumed throughout Phase 2.

Make the following variables available in conversation context for the algorithm:

- `STRATEGY` = `"disney"` (forced — PROFILE.strategy_constraints.forced == true)
- `SESSION_ID` = the session id created in Phase 1
- `ROUND_NUMBER` = `session.yaml.metrics.rounds_completed` (0 for fresh sessions, N for resume)
- `VERBOSE_FLAG` = `{verbose_flag}` parsed earlier
- `DIAGNOSTIC_FLAG` = `{diagnostic_flag}` parsed earlier
- `INTERACTIVE_FLAG` = `{interactive_flag}` parsed earlier
- `TOKEN_SCRIPT` = will be resolved by phase-2-core.md Step 2.0 (reads from `references/token-tracking.md`)

### Execute the canonical algorithm

**Read** `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/phase-2-core.md` and follow §2 (Round Loop algorithm). The algorithm internally loops Steps 2.0 → 2.9 (with brainstorm's Step 2.10 Phase Transition activating after Step 2.9 dispatch when the facilitator returns `next: "phase"`) until terminal dispatch — typically `conclude` from the `critic` phase.

After phase-2-core.md returns control, proceed to Phase 3 below.

---

## Phase 3: Completion

### Step 3.0: Final Diagnostic Report (IF --diagnostic)

**IF** diagnostic_flag == true:

**Use the session-observer agent** with this input:

```yaml
mode: "end-session"
session_path: ".s2s/sessions/{session-id}"
workflow_type: "brainstorm"
strategy: "{strategy_to_use}"
```

The observer will return a final diagnostic summary.

**Display final diagnostic report**:
```
╔════════════════════════════════════════════════════════════╗
║                    DIAGNOSTIC REPORT                        ║
╠════════════════════════════════════════════════════════════╣
║ Session: {session-id}                                       ║
║ Workflow: brainstorm | Strategy: {strategy_to_use} | Rounds: {N} ║
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

Extract from session file (Single Source of Truth - ALL artifacts are embedded):
- `artifacts.ideas` - map of IDEA-* with full content
- `artifacts.risks` - map of RISK-* with full content
- `artifacts.mitigations` - map of MIT-* with full content
- `artifacts.open_questions` - map of OQ-* with full content
- `artifacts.conflicts` - map of CONF-* with full content
- Aggregate counts from `metrics.artifacts.by_type` and `metrics.artifacts.by_state`

Categorize artifacts by Disney phase:
- **Dreamer phase**: IDEA-* where `disney_phase == "dreamer"`
- **Realist phase**: IDEA-* with feasibility assessments
- **Critic phase**: RISK-* and MIT-* artifacts

### Step 3.4: User Review

Categorize and present brainstorm results:

- **Immediately feasible ideas**: Ready to implement (from realist phase assessments)
- **Requires more work**: Needs further analysis
- **Long-term/aspirational**: Future consideration

Pair risks with mitigations.

Present gathered brainstorm output:

    Brainstorm Session Summary:
    ═══════════════════════════

    Ideas Generated:
    ────────────────
    {for each ID, artifact in artifacts.ideas}
    {ID}: {artifact.title}
    Feasibility: {immediately|requires-work|long-term}
    {artifact.description}
    {/for}

    Risks Identified:
    ─────────────────
    {for each ID, artifact in artifacts.risks}
    {ID}: {artifact.title}
    Severity: {artifact.severity}
    Mitigation: {linked MIT-* or "open"}
    {/for}

    Open Questions:
    ───────────────
    {for each ID, artifact in artifacts.open_questions}
    - {ID}: {artifact.title}
    {/for}

Ask using AskUserQuestion:
- "Review brainstorm output. Would you like to:"
  - Options: "Approve and generate summary" / "Refine ideas" / "Add more ideas"

### Step 3.5-3.7: Generate Output

Read the file at `${CLAUDE_PLUGIN_ROOT}/skills/output-generation/SKILL.md` and follow the instructions for workflow_type="brainstorm":
1. Generate `.s2s/sessions/{session-id}-summary.md`
2. Update `.s2s/ideas.md` with new ideas
3. Display output summary

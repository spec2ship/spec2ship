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
objectives:
  - "{extracted}"
constraints:
  - "{extracted}"
scope:
  in:
    - "{extracted}"
  out:
    - "{extracted}"

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

Read the file at `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/agenda-design.md` and extract topics YAML, then write:
```yaml
# Captured: {ISO timestamp}
source: "${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/agenda-design.md"
workflow: "design"

topics:
  - id: "high-level-arch"
    name: "High-level architecture"
    critical: true
    done_when:
      criteria:
        - "Architectural style chosen"
        - "Key components identified"
        - "Data flow defined"
      min_decisions: 1
    exploration: "What other architectural styles should we consider?"
  # ... (copy all topics from agenda-design.md)
```

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

If --skip-roundtable is NOT present:

The Phase 2 Round Loop is the canonical, profile-aware algorithm defined in `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/phase-2-core.md`. This command delegates execution to that file after loading the design profile.

### Profile loading and context setup

**Read** `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/profiles/design.yaml` and store the parsed YAML object as `PROFILE`. This provides workflow-specific values (artifact types, participants, agenda axis, default strategy `debate`) consumed throughout Phase 2.

Make the following variables available in conversation context for the algorithm:

- `STRATEGY` = `{strategy_to_use}` (resolved earlier in this command)
- `SESSION_ID` = the session id created in Phase 1
- `ROUND_NUMBER` = `session.yaml.metrics.rounds_completed` (0 for fresh sessions, N for resume)
- `VERBOSE_FLAG` = `{verbose_flag}` parsed earlier
- `DIAGNOSTIC_FLAG` = `{diagnostic_flag}` parsed earlier
- `INTERACTIVE_FLAG` = `{interactive_flag}` parsed earlier
- `TOKEN_SCRIPT` = will be resolved by phase-2-core.md Step 2.0 (reads from `references/token-tracking.md`)

### Execute the canonical algorithm

**Read** `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/phase-2-core.md` and follow §2 (Round Loop algorithm). The algorithm internally loops Steps 2.0 → 2.9 until terminal dispatch (`conclude`, `escalate` resolved to exit, `max_rounds`, or context capacity).

When `STRATEGY == "debate"`, the synthesis at Step 2.4 may include an optional `debate_phase` field in the round summary. This is captured at Step 2.6 of phase-2-core.md.

After phase-2-core.md returns control, proceed to Phase 3 below.

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

Extract from session file (Single Source of Truth - ALL artifacts are embedded):
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

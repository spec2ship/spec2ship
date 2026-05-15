---
description: Define functional requirements through a roundtable discussion. Reads CONTEXT.md and produces structured requirements.md. Auto-detects active sessions.
allowed-tools: Bash(pwd:*), Bash(ls:*), Bash(mkdir:*), Bash(date:*), Bash(grep:*), Read, Write, Edit, Glob, Task, AskUserQuestion
argument-hint: [--skip-roundtable] [--format srs|volere|simple] [--strategy consensus-driven|standard|six-hats] [--verbose] [--interactive] [--diagnostic] [--new] [--session <id>]
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
- Check if `.s2s/requirements.md` exists
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

**FAST PATH: Check state.json** (immediate resume suggestion):

**IF** `.s2s/state.json` exists:
1. Read the file and check `active_session`
2. **IF** `active_session` is not null AND `active_session.workflow_type == "specs"`:
   - Extract session_id from `active_session.id`
   - Verify session file exists: `.s2s/sessions/{session_id}.yaml`
   - Read session file and check `status`
   - **IF** session status is "active":
     - Display:
       ```
       Resume active specs session?
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

**FALLBACK: Grep scan** for active specs sessions:

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

Read `.s2s/CONTEXT.md` and verify it has been populated.

If CONTEXT.md contains placeholder text like "{Project description}":

    Error: Project context not defined.
    Run /s2s:init first to set up the project and gather context.

### Smart Source Detection (no flags needed)

**Detect available sources** for requirements input:

1. **Check for recent brainstorm sessions**:
   Use Bash to find brainstorm sessions from the last 7 days:
   ```bash
   find .s2s/sessions -name "*.yaml" -mtime -7 2>/dev/null | xargs grep -l 'workflow_type: brainstorm' 2>/dev/null
   ```

2. **Check for ideas.md with active ideas**:
   - Read `.s2s/ideas.md` if exists
   - Count ideas under `## Active` section (not `## Parked`, `## Promoted`, `## Rejected`)
   - Look for `**Status**: draft` or `**Status**: validated`

3. **Check for BACKLOG items**:
   - Read `.s2s/BACKLOG.md` if exists
   - Count items under `## Planned` section with status `planned`

**IF sources found**:

Display sources and ask user:

```
Available Input Sources
═══════════════════════

{IF recent brainstorm sessions found}
Recent Brainstorm Sessions:
- {session-id}: "{topic}" ({N} ideas, {date})
{/IF}

{IF active ideas in ideas.md}
Active Ideas (.s2s/ideas.md):
- {count} draft/validated ideas available
{/IF}

{IF planned BACKLOG items}
Planned Backlog Items (.s2s/BACKLOG.md):
- {count} features planned for implementation
{/IF}

These sources can inform requirements gathering.
```

Ask using AskUserQuestion:
- "Would you like to use these as input for requirements?"
  - Options:
    - "Yes, use all available sources (recommended)" - load all sources into context
    - "Select specific sources" - let user choose
    - "Start fresh" - ignore and start from CONTEXT.md only

**IF user selects "Select specific sources"**:
Present checkboxes for:
- Each brainstorm session
- ideas.md
- BACKLOG.md

**Store selected sources** as `input_sources` for use in Phase 1 session setup.

**IF ID passed in arguments** (e.g., "specs IDEA-001"):
- Parse the ID from $ARGUMENTS
- **IF IDEA-*** pattern: Read `.s2s/ideas.md`, find that idea, use as primary input
- **IF FEAT-*** pattern: Read `.s2s/BACKLOG.md`, find that item, use as primary input
- Display: "Using {ID}: {title} as primary input for requirements"

### Check for existing requirements

If `.s2s/requirements.md` exists and has content:
- Display summary of existing requirements (count REQ-* entries)
- Ask using AskUserQuestion: "Requirements exist. What would you like to do?"
  - Options: "Override (replace all)" / "Merge (add new)" / "Cancel"
- If cancel, stop
- If override, will replace entire file at end
- If merge, will append new REQ-* with incremented IDs at end

### Parse arguments

Extract from $ARGUMENTS:
- **--skip-roundtable**: Skip discussion, generate from CONTEXT.md directly
- **--format**: Document format (srs|volere|simple). Default: srs
- **--strategy**: Override strategy (optional)

**Boolean flags**: `--verbose`, `--interactive`, and `--diagnostic` → parse as `true` if present, `false` if absent.

**IF --diagnostic is true**: Force `verbose_flag = true` (diagnostic mode requires verbose dumps for analysis).

### Determine strategy

Read `.s2s/config.yaml` and determine the strategy to use:

1. **IF --strategy argument provided**: Use that value
2. **ELSE**: Read `roundtable.strategy.by_workflow_type.specs` from config
3. **FALLBACK**: If not found in config, use `"consensus-driven"`

Store as **strategy_to_use** and use this value throughout the command.

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

# Input sources detected by smart source detection
input_sources:
  brainstorm_sessions:
    # IF brainstorm sessions were selected, list session IDs and key ideas
    - session_id: "{session-id}"
      topic: "{topic}"
      ideas: ["{IDEA-* titles from session}"]
  ideas:
    # IF ideas.md was selected, list active ideas
    - id: "IDEA-001"
      title: "{title}"
      status: "{draft|validated}"
      problem: "{problem description}"
  backlog:
    # IF BACKLOG.md was selected, list planned items
    - id: "FEAT-001"
      title: "{title}"
      context: "{description}"
  primary_id: "{IF specific ID was passed, e.g., IDEA-001}"
```

**YOU MUST use Write tool NOW** to create `config-snapshot.yaml`:

Read `.s2s/config.yaml` and extract roundtable config, then write:
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
  - "ux-researcher"
  - "business-analyst"
  - "qa-lead"
```

**YOU MUST use Write tool NOW** to create `agenda.yaml`:

Read the file at `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/agenda-specs.md` and extract topics YAML, then write:
```yaml
# Captured: {ISO timestamp}
source: "${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/agenda-specs.md"
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
  requirements: {}      # REQ-*: {state, title, description, acceptance, ...}
  business_rules: {}    # BR-*: {state, title, description, conditions, ...}
  nfr: {}               # NFR-*: {state, title, category, target, ...}
  exclusions: {}        # EX-*: {state, title, description, rationale, ...}
  open_questions: {}    # OQ-*: {state, title, description, raised_by, ...}
  conflicts: {}         # CONF-*: {state, title, positions, resolution, ...}

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
    by_state: {}
  topics:
    total: 6
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

The Phase 2 Round Loop is the canonical, profile-aware algorithm defined in `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/phase-2-core.md`. This command delegates execution to that file after loading the specs profile.

### Profile loading and context setup

**Read** `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/profiles/specs.yaml` and store the parsed YAML object as `PROFILE`. This provides workflow-specific values (artifact types, participants, agenda axis, default strategy) consumed throughout Phase 2.

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

After phase-2-core.md returns control, proceed to Phase 3 below.

---

## Phase 3: Completion

### Step 3.0: Final Diagnostic Report (IF --diagnostic)

**IF** diagnostic_flag == true:

**Use the session-observer agent** with this input:

```yaml
mode: "end-session"
session_path: ".s2s/sessions/{session-id}"
workflow_type: "specs"
strategy: "{strategy_to_use}"
```

The observer will return a final diagnostic summary.

**Display final diagnostic report**:
```
╔════════════════════════════════════════════════════════════╗
║                    DIAGNOSTIC REPORT                        ║
╠════════════════════════════════════════════════════════════╣
║ Session: {session-id}                                       ║
║ Workflow: specs | Strategy: {strategy_to_use} | Rounds: {N}  ║
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
- `artifacts.requirements` - map of REQ-* with full content
- `artifacts.business_rules` - map of BR-* with full content
- `artifacts.nfr` - map of NFR-* with full content
- `artifacts.exclusions` - map of EX-* with full content
- `artifacts.open_questions` - map of OQ-* with full content
- `artifacts.conflicts` - map of CONF-* with full content
- Aggregate counts from `metrics.artifacts.by_type` and `metrics.artifacts.by_state`

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

### Step 3.5-3.7: Generate Output

Read the file at `${CLAUDE_PLUGIN_ROOT}/skills/output-generation/SKILL.md` and follow the instructions for workflow_type="specs":
1. Generate `.s2s/requirements.md` (merge or override mode based on earlier choice)
2. Update `.s2s/CONTEXT.md`
3. Display output summary

---

## Skip Roundtable Mode

**If --skip-roundtable IS present:**

1. Read CONTEXT.md directly
2. Infer requirements from objectives and scope
3. Generate basic requirement list without discussion
4. Skip session folder creation
5. Proceed to document generation

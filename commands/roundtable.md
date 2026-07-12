---
description: Start or resume a roundtable discussion with AI expert participants. Use for technical decisions, architecture reviews, or requirements refinement.
allowed-tools: Bash(pwd:*), Bash(ls:*), Bash(mkdir:*), Bash(date:*), Bash(grep:*), Read, Write, Edit, Glob, Task, AskUserQuestion
argument-hint: "topic" [--strategy standard|disney|debate|consensus-driven|six-hats] [--participants list] [--workflow-type specs|design|brainstorm] [--output-type adr|requirements|architecture|summary] [--verbose] [--interactive] [--diagnostic] [--new] [--session <id>]
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

## Invocation modes

`roundtable.md` is the master orchestrator for all 4 workflow types. It runs in two modes:

- **Native**: invoked directly as `/s2s:roundtable`. `workflow_type` resolves to `roundtable`.
- **Delegated**: a thin launcher (`/s2s:specs`, `/s2s:design`, `/s2s:brainstorm`) Reads this file and follows it after its own workflow-specific prep. The launcher pre-sets handoff variables in conversation context.

**Handoff-variable contract** (delegated mode; in native mode none are set):

| Variable | Set by | Consumed at |
|----------|--------|-------------|
| `WORKFLOW_TYPE` | launcher (mandatory) | PHASE 0 workflow_type resolution + profile load |
| `INPUT_SOURCES` | specs launcher | PHASE 1 `context-snapshot.yaml` `input_sources:` block |
| `OUTPUT_MERGE_MODE` | specs/design launcher | PHASE 4 output generation (`override` / `merge`) |
| `OUTPUT_FORMAT` | specs launcher | PHASE 4 output generation (`--format` value) |
| `FOCUS_AREA` | design launcher | facilitator discussion-context hint + PHASE 4 |

Strategy and output-type are NOT handoff variables: the master resolves strategy via the D3 hierarchy and output-type from `workflow_type`.

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
- **--workflow-type**: Optional (specs|design|brainstorm|roundtable).
- **--output-type**: Optional (adr|requirements|architecture|summary). Default: based on workflow

**Resolve `workflow_type`** (used throughout this command and to load the profile): if the `WORKFLOW_TYPE` handoff variable is set (delegated mode), use it; else if `--workflow-type` is given, use that; else default `"roundtable"` (native mode).
- **--verbose**: Optional. Include full participant responses in session file
- **--interactive**: Optional. Ask user after each round
- **--new**: Optional. Force create new session (skip auto-detect)
- **--session**: Optional. Resume specific session by ID

**Boolean flags**: `--verbose`, `--interactive`, `--diagnostic` → parse as `true` if present, `false` if absent.

**IF --diagnostic is true**: Force `verbose_flag = true` (diagnostic mode requires verbose dumps for analysis).

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
2. **IF** `active_session` is not null AND `active_session.workflow_type == {workflow_type}` (the resolved workflow_type):
   - Auto-detect is scoped to the invoked workflow_type (TECH-002 Phase 8): `/s2s:specs` (delegated) offers only `specs` sessions; native `/s2s:roundtable` offers only `roundtable` sessions. Resume of any workflow_type is supported (Phase 4 §4.3 step 4).
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

**YOU MUST use Bash tool** to find active sessions for the resolved workflow_type:

```bash
grep -l 'workflow_type: {workflow_type}' .s2s/sessions/*.yaml 2>/dev/null | xargs grep -l 'status: active' 2>/dev/null
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
Active {workflow_type} sessions found:
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

## Load workflow profile

**Read** `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/profiles/{workflow_type}.yaml` and store the parsed object as `PROFILE`. All 4 workflow types have a profile. `PROFILE` drives session setup below (topic, artifacts, agenda/phases, participants) and is reused in PHASE 3.

## Validate topic

The session topic is resolved per `PROFILE.topic`:
- IF `PROFILE.topic.source == "cli-arg.topic"` (roundtable, brainstorm): use the topic from `$ARGUMENTS`. If no topic was provided and not resuming, ask using AskUserQuestion.
- IF `PROFILE.topic.source` begins with `context-snapshot.` (specs, design): the topic is **synthesized** in "Create session" below from `PROFILE.topic.pattern` (no prompt).

## Load configuration

Read `.s2s/config.yaml` and extract:
- Default strategy: `roundtable.strategy.default`
- Workflow strategy: `roundtable.strategy.by_workflow_type[workflow_type]` (if workflow_type specified)
- Default participants: `roundtable.participants.by_workflow_type[workflow_type]`
- Escalation settings: `roundtable.escalation`
- Max rounds per conflict: `roundtable.escalation.triggers.max_rounds_per_conflict`

**Resolve participants** (first match wins):
1. `--participants` list from `$ARGUMENTS` — honored only when `PROFILE.participants.configurable == true`; if the profile is not configurable, display `"⚠️ {workflow_type} panel is fixed, ignoring --participants"` and fall through.
2. `.s2s/config.yaml` `roundtable.participants.by_workflow_type[workflow_type]` (if set).
3. `PROFILE.participants.default`.

**Panel domain coverage check (VKT-035)** — after resolution, IF `workflow_type` is `specs` or `design` AND the resolved panel contains NO technical role (none of: `software-architect`, `technical-lead`, `devops-engineer`, `security-champion`, `claude-code-expert`): set `PANEL_WARNING = true`. Warn only — do NOT block session creation. The warning text is rendered inside the "Display session start" block below (BUG-026: a standalone display step here gets skipped at runtime; the session-start block is always rendered, so the warning rides it).

## Auto-detect strategy (if not specified)

> **Note**: Strategy auto-detection is performed by the **command** (roundtable.md),
> NOT by the facilitator agent. The command analyzes topic keywords before
> launching any agents.

If --strategy not provided:

> **Keyword → strategy mapping (user discoverability)**: this table is documented here for UX hints. The authoritative strategy descriptions live in `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-strategies/references/{strategy}.md` (consumed via the Option B parser, see "Resolve strategy hooks" section below). If this table drifts from the strategy docs, the strategy docs are correct. (TECH-002 Phase 4 §4.4 disclaimer.)

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

Read the file at `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-strategies/references/{strategy}.md`. The canonical phase enumeration for the chosen strategy lives in its Configuration block (YAML at the top of the doc). The strategy-hook overrides parsed in the "Resolve strategy hooks" section below surface phase metadata when needed (e.g. `debate_phase` for debate strategy). Per TECH-002 Phase 4 §4.4: inline phase enumeration removed to eliminate drift versus strategy docs (consensus-driven and six-hats had stale phase names pre-Phase-4; source-of-truth deferral resolves).

Each phase in the strategy doc declares:
- `name`: phase identifier
- `min_rounds`: minimum rounds before advancing (default: 1)
- `goal` / `prompt_suffix`: what the phase should achieve / how facilitator frames it

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

## Create session

`PROFILE` (loaded above) drives every workflow-specific value here. This session-setup path is identical for all 4 workflow types (TECH-002 Phase 8: profile-driven PHASE 1).

### Step 1: Resolve the topic

Per `PROFILE.topic`:
- `source: cli-arg.topic` → the topic from `$ARGUMENTS` (resolved at "Validate topic" above).
- `source: context-snapshot.project_name` → substitute `{project_name}` (from `.s2s/CONTEXT.md`) into `PROFILE.topic.pattern`.

### Step 2: Session folder

1. `mkdir -p .s2s/sessions`
2. Generate session ID: `{YYYYMMDD}-{HHMMSS}-{workflow_type}-{topic-slug}` (slug: lowercase, hyphens, max 30 chars, from the resolved topic). The `workflow_type` prefix keeps ids consistent across native and delegated invocation.
3. `mkdir -p .s2s/sessions/{session-id}`
4. IF `verbose_flag` OR `diagnostic_flag`: `mkdir -p .s2s/sessions/{session-id}/rounds`

### Step 3: Snapshot files

`phase-2-core.md` (§2.0, §3) reads `config-snapshot.yaml` and `context-snapshot.yaml` as canonical inputs. The master writes them for **all** workflow types.

**Write** `.s2s/sessions/{session-id}/context-snapshot.yaml`. Read `.s2s/CONTEXT.md` (and `.s2s/requirements.md` when present) and write:

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
  in: ["{extracted}"]
  out: ["{extracted}"]
```

Append the workflow-specific block:
- **specs**: `input_sources:` populated from the `INPUT_SOURCES` handoff variable (brainstorm sessions / ideas / backlog / `primary_id` / `baseline_requirements`), or empty when unset. `baseline_requirements` (VKT-004) carries `{path, items: [{id: "BASE-{NNN}", title, summary}]}` — the parsed baseline items the session must cover.
- **design**: `requirements_summary:` with `core:` and `nfr:` lists from `.s2s/requirements.md`.
- **brainstorm**: `brainstorm_topic: "{topic}"`.
- **roundtable**: no extra block.

**Write** `.s2s/sessions/{session-id}/config-snapshot.yaml`. Read `.s2s/config.yaml` and write:

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
  - "{each resolved participant}"
```

**IF** `PROFILE.progress.agenda_reference` is set (specs, design): **Write** `.s2s/sessions/{session-id}/agenda.yaml`. Read `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/{PROFILE.progress.agenda_reference}` and copy its topics:

```yaml
# Captured: {ISO timestamp}
source: "{PROFILE.progress.agenda_reference}"
workflow: "{workflow_type}"
topics:
  # ... all topics from the referenced agenda file
```

Workflows without `agenda_reference` (roundtable, brainstorm) get no `agenda.yaml`.

### Step 4: Session file

**Write** `.s2s/sessions/{session-id}.yaml`. The skeleton is profile-driven:
- `artifacts:` is one empty map per entry in `PROFILE.artifact_types`, keyed by its `session_key`.
- progress block, per `PROFILE.progress.axis`:
  - `axis: agenda` → an `agenda:` list with one `{topic_id, status: "open", coverage: []}` entry per agenda topic (the `agenda.yaml` topics, or a single `main` topic when `agenda_reference` is absent); and `metrics.topics: {total: {count}, closed: 0}`.
  - `axis: disney_phase` → `current_phase:` (first phase) and a `phases:` list of `{name, status, rounds: []}`; and `metrics.phases: {<phase>: 0, ...}`.

```yaml
# Session file - Single Source of Truth
id: "{session-id}"
topic: "{resolved topic}"
workflow_type: "{workflow_type}"
strategy: "{strategy_to_use}"
status: "active"

timing:
  started_at: "{ISO timestamp}"
  updated_at: "{ISO timestamp}"
  closed_at: null

participants: ["{resolved list}"]

# Agent state (for resume capability)
agent_state:
  facilitator:
    agent_id: null
    last_round: 0
    last_action: null
    hook_overrides: {HOOK_OVERRIDES from "Resolve strategy hooks" step above}  # Option B (TECH-002 Phase 4)
  participants: {}

# Artifacts: one empty map per PROFILE.artifact_types[].session_key
artifacts:
  {session_key}: {}
  # ... repeat for every PROFILE.artifact_types entry

# Progress block per PROFILE.progress.axis (agenda: OR current_phase: + phases:)
{agenda or phases block per the rule above}

# Rounds with summary
rounds: []

# Metrics
metrics:
  rounds_completed: 0
  artifacts:
    total: 0
    by_type: {}
    by_state: {}
  {topics or phases counter per axis}
  consensus_rate: 0.0
  # TECH-009: Token tracking
  tokens:
    total: 0
    by_round: []

# Validation state
validation:
  last_check: null
  status: null
  warnings: []

# Linked sessions (optional)
linked_sessions: {}
```

## Display session start

**YOU MUST display this block** (including the warning line when `PANEL_WARNING == true` — do not drop it):

    Roundtable Session Started
    ═══════════════════════════

    Session: {session-id}
    Topic: {topic}
    Strategy: {strategy}
    Participants: {list}
    Workflow: {workflow_type}
    {IF PANEL_WARNING}
    ⚠️  Panel has no technical role: feasibility and technical constraints
        may go unchallenged. Add one via --participants or config.yaml
        (roundtable.participants.by_workflow_type.{workflow_type}).
    {/IF}

    Starting discussion...

---

# PHASE 2: RESUME SESSION

Read the session file `.s2s/sessions/{session-id}.yaml` and extract:
- `workflow_type` (drives profile load and state.json below; do NOT assume `roundtable`)
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
    "workflow_type": "{workflow_type from session file}",
    "strategy": "{strategy}",
    "phase": "{state_phase: from session file progress block, or PROFILE.state_phase}",
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

**Ensure `PROFILE` is loaded**: on the new-session path it was loaded in PHASE 1 ("Load workflow profile"). On the resume path (PHASE 2, PHASE 1 skipped), **Read** `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/profiles/{workflow_type}.yaml` now and store it as `PROFILE` (`{workflow_type}` from the resumed session file). `PROFILE` provides workflow-specific values (artifact types, participants, agenda axis, default strategy, phase transition gating) consumed throughout Phase 2.

Make the following variables available in conversation context for the algorithm:

- `STRATEGY` = `{strategy_to_use}` (resolved earlier in this command per the resolution hierarchy: CLI → config.yaml → profile fallback; see `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/strategy-resolution.md`)
- `SESSION_ID` = the session id created in Phase 1 (workflow_type-prefixed per §4.3 step 2)
- `ROUND_NUMBER` = `session.yaml.metrics.rounds_completed` (0 for fresh sessions, N for resume)
- `VERBOSE_FLAG` = `config-snapshot.yaml.verbose` (the snapshot written in Phase 1; canonical source per `phase-2-core.md` §3)
- `DIAGNOSTIC_FLAG` = `config-snapshot.yaml.diagnostic`
- `INTERACTIVE_FLAG` = `config-snapshot.yaml.interactive`
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

**Honor the delegated-mode handoff variables** when set (a thin launcher pre-set them; see "Invocation modes"):
- `OUTPUT_MERGE_MODE` (specs, design): `merge` appends new artifacts with incremented IDs to the existing `requirements.md` / `architecture.md`; `override` (or unset) replaces the file.
- `OUTPUT_FORMAT` (specs): the document format passed to the output skill (`srs` | `volere` | `simple`); default `srs`.
- `FOCUS_AREA` (design): if set, note the focus area in the generated architecture document.

## CRITICAL REMINDERS

- **YOU MUST use the Task tool** for facilitator and participants (per phase-2-core.md); do NOT simulate responses.
- **Launch ALL participant Tasks in a SINGLE message** to ensure blind voting (Step 2.3).
- **Update session file after EACH round** (Step 2.6); do NOT batch updates.
- **Minimum 3 rounds** before conclude (per config `roundtable.limits.min_rounds`).
- **Maximum 20 rounds** force conclude (per config `roundtable.limits.max_rounds`).
- **state.json updates**: Step 2.1 writes `active_session`; Step 4.1 clears it. Token tracking checkpoints per `references/token-tracking.md`.

---
name: Roundtable Execution
description: "This skill provides instructions for executing multi-agent roundtable discussions.
  Use when a command needs to run discussion rounds with facilitator and participants.
  Referenced by: specs.md, design.md, brainstorm.md.
  Trigger: 'execute roundtable', 'run discussion rounds', 'multi-agent discussion'."
version: 2.0.0
---

# Roundtable Execution Instructions

This skill provides step-by-step instructions for executing a multi-agent roundtable discussion with file-based artifact management.

## When to Use This Skill

- Executing `/s2s:specs` requirements gathering
- Executing `/s2s:design` architecture design
- Executing `/s2s:brainstorm` ideation sessions

---

## Workflow Context

Each workflow has specific goals, participants, artifacts, and outputs:

### specs Workflow

| Aspect | Value |
|--------|-------|
| **Goal** | Define WHAT to build - requirements, constraints, scope |
| **Default Participants** | product-manager, ux-researcher, business-analyst, qa-lead |
| **Default Strategy** | consensus-driven |
| **Primary Artifacts** | REQ-* (requirements), BR-* (business rules), NFR-* (non-functional) |
| **Secondary Artifacts** | OQ-* (open questions), CONF-* (conflicts), EX-* (exclusions) |
| **Output** | `.s2s/requirements.md` |
| **Agenda** | `references/agenda-specs.md` |

### design Workflow

| Aspect | Value |
|--------|-------|
| **Goal** | Define HOW to build - architecture, components, interfaces |
| **Default Participants** | software-architect, security-champion, technical-lead, devops-engineer |
| **Default Strategy** | debate |
| **Primary Artifacts** | ARCH-* (decisions), COMP-* (components), INT-* (interfaces) |
| **Secondary Artifacts** | ADR-* (decision records), OQ-*, CONF-* |
| **Output** | `.s2s/architecture.md` + `.s2s/decisions/` |
| **Agenda** | `references/agenda-design.md` |

### brainstorm Workflow

| Aspect | Value |
|--------|-------|
| **Goal** | Explore possibilities - ideas, risks, mitigations |
| **Default Participants** | Variable (specified via --participants flag) |
| **Default Strategy** | disney (FORCED - cannot be changed) |
| **Primary Artifacts** | IDEA-* (ideas), RISK-* (risks), MIT-* (mitigations) |
| **Secondary Artifacts** | OQ-* |
| **Output** | `.s2s/sessions/{session-id}-summary.md` |
| **Agenda** | `references/agenda-brainstorm.md` (phase-based) |

### Workflow Differences Summary

| Aspect | specs | design | brainstorm |
|--------|-------|--------|------------|
| Focus | User needs, requirements | Technical architecture | Creative exploration |
| Tone | Collaborative agreement | Adversarial evaluation | No criticism (dreamer) → Full critique (critic) |
| Participants | Business + QA focus | Technical focus | Flexible |
| Strategy | Consensus | Debate | Disney phases |

---

## Key Architecture

- **Session file**: `.s2s/sessions/{session-id}.yaml` - Slim index
- **Session folder**: `.s2s/sessions/{session-id}/` - Artifacts and dumps
- **Artifacts**: Individual YAML files per requirement/conflict/etc.
- **Verbose dumps**: `rounds/` subfolder with per-actor dump files

---

## PHASE 1: Session Setup

### Step 1.1: Generate Session ID

```
{YYYYMMDD}-{workflow_type}-{project-slug}
Example: 20260107-requirements-elfgiftrush
```

### Step 1.2: Create Session Folder Structure

```bash
mkdir -p .s2s/sessions/{session-id}
mkdir -p .s2s/sessions/{session-id}/rounds  # Only if --verbose
```

### Step 1.3: Create Snapshot Files

**context-snapshot.yaml**: Read `.s2s/CONTEXT.md` and write YAML snapshot:
```yaml
# Captured: {ISO timestamp}
source: ".s2s/CONTEXT.md"

project_name: "{from CONTEXT.md}"
description: "{from CONTEXT.md}"
objectives: [...]
constraints: [...]
scope:
  in: [...]
  out: [...]
```

**config-snapshot.yaml**: Read `.s2s/config.yaml` and write relevant config:
```yaml
# Captured: {ISO timestamp}
source: ".s2s/config.yaml"

# Project type for scope awareness
project:
  type: "{from config.yaml: type}"  # standalone | workspace | component
  workspace_path: "{from config.yaml: workspace.path if component, else null}"

verbose: {verbose_flag}
interactive: {interactive_flag}
strategy: "{strategy}"

# Read from config.yaml - DO NOT hardcode values
limits:
  min_rounds: "{from config.yaml: roundtable.limits.min_rounds}"
  max_rounds: "{from config.yaml: roundtable.limits.max_rounds}"
escalation:
  max_rounds_per_conflict: "{from config.yaml: roundtable.escalation.triggers.max_rounds_per_conflict}"
  confidence_below: "{from config.yaml: roundtable.escalation.triggers.confidence_below}"
  critical_keywords: "{from config.yaml: roundtable.escalation.triggers.critical_keywords}"

# Consensus rules per strategy (ADR-0010)
consensus: "{from config.yaml: roundtable.strategy.consensus[strategy]}"

participants: [...]

# Workspace scope (only if type is workspace or component)
# Used by facilitator to validate topic appropriateness
workspace_scope: null  # See Step 1.3b for population
```

**agenda.yaml**: Copy workflow agenda from `references/agenda-{workflow_type}.md`:
```yaml
# Captured: {ISO timestamp}
source: "skills/roundtable-execution/references/agenda-{workflow_type}.md"
workflow: "{workflow_type}"
topics: [...]  # Full topic definitions with done_when criteria
```

### Step 1.3b-1.4: Workspace Scope (if applicable)

**IF project.type == "standalone"**: Skip to Step 1.5.

**IF project.type == "workspace" OR "component"**: See `references/workspace-scope.md` for:
- Step 1.3b: Load workspace scope from workspace.yaml
- Step 1.3c: Context loading strategy (ADR-0009)
- Step 1.4: Topic validation and scope notices

### Step 1.5: Create Session Index File

Write `.s2s/sessions/{session-id}.yaml` (for full schema details, see `references/session-schema.md`):
```yaml
id: "{session-id}"
topic: "{topic}"
workflow_type: "{workflow_type}"
strategy: "{strategy}"
status: "active"

timing:
  started_at: "{ISO timestamp}"
  updated_at: "{ISO timestamp}"
  closed_at: null

# Agent state (for resume capability)
agent_state:
  facilitator:
    agent_id: null
    last_round: 0
    last_action: null
  participants: {}

# ARTIFACTS - embedded with full content (NOT separate files)
artifacts:
  requirements: {}      # REQ-*: {state, title, description, ...}
  business_rules: {}    # BR-*: {state, title, description, ...}
  nfr: {}               # NFR-*: {state, category, target, ...}
  exclusions: {}        # EX-*: {state, title, rationale, ...}
  open_questions: {}    # OQ-*: {state, question, raised_by, ...}
  conflicts: {}         # CONF-*: {state, positions, resolution, ...}

agenda: []  # Will be populated from agenda.yaml

rounds: []

metrics:
  rounds_completed: 0
  artifacts:
    total: 0
    by_type: {}
    by_state: {}
  topics:
    total: 0
    closed: 0
  consensus_rate: 0.0
  tokens:
    estimated_total: 0
    by_round: []

validation:
  last_check: null
  status: null
  warnings: []
```

---

## PHASE 2: Round Execution Loop

### Loop Variables

```
round_number = 0
session_folder = ".s2s/sessions/{session-id}/"
```

### Step 2.1: Display Round Start

```
═══════════════════════════════════════════════════════════════
ROUNDTABLE: {topic}
Strategy: {strategy} | Round: {round_number + 1}
═══════════════════════════════════════════════════════════════

AGENDA STATUS:
{for each topic in agenda}
[{status}] {topic_name} {(CRITICAL) if critical}
{/for}

ARTIFACTS: {count} requirements, {count} conflicts, {count} open questions
```

**IF tokens_flag AND round_number == 0**: Read `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/token-estimation.md` → Execute "Script Location" section, then "Session Start" section

**IF tokens_flag**: Read `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/token-estimation.md` → Execute "Per-Round Init" section

### Step 2.2: Facilitator Question

**Use the roundtable-facilitator agent** with this input:

```yaml
action: "question"
round: {round_number + 1}
topic: "{session topic}"
strategy: "{strategy}"
phase: "{current phase from strategy}"
workflow_type: "{workflow_type}"

# Values from config-snapshot.yaml (NOT hardcoded)
escalation_config:
  min_rounds: "{from config-snapshot.yaml: limits.min_rounds}"
  max_rounds: "{from config-snapshot.yaml: limits.max_rounds}"
  max_rounds_per_conflict: "{from config-snapshot.yaml: escalation.max_rounds_per_conflict}"
  confidence_below: "{from config-snapshot.yaml: escalation.confidence_below}"

# Consensus rules for current strategy (ADR-0010)
consensus: "{from config-snapshot.yaml: consensus}"

# Project context (from context-snapshot.yaml)
project_context:
  name: "{project name}"
  description: "{project description}"
  domain: "{domain}"
  tech_stack: ["{tech}"]
  constraints: ["{constraint}"]

# Current session state (from session file - FULL content for context building)
# Facilitator uses this to build participant_context
session_state:
  artifacts:
    requirements: [{id, title, state, description, acceptance, ...}]
    conflicts: [{id, title, state, positions, ...}]
    open_questions: [{id, title, state, description, ...}]
    # ... all artifact types with FULL content
  rounds:
    - round: {N}
      focus: "{topic_id}"
      synthesis: "{synthesis text}"
    # ... previous rounds

agenda:
  - id: "{topic_id}"
    title: "{topic title}"
    status: "{open|partial|closed}"
    priority: "{critical|normal}"
    done_when:
      criteria: [...]
      min_requirements: {N}
  # ... more topics from agenda.yaml

participants:
  - "{participant-1}"
  - "{participant-2}"
  # ... configured participants
```

The facilitator will return:
```yaml
action: "question"
decision:
  focus_type: "{agenda|conflict|open_question}"
  topic_id: "{topic}"
  rationale: "{reason}"
question: "{the question for participants}"
exploration: "{exploration prompt}"
participants: "all"  # or list of specific participants

# PARTICIPANT CONTEXT - Ready to use by command
# Command passes this directly to participants (they have NO tools)
participant_context:
  shared:
    project_summary: |
      {Condensed project info from context-snapshot.yaml}
    relevant_artifacts:
      - id: "{ID}"
        title: "{title}"
        state: "{state}"
        description: |
          {FULL description - not truncated}
        # ... all fields of each artifact
    open_conflicts: [...]    # Full content, not just IDs
    open_questions: [...]    # Full content, not just IDs
    recent_rounds:
      - round: {N}
        synthesis: |
          {FULL synthesis text}
  overrides: null  # or per-participant directives for debate/six-hats
```

**Parse response**: Extract `decision`, `participant_context`, `question`, `exploration`, `participants`

**IF --verbose**: Write dump file `rounds/{NNN}-01-facilitator-question.yaml` (see `references/verbose-dump-format.md` for naming and content format)

**IF tokens_flag**: Read `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/token-estimation.md` → Execute "Capture T1" section

### Step 2.3: Participant Responses (PARALLEL)

**Launch ALL participant agents in SINGLE message** for blind voting.

For EACH participant, **use the roundtable-{participant-id} agent** with this input:

```yaml
round: {round_number + 1}
topic: "{session topic}"
phase: "{current phase}"
workflow_type: "{workflow_type}"

question: "{facilitator's question}"

exploration: "{facilitator's exploration prompt}"

# CRITICAL: Participants have tools: [] - they CANNOT read files
# ALL context MUST be provided inline
# Copy VERBATIM from participant_context.shared - do NOT summarize
context:
  project_summary: |
    {COPY from participant_context.shared.project_summary}

  relevant_artifacts:
    # For EACH artifact: copy ALL fields (id, title, state, description, etc.)
    - id: "{ID}"
      title: "{title}"
      state: "{state}"
      description: |
        {FULL description - do NOT truncate}
      # ... copy ALL other fields present

  open_conflicts:
    # Copy from participant_context.shared.open_conflicts with ALL fields

  open_questions:
    # Copy from participant_context.shared.open_questions with ALL fields

  recent_rounds:
    # Copy from participant_context.shared.recent_rounds with FULL synthesis
    - round: {N}
      synthesis: |
        {FULL synthesis text - do NOT truncate}
```

Each participant will return:
```yaml
participant: "{participant-id}"

position: |
  {2-3 sentence position statement}

rationale:
  - "{reason 1}"
  - "{reason 2}"

trade_offs:
  optimizing_for: "{what they prioritize}"
  accepting_as_cost: "{trade-off accepted}"
  risks:
    - "{risk}"

concerns:
  - "{concern}"

suggestions:
  - "{suggestion}"

confidence: 0.85

references:
  - "{reference}"
```

**Store responses** in `participant_responses[]`

**IF --verbose**: Write dump files `rounds/{NNN}-02-{participant-id}.yaml` for each

**IF tokens_flag**: Read `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/token-estimation.md` → Execute "Capture T2" section

### Step 2.4: Facilitator Synthesis

**Use the roundtable-facilitator agent** with this input:

```yaml
action: "synthesis"
round: {round_number + 1}
topic: "{session topic}"
strategy: "{strategy}"
phase: "{current phase}"

# Values from config-snapshot.yaml (NOT hardcoded)
escalation_config:
  min_rounds: "{from config-snapshot.yaml: limits.min_rounds}"
  max_rounds: "{from config-snapshot.yaml: limits.max_rounds}"
  max_rounds_per_conflict: "{from config-snapshot.yaml: escalation.max_rounds_per_conflict}"
  confidence_below: "{from config-snapshot.yaml: escalation.confidence_below}"

# Consensus rules for current strategy (ADR-0010)
consensus: "{from config-snapshot.yaml: consensus}"

question_asked: "{facilitator's question from step 2.2}"

responses:
  software-architect:
    position: "{position}"
    rationale: [...]
    concerns: [...]
    suggestions: [...]
    confidence: 0.85
  technical-lead:
    position: "{position}"
    rationale: [...]
    concerns: [...]
    suggestions: [...]
    confidence: 0.8
  # ... all participant responses

full_agenda:
  - id: "{topic_id_1}"
    status: "{open|partial|closed}"
    priority: "{critical|normal}"
  - id: "{topic_id_2}"
    status: "{open|partial|closed}"
    priority: "{critical|normal}"
  # ... ALL topics from agenda.yaml with CURRENT status
  # CRITICAL: Facilitator needs full visibility to enforce closure rules

focus_topic:
  id: "{topic from step 2.2}"
  done_when:
    criteria: [...]
    min_requirements: {N}

open_conflicts: []
artifacts_count: {current count}
```

The facilitator will return:
```yaml
action: "synthesis"

synthesis: "{2-4 sentence summary of alignment and key points}"

proposed_artifacts:
  - type: "{requirement|conflict|open_question|business_rule|...}"
    title: "{title}"
    state: "{approved|in_progress|blocked|...}"  # ADR-0010: single state field
    topic_id: "{agenda topic}"
    description: "..."
    # ... type-specific fields

resolved_conflicts: []  # or list of {conflict_id, resolution, method}

agenda_update:
  topic_id: "{topic}"
  new_status: "{open|partial|closed}"
  coverage_added: [...]
  remaining_for_closure: [...]

constraints_check:
  rounds_completed: {N}
  min_rounds: "{from escalation_config}"  # NOT hardcoded
  can_conclude: {true|false}
  reason: "{explanation}"

next: "{continue|conclude|escalate}"

next_focus:
  type: "{agenda|conflict|open_question}"
  topic_id: "{topic}"
  reason: "{reason}"

escalation_reason: null
```

**Parse response**: Extract `synthesis`, `proposed_artifacts`, `resolved_conflicts`, `agenda_update`, `next`, `next_focus`

**IF --verbose**: Write dump file `rounds/{NNN}-03-facilitator-synthesis.yaml`

**IF tokens_flag**: Read `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/token-estimation.md` → Execute "Capture T3" section, then "Round Recap" section

**IF diagnostic_flag**: Read `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/diagnostic.md` → Execute "Per-Round Diagnostic" section

### Step 2.5: Process Artifacts

For each `proposed_artifact`:

1. **Determine ID**: Count existing keys in `artifacts.{type}`, assign next available ID
   - Requirements: `REQ-{NNN}`
   - Conflicts: `CONF-{NNN}`
   - Open questions: `OQ-{NNN}`
   - Etc.

2. **Embed in session file**: Add to `artifacts.{type}` map with full content

**IMPORTANT**: Artifacts are EMBEDDED in session file, NOT separate files.

For each `resolved_conflict`:

1. **Update state**: Change `state` from `in_progress` to `resolved`, add `resolution` text
2. **Track transition**: Add to `rounds[].artifacts_transitioned` for audit

### Step 2.6: Update Session File

Append round to `rounds[]` with full audit trail (per ADR-0010 and session-schema.md):

```yaml
rounds:
  - round: {N}
    timestamp: "{ISO timestamp}"
    topic_id: "{focus topic_id}"

    # Facilitator question (for audit)
    facilitator_question: |
      {the question asked}

    # Synthesis summary (for audit)
    synthesis_summary: |
      {2-4 sentence synthesis from facilitator}

    # Participant positions (condensed for audit)
    participant_positions:
      {participant-id}: |
        {1-2 sentence position summary}
      # ... all participants

    # Key outcomes
    key_decisions:
      - "{decision 1}"
      - "{decision 2}"
    artifacts_created: ["{ID}", ...]
    artifacts_transitioned:          # ADR-0010: round-level audit trail
      - id: "{ID}"
        from: "{previous_state}"
        to: "{new_state}"
        reason: "{reason for transition}"
    resolved_conflicts:
      - conflict_id: "{CONF-NNN}"
        resolution: "{how resolved}"
        method: "{consensus|facilitator|user_decision}"
    resolved_questions:
      - question_id: "{OQ-NNN}"
        answer: "{the answer}"
    consensus_reached: {true|false}
    next_action: "{continue|conclude|escalate}"
```

Update `agenda[]` status based on `agenda_update`.

Update `metrics`:
```yaml
metrics:
  rounds_completed: {N}
  artifacts:
    total: {count all keys in artifacts.*}
    by_type: {type: count, ...}
    by_state: {state: count, ...}
  topics:
    total: {count}
    closed: {count closed}
  consensus_rate: {consensus_reached rounds / total rounds}
```

### Step 2.7: Display Round Recap

```
───────────────────────────────────────────────────────────────
ROUND {round_number + 1} COMPLETE
───────────────────────────────────────────────────────────────

Focus: {focus_type} - {topic_id}

Synthesis:
{facilitator's synthesis}

New Artifacts:
{for each created}
  + {ID}: {title}
{/for}

{if resolved_conflicts}
Resolved:
{for each resolved}
  ✓ {conflict_id}: {resolution}
{/for}

Agenda:
{for each topic}
  [{status}] {topic_name}
{/for}

Next: {next_focus or "Conclusion pending"}
───────────────────────────────────────────────────────────────
```

### Step 2.8: Handle Interactive Mode

**IF interactive_flag == true**:
- Use AskUserQuestion:
  - "Continue to next round"
  - "Skip to conclusion"
  - "Exit (resume later)"

**IF interactive_flag == false**:
- Proceed automatically

### Step 2.9: Evaluate Next Action

**Check min_rounds override**:
- If `round_number < min_rounds` AND `next == "conclude"`:
- Override to `next = "continue"`

**Based on `next`**:

| Action | Behavior |
|--------|----------|
| continue | Increment round_number, REPEAT from Step 2.1 |
| conclude | EXIT loop, proceed to PHASE 3 |
| escalate | Handle escalation (see below) |

### Step 2.10: Handle Escalation

If `next == "escalate"`:

1. Display escalation reason
2. Use AskUserQuestion:
   - "Accept facilitator recommendation"
   - "Provide your own decision"
   - "Continue discussion"
3. Record user decision
4. Continue or conclude based on choice

### Step 2.11: Safety Limits

**HARD LIMIT**: If `round_number >= max_rounds`:
- Force conclude
- Note in session: "Reached maximum rounds limit"

### Error Handling

If Task calls fail or session file writes fail, see `references/error-handling.md` for recovery patterns.

### Step Validation

After each major step (2.2, 2.3, 2.4, 2.5), verify correct execution using the checklist in `references/definition-of-done.md`.

---

## PHASE 3: Completion

**IF diagnostic_flag**: Read `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/diagnostic.md` → Execute "End-Session Diagnostic Report" section

**IF tokens_flag**: Read `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/token-estimation.md` → Execute "Session Complete" section

### Step 3.1: Update Session Status

```yaml
status: "closed"
timing:
  closed_at: "{ISO timestamp}"
```

### Step 3.2: Read Session for Summary

**YOU MUST Read session file** to generate summary from Single Source of Truth.

Extract:
- All consensus artifacts
- Unresolved conflicts
- Agenda final status

### Step 3.4-3.5: Generate Output

Read the file at `${CLAUDE_PLUGIN_ROOT}/skills/output-generation/SKILL.md` and follow the instructions for the current workflow_type.

The output-generation skill handles:
- Format-specific document generation (SRS, arc42, summary)
- Merge vs override mode
- CONTEXT.md update (for specs/design)
- Output summary display

---

## Reference Files

| File | Content |
|------|---------|
| `references/session-schema.md` | Full YAML schema |
| `references/agenda-specs.md` | Specs workflow agenda with DoD |
| `references/agenda-design.md` | Design workflow agenda with DoD |
| `references/agenda-brainstorm.md` | Brainstorm workflow (phase-based) |
| `references/error-handling.md` | Error recovery patterns |
| `references/workspace-scope.md` | Workspace/component scope handling |
| `references/verbose-dump-format.md` | Verbose dump file naming and content |
| `references/definition-of-done.md` | Step validation checklist |
| `references/diagnostic.md` | Diagnostic mode (hooks at Step 2.4 and PHASE 3) |
| `references/token-estimation.md` | Token tracking mode (hooks at Steps 2.1-2.4 and PHASE 3) |

---

*Referenced by: specs.md, design.md, brainstorm.md, roundtable.md*

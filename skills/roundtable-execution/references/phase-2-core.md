# Phase 2 Core Algorithm — Executable Reference

> **Status**: executable single-source for the Phase 2 Round Execution Loop (TECH-002 Phase 7B.4a, 2026-05-15).
>
> This document is the canonical Phase 2 algorithm. Each `/s2s:specs`, `/s2s:design`, `/s2s:brainstorm` command Reads this file at the start of Phase 2 and follows its instructions, with workflow-specific values supplied by a profile YAML from `profiles/`.
>
> **Maintenance rule**: when changing Phase 2 behavior, edit THIS file. Commands consume it; do not duplicate.

---

## 1. Workflow profiles

The same algorithm runs in three flavors, parameterized by `workflow_type`. Every workflow-specific value is captured in a **profile YAML** under `skills/roundtable-execution/profiles/`. References in §2 below use `{{profile.X}}` paths.

**Profiles**:
- `profiles/specs.yaml`
- `profiles/design.yaml`
- `profiles/brainstorm.yaml`

**Schema documentation**: `references/profile-schema.md` (canonical schema + field-to-§1 mapping + validation rules + how-to-add-a-workflow guide).

### Human-readable summary

For quick reference, the workflow differences captured by the profiles:

| Parameter | `specs` | `design` | `brainstorm` | Profile path |
|-----------|---------|----------|--------------|--------------|
| `workflow_type` literal | `"specs"` | `"design"` | `"brainstorm"` | `workflow_type` |
| `topic_pattern` | `"Requirements definition for {project_name}"` | `"Architecture design for {project_name}"` | `"{topic}"` (from `--topic`) | `topic.pattern` |
| `state.json.active_session.phase` | `"requirements"` | `"design"` | `"{current_phase}"` (variable) | `state_phase` |
| Participants (4) | PM, UX, BA, QA | Arch, Sec, TechLead, DevOps | PM, Arch, TechLead, DevOps | `participants.default` |
| Artifact types | REQ, BR, NFR, EX, OQ, CONF | ARCH, COMP, INT, OQ, CONF | IDEA, RISK, MIT, OQ, CONF | `artifact_types[].prefix` |
| Progress axis | `agenda` | `agenda` | `disney_phase` | `progress.axis` |
| Default agenda count | 6 | 5 | n/a | `progress.agenda_count` |
| `updates_since_last_round.*_changes` | `agenda_changes` | `agenda_changes` | `phase_changes` | `progress.changes_field` |
| Synthesis input progress fields | `full_agenda` + `focus_topic` | same | `phases_status` + `current_phase` + `artifacts_summary` | `progress.synthesis_input_fields` |
| Synthesis output progress field | `agenda_update` | `agenda_update` | `phase_recommendation` | `progress.synthesis_output_field` |
| Round summary tag | `topic_id` | `topic_id` (+ optional `debate_phase` for debate) | `disney_phase` | `round_summary.tag_field` |
| `next` values | `continue` / `conclude` / `escalate` | same | + **`phase`** | `next_values` |
| Step 2.10 Phase Transition | n/a | n/a | **present** | `has_phase_transition` |
| Step 2.1 display block | minimal | minimal | rich (Disney phase rules) | `display_block_style` |

The table is informational; the authoritative source is each profile YAML.

> **Out-of-scope drifts** known but not yet fixed:
> - `session-schema.md` lists design artifact types without `INT-*`; design profile uses `INT-*`. Schema doc incomplete.
> - `session-schema.md` does not list `CONF-*` for brainstorm; brainstorm profile defines `CONF-*`. Same shape.

---

## 2. Round Loop algorithm

### 2.0 — How a command invokes this document

Before Reading this file, the calling command MUST have made the following available in conversation context:

| Variable | Source | Notes |
|----------|--------|-------|
| `PROFILE` | parsed `profiles/{workflow_type}.yaml` | the loaded workflow profile object |
| `STRATEGY` | resolved strategy name | e.g., `"consensus-driven"`, `"debate"`, `"disney"` |
| `SESSION_ID` | from `session.yaml.id` | string |
| `ROUND_NUMBER` | from `session.yaml.metrics.rounds_completed` | integer; 0 for fresh, N for resume |
| `VERBOSE_FLAG` | from `config-snapshot.yaml.verbose` | boolean |
| `DIAGNOSTIC_FLAG` | from `config-snapshot.yaml.diagnostic` | boolean |
| `INTERACTIVE_FLAG` | from `config-snapshot.yaml.interactive` | boolean |
| `TOKEN_SCRIPT` | from token-tracking.md "Script Location" | path to capture script |

The algorithm loops Steps 2.0 → 2.9 internally until Step 2.9 dispatches a terminal action. Control then returns to the command, which executes Phase 3.

---

### Step 2.0 — Context Capacity Check

Identical across all profiles.

1. Read `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/token-tracking.md`.
2. Execute the "Script Location" section to (re-)resolve `TOKEN_SCRIPT` at the start of EVERY round, **unconditionally**. Do NOT assume `TOKEN_SCRIPT` carried over from a previous round: after `/compact` or `/clear` the value is lost even though the model may "recall" it, which silently disables token tracking and lets the loop run past capacity (BUG-012).
3. Execute the "Context Capacity Check" section. This computes `SHOULD_STOP` and `SHOULD_WARN` flags based on current context usage.

Token checkpoints `T1`, `T2`, `T3` fire at the end of Steps 2.2, 2.3, 2.4 respectively (commands shown in those steps).

---

### Step 2.1 — Display Round Start

#### 2.1a Display block

**IF** `PROFILE.display_block_style == "minimal"`:

Display a single line summarizing the round start:

```
Round {ROUND_NUMBER + 1}: {topics closed}/{total topics} agenda | Artifacts: {counts by primary type}
```

Source counts: `session.yaml.agenda` (status counts) and `session.yaml.metrics.artifacts.by_type` (filtered by `PROFILE.artifact_types[].is_primary == true`).

**IF** `PROFILE.display_block_style == "rich"`:

Read the live `session.current_phase` value. Display:

```
═══════════════════════════════════════════════════════════════
{{PROFILE.workflow_type | uppercase}}: {{session.topic}}
Strategy: {{STRATEGY}} | Phase: {{session.current_phase}} | Round: {{ROUND_NUMBER + 1}}
═══════════════════════════════════════════════════════════════

{IF session.current_phase == "dreamer"}
DREAMER PHASE: Think BIG! No constraints, wild ideas welcome.
{/IF}
{IF session.current_phase == "realist"}
REALIST PHASE: Evaluate feasibility. How would we implement?
{/IF}
{IF session.current_phase == "critic"}
CRITIC PHASE: Identify risks. What could go wrong?
{/IF}

ARTIFACTS: {counts from session.metrics.artifacts.by_type}
```

#### 2.1b Update state.json

**IF `.s2s/state.json` exists**: Read it first to get the current `active_plan` value (to preserve it).

**IMMEDIATELY** use Write tool to write `.s2s/state.json`:

```json
{
  "active_session": {
    "id": "{{SESSION_ID}}",
    "workflow_type": "{{PROFILE.workflow_type}}",
    "strategy": "{{STRATEGY}}",
    "phase": "{{PROFILE.state_phase}}",
    "round": {{ROUND_NUMBER + 1}},
    "participants_count": {{length of PROFILE.participants.default}}
  },
  "active_plan": {existing active_plan value OR null if file didn't exist},
  "last_activity": {
    "timestamp": "{ISO timestamp}",
    "action": "round_started",
    "session_id": "{{SESSION_ID}}"
  }
}
```

**SPECIAL CASE**: when `PROFILE.state_phase == "{current_phase}"` (brainstorm), substitute the placeholder with the live `session.current_phase` value (one of `"dreamer"` / `"realist"` / `"critic"`), NOT the literal string.

---

### Step 2.2 — Facilitator Question

#### 2.2a Resume vs fresh

Read `agent_state.facilitator` from session file.

**IF** `agent_state.facilitator.agent_id` is NOT null AND `ROUND_NUMBER > 0` (continuation):

Resume the `roundtable-facilitator` agent via Task tool with `resume: "{agent_state.facilitator.agent_id}"`.

**ELSE** (fresh — first round or no saved agent_id):

Invoke the `roundtable-facilitator` agent fresh.

#### 2.2b Input YAML

Build the input YAML below, substituting `{{}}` placeholders with profile/session values:

```yaml
action: "question"
round: {{ROUND_NUMBER + 1}}
topic: "{{session.topic}}"             # resolved at Phase 1 from PROFILE.topic.pattern
strategy: "{{STRATEGY}}"
phase: "{{PROFILE.state_phase}}"        # for brainstorm, substitute session.current_phase
workflow_type: "{{PROFILE.workflow_type}}"

# Escalation config (from config-snapshot.yaml)
escalation_config:
  min_rounds: {from config-snapshot.limits.min_rounds}
  max_rounds: {from config-snapshot.limits.max_rounds}
  max_rounds_per_conflict: {from config-snapshot.escalation.max_rounds_per_conflict}
  confidence_below: {from config-snapshot.escalation.confidence_below}

# Project context (from context-snapshot.yaml)
project_context:
  name: "{project name}"
  description: "{project description}"
  domain: "{domain}"
  tech_stack: ["{tech}"]
  constraints: ["{constraint}"]
  # IF PROFILE.workflow_type == "design": add `requirements_summary` (from requirements.md, summarized)
  # IF PROFILE.workflow_type == "brainstorm": add `brainstorm_topic` (from CLI arg)

# Current session state
session_state:
  artifacts:
    # For each PROFILE.artifact_types[].session_key, include current contents:
    {{PROFILE.artifact_types[0].session_key}}: [{id, title, state, ...}]
    {{PROFILE.artifact_types[1].session_key}}: [...]
    # ... all profile-defined types
  rounds:
    - round: {N}
      focus: "{topic_id or disney_phase}"
      synthesis: "{synthesis text}"
    # ... previous rounds (full content for resume context)

participants: {{PROFILE.participants.default}}
```

**Progress axis fields** (conditional on profile):

**IF** `PROFILE.progress.axis == "agenda"`:

```yaml
agenda:
  - id: "{topic_id}"
    title: "{title}"
    status: "{open|partial|closed}"
    priority: "{priority}"
    done_when:
      criteria: [...]
      min_requirements: {N}
  # ... all topics from session.agenda
```

**IF** `PROFILE.progress.axis == "disney_phase"`:

```yaml
phases_status:
  - name: "dreamer"
    status: "{active|completed|pending}"
    rounds: [...]
  - name: "realist"
    status: "..."
  - name: "critic"
    status: "..."

disney_phase_rules:
  current_phase: "{{session.current_phase}}"
  rules:
    dreamer: "No criticism, big ideas welcome, build on others' ideas"
    realist: "How would we implement? What's needed?"
    critic: "Identify risks, weaknesses, what could fail"
```

**On resume only** (`agent_state.facilitator.agent_id != null`), additionally include:

```yaml
resume: true
updates_since_last_round:
  new_artifacts: ["{IDs created last round}"]
  resolved_conflicts: ["{IDs}"]
  resolved_questions: ["{IDs}"]
  {{PROFILE.progress.changes_field}}:    # agenda_changes OR phase_changes
    - topic_id_or_phase: "{value}"
      old_status: "{previous}"
      new_status: "{current}"
```

**On fresh only** (first round of new session), additionally include workspace-awareness fields:

```yaml
project_scope:
  type: {from config-snapshot.project.type}
  workspace_path: {from config-snapshot.project.workspace_path}
workspace_scope: {from config-snapshot.workspace_scope}
cross_cutting_decisions: {from config-snapshot.cross_cutting_decisions}
```

#### 2.2c Facilitator response

**Hook overrides dispatch (TECH-002 Phase 4, Option B)**

Before invoking the facilitator agent, read `session.yaml.agent_state.facilitator.hook_overrides` and dispatch via 3-branch logic:

- **Branch 1** (`hook_overrides.skip == true`): include `hook_overrides: {skip: true}` in the facilitator agent input. Facilitator emits no per-round overrides (strategy declares no hooks: `standard`, `consensus-driven`, `disney`, `six-hats` pre-baseline).
- **Branch 2** (`hook_overrides` has policy fields, e.g. `participant_response_field` + `round_summary_field` + `policy`): include the full dict in the facilitator agent input. Facilitator populates `participant_context.overrides.{participant-id}.{field}` per the policy (currently only `debate` with `policy: "facilitator_emergent"`).
- **Branch 3** (`hook_overrides` field is absent from session.yaml): do NOT include `hook_overrides:` key in the facilitator agent input. Facilitator falls back to current LLM-emergent inference. Branch 3 triggers for pre-Phase-4 sessions resumed via `--session {id}` (backward-compat).

See `references/strategy-hook-resolution.md` for the fixture defining which strategies map to which branches, and `agents/roundtable/facilitator.md` "Hook override consumption" section for the matching consumer logic.

The facilitator returns:

```yaml
action: "question"
decision:
  focus_type: "{agenda|conflict|open_question}"        # specs/design
  # OR for brainstorm: "disney_phase"
  topic_id: "{topic}"
  rationale: "{reason}"
question: "{the question}"
exploration: "{exploration prompt}"
participants: "all"

participant_context:
  shared:
    project_summary: |
      {condensed project info}
    relevant_artifacts: [{id, title, state, ...full content...}]
    open_conflicts: [...]
    open_questions: [...]
    recent_rounds: [{round, synthesis, ...}]
  overrides: null  # OR per-participant directives — see strategy-hooks.md
                   # debate: {participant-id: {debate_role: "pro"|"con"}}
                   # six-hats: {participant-id: {hat_role: "white"|"red"|...}} (future)
```

#### 2.2d Save agent state

Update `session.yaml`:

```yaml
agent_state:
  facilitator:
    agent_id: "{agentId from facilitator response}"
    last_round: {{ROUND_NUMBER + 1}}
    last_action: "question"
```

#### 2.2e Verbose dump (IF VERBOSE_FLAG)

**IF** `VERBOSE_FLAG == true`: write `rounds/{NNN}-01-facilitator-question.yaml`. **NNN** is the zero-padded round number `(ROUND_NUMBER + 1)`. See `verbose-dump-format.md` for the canonical schema. Save FULL `participant_context.shared` content (no summarization, no placeholders).

#### 2.2f Token checkpoint T1

**MANDATORY**: `bash "{{TOKEN_SCRIPT}}" capture "{{SESSION_ID}}" T1`

---

### Step 2.3 — Participant Responses (PARALLEL)

**CRITICAL context-passing rule**: participants have `tools: []`. They cannot read files. Copy `participant_context.shared` from Step 2.2 response VERBATIM. Never summarize, never truncate, never substitute placeholders. If incomplete, participants will hallucinate.

#### 2.3a For each participant (parallel)

For EACH participant id in `PROFILE.participants.default`, in a **single message** (parallel execution, one Task tool call per participant):

**Resume vs fresh check**:

**IF** `agent_state.participants.{id}.agent_id` is NOT null AND `ROUND_NUMBER > 0`: resume that participant agent via Task tool with `resume: "{agent_state.participants.{id}.agent_id}"`.

**ELSE**: fresh invocation of the participant agent.

#### 2.3b Input YAML (per participant)

```yaml
action: "respond"
round: {{ROUND_NUMBER + 1}}
strategy: "{{STRATEGY}}"
phase: "{{PROFILE.state_phase}}"        # for brainstorm: session.current_phase
workflow_type: "{{PROFILE.workflow_type}}"

question: "{question from Step 2.2c}"
exploration: "{exploration from Step 2.2c}"

context:                                # VERBATIM copy from participant_context.shared
  project_summary: |
    {full project summary}
  relevant_artifacts: [...]              # full content
  open_conflicts: [...]
  open_questions: [...]
  recent_rounds: [...]

overrides: {{participant_context.overrides[{id}]}}  # null OR strategy-specific directives
```

**IF** `PROFILE.workflow_type == "brainstorm"`, additionally include:

```yaml
disney_phase_instructions:
  current_phase: "{{session.current_phase}}"
  instructions:
    dreamer: "Generate ideas freely. No criticism. Build on others."
    realist: "Evaluate feasibility. Suggest implementation paths."
    critic: "Identify risks and weaknesses. Propose mitigations."
```

#### 2.3c Participant response

Each participant returns the canonical schema:

```yaml
participant: "{participant-id}"
position: |
  {2-3 sentence position statement}
rationale:
  - "{reason 1}"
  - "{reason 2}"
trade_offs:
  optimizing_for: "{priority}"
  accepting_as_cost: "{trade-off}"
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

**Brainstorm extras** (when `PROFILE.workflow_type == "brainstorm"`):

The participant response includes phase-specific arrays:
- Dreamer phase: `ideas: [{title, description}, ...]`
- Realist phase: feasibility-tagged ideas (still under `ideas` with assessments)
- Critic phase: `risks: [{title, severity, ...}]`, `mitigations: [{title, risk_id, ...}]`

**Strategy hook** (when `STRATEGY == "debate"`):

The participant response includes an additional top-level field `debate_role: "pro" | "con"`. The value comes from Step 2.2c facilitator response's `participant_context.overrides.{participant-id}.debate_role`. The participant echoes the assigned role and shapes argumentation accordingly. See `strategy-hooks.md` §3.

**Strategy hook** (when `STRATEGY == "six-hats"`, future — currently untested):

The participant response includes `hat_role: "white" | "red" | "black" | "yellow" | "green" | "blue"`. See `strategy-hooks.md` §5.

#### 2.3d Save agent state

Update `session.yaml`:

```yaml
agent_state:
  participants:
    {id}:
      agent_id: "{agentId from participant response}"
      last_round: {{ROUND_NUMBER + 1}}
```

#### 2.3e Verbose dump (IF VERBOSE_FLAG)

**IF** `VERBOSE_FLAG == true`: for EACH participant, write `rounds/{NNN}-02-{participant-id}.yaml`. Header comment is `# Round {N} - {Role} Response` (specs/design) or `# Round {N} - {Role} Response ({disney_phase} phase)` (brainstorm). Capture ALL response fields including `rationale`, `concerns`, `suggestions`. See `verbose-dump-format.md` for full schema.

#### 2.3f Token checkpoint T2

**MANDATORY**: `bash "{{TOKEN_SCRIPT}}" capture "{{SESSION_ID}}" T2`

---

### Step 2.4 — Facilitator Synthesis

#### 2.4a Resume facilitator (same as 2.2)

**IF** `agent_state.facilitator.agent_id` is NOT null: resume the same facilitator with `action: "synthesis"`.

**ELSE** (rare — only if 2.2 was a fresh invocation that did not save agent_id): fresh invocation. Pass full context.

#### 2.4b Input YAML

```yaml
action: "synthesis"
round: {{ROUND_NUMBER + 1}}
topic: "{{session.topic}}"
strategy: "{{STRATEGY}}"
phase: "{{PROFILE.state_phase}}"
workflow_type: "{{PROFILE.workflow_type}}"

escalation_config: {... from 2.2b ...}

question_asked: "{question from 2.2c}"

responses:                              # ALL participant responses, keyed by participant id
  "{participant-id-1}":
    position: "..."
    rationale: [...]
    trade_offs: {...}
    concerns: [...]
    suggestions: [...]
    confidence: 0.85
    references: [...]
    # Brainstorm extras: ideas, risks, mitigations as applicable
  "{participant-id-2}": {...}
  # ... all 4 participants

open_conflicts: [...]                   # from session_state.artifacts.conflicts where state != resolved
artifacts_count: {total from session.metrics.artifacts.total}
```

**Progress fields** (conditional):

**IF** `PROFILE.progress.axis == "agenda"`:

```yaml
full_agenda: [...]                     # full session.agenda with statuses
focus_topic:
  id: "{topic_id from 2.2c decision}"
  title: "..."
  done_when:
    criteria: [...]
    min_requirements: {N}
```

**IF** `PROFILE.progress.axis == "disney_phase"`:

```yaml
phases_status: [...]                   # session.phases array
current_phase: "{{session.current_phase}}"
artifacts_summary:
  ideas_count: {N}
  risks_count: {N}
  mitigations_count: {N}
```

#### 2.4c Facilitator response

```yaml
synthesis: |
  {2-4 sentence summary of round outcomes}

proposed_artifacts:                     # typed per PROFILE.artifact_types[]
  - type: "{REQ|BR|NFR|ARCH|IDEA|...}"
    title: "{title}"
    state: "{draft|in_progress|accepted}"
    topic_id: "{topic_id}"             # specs/design
    # OR for brainstorm: disney_phase, severity (for risks), etc.
    description: "..."
    # ... type-specific fields per references/artifact-schemas/{type}.md

resolved_conflicts: []                  # array of conflict IDs whose state moves to "resolved"

# Progress update (conditional on PROFILE.progress.synthesis_output_field)
# IF agenda axis:
agenda_update:
  topic_id: "{topic}"
  new_status: "{partial|closed}"
  coverage_added: [...]
  remaining_for_closure: [...]
# IF disney_phase axis:
phase_recommendation:
  action: "{continue|advance}"
  reason: "..."

constraints_check:
  rounds_completed: {{ROUND_NUMBER + 1}}
  min_rounds: {from config-snapshot.limits.min_rounds}
  can_conclude: {true|false}
  reason: "..."

next: "{value from PROFILE.next_values}"      # continue|conclude|escalate; +"phase" for brainstorm

next_focus:                              # specs/design
  type: "{agenda|conflict|open_question}"
  topic_id: "{topic}"
  reason: "..."

escalation_reason: null                  # set when next == "escalate"
```

#### 2.4d Save agent state

Update `session.yaml`:

```yaml
agent_state:
  facilitator:
    agent_id: "{agentId from facilitator response}"
    last_round: {{ROUND_NUMBER + 1}}
    last_action: "synthesis"
```

#### 2.4e Verbose dump (IF VERBOSE_FLAG)

**IF** `VERBOSE_FLAG == true`: write `rounds/{NNN}-03-facilitator-synthesis.yaml` per `verbose-dump-format.md`. The dump MUST include:

```yaml
result:
  artifacts_proposed: {count}
  conflicts_resolved: {count}            # MANDATORY in all workflows
  status: "closed"

verification:                            # MANDATORY in all workflows
  expected_artifacts:                    # MANDATORY: list of {map, expected_keys}
    - map: "artifacts.{{PROFILE.artifact_types[0].session_key}}"
      expected_keys: [...]
    # ... one entry per artifact_type in PROFILE
  round_summary:                         # MANDATORY
    expected_round: {{ROUND_NUMBER + 1}}
    required_fields: [timestamp, topic_id_or_disney_phase, facilitator_question,
                      synthesis_summary, participant_positions, artifacts_created,
                      next_action]
  # IF PROFILE.progress.axis == "agenda":
  agenda_status:
    topic_id: "{from agenda_update.topic_id}"
    expected_status: "{from agenda_update.new_status}"
  # IF PROFILE.progress.axis == "disney_phase":
  phases_status:
    current_phase: "{{session.current_phase}}"
    expected_action: "{from phase_recommendation.action}"
  metrics_consistency:                   # MANDATORY
    rounds_completed: {{ROUND_NUMBER + 1}}
    artifacts_total: {sum of all artifact maps}
  context_propagation:                   # MANDATORY
    participant_context_keys: [project_summary, relevant_artifacts, open_conflicts,
                               open_questions, recent_rounds]
```

#### 2.4f Token checkpoint T3

**MANDATORY**: `bash "{{TOKEN_SCRIPT}}" capture "{{SESSION_ID}}" T3`

---

### Step 2.5 — Process Artifacts

For each `proposed_artifact` from Step 2.4c:

1. **Determine session key**: find the matching `PROFILE.artifact_types[]` entry where `prefix == proposed_artifact.type`. Use its `session_key` (e.g., `REQ → requirements`, `ARCH → architecture_decisions`, `IDEA → ideas`).
2. **Count existing**: count keys in `session.yaml.artifacts.{session_key}`.
3. **Assign ID**: next available — e.g., if `requirements` has 14 entries (REQ-001 to REQ-014), new artifact is `REQ-015`.
4. **Edit session file**: add the artifact to `artifacts.{session_key}` with the full content per the type-specific schema. **Read** `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/artifact-schemas/{prefix-lowercase}.md` for the canonical schema (e.g., `req.md` for `REQ-*`, `arch.md` for `ARCH-*`). See `artifact-schemas/README.md` for the type → file → workflow mapping.

Artifacts are EMBEDDED in the session file, not separate files (per ADR-0008/0010).

**For resolved conflicts**: edit the existing `CONF-*` entry in place (`state: resolved`, `resolution: "{text from synthesis}"`) and append a `rounds[].artifacts_transitioned` entry for audit.

---

### Step 2.6 — Update Session File

**Single Edit operation** appending to `rounds:` and updating top-level fields.

#### 2.6a Append to rounds[]

Build the round entry:

```yaml
- round: {{ROUND_NUMBER + 1}}
  timestamp: "{ISO timestamp}"
  {{PROFILE.round_summary.tag_field}}: "{value}"   # topic_id OR disney_phase
  facilitator_question: "{question from 2.2c}"
  synthesis_summary: "{synthesis from 2.4c}"
  participant_positions:                            # keyed by participant id
    "{participant-id-1}": "{position}"
    # ... all 4 participants
  key_decisions: [...]
  artifacts_created: ["{IDs assigned in 2.5}"]
  resolved_conflicts: ["{IDs from 2.4c.resolved_conflicts}"]
  resolved_questions: ["{IDs marked resolved}"]
  consensus_reached: {true|false}
  next_action: "{from 2.4c.next}"
```

**Strategy hooks** for the round entry (additional optional fields):

- **IF** `STRATEGY == "debate"`: append `debate_phase: "opening" | "rebuttal" | "closing" | "synthesis"` reflecting the active debate phase. Source: synthesis from Step 2.4c (facilitator-driven). See `strategy-hooks.md` §4.
- **IF** `STRATEGY == "six-hats"` (future): append `hat_phase: "{hat-name}"`. See `strategy-hooks.md` §6.

Other strategies (`standard`, `consensus-driven`) do not add extra fields to the round entry.

#### 2.6b Update timing and progress

- `timing.updated_at` = current ISO timestamp
- Progress: update `agenda[topic].status` (specs/design) OR `phases[name].status` (brainstorm) per the synthesis's `agenda_update` or `phase_recommendation`.

#### 2.6c Update metrics

```yaml
metrics:
  rounds_completed: {{ROUND_NUMBER + 1}}
  artifacts:
    total: {sum of all artifact_types[].session_key sizes}
    by_type: {<session_key>: <count>, ...}
    by_state: {draft: N, in_progress: N, accepted: N, resolved: N}
  # axis-specific:
  topics:                                # IF PROFILE.progress.axis == "agenda"
    total: {{PROFILE.progress.agenda_count}}
    closed: {count of agenda entries with status == "closed"}
  phases:                                # IF PROFILE.progress.axis == "disney_phase"
    dreamer: {round count in dreamer phase}
    realist: {round count in realist phase}
    critic: {round count in critic phase}
  consensus_rate: {fraction of rounds with consensus_reached: true}
  tokens:
    total: {cumulative from token-tracking}
    by_round: [...]
```

---

### Step 2.6b — Validate Round Output

Read `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/round-validation.md` and execute its checks against the just-updated session file.

**Non-blocking**: display warnings but continue execution.

---

### Step 2.6c — Diagnostic Observation

**MANDATORY when `DIAGNOSTIC_FLAG == true`.** Do NOT skip this step. (See BUG-013 for context — this step was historically skipped at runtime because output was display-only; FIX-S1 adds persistence to anchor LLM commitment.)

**IF** `DIAGNOSTIC_FLAG == true`:

**Use the session-observer agent** with this input:

```yaml
mode: "per-round"
session_path: ".s2s/sessions/{{SESSION_ID}}"
round: {{ROUND_NUMBER + 1}}
workflow_type: "{{PROFILE.workflow_type}}"
strategy: "{{STRATEGY}}"
```

The observer returns:

```yaml
round: {N}
status: "ok" | "warning" | "anomaly"
findings: [...]
recommendation: "Continue" | "Review findings" | "Stop for investigation"
notes: |
  Optional free-form observations.
```

**Display** observer result inline:

```
[DIAGNOSTIC] Round {N}: {status}
{IF findings not empty}
Findings:
- {for each finding: type, detail, severity}
{/IF}
Recommendation: {recommendation}
```

**FIX-S1 — Persist observer output (MANDATORY)**: write `rounds/{NNN}-04-session-observer.yaml` with the full input + response. **NNN** is the zero-padded `(ROUND_NUMBER + 1)`. Structure:

```yaml
# Round {N} - Session Observer (per-round)
round: {{ROUND_NUMBER + 1}}
phase: 4
actor: "session-observer"
action: "observe"
started_at: "{ISO timestamp}"
completed_at: "{ISO timestamp}"

input: {... the YAML input sent ...}

response: {... the observer's full response ...}

result:
  status: "{from response.status}"
  findings_count: {len(response.findings)}
  recommendation: "{from response.recommendation}"
```

**IF** `response.recommendation == "Stop for investigation"`:

Ask user via `AskUserQuestion`:
- "Diagnostic observer recommends stopping. What would you like to do?"
  - "Investigate now"
  - "Continue anyway"
  - "Abort session"

Else: continue to Step 2.7.

---

### Step 2.7 — Display Round Recap

Show:
- Synthesis text (from 2.4c)
- New artifacts created (IDs + titles from 2.5)
- Resolved conflicts (IDs)
- Axis status:
  - **IF** `PROFILE.progress.axis == "agenda"`: agenda status (closed/total + which topic was focus)
  - **IF** `PROFILE.progress.axis == "disney_phase"`: current phase + transition recommendation
- Token recap section (per `token-tracking.md`)

---

### Step 2.8 — Handle Interactive Mode

**IF** `INTERACTIVE_FLAG == true`:

Ask user via `AskUserQuestion`:
- Specs/design: "Continue to next round, conclude session, or exit?"
- Brainstorm: same, plus "Skip to next Disney phase".

**IF** `INTERACTIVE_FLAG == false`:

Proceed automatically. Do NOT stop. Do NOT ask.

**Stop conditions** (override `INTERACTIVE_FLAG`):
- `SHOULD_STOP == true` (context capacity reached)
- `ROUND_NUMBER + 1 >= max_rounds` (from config-snapshot.limits.max_rounds)
- Step 2.4c returned `next == "escalate"` (handled by Step 2.9)

---

### Step 2.9 — Evaluate Next Action (CRITICAL)

#### 2.9a Min_rounds enforcement (MANDATORY)

```
IF ROUND_NUMBER + 1 < min_rounds (from config-snapshot.limits.min_rounds) AND next == "conclude":
  OVERRIDE next = "continue"
  Display: "⚠️ min_rounds not reached ({ROUND_NUMBER + 1}/{min_rounds}), continuing..."
```

This applies uniformly across workflows. Added in TECH-002 Phase 3; preserve verbatim.

#### 2.9b Dispatch

Dispatch on `next` (validated against `PROFILE.next_values`):

| `next` value | Action |
|--------------|--------|
| `continue` | loop back to Step 2.0 (next round) |
| `phase` (brainstorm only) | execute Step 2.10 (phase transition), then loop back to Step 2.0 |
| `conclude` | exit Phase 2; control returns to command for Phase 3 |
| `escalate` | ask user via `AskUserQuestion` (options: continue, conclude, abort); based on choice, loop or exit |

For brainstorm: `conclude` is only valid when `session.current_phase == "critic"`. If facilitator returns `conclude` from an earlier phase, treat as drift (override to `phase` and warn).

---

### Step 2.10 — Phase Transition (BRAINSTORM ONLY)

**Applicable only when** `PROFILE.has_phase_transition == true`.

**Read** `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/disney-phase-machine.md` and follow §6 (Implementation note for Step 2.10). The reference document is the canonical state machine spec.

Summary:
- When Step 2.4 returned `next: "phase"`: advance phase per state machine, update session.yaml, display banner.
- When `session.current_phase == "critic"` AND Step 2.4 returned `next: "conclude"`: exit loop (proceed to Step 2.9 dispatch).
- Drift handling: if facilitator returns `conclude` from a non-critic phase, override to `phase` and warn.

---

## 3. Caller-side invocation pattern

A command consumes this document with the following Phase 2 section (~10 lines):

```markdown
## Phase 2: Round Execution Loop

If --skip-roundtable is NOT present:

1. **Load workflow profile**:
   Read `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/profiles/{workflow_type}.yaml`.
   Store the parsed object as `PROFILE`.

2. **Set runtime context** (read from config-snapshot.yaml):
   - `STRATEGY` = config-snapshot.strategy (after PROFILE.strategy_constraints check)
   - `SESSION_ID` = session.yaml.id
   - `ROUND_NUMBER` = session.yaml.metrics.rounds_completed (0 for fresh, N for resume)
   - `VERBOSE_FLAG` = config-snapshot.verbose
   - `DIAGNOSTIC_FLAG` = config-snapshot.diagnostic
   - `INTERACTIVE_FLAG` = config-snapshot.interactive
   - `TOKEN_SCRIPT` = result of Step 2.0 from `token-tracking.md`

3. **Execute the canonical Phase 2 algorithm**:
   Read `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/phase-2-core.md`.
   Follow its instructions (§2), looping Steps 2.0 → 2.9 until terminal dispatch.

4. After phase-2-core.md returns control, proceed to Phase 3.
```

Phase 1 (profile-aware setup) and Phase 3 (output generation) were moved out of each command into the master orchestrator `commands/roundtable.md` in TECH-002 Phase 8. The thin launchers (`specs.md`, `design.md`, `brainstorm.md`) Read-and-follow the master; the caller pattern documented above is the master's PHASE 3 invocation.

---

## 4. Contract invariants (cross-reference)

The §10 contract invariants in `.s2s/plans/20260506-tech002-phase7b-deep-extraction.md` MUST be preserved by this document and its callers. Key items:

- Dump file naming `rounds/{NNN}-{PP}-{actor}.yaml` (NNN=3-digit round, PP=01|02|03|04, actor per role).
- Step ordering 2.0 → 2.1 → 2.2 → 2.3 → 2.4 → 2.5 → 2.6 → 2.6b → 2.6c → 2.7 → 2.8 → 2.9 → (2.10 if brainstorm and `next == "phase"`) → loop.
- Token checkpoints T1 (after 2.2), T2 (after 2.3), T3 (after 2.4).
- Min_rounds enforcement at Step 2.9.
- Resume conditions on `agent_state.{facilitator,participants}.agent_id`.
- `verification` block MANDATORY in synthesis dumps with 5 sub-keys (`expected_artifacts`, `round_summary`, axis-specific status, `metrics_consistency`, `context_propagation`).
- `result.conflicts_resolved` MANDATORY in synthesis dumps.

Breaking any of these is grounds for revert per the plan.

---

## 5. Migration status (post-7B.5)

- ✅ Doc is executable (this file).
- ✅ Profiles defined (`profiles/{specs,design,brainstorm}.yaml`).
- ✅ Schema documented (`profile-schema.md`).
- ✅ Commands wired to consume this doc (7B.4b — Phase 2 sections replaced with ~28-line invocation each).
- ✅ Artifact schemas extracted (`artifact-schemas/{req,br,nfr,ex,arch,comp,int,idea,risk,mit,oq,conf}.md` — 12 files + README).
- ✅ Disney phase machine extracted (`disney-phase-machine.md`).
- ✅ `verbose-dump-format.md` documents `{NNN}-04-session-observer.yaml` (FIX-S1, BUG-013).
- ✅ `roundtable-execution/SKILL.md` restructured to thin overview pointing here (7B.5).
- ✅ Strategy hooks contract documented (`strategy-hooks.md`, TECH-002 Phase 7B.6) and wired via Option B (TECH-002 Phase 4). Hook points integrated in Step 2.2c (overrides 3-branch dispatch per `strategy-hook-resolution.md`), Step 2.3c (debate_role, hat_role), Step 2.6a (debate_phase, hat_phase). Strategy resolution follows the D3 hierarchy (`strategy-resolution.md`).

This document is the authoritative execution source for Phase 2 across all three workflows.

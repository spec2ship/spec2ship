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
| **Output** | `docs/specifications/requirements.md` |
| **Agenda** | `references/agenda-specs.md` |

### design Workflow

| Aspect | Value |
|--------|-------|
| **Goal** | Define HOW to build - architecture, components, interfaces |
| **Default Participants** | software-architect, security-champion, technical-lead, devops-engineer |
| **Default Strategy** | debate |
| **Primary Artifacts** | ARCH-* (decisions), COMP-* (components), INT-* (interfaces) |
| **Secondary Artifacts** | ADR-* (decision records), OQ-*, CONF-* |
| **Output** | `docs/architecture/` + ADR files |
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

verbose: {verbose_flag}
interactive: {interactive_flag}
strategy: "{strategy}"
limits:
  min_rounds: 3
  max_rounds: 20
escalation:
  max_rounds_per_conflict: 3
  confidence_below: 0.5
  critical_keywords: ["security", "must-have", "blocking", "legal"]
participants: [...]
```

**agenda.yaml**: Copy workflow agenda from `references/agenda-{workflow_type}.md`:
```yaml
# Captured: {ISO timestamp}
source: "skills/roundtable-execution/references/agenda-{workflow_type}.md"
workflow: "{workflow_type}"
topics: [...]  # Full topic definitions with done_when criteria
```

### Step 1.4: Create Session Index File

Write `.s2s/sessions/{session-id}.yaml`:
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

artifacts:
  requirements: []
  business_rules: []
  conflicts: []
  open_questions: []
  exclusions: []

agenda: []  # Will be populated from agenda.yaml

rounds: []

metrics:
  rounds: 0
  tasks: 0
  tokens: 0
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

### Step 2.2: Facilitator Question

**Use the roundtable-facilitator agent** with this input:

```yaml
action: "question"
round: {round_number + 1}
topic: "{session topic}"
strategy: "{strategy}"
phase: "{current phase from strategy}"
workflow_type: "{workflow_type}"

escalation_config:
  min_rounds: 3
  max_rounds: 20
  max_rounds_per_conflict: 3
  confidence_below: 0.5

agenda:
  - id: "{topic_id}"
    title: "{topic title}"
    status: "{open|partial|closed}"
    priority: "{critical|normal}"
    done_when:
      criteria: [...]
      min_requirements: {N}
  # ... more topics from agenda.yaml

open_conflicts: []  # list of {id, description, rounds_persisted}
open_questions: []  # list of {id, description, blocking_topic}
artifacts_count: {count from session file}
previous_synthesis: "{synthesis from last round or null}"
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
context_files: ["context-snapshot.yaml", ...]
```

**Parse response**: Extract `decision`, `context_files`, `question`, `exploration`, `participants`

**IF --verbose**: Write dump file `rounds/{NNN}-01-facilitator-question.yaml`

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

context_files:
  - "{session_folder}/context-snapshot.yaml"
  # ... other files from facilitator's context_files
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

### Step 2.4: Facilitator Synthesis

**Use the roundtable-facilitator agent** with this input:

```yaml
action: "synthesis"
round: {round_number + 1}
topic: "{session topic}"
strategy: "{strategy}"
phase: "{current phase}"

escalation_config:
  min_rounds: 3
  max_rounds: 20
  max_rounds_per_conflict: 3
  confidence_below: 0.5

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
    status: "{consensus|draft|conflict}"
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
  min_rounds: 3
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

### Step 2.5: Process Artifacts

For each `proposed_artifact`:

1. **Determine ID**: Read current registry, assign next available ID
   - Requirements: `REQ-{NNN}`
   - Conflicts: `CONF-{NNN}`
   - Open questions: `OQ-{NNN}`
   - Etc.

2. **Write artifact file**: `{session_folder}/{ID}.yaml`

3. **Update registry** in session file

For each `resolved_conflict`:

1. **Update conflict file**: Add `resolved_round` and `resolution`
2. **Update registry** if needed

### Step 2.6: Update Session File

Append round to `rounds[]`:
```yaml
- number: {round_number + 1}
  focus:
    type: "{focus_type}"
    topic_id: "{topic_id}"
  artifacts_created: ["{new artifact IDs}"]
  conflicts_resolved: ["{resolved conflict IDs}"]
  next: "{next action}"
```

Update `agenda[]` status based on `agenda_update`.

Update `metrics`.

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

---

## PHASE 3: Completion

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

### Step 3.4: Generate Output

Based on workflow_type, generate appropriate output document:
- **specs**: `docs/specifications/requirements.md`
- **design**: `docs/architecture/` files + ADRs
- **brainstorm**: `.s2s/sessions/{session-id}-summary.md`

### Step 3.5: Display Completion

```
═══════════════════════════════════════════════════════════════
ROUNDTABLE COMPLETE
═══════════════════════════════════════════════════════════════

Session: {session-id}
Rounds: {total_rounds}
Duration: {duration}

Artifacts Created:
  Requirements: {count}
  Business Rules: {count}
  Conflicts Resolved: {count}
  Open Questions: {count}

Output: {output file path}

Next steps:
  /s2s:design   - Design architecture (if specs)
  /s2s:plan     - Generate implementation plans
═══════════════════════════════════════════════════════════════
```

---

## Verbose Dump File Format

When `--verbose` flag is set, write dump files to `rounds/` subfolder.

### Naming Convention

```
{NNN}-{PP}-{actor}.yaml

NNN = 3-digit round number (001, 002, ...)
PP = 2-digit phase (01=question, 02=responses, 03=synthesis)
actor = facilitator, product-manager, etc.
```

### Dump File Content

```yaml
round: {N}
phase: {P}
actor: "{actor-id}"

timing:
  started_at: "{ISO timestamp}"
  completed_at: "{ISO timestamp}"
  duration_ms: {calculated}

tokens:
  input: {estimated}
  output: {estimated}

prompt: |
  {exact prompt sent}

response: |
  {exact response received}

result:
  valid: true
  warnings: []
  artifacts_created: [...]  # Only in synthesis
```

---

## Definition of Done Checklist

### After Step 2.2 (Facilitator Question):
- [ ] roundtable-facilitator agent was invoked with `action: "question"` input
- [ ] Facilitator returned valid YAML with `action: "question"`
- [ ] Decision includes focus_type and topic_id
- [ ] Context files list is present
- [ ] Dump file written (if verbose)

### After Step 2.3 (Participant Responses):
- [ ] ALL participant agents launched in SINGLE message (parallel execution)
- [ ] ALL participants returned valid YAML with `participant: "{id}"`
- [ ] Each response has position, rationale, confidence, concerns, suggestions
- [ ] Dump files written (if verbose)

### After Step 2.4 (Facilitator Synthesis):
- [ ] roundtable-facilitator agent was invoked with `action: "synthesis"` input
- [ ] Synthesis includes proposed_artifacts and constraints_check
- [ ] next is one of: continue, conclude, escalate
- [ ] Dump file written (if verbose)

### After Step 2.5 (Process Artifacts):
- [ ] New artifact files written
- [ ] Session file updated with new IDs
- [ ] Resolved conflicts updated

---

## Reference Files

- `references/session-schema.md` - Full YAML schema
- `references/agenda-specs.md` - Specs workflow agenda with DoD
- `references/agenda-design.md` - Design workflow agenda with DoD
- `references/agenda-brainstorm.md` - Brainstorm workflow (phase-based)
- `references/error-handling.md` - Error recovery patterns

---

*Referenced by: specs.md, design.md, brainstorm.md*

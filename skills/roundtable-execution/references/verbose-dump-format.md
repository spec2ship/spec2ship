# Verbose Dump File Format

When `--verbose` flag is set, write dump files to `rounds/` subfolder within the session folder.

## Naming Convention

```
Facilitator:      {NNN}-{PP}-facilitator-{action}.yaml
Participant:      {NNN}-02-{participant-id}.yaml
Session-Observer: {NNN}-04-session-observer.yaml      (NEW in 7B.4a, FIX-S1)

NNN = 3-digit round number (001, 002, ...)
PP = 2-digit phase (01=question, 02=responses, 03=synthesis, 04=observer)
action = question | synthesis (for facilitator files)
participant-id = product-manager, software-architect, etc.
```

**Examples**:
- `001-01-facilitator-question.yaml` - Facilitator question (phase 1)
- `001-02-software-architect.yaml` - Participant response (phase 2)
- `001-02-product-manager.yaml` - Participant response (phase 2)
- `001-03-facilitator-synthesis.yaml` - Facilitator synthesis (phase 3)
- `001-04-session-observer.yaml` - Per-round diagnostic observer (phase 4, only when `--diagnostic`)

**YAML `actor` field**: Always just `facilitator`, `{participant-id}`, or `session-observer` (not `facilitator-question`).

## Usage in Commands

Commands write dump files after each agent interaction:

| Step | File Pattern | Content |
|------|--------------|---------|
| 2.2 Facilitator Question | `{NNN}-01-facilitator-question.yaml` | Question decision + participant context |
| 2.3 Participant Response | `{NNN}-02-{participant-id}.yaml` | Position and rationale |
| 2.4 Facilitator Synthesis | `{NNN}-03-facilitator-synthesis.yaml` | Synthesis, artifacts, next action |

---

## Workflow-Specific Fields

Some fields vary by workflow type:

| Field | specs/design | brainstorm |
|-------|--------------|------------|
| `response.decision` | ✓ (focus decision) | - (uses disney phases) |
| `disney_phase` | - | ✓ (dreamer/realist/critic) |
| `response.ideas/risks/mitigations` | - | ✓ (participant responses) |

Fields not applicable to a workflow are simply omitted from the dump.

---

## Facilitator Question Dump

```yaml
# Round {N} - Facilitator Question
# Note: brainstorm adds `disney_phase:` field
round: {N}
phase: 1
actor: "facilitator"
action: "question"
started_at: "{ISO timestamp}"
completed_at: "{ISO timestamp}"

# STRUCTURED input (YAML object, not text)
input:
  action: "question"
  round: {N}
  topic: "{session topic}"
  strategy: "{strategy}"
  phase: "{current phase}"
  workflow_type: "{workflow_type}"
  escalation_config: {...}
  agenda: [...]
  # ... full input sent to facilitator

# STRUCTURED response (YAML object, not text)
response:
  decision:
    focus_type: "{agenda|conflict|open_question}"
    topic_id: "{topic}"
    rationale: "{reason}"
  question: "{the question}"
  exploration: "{exploration prompt}"
  participant_context:
    shared:
      project_summary: |
        {FULL project summary}
      relevant_artifacts:
        - id: "{ID}"
          title: "{title}"
          state: "{state}"
          # ... full artifact content
      open_conflicts: [...]
      open_questions: [...]
      recent_rounds: [...]
    overrides: null  # or per-participant directives
  participants: "all"

result:
  status: "closed"

tokens:
  input_estimate: {estimated input tokens}
  output_estimate: {estimated output tokens}
```

---

## Participant Response Dump

```yaml
# Round {N} - {Role} Response
round: {N}
phase: 2
actor: "{participant-id}"
action: "response"
started_at: "{ISO timestamp}"
completed_at: "{ISO timestamp}"

# STRUCTURED input
input:
  round: {N}
  topic: "{session topic}"
  phase: "{current phase}"
  workflow_type: "{workflow_type}"
  question: "{facilitator's question}"
  exploration: "{exploration prompt}"
  context:
    project_summary: |
      {project summary}
    relevant_artifacts: [...]
    open_conflicts: [...]
    open_questions: [...]
    recent_rounds: [...]

# STRUCTURED response
response:
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

result:
  status: "closed"

tokens:
  input_estimate: {estimated input tokens}
  output_estimate: {estimated output tokens}
```

---

## Facilitator Synthesis Dump

```yaml
# Round {N} - Facilitator Synthesis
round: {N}
phase: 3
actor: "facilitator"
action: "synthesis"
started_at: "{ISO timestamp}"
completed_at: "{ISO timestamp}"

# STRUCTURED input
input:
  action: "synthesis"
  round: {N}
  topic: "{session topic}"
  strategy: "{strategy}"
  phase: "{current phase}"
  escalation_config: {...}
  question_asked: "{facilitator's question from step 2.2}"
  responses:
    {participant-id}:
      position: "{position}"
      rationale: [...]
      concerns: [...]
      suggestions: [...]
      confidence: 0.85
    # ... all participants
  full_agenda: [...]
  focus_topic: {...}
  open_conflicts: [...]
  artifacts_count: {count}

# STRUCTURED response
response:
  synthesis: |
    {2-4 sentence summary}
  proposed_artifacts:
    - type: "{requirement|conflict|...}"
      title: "{title}"
      state: "{state}"
      topic_id: "{topic}"
      description: "..."
      # ... type-specific fields
  resolved_conflicts: []
  agenda_update:
    topic_id: "{topic}"
    new_status: "{partial|closed}"
    coverage_added: [...]
    remaining_for_closure: [...]
  constraints_check:
    rounds_completed: {N}
    min_rounds: {from config}
    can_conclude: {true|false}
    reason: "{explanation}"
  next: "{continue|conclude|escalate}"
  next_focus:
    type: "{agenda|conflict|open_question}"
    topic_id: "{topic}"
    reason: "{reason}"
  escalation_reason: null

result:
  artifacts_proposed: {count}
  conflicts_resolved: {count}
  status: "closed"

tokens:
  input_estimate: {estimated input tokens}
  output_estimate: {estimated output tokens}

# VERIFICATION CHECKLIST - for diagnostic/automated checking
verification:
  expected_artifacts:
    - map: "artifacts.requirements"
      expected_keys: ["{REQ-*}", ...]
    - map: "artifacts.conflicts"
      expected_keys: ["{CONF-*}", ...]
  round_summary:
    expected_round: {N}
    required_fields:
      - "timestamp"
      - "topic_id"
      - "facilitator_question"
      - "synthesis_summary"
      - "participant_positions"
      - "artifacts_created"
      - "next_action"
  agenda_status:
    topic_id: "{agenda_update.topic_id}"
    expected_status: "{agenda_update.new_status}"
  metrics_consistency:
    rounds_completed: {N}
    artifacts_total: {sum of all artifact maps}
  context_propagation:
    participant_context_keys:
      - "project_summary"
      - "relevant_artifacts"
      - "open_conflicts"
      - "open_questions"
      - "recent_rounds"
```

---

## Session-Observer Dump (Step 2.6c — added in TECH-002 Phase 7B.4a per FIX-S1 / BUG-013)

When `--diagnostic` flag is set, Step 2.6c writes the session-observer output per round:

**Filename**: `{NNN}-04-session-observer.yaml` (NNN = zero-padded round number)

```yaml
# Round {N} - Session Observer (per-round)
round: {N}
phase: 4
actor: "session-observer"
action: "observe"
started_at: "{ISO timestamp}"
completed_at: "{ISO timestamp}"

# STRUCTURED input (the YAML sent to session-observer agent)
input:
  mode: "per-round"
  session_path: ".s2s/sessions/{session-id}"
  round: {N}
  workflow_type: "{specs|design|brainstorm}"
  strategy: "{strategy}"

# STRUCTURED response (the observer's full YAML response)
response:
  mode: "per-round"
  round: {N}
  status: "ok" | "warning" | "anomaly"
  findings:
    - type: "{missing_context|strategy_deviation|...}"
      detail: "{description}"
      severity: "low" | "medium" | "high"
    # ... zero or more findings
  recommendation: "Continue" | "Review findings" | "Stop for investigation"
  notes: |
    Optional free-form observations.

result:
  status: "{response.status}"
  findings_count: {len(response.findings)}
  recommendation: "{response.recommendation}"
```

**Why this dump exists**: BUG-013 (TECH-002 Phase 7B.2 investigation) identified that Step 2.6c was consistently skipped at runtime because its output was display-only (no file artifact = no LLM commitment proof). Persistence anchors the step in the round's file pattern, matching the canonical `01-question`, `02-{participant}`, `03-synthesis` pattern with a new `04-session-observer` slot.

---

## Key Principles

1. **Structured YAML**: Use `input:` and `response:` as YAML objects, NOT text blobs
2. **Full content**: Save complete input/response, not summaries
3. **Verification**: Include checklist for diagnostic tools (session-observer)
4. **Consistent naming**: See naming convention above (facilitator includes action, participant does not)
5. **Diagnostic persistence**: When `--diagnostic` is set, Step 2.6c MUST write the session-observer dump (FIX-S1 / BUG-013)

---

*Updated to use structured format per TECH-002 consolidation. Session-observer dump added in TECH-002 Phase 7B.4a (2026-05-15).*

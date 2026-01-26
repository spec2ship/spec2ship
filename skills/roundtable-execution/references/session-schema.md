# Session File Schema

Complete YAML schema for roundtable session files and folder structure.

## File Structure

```
.s2s/sessions/
├── {session-id}.yaml              # Main session file (single source of truth)
└── {session-id}/                  # Session folder (for snapshots and verbose)
    ├── context-snapshot.yaml      # Immutable project context
    ├── config-snapshot.yaml       # Immutable roundtable config
    ├── agenda.yaml                # Workflow agenda with done_when criteria
    │
    └── rounds/                    # Verbose dumps (only with --verbose)
        ├── 001-01-facilitator-question.yaml
        ├── 001-02-product-manager.yaml
        ├── 001-02-business-analyst.yaml
        ├── 001-02-qa-lead.yaml
        ├── 001-03-facilitator-synthesis.yaml
        └── ...
```

**IMPORTANT**: Artifacts are EMBEDDED in the session file, NOT stored as separate files.

---

## Session File: `{session-id}.yaml`

Main session file containing all metadata, embedded artifacts, and round summaries.

```yaml
id: "20260107-requirements-elfgiftrush"
topic: "Requirements definition for ElfGiftRush"
workflow_type: "specs"  # specs | design | brainstorm
strategy: "consensus-driven"
status: "closed"  # active | closed

timing:
  started_at: "2026-01-07T13:05:00Z"
  updated_at: "2026-01-07T13:25:00Z"
  closed_at: "2026-01-07T13:25:00Z"

# Agent state (for resume capability)
agent_state:
  facilitator:
    agent_id: "abc123"
    last_round: 3
    last_action: "synthesis"
  participants: {}

# ARTIFACTS - embedded with full content (NOT separate files)
# Uses single "state" field per ADR-0010 (replaces status+agreement)
artifacts:
  requirements:
    REQ-001:
      state: "approved"          # Single state field (ADR-0010)
      created_round: 1
      topic_id: "user-workflows"
      title: "Gift Throwing Mechanic"
      priority: "must"
      description: |
        Users can throw gifts at targets...
      acceptance:
        - "Gift trajectory follows physics"
        - "Score updates on hit"
      proposed_by: "facilitator"
      supported_by: ["product-manager", "qa-lead"]
      related_to: []             # Optional: related artifact IDs
  business_rules: {}
  nfr: {}
  exclusions: {}
  open_questions:
    OQ-001:
      state: "resolved"          # Single state field
      created_round: 1
      topic_id: "user-workflows"
      title: "Which auth provider?"
      description: "Should we use OAuth or custom auth?"
      raised_by: "technical-lead"
      blocking: false
      resolution: "Use OAuth for MVP"  # Free text, optional
  conflicts: {}

# Agenda status
agenda:
  - topic_id: "user-workflows"
    status: "closed"
    coverage: ["REQ-001", "REQ-002"]
  - topic_id: "functional-requirements"
    status: "closed"
    coverage: ["REQ-003"]

# Round summaries (details in rounds/ folder if verbose)
# Per ADR-0010: artifacts_transitioned provides audit trail for state changes
rounds:
  - round: 1
    timestamp: "2026-01-07T13:10:00Z"
    topic_id: "user-workflows"
    facilitator_question: "What are the primary user workflows?"
    synthesis_summary: "Identified 2 key workflows..."
    participant_positions:
      product-manager: "Focus on casual gameplay..."
      qa-lead: "Consider edge cases..."
    key_decisions:
      - "Four-phase workflow adopted"
      - "Zero-friction entry required"
    artifacts_created: ["REQ-001", "REQ-002"]
    artifacts_transitioned:          # ADR-0010: round-level audit trail
      - id: "REQ-001"
        from: "draft"
        to: "approved"
        reason: "consensus reached"
      - id: "OQ-001"
        from: "in_progress"
        to: "resolved"
        reason: "addressed by REQ-002"
    resolved_conflicts:
      - conflict_id: "CONF-001"
        resolution: "Agreed on touch-drag approach"
        method: "consensus"  # consensus | facilitator | user_decision
    resolved_questions:
      - question_id: "OQ-001"
        answer: "Tutorial shown on first play only"
    consensus_reached: true
    next_action: "continue"

# Aggregated metrics
metrics:
  rounds_completed: 3
  artifacts:
    total: 5
    by_type: {requirements: 3, open_questions: 1, exclusions: 1}
    by_state: {approved: 3, in_progress: 1, resolved: 1}
  topics:
    total: 6
    closed: 6
  consensus_rate: 0.85

  # TECH-009: Progressive precision token tracking
  tokens:
    total: 45000              # Final accumulated total
    by_round:                 # Per-round detail with progressive precision
      - round: 1
        estimate: 12000       # T3-T0 (immediate, full round subagents)
        actual: 14500         # T0_2 - T0_1 (calculated at round 2, includes orchestrator)
        source: "measured"    # measured | estimated | interrupted | noisy
      - round: 2
        estimate: 15000
        actual: 17200
        source: "measured"
      - round: 3
        estimate: 18000
        actual: null          # Not yet calculated (last round or session closed)
        source: "estimated"
    # Note: stats (avg_actual, overhead_delta, sample_count) are calculated
    # on-the-fly by token-tracker.sh, not persisted in session file

# Validation state
validation:
  last_check: "2026-01-07T13:25:00Z"
  status: "valid"
  warnings: []
```

---

## Snapshot Files

### context-snapshot.yaml

Immutable copy of CONTEXT.md at session start.

```yaml
# Captured: 2026-01-07T13:05:00Z
source: ".s2s/CONTEXT.md"

project_name: "ElfGiftRush"
description: "Holiday-themed arcade game"

objectives:
  - "Create fun casual game"
  - "Simple mechanics"

constraints:
  - "Browser-based"
  - "Desktop + mobile"

scope:
  in:
    - "Single-player"
    - "Score tracking"
  out:
    - "Multiplayer"
    - "Backend"
```

### config-snapshot.yaml

Immutable copy of roundtable config at session start.

```yaml
# Captured: 2026-01-07T13:05:00Z
source: ".s2s/config.yaml"

verbose: true
interactive: false
strategy: "consensus-driven"

# Read from config.yaml at session start
limits:
  min_rounds: 3                  # from config.yaml: roundtable.limits.min_rounds
  max_rounds: 20                 # from config.yaml: roundtable.limits.max_rounds

escalation:
  max_rounds_per_conflict: 3     # from config.yaml: roundtable.escalation.triggers.*
  confidence_below: 0.5
  critical_keywords: ["security", "must-have", "blocking", "legal"]

# Consensus rules for current strategy (ADR-0010)
consensus:
  threshold: 1.0                 # from config.yaml: roundtable.strategy.consensus[strategy]
  mechanism: "consent"
  block_prevents_terminal: true

participants:
  - "product-manager"
  - "business-analyst"
  - "qa-lead"
```

### agenda.yaml

Workflow agenda with Definition of Done criteria.

```yaml
# Captured: 2026-01-07T13:05:00Z
source: "skills/roundtable-execution/references/agenda-specs.md"
workflow: "specs"

topics:
  - id: "user-workflows"
    name: "User workflows"
    critical: true
    done_when:
      criteria:
        - "Entry/exit conditions defined"
        - "Happy path documented"
      min_requirements: 2
    exploration: "Are there other workflows we should consider?"

  - id: "functional-requirements"
    name: "Functional requirements"
    critical: true
    done_when:
      criteria:
        - "Core mechanics defined"
        - "Measurable criteria for each"
      min_requirements: 3
    exploration: "Are there other features we should consider?"
```

---

## Embedded Artifact Schemas

Artifacts are stored as maps inside `artifacts.{type}` in the session file.
Each artifact has a single **state** field per ADR-0010.

### State Model (ADR-0010)

**Universal states** (all artifact types):
- `draft` - Initial state after creation
- `needs_discussion` - Queued for discussion
- `in_progress` - Currently being discussed
- `blocked` - Has blocking concern
- `deferred` - Postponed for later
- `rejected` - Explicitly rejected

**Type-specific terminal states**:
- REQ, BR, NFR, EX: `approved`, `implemented`
- DEC, ARCH: `accepted`
- IDEA: `promoted`, `parked`
- OQ, CONF: `resolved`

### Requirement (REQ-*)

```yaml
artifacts:
  requirements:
    REQ-001:
      state: "approved"          # Single state field (ADR-0010)
      created_round: 1
      topic_id: "user-workflows"
      title: "Game Entry"
      priority: "must"           # must|should|could|wont
      description: |
        Zero-friction start with prominent Play button.
      acceptance:
        - "One-tap start"
        - "No registration"
        - "<3 seconds to gameplay"
      proposed_by: "facilitator"
      supported_by: ["product-manager", "qa-lead"]
      related_to: []             # Optional: related artifact IDs
```

### Business Rule (BR-*)

```yaml
artifacts:
  business_rules:
    BR-001:
      state: "approved"
      created_round: 1
      topic_id: "business-rules"
      title: "60-Second Game Duration"
      description: |
        Game duration is fixed at exactly 60 seconds.
      conditions: |
        Every game session
      actions: |
        Timer starts at 60s and counts down
      related_to: []             # Optional: related artifact IDs
```

### NFR (NFR-*)

```yaml
artifacts:
  nfr:
    NFR-001:
      state: "approved"
      created_round: 3
      topic_id: "nfr-measurable"
      title: "Frame Rate"
      category: "performance"    # performance|reliability|security|usability|scalability
      description: |
        Game must maintain smooth animation.
      target: "60 FPS"
      minimum: "30 FPS"
      measurement: "Browser DevTools performance panel"
      related_to: []             # Optional: related artifact IDs
```

### Conflict (CONF-*)

```yaml
artifacts:
  conflicts:
    CONF-001:
      state: "resolved"          # in_progress|blocked|resolved
      created_round: 1
      topic_id: "functional-requirements"
      title: "Mobile Input Method"
      description: |
        No agreement on touch control implementation.
      positions:
        product-manager: "Virtual joystick"
        qa-lead: "Touch-drag with offset"
      resolution: "Direct touch-drag with 40-60px offset"  # Free text
      resolution_method: "consensus"  # consensus|escalation|facilitator
```

### Open Question (OQ-*)

```yaml
artifacts:
  open_questions:
    OQ-001:
      state: "in_progress"       # draft|in_progress|blocked|resolved|deferred
      created_round: 1
      topic_id: "user-workflows"
      title: "Pause Functionality"
      description: |
        Should the game have pause functionality?
      raised_by: "qa-lead"
      blocking: false
      resolution: null           # Free text when resolved
```

### Exclusion (EX-*)

```yaml
artifacts:
  exclusions:
    EX-001:
      state: "approved"
      created_round: 3
      topic_id: "out-of-scope"
      title: "Multiplayer Mode"
      description: |
        Multiplayer/networking is explicitly out of scope.
      rationale: |
        MVP focus on single-player experience.
      future_consideration: true
      related_to: []             # Optional: related artifact IDs
```

---

## Verbose Dump Files (rounds/ folder)

Only created when `--verbose` flag is used. Uses **structured YAML format** (not text blobs).

See `references/verbose-dump-format.md` for complete format specification.

### Naming Convention

```
Facilitator: {NNN}-{PP}-facilitator-{action}.yaml
Participant: {NNN}-02-{participant-id}.yaml

NNN = 3-digit round number (001, 002, ...)
PP = 2-digit phase (01=question, 02=responses, 03=synthesis)
action = question | synthesis (for facilitator files)
```

**Examples**:
- `001-01-facilitator-question.yaml` - Facilitator question
- `001-02-product-manager.yaml` - Participant response
- `001-03-facilitator-synthesis.yaml` - Facilitator synthesis

**Note**: YAML `actor` field is just `facilitator` or `{participant-id}`, not `facilitator-question`.

### Facilitator Question Dump (example)

```yaml
round: 1
phase: 1
actor: "facilitator"
action: "question"
started_at: "2026-01-07T13:05:00Z"
completed_at: "2026-01-07T13:05:12Z"

# STRUCTURED input (YAML object)
input:
  action: "question"
  round: 1
  topic: "Requirements definition for ElfGiftRush"
  strategy: "consensus-driven"
  workflow_type: "specs"
  agenda:
    - id: "user-workflows"
      status: "open"
      priority: "critical"

# STRUCTURED response (YAML object)
response:
  decision:
    focus_type: "agenda"
    topic_id: "user-workflows"
    rationale: "Starting with critical topic"
  question: "What are the primary user workflows?"
  exploration: "Are there other workflows we should consider?"
  participant_context:
    shared:
      project_summary: "Holiday-themed arcade game..."
      relevant_artifacts: []
  participants: "all"

result:
  status: "closed"

tokens:
  input_estimate: 2500
  output_estimate: 400
```

### Participant Response Dump (example)

```yaml
round: 1
phase: 2
actor: "product-manager"
action: "response"
started_at: "2026-01-07T13:05:15Z"
completed_at: "2026-01-07T13:05:28Z"

input:
  round: 1
  question: "What are the primary user workflows?"
  exploration: "Are there other workflows we should consider?"
  context:
    project_summary: "Holiday-themed arcade game..."

response:
  participant: "product-manager"
  position: "Four-phase workflow with zero-friction entry"
  rationale:
    - "Casual players expect instant start"
    - "Holiday theme suggests fun"
  confidence: 0.85
  concerns:
    - "Mobile controls responsiveness"
  suggestions:
    - "Onboarding hint on first play"

result:
  status: "closed"

tokens:
  input_estimate: 1800
  output_estimate: 450
```

### Facilitator Synthesis Dump (example)

```yaml
round: 1
phase: 3
actor: "facilitator"
action: "synthesis"
started_at: "2026-01-07T13:06:00Z"
completed_at: "2026-01-07T13:06:25Z"

input:
  action: "synthesis"
  round: 1
  question_asked: "What are the primary user workflows?"
  responses:
    product-manager:
      position: "Four-phase workflow..."
      confidence: 0.85
    business-analyst:
      position: "Same four phases..."
      confidence: 0.80

response:
  synthesis: "Strong alignment on four-phase workflow..."
  proposed_artifacts:
    - type: "requirement"
      title: "Game Entry"
      state: "approved"
      description: "Zero-friction start"
  artifacts_transitioned:
    - id: "REQ-001"
      from: "draft"
      to: "approved"
      reason: "consensus reached"
  agenda_update:
    topic_id: "user-workflows"
    new_status: "partial"
  next: "continue"

result:
  artifacts_proposed: 1
  status: "closed"

tokens:
  input_estimate: 3500
  output_estimate: 800

verification:
  expected_artifacts:
    - map: "artifacts.requirements"
      expected_keys: ["REQ-001"]
```

---

## Artifact Types by Workflow

| Workflow | Artifact Types |
|----------|---------------|
| **specs** | REQ-*, BR-*, NFR-*, EX-*, CONF-*, OQ-* |
| **design** | ARCH-*, COMP-*, CONF-*, OQ-* |
| **brainstorm** | IDEA-*, RISK-*, MIT-*, OQ-* |

---

## State Values (ADR-0010)

### Session and Agenda

| Entity | Valid States |
|--------|-------------|
| Session | active, closed |
| Agenda topic | open, partial, closed |

### Artifact States

**Universal states** (apply to all artifact types):

| State | Description | Facilitator Action |
|-------|-------------|-------------------|
| `draft` | Initial state after creation | Passive (log) |
| `needs_discussion` | Queued for discussion | Passive (queue) |
| `in_progress` | Currently being discussed | Active (drive resolution) |
| `blocked` | Has blocking concern | Active (address block) |
| `deferred` | Postponed for later | Passive (review at close) |
| `rejected` | Explicitly rejected | Passive (archive) |

**Type-specific terminal states**:

| Artifact Type | Terminal States |
|---------------|-----------------|
| REQ, BR, NFR, EX | `approved`, `implemented` |
| DEC, ARCH | `accepted` |
| IDEA | `promoted`, `parked` |
| OQ, CONF | `resolved` |

### Transition Conditions (Prose)

- **draft → needs_discussion**: Artifact is ready for group discussion
- **needs_discussion → in_progress**: Facilitator selects for current round
- **in_progress → terminal**: Consensus reached per strategy threshold (no blocks)
- **in_progress → blocked**: At least one participant signals block
- **in_progress → deferred**: Explicit decision to postpone
- **blocked → in_progress**: Blocking concern addressed
- **Any → rejected**: Explicit decision to abandon

For strategies without voting (debate, disney), the facilitator determines terminal transitions based on discussion quality and coverage.

---

*Part of roundtable-execution skill | Updated per ADR-0010*

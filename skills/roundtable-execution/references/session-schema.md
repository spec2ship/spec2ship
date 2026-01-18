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
artifacts:
  requirements:
    REQ-001:
      status: "active"
      agreement: "consensus"
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
      amendments: []
  business_rules: {}
  nfr: {}
  exclusions: {}
  open_questions:
    OQ-001:
      status: "resolved"
      created_round: 1
      topic_id: "user-workflows"
      title: "Which auth provider?"
      description: "Should we use OAuth or custom auth?"
      raised_by: "technical-lead"
      blocking: false
      resolution: "Use OAuth for MVP"
      resolved_round: 2
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
rounds:
  - round: 1
    topic_id: "user-workflows"
    facilitator_question: "What are the primary user workflows?"
    synthesis_summary: "Identified 2 key workflows..."
    participant_positions:
      product-manager: "Focus on casual gameplay..."
      qa-lead: "Consider edge cases..."
    artifacts_created: ["REQ-001", "REQ-002"]
    consensus_reached: true
    next_action: "continue"

# Aggregated metrics
metrics:
  rounds_completed: 3
  artifacts:
    total: 5
    by_type: {requirements: 3, open_questions: 1, exclusions: 1}
    by_status: {active: 4, resolved: 1}
  topics:
    total: 6
    closed: 6
  consensus_rate: 0.85
  tokens:
    estimated_total: 45000
    by_round: [12000, 15000, 18000]

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

limits:
  min_rounds: 3
  max_rounds: 20

escalation:
  max_rounds_per_conflict: 3
  confidence_below: 0.5
  critical_keywords: ["security", "must-have", "blocking", "legal"]

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
Each artifact has a **lifecycle status** and an **agreement level**.

### Requirement (REQ-*)

```yaml
artifacts:
  requirements:
    REQ-001:
      status: "active"           # Lifecycle: active|amended|superseded|withdrawn
      agreement: "consensus"     # Agreement: consensus|draft|conflict
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
      amendments: []
```

### Business Rule (BR-*)

```yaml
artifacts:
  business_rules:
    BR-001:
      status: "active"
      agreement: "consensus"
      created_round: 1
      topic_id: "business-rules"
      title: "60-Second Game Duration"
      description: |
        Game duration is fixed at exactly 60 seconds.
      conditions: |
        Every game session
      actions: |
        Timer starts at 60s and counts down
      amendments: []
```

### NFR (NFR-*)

```yaml
artifacts:
  nfr:
    NFR-001:
      status: "active"
      agreement: "consensus"
      created_round: 3
      topic_id: "nfr-measurable"
      title: "Frame Rate"
      category: "performance"    # performance|reliability|security|usability|scalability
      description: |
        Game must maintain smooth animation.
      target: "60 FPS"
      minimum: "30 FPS"
      measurement: "Browser DevTools performance panel"
      amendments: []
```

### Conflict (CONF-*)

```yaml
artifacts:
  conflicts:
    CONF-001:
      status: "resolved"         # open|resolved
      created_round: 1
      resolved_round: 2
      topic_id: "functional-requirements"
      title: "Mobile Input Method"
      description: |
        No agreement on touch control implementation.
      positions:
        product-manager: "Virtual joystick"
        qa-lead: "Touch-drag with offset"
      resolution: "Direct touch-drag with 40-60px offset"
      resolution_method: "consensus"  # consensus|escalation|facilitator
```

### Open Question (OQ-*)

```yaml
artifacts:
  open_questions:
    OQ-001:
      status: "open"             # open|resolved
      created_round: 1
      topic_id: "user-workflows"
      title: "Pause Functionality"
      description: |
        Should the game have pause functionality?
      raised_by: "qa-lead"
      blocking: false
      resolution: null           # Filled when resolved
      resolved_round: null
```

### Exclusion (EX-*)

```yaml
artifacts:
  exclusions:
    EX-001:
      status: "active"
      agreement: "consensus"
      created_round: 3
      topic_id: "out-of-scope"
      title: "Multiplayer Mode"
      description: |
        Multiplayer/networking is explicitly out of scope.
      rationale: |
        MVP focus on single-player experience.
      future_consideration: true
      amendments: []
```

---

## Verbose Dump Files (rounds/ folder)

Only created when `--verbose` flag is used.

### Naming Convention

```
{round}-{phase}-{actor}.yaml

Examples:
001-01-facilitator-question.yaml
001-02-product-manager.yaml
001-02-business-analyst.yaml
001-02-qa-lead.yaml
001-03-facilitator-synthesis.yaml
```

- `{round}`: 3-digit round number (001, 002, ...)
- `{phase}`: 2-digit phase (01=question, 02=responses, 03=synthesis)
- `{actor}`: facilitator, product-manager, etc.

### Facilitator Question Dump

```yaml
round: 1
phase: 1
actor: "facilitator"

timing:
  started_at: "2026-01-07T13:05:00Z"
  completed_at: "2026-01-07T13:05:12Z"
  duration_ms: 12345

tokens:
  input: 2500
  output: 400

prompt: |
  You are the Roundtable Facilitator.

  === SESSION STATE ===
  Round: 1
  Session folder: .s2s/sessions/20260107-requirements-elfgiftrush/

  === ARTIFACT SUMMARY ===
  (none yet - first round)

  === AGENDA STATUS ===
  [open] user-workflows (CRITICAL)
  [open] functional-requirements (CRITICAL)

  === YOUR TASK ===
  1. Decide focus for this round
  2. Select context files for participants
  3. Generate question + exploration prompt

response: |
  action: "question"
  decision:
    focus_type: "agenda"
    topic_id: "user-workflows"
    rationale: "Starting with critical topic"
  context_files:
    - "context-snapshot.yaml"
  question: "What are the primary user workflows?"
  exploration: "Are there other workflows we should consider?"
  participants: "all"

result:
  valid: true
  warnings: []
```

### Participant Response Dump

```yaml
round: 1
phase: 2
actor: "product-manager"

timing:
  started_at: "2026-01-07T13:05:15Z"
  completed_at: "2026-01-07T13:05:28Z"
  duration_ms: 13123

tokens:
  input: 1800
  output: 450

prompt: |
  You are the Product Manager in a roundtable discussion.

  === CONTEXT FILES ===
  Read these files (DO NOT read other session files):
  - .s2s/sessions/20260107-.../context-snapshot.yaml

  === QUESTION ===
  What are the primary user workflows?

  === EXPLORATION ===
  Are there other workflows we should consider?

response: |
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
  valid: true
  warnings: []
```

### Facilitator Synthesis Dump

```yaml
round: 1
phase: 3
actor: "facilitator"

timing:
  started_at: "2026-01-07T13:06:00Z"
  completed_at: "2026-01-07T13:06:25Z"
  duration_ms: 25678

tokens:
  input: 3500
  output: 800

prompt: |
  === ROUND 1 RESPONSES ===
  **Product Manager** (0.85): Four-phase workflow...
  **Business Analyst** (0.80): Same four phases...
  **QA Lead** (0.85): Four-phase with testing focus...

  === ARTIFACT SUMMARY ===
  (none yet)

  === YOUR TASK ===
  Synthesize and propose artifacts.

response: |
  action: "synthesis"
  synthesis: "Strong alignment on four-phase workflow..."
  proposed_artifacts:
    - type: "requirement"
      title: "Game Entry"
      status: "consensus"
      description: "Zero-friction start"
      acceptance:
        - "One-tap start"
    - type: "conflict"
      title: "Mobile Input Method"
      positions:
        product-manager: "Virtual joystick"
        qa-lead: "Touch-drag"
  agenda_update:
    topic_id: "user-workflows"
    new_status: "partial"
    coverage_added: ["Core workflow phases"]
  next: "continue"

result:
  valid: true
  warnings: []
  artifacts_created: ["REQ-001", "CONF-001"]
```

---

## Artifact Types by Workflow

| Workflow | Artifact Types |
|----------|---------------|
| **specs** | REQ-*, BR-*, NFR-*, EX-*, CONF-*, OQ-* |
| **design** | ARCH-*, COMP-*, CONF-*, OQ-* |
| **brainstorm** | IDEA-*, RISK-*, MIT-*, OQ-* |

---

## Status Values

| Entity | Valid Statuses |
|--------|---------------|
| Session | active, closed |
| Agenda topic | open, partial, closed |
| Requirement | draft, consensus, conflict |
| Conflict | open, resolved, escalated |
| Open question | pending, addressed, deferred |
| Exclusion | proposed, confirmed |

---

*Part of roundtable-execution skill*

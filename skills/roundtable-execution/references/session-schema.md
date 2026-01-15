# Session File Schema

Complete YAML schema for roundtable session files and folder structure.

## File Structure

```
.s2s/sessions/
├── {session-id}.yaml              # Session file with embedded artifacts
└── {session-id}/                  # Session folder
    ├── context-snapshot.yaml      # Immutable project context
    ├── config-snapshot.yaml       # Immutable config
    ├── agenda.yaml                # Workflow agenda with DoD
    │
    └── rounds/                    # Verbose dumps (only with --verbose)
        ├── 001-01-facilitator-question.yaml
        ├── 001-02-product-manager.yaml
        ├── 001-02-business-analyst.yaml
        ├── 001-02-qa-lead.yaml
        ├── 001-03-facilitator-synthesis.yaml
        └── ...
```

**Note**: Artifacts are EMBEDDED in the session file, NOT stored as separate files.

---

## Session File: `{session-id}.yaml`

Session file with metadata, embedded artifacts, and round summaries.

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

# Embedded artifacts (full content, not just IDs)
artifacts:
  requirements:
    REQ-001:
      status: "active"
      agreement: "consensus"
      created_round: 1
      topic_id: "user-workflows"
      title: "Game Entry"
      description: |
        Zero-friction start with prominent Play button.
      acceptance:
        - "One-tap start"
        - "No registration"
      priority: "must"
      proposed_by: "facilitator"
      supported_by: ["product-manager", "business-analyst"]
    REQ-002:
      status: "active"
      agreement: "consensus"
      created_round: 2
      topic_id: "user-workflows"
      title: "Game Entry with Tutorial"
      description: |
        Zero-friction start with optional tutorial on first play.
      acceptance:
        - "One-tap start"
        - "Tutorial shown only on first play"
        - "Skip option available"
      priority: "must"
      related_to: ["REQ-001"]  # Refines REQ-001
      proposed_by: "facilitator"
      supported_by: ["product-manager", "ux-researcher"]
  business_rules:
    BR-001:
      status: "active"
      agreement: "consensus"
      created_round: 2
      topic_id: "business-rules"
      title: "60-Second Game Duration"
      description: |
        Game duration is fixed at exactly 60 seconds.
      rationale: "Creates urgency without frustration"
      related_to: ["REQ-001"]  # Rule applies to game entry flow
  conflicts:
    CONF-001:
      status: "resolved"
      created_round: 1
      topic_id: "functional-requirements"
      title: "Mobile Input Method"
      related_to: ["REQ-001", "REQ-002"]  # Conflict about these requirements
      positions:
        - participant: "product-manager"
          stance: "Virtual joystick"
        - participant: "qa-lead"
          stance: "Touch-drag with offset"
      resolution:
        summary: "Direct touch-drag with 40-60px offset"
        method: "consensus"
      resolved_round: 2
  open_questions:
    OQ-001:
      status: "resolved"
      created_round: 1
      topic_id: "user-workflows"
      title: "Pause Functionality"
      description: |
        Should the game have pause functionality?
      raised_by: "qa-lead"
      related_to: ["REQ-001"]  # Question about game entry flow
      resolution: "Out of scope for MVP"
      resolved_round: 3

# Agenda status
agenda:
  - topic_id: "user-workflows"
    status: "closed"
    coverage: ["Core workflow phases", "Entry point"]
    closed_round: 2
  - topic_id: "functional-requirements"
    status: "closed"
    coverage: ["Game mechanics"]
    closed_round: 3

# Round summaries (details in rounds/ folder if verbose)
rounds:
  - number: 1
    focus:
      type: "agenda"  # agenda | conflict | open_question
      topic_id: "user-workflows"
    artifacts_created: ["REQ-001", "CONF-001", "OQ-001"]
    conflicts_resolved: []
    questions_resolved: []
    next: "continue"  # continue | conclude | escalate
  - number: 2
    focus:
      type: "conflict"
      topic_id: "CONF-001"
    artifacts_created: ["BR-001"]
    conflicts_resolved: ["CONF-001"]
    questions_resolved: []
    next: "continue"
  - number: 3
    focus:
      type: "open_question"
      topic_id: "OQ-001"
    artifacts_created: []
    conflicts_resolved: []
    questions_resolved: ["OQ-001"]
    next: "conclude"

# Aggregated metrics
metrics:
  rounds: 3
  artifacts:
    total: 4
    by_status:
      active: 2
      open: 0
      resolved: 2
  tokens: 45000
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

All artifacts are embedded in the session file under `artifacts.{type}`. See session file example above for complete structure.

### Common Optional Field: `related_to`

All artifact types support an optional `related_to` field:

```yaml
related_to: ["REQ-001", "BR-002"]  # Array of artifact IDs
```

**Semantics**: Indicates correlation with other artifacts (not hierarchy or superseding).

**Used by facilitator**: When selecting `relevant_artifacts` for participant context, artifacts referenced via `related_to` are automatically included (1 level deep, bidirectional).

### Standard Artifacts (status: "active")

- **Requirements** (REQ-*): status, agreement, title, description, acceptance[], priority, related_to?
- **Business Rules** (BR-*): status, agreement, title, description, rationale, related_to?
- **NFRs** (NFR-*): status, agreement, title, category, target, minimum, measurement, related_to?
- **Exclusions** (EX-*): status, agreement, title, description, rationale, future_consideration, related_to?
- **Ideas** (IDEA-*): status, agreement, title, description, disney_phase, related_to?
- **Risks** (RISK-*): status, agreement, title, description, likelihood, impact, related_to?
- **Mitigations** (MIT-*): status, agreement, title, risk_id, description (risk_id is the relation)
- **Architecture Decisions** (ARCH-*): status, agreement, title, context, decision, rationale, related_to?
- **Components** (COMP-*): status, agreement, title, purpose, interfaces, related_to?
- **Interfaces** (INT-*): status, agreement, title, type, description, endpoints, related_to?

### Resolution Artifacts (status: "open"|"resolved")

- **Conflicts** (CONF-*): status, positions[], resolution.summary, resolution.method, related_to?
- **Open Questions** (OQ-*): status, description, raised_by, resolution, related_to?

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
| **design** | ARCH-*, COMP-*, INT-*, CONF-*, OQ-* |
| **brainstorm** | IDEA-*, RISK-*, MIT-*, OQ-* |

---

## Status Values

| Entity | Valid Statuses | Notes |
|--------|---------------|-------|
| Session | active, closed | Terminal state: closed |
| Agenda topic | open, partial, closed | Progress tracking |
| Standard artifacts | active | Use `agreement` for consensus level |
| Conflicts | open, resolved | Resolution tracked in `resolution.method` |
| Open questions | open, resolved | Resolution tracked in `resolution` |

### Agreement Levels (for standard artifacts)

| Level | Description |
|-------|-------------|
| consensus | All participants agreed |
| draft | Tentative, needs further discussion |
| conflict | Disagreement exists, separate CONF artifact created |

### Resolution Methods (for conflicts)

| Method | Description |
|--------|-------------|
| consensus | Participants reached agreement |
| facilitator | Facilitator made judgment call |
| user_decision | User intervened via escalation |

---

*Part of roundtable-execution skill*

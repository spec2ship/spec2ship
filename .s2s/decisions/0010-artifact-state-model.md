# Artifact State Model for LLM-Driven Roundtables

## Status

accepted

## Context and Problem Statement

The current artifact model uses two fields (`status` and `agreement`) with overlapping semantics. This creates ambiguity for the LLM facilitator and complicates session recovery.

Key issues:
- `status: "active"` is redundant (always same value for standard artifacts)
- `agreement: "draft"` vs `status: "open"` have semantic overlap
- Unclear facilitator actions per state
- Session recovery needs deterministic state reconstruction

An initial roundtable (10 rounds) proposed an elaborate solution with immutable artifacts, supersedes chains, WAL-style intent logging, and a dedicated skill for state transitions. Upon review, this was deemed **overengineered for the s2s context**.

## LLM-First Design Principles

These principles guided the final decision and should inform all future s2s architectural choices:

### 1. Simplicity over theoretical correctness

LLMs process YAML files directly. Every additional field, nested structure, or cross-reference increases cognitive load and error probability. A simpler model that an LLM can reliably execute is better than an elaborate model that introduces edge cases.

### 2. No database patterns in file-based systems

Patterns like write-ahead logging (WAL), immutable records with supersedes chains, and chain traversal are designed for databases with transaction guarantees. Claude Code operates on plain files. These patterns add complexity without the benefits they provide in their native context.

### 3. Natural audit in chronological structures

Session files already have a `rounds[]` array that captures the chronological evolution of the discussion. Audit information belongs there, not duplicated in artifact fields or parallel structures.

### 4. No timers or background processes

Claude Code cannot set timers or run background checks. Concepts like "staleness timeout after 15 minutes" are unimplementable. The facilitator evaluates progress based on round count and content, not wall-clock time.

### 5. Prose over predicates for LLM instructions

LLMs understand natural language better than formal predicates. Transition rules described in prose ("when consensus is reached") are more reliable than boolean formulas.

## Decision Drivers

- **Determinism**: LLM facilitator must know exactly what to do for each state
- **Recovery**: Session can be interrupted; must reconstruct situation from saved state
- **Simplicity**: Minimal cognitive load for LLM to process
- **Auditability**: History of changes must be recoverable
- **Consistency**: Same model works across specs, design, brainstorm workflows

## Considered Options

1. Two-field model (status + agreement) - current, with clarified semantics
2. Single state field with mutable artifacts + round-level audit
3. Single state field with immutable artifacts + supersedes chains
4. Single state field with WAL-style intent logging

## Decision Outcome

Chosen option: **Single state field with mutable artifacts and round-level audit trail**.

This provides determinism and auditability while keeping the model simple enough for reliable LLM execution.

### Core Design

**Single state field** replaces `status` and `agreement`:

```yaml
state: "approved"  # Not: status + agreement
```

**Hybrid model** with universal behavioral states plus type-specific terminals:

| Category | States |
|----------|--------|
| Universal (all types) | `draft`, `needs_discussion`, `in_progress`, `blocked`, `deferred`, `rejected` |
| REQ terminals | `approved`, `implemented` |
| DEC/ARCH terminals | `accepted` |
| IDEA terminals | `promoted`, `parked` |
| OQ/CONF terminals | `resolved` |

**Mutable in-place**: Artifacts are modified directly. State changes are audited in the round summary.

**Round-level audit**: Each round records state transitions:

```yaml
rounds:
  - number: 3
    synthesis: "..."
    artifacts_created: [REQ-003]
    artifacts_transitioned:
      - id: REQ-001
        from: "in_progress"
        to: "approved"
        reason: "consensus reached"
      - id: OQ-002
        from: "open"
        to: "resolved"
        reason: "addressed by REQ-003"
```

### Artifact Schema

```yaml
artifacts:
  requirements:
    REQ-001:
      state: "approved"
      created_round: 1
      title: "User authentication"
      description: "..."
      acceptance: [...]
      proposed_by: "facilitator"
      supported_by: [software-architect, technical-lead]

  open_questions:
    OQ-001:
      state: "resolved"
      created_round: 1
      title: "Which auth method?"
      description: "..."
      raised_by: "software-architect"
      resolution: "JWT chosen, see REQ-003"  # Free text, optional
```

### Consequences

- Good, because single state eliminates ambiguity
- Good, because mutable artifacts keep YAML simple
- Good, because audit trail in rounds is natural and chronological
- Good, because no chain traversal needed
- Good, because LLM can reliably read and update
- Neutral, because artifact alone doesn't show history (must check rounds)

## Supporting Decisions

### Facilitator-driven state decisions

The facilitator agent is the sole **decision-maker** for artifact state changes. The command **applies** these decisions by writing to the session file.

| Component | Role | Capability |
|-----------|------|------------|
| Facilitator agent | Decides state transitions | Proposes in synthesis output |
| Command (roundtable.md) | Executes decisions | Writes to session file |
| Participants | Signal support/block | No direct state modification |

This separation ensures:
- Single decision authority (facilitator)
- Reliable file I/O (command has Write tool)
- Clear audit trail (command logs what facilitator decided)

### Consensus threshold (strategy-specific)

Consensus rules vary by strategy. Configured in `config.yaml` under `roundtable.strategy.{name}`:

| Strategy | Threshold | Mechanism | Block behavior |
|----------|-----------|-----------|----------------|
| **standard** | 2/3 (67%) | Majority vote | Single block prevents terminal |
| **consensus-driven** | 100% | Consent-based | Single block triggers discussion |
| **debate** | N/A | Facilitator weighs | No voting, facilitator decides |
| **disney** | N/A | Phase collection | No voting, ideas gathered |
| **six-hats** | 2/3 (67%) | Majority after all hats | Single block prevents terminal |

Block priority applies to all strategies with voting: any single `block` prevents terminal state transition until addressed.

### Active vs passive states

**Active** (facilitator must act):
- `blocked` - Address blocking concern before proceeding
- `in_progress` - Drive toward resolution

**Passive** (informational):
- `draft`, `needs_discussion`, `deferred`, `rejected`, terminal states

### Deferred review at session close

When concluding a session, the facilitator surfaces all `deferred` artifacts for explicit decision: resolve, reject, or carry forward.

### Transition rules location

Documented in `skills/roundtable-execution/references/session-schema.md` alongside the schema definition. No separate skill needed.

## Rejected Alternatives

The following patterns from the initial roundtable were explicitly rejected:

### Immutable with supersedes chains

**Rejected because**: Chain traversal adds complexity. The audit benefit is achieved more simply via round summaries. Sessions are ephemeral (hours), not permanent records like ADRs.

### Intent logging (WAL pattern)

**Rejected because**: Claude Code is not a database. Session interruption recovery works by reading the saved state; no pending transaction log is needed. The existing `agent_state.last_action` field suffices.

### Staleness timeout (15 minutes)

**Rejected because**: No timer mechanism exists. Progress is evaluated by round count and synthesis content.

### metadata.resolution_type

**Rejected because**: Semantic nuance without behavioral impact. The resolution context is already in the round that performed the transition. Free-text `resolution` field on OQ/CONF suffices if needed.

### Dedicated skill for state machine

**Rejected because**: Adds indirection. The transition rules are few and simple; documenting them in session-schema.md keeps everything in one place.

### Max chain depth with lazy consolidation

**Rejected because**: Not applicable without supersedes chains.

## State Transitions

```
                    ┌──────────────────┐
                    │      draft       │
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │ needs_discussion │
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
        ┌───────────│   in_progress    │───────────┐
        │           └────────┬─────────┘           │
        │                    │                     │
        ▼                    ▼                     ▼
┌───────────────┐   ┌───────────────┐   ┌─────────────────┐
│    blocked    │   │   deferred    │   │ {type terminal} │
└───────┬───────┘   └───────────────┘   └─────────────────┘
        │
        ▼
  (resolve block)
        │
        ▼
   in_progress
```

### Transition conditions (prose)

- **draft → needs_discussion**: Artifact is ready for group discussion
- **needs_discussion → in_progress**: Facilitator selects for current round
- **in_progress → terminal**: Consensus reached per strategy threshold (no blocks)
- **in_progress → blocked**: At least one participant signals block
- **in_progress → deferred**: Explicit decision to postpone
- **blocked → in_progress**: Blocking concern addressed
- **Any → rejected**: Explicit decision to abandon

Note: For strategies without voting (debate, disney), the facilitator determines terminal transitions based on discussion quality and coverage.

## Related Decisions

- [0006](0006-session-embedded-artifacts.md) - Session embedded artifacts (schema context)

---

*Derived from roundtable session 20260118-roundtable-artifact-state-model (10 rounds), with post-roundtable simplification based on LLM-first principles.*

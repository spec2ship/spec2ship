# Roundtable Flow

This document describes the complete flow of a roundtable discussion from user command to output document.

## Architecture Overview

> **Key Constraint**: Claude Code subagents cannot spawn other subagents.
> Solution: Orchestration logic is **inline in the command** (start.md), not a separate agent.

```
┌─────────────────────────────────────────────────────────────────┐
│  User: /s2s:specs, /s2s:design, /s2s:brainstorm                │
│  • Workflow-specific setup and validation                       │
│  • Delegates via SlashCommand:/s2s:roundtable:start             │
│  • Post-processes results into workflow-specific output         │
└──────────────────────────────┬──────────────────────────────────┘
                               │ SlashCommand
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│  Command (start.md) - INLINE ORCHESTRATION                      │
│                                                                 │
│  PHASE 1: SETUP                                                 │
│  • Parse arguments, validate environment                        │
│  • Auto-detect strategy from topic keywords                     │
│  • Create session file .s2s/sessions/{id}.yaml                  │
│  • Load strategy config from skill                              │
│                                                                 │
│  PHASE 2: DISCUSSION LOOP (inline, not delegated)               │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ For each round until conclusion:                            ││
│  │                                                             ││
│  │ Step 1: Task(facilitator) → generate question               ││
│  │ Step 2: Task(participants) → parallel responses             ││
│  │ Step 3: Task(facilitator) → synthesize                      ││
│  │ Step 4: Batch write round to session file                   ││
│  │ Step 5: Evaluate next_action                                ││
│  │         continue → loop | phase → advance | conclude → exit ││
│  │         escalate → ask user → continue or conclude          ││
│  └─────────────────────────────────────────────────────────────┘│
│                                                                 │
│  PHASE 3: COMPLETION                                            │
│  • Generate output (ADR, requirements, architecture, summary)   │
│  • Update state.yaml                                            │
│  • Display summary                                              │
└─────────────────────────────────────────────────────────────────┘

Agents (stateless, called per-round):
┌─────────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐
│ Facilitator │  │ Arch    │  │ Tech    │  │ QA      │  │ DevOps  │
│ (opus)      │  │ itect   │  │ Lead    │  │ Lead    │  │ Eng     │
└─────────────┘  └─────────┘  └─────────┘  └─────────┘  └─────────┘
```

## Complete Flow: Single Round

```
┌──────────────────────────────────────────────────────────────────┐
│ ROUND N                                                          │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│ 1. COMMAND: Prepare round context                                │
│    ├── Read session file for current state                       │
│    ├── Calculate consensus/conflicts from rounds[]               │
│    └── Check max_rounds limit                                    │
│                                                                  │
│ 2. FACILITATOR: Generate question                                │
│    ├── Task(facilitator) with curated session context            │
│    ├── Returns: { action: "question", question, focus }          │
│    └── Command validates YAML, uses fallback if malformed        │
│                                                                  │
│ 3. PARTICIPANTS: Respond (parallel, blind voting)                │
│    ├── Task(architect) ─┐                                        │
│    ├── Task(tech-lead) ─┼── All launched in SINGLE message       │
│    ├── Task(qa-lead) ───┤   No agent sees other responses        │
│    ├── Task(devops) ────┤                                        │
│    └── Task(prod-mgr) ──┘                                        │
│                                                                  │
│    Each returns: { position, rationale, confidence, concerns }   │
│                                                                  │
│ 4. FACILITATOR: Synthesize responses                             │
│    ├── Task(facilitator) with all participant responses          │
│    ├── Identifies consensus points                               │
│    ├── Identifies conflicts with positions                       │
│    └── Returns: { action: "synthesis", synthesis,                │
│                   consensus, conflicts, resolved, next_action }  │
│                                                                  │
│ 5. COMMAND: Evaluate next action                                 │
│    ├── continue → Loop back to step 1                            │
│    ├── phase → Update phase, loop back                           │
│    ├── conclude → Exit loop, generate output                     │
│    └── escalate → AskUserQuestion, record decision               │
│                                                                  │
│ 6. COMMAND: Batch write to session file                          │
│    └── Append round to rounds[], atomic update                   │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

## Why Inline Orchestration

A previous architecture approach used a separate orchestrator agent:

```
❌ BROKEN: start.md → Task(orchestrator) → Task(facilitator)
                                         → Task(participants)
```

This fails because **subagents cannot spawn other subagents** in Claude Code.

```
✅ (WORKS): start.md contains loop → Task(facilitator)
                                   → Task(participants)
```

The **main agent** (executing the command) CAN call Task() multiple times.

## Participation Modes

### Parallel Mode (Default)

Used by: Standard, Disney (within phase), Debate (within side)

```
Command launches in SINGLE message:
    Task(architect) ──┬── All execute simultaneously
    Task(tech-lead) ──┤   Responses collected together
    Task(qa-lead) ────┤   No agent sees others' responses
    Task(devops) ─────┤
    Task(prod-mgr) ───┘
```

**Benefits**:
- Prevents sycophancy (no copying)
- True independent perspectives
- Faster execution

### Sequential Mode

Used by: Six Hats, Consensus-Driven (iterative)

```
Command launches sequentially:
    Task(participant-1) → response
        ↓ passed to
    Task(participant-2) → response
        ↓ passed to
    Task(participant-3) → response
        ...
```

**Benefits**:
- Building on ideas
- Iterative refinement
- Deeper exploration

## Session File Structure

Single source of truth with flat `rounds[]` array:

```yaml
id: "20260105-140000-api-design"
topic: "API Design Requirements"
strategy: "disney"
status: "active"

rounds:
  - number: 1
    phase: "dreamer"
    timestamp: "2026-01-05T14:00:00Z"
    question: "What are ideal requirements?"
    # responses: ONLY included if --verbose flag
    synthesis: "Participants agreed on..."
    consensus: ["REST API", "OAuth 2.0"]
    conflicts:
      - id: "rate-limiting"
        description: "Per-user vs per-key"
        positions:
          architect: "Per-user"
          tech-lead: "Per-key"
    resolved: []
```

**Key design decisions**:
- `responses[]` omitted by default (synthesis is the summary)
- `responses[]` included only with `--verbose` flag
- Consensus/conflicts tracked per-round, derived on demand
- Max 3 levels of nesting for LLM parsing reliability

## Fallback Behavior

When facilitator returns invalid YAML:

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. Parse YAML response                                          │
│    └── If valid: use response                                   │
│                                                                 │
│ 2. If invalid: use deterministic fallback                       │
│    ├── For question:                                            │
│    │   action: "question"                                       │
│    │   question: "What are the key considerations for {topic}?" │
│    │   participants: "all"                                      │
│    │   focus: "Core requirements"                               │
│    │                                                            │
│    └── For synthesis:                                           │
│        action: "synthesis"                                      │
│        synthesis: "Discussion continues on {topic}."            │
│        consensus: []                                            │
│        conflicts: []                                            │
│        resolved: []                                             │
│        next_action: "continue"                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Escalation Flow

When escalation triggers fire:

```
┌─────────────────────────────────────────────────────────────────┐
│ TRIGGER CONDITIONS:                                             │
│ ├── Same conflict persists after max_rounds_per_conflict        │
│ ├── Participant confidence below threshold                      │
│ ├── Critical keywords detected (security, must-have, blocking)  │
│ └── Facilitator explicitly returns next_action: "escalate"      │
├─────────────────────────────────────────────────────────────────┤
│ ESCALATION FLOW:                                                │
│                                                                 │
│ 1. Facilitator returns:                                         │
│    { next_action: "escalate", escalation_reason, positions }    │
│                                                                 │
│ 2. Command displays positions to user:                          │
│    "⚠️ Escalation Required"                                      │
│    "Reason: {escalation_reason}"                                │
│    Positions: {all participant positions}                       │
│                                                                 │
│ 3. Command asks user via AskUserQuestion:                       │
│    - Accept facilitator recommendation                          │
│    - Provide your own decision                                  │
│    - Continue discussion for N more rounds                      │
│                                                                 │
│ 4. Based on user choice:                                        │
│    ├── Decision provided → Record in escalations[], continue    │
│    └── Continue → Resume loop with user input as context        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Strategy-Specific Flows

### Disney Strategy (3 phases)

```
Phase 1: DREAMER              Phase 2: REALIST              Phase 3: CRITIC
─────────────────────────     ─────────────────────────     ─────────────────────────
"What if anything were        "How do we actually do        "What could go wrong?"
 possible?"                    this?"

No constraints                Ground ideas in reality       Stress-test the plan
No criticism                  Timeline, resources           Risk identification
Focus on ideal solution       Identify MVP                  Edge cases, security

Context: Topic only           Context: + Dreamer output     Context: + Dreamer + Realist
```

### Debate Strategy (Pro vs Con)

```
Opening (parallel)     Rebuttal (parallel)     Closing (parallel)
──────────────────     ────────────────────    ──────────────────
Pro presents case      Pro addresses Con       Pro final summary
Con presents case      Con addresses Pro       Con final summary

                       Facilitator Synthesis
                       ─────────────────────
                       Weighs arguments
                       Produces recommendation
```

**Debate sides** are auto-assigned by facilitator, or override with `--pro` and `--con` flags.

## Data Flow Summary

```
User Command
    │
    ▼
┌─────────────┐
│ start.md    │──┬── Creates session file
│ (inline     │  ├── Runs discussion loop
│ orchestr.)  │  ├── Launches facilitator (2x/round)
│             │  ├── Launches participants (parallel)
│             │  └── Batch writes after each round
└─────────────┘
       │
       ▼
┌─────────────┐
│ Facilitator │──┬── Generates questions
│             │  └── Synthesizes responses
└─────────────┘
       │
       ▼
┌─────────────┐
│Participants │──── Provide domain perspectives
└─────────────┘
       │
       ▼
┌─────────────┐
│ start.md    │──┬── Evaluates next_action
│             │  └── Generates output document
└─────────────┘
       │
       ▼
Output: ADR, Requirements, Architecture, Summary
```

## Agent Isolation

| Component | Reads Session? | Receives in Prompt |
|-----------|----------------|-------------------|
| **start.md** | ✅ YES | N/A (is the orchestrator) |
| **Facilitator** | ❌ NO | Curated state (phase, consensus, conflicts) |
| **Participants** | ❌ NO | Topic + question + project context only |

This isolation ensures:
- No direct agent-to-agent communication
- Controlled information flow
- Predictable behavior

---
*See [components.md](./components.md) for detailed component documentation*
*Part of Spec2Ship Roundtable documentation*

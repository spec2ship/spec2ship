# Roundtable

The Roundtable is Spec2Ship's multi-agent discussion system for collaborative decision-making.

## How It Works

```
┌─────────────────────────────────────────────────────────────┐
│                     WORKFLOW COMMAND                        │
│         (specs.md, design.md, brainstorm.md)                │
└─────────────────────────────────────────────────────────────┘
                           │
              For each round:
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ 1. FACILITATOR generates question                           │
│    - Considers agenda, previous rounds, artifacts           │
│    - Prepares context for participants                      │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. PARTICIPANTS respond in parallel (blind voting)          │
│    - Each agent provides domain perspective                 │
│    - Cannot see other agents' responses                     │
│    - Propose artifacts, raise concerns                      │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. FACILITATOR synthesizes                                  │
│    - Identifies consensus and conflicts                     │
│    - Creates/updates artifacts                              │
│    - Decides: continue, phase-transition, or conclude       │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. SESSION updated                                          │
│    - Round summary saved                                    │
│    - Artifacts persisted                                    │
│    - Metrics updated                                        │
└─────────────────────────────────────────────────────────────┘
```

## Key Components

### Facilitator

The orchestrator of the discussion:
- Generates questions based on agenda and strategy
- Prepares context for participants
- Synthesizes responses into decisions
- Manages discussion flow

### Participants

Domain experts who contribute perspectives:
- Receive context from facilitator (no file access)
- Provide position statements with rationale
- Propose and amend artifacts
- Flag concerns and raise questions

### Session

Persistent state of the discussion:
- All artifacts with full history
- Round summaries and positions
- Metrics and validation status
- Agent state for resume capability

## Blind Voting

Participants respond in parallel without seeing each other's responses:
- Prevents anchoring bias
- Reduces sycophancy
- Produces genuine disagreements
- Enables honest positions

## Artifact Types

| Workflow | Artifacts |
|----------|-----------|
| **specs** | REQ (requirements), BR (business rules), NFR (non-functional), EX (exclusions) |
| **design** | ARCH (decisions), COMP (components), INT (interfaces) |
| **brainstorm** | IDEA (ideas), RISK (risks), MIT (mitigations) |
| **all** | OQ (open questions), CONF (conflicts) |

## Continuation Rules

The facilitator decides after each round:
- **continue**: More discussion needed on current topic
- **next-topic**: Move to next agenda item
- **phase**: Transition to next phase (Disney strategy)
- **conclude**: All topics adequately covered
- **escalate**: Human input needed

## Minimum Rounds

Each roundtable requires at least 3 rounds to ensure:
- Adequate exploration of topics
- Time for disagreements to surface
- Opportunity for refinement

---

*See also: [Strategies](./strategies.md) | [Agents](./agents.md)*

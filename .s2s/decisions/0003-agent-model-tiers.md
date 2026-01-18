# Agent Model Tiers

## Status

accepted

## Context and Problem Statement

Different agents have different requirements for reasoning capability. Some tasks require deep analysis while others are simple validation. How should we assign models to agents to balance quality and cost?

## Decision Drivers

- Facilitator decisions impact entire roundtable quality
- Most participants need good reasoning but not maximum capability
- Some validation tasks are simple pattern matching
- Cost efficiency matters for frequent operations
- User should be able to override with their preferred model

## Considered Options

- Same model for all agents
- Per-agent model specification
- Tiered model assignment based on task criticality

## Decision Outcome

Chosen option: "Tiered model assignment based on task criticality", because it balances quality with cost efficiency.

| Tier | Model | Use Case |
|------|-------|----------|
| **Critical** | opus | Facilitator decisions (synthesis, agenda) |
| **Default** | inherit | Most agents - inherits user's model |
| **Fast** | haiku | Simple validation tasks |

### Consequences

- Good, because facilitator gets maximum capability for critical decisions
- Good, because participants use user's preferred model
- Good, because simple tasks are fast and cheap
- Bad, because tier assignment requires judgment
- Neutral, because user can override via config

## Pros and Cons of the Options

### Same model for all agents

Use opus (or user-specified) for everything.

- Good, because simple configuration
- Good, because consistent quality
- Bad, because expensive for simple tasks
- Bad, because slow for validation

### Per-agent model specification

Each agent specifies its own model.

- Good, because fine-grained control
- Bad, because complex configuration
- Bad, because hard to maintain consistency

### Tiered model assignment

Three tiers based on task criticality.

- Good, because balances quality and cost
- Good, because simple mental model (critical/default/fast)
- Good, because `inherit` respects user preference
- Neutral, because requires categorizing agents

## More Information

Agent tier is specified in frontmatter:

```yaml
---
name: roundtable-facilitator
model: opus  # Critical tier
---
```

```yaml
---
name: roundtable-software-architect
model: inherit  # Default tier - uses user's model
---
```

```yaml
---
name: session-validator
model: haiku  # Fast tier
---
```

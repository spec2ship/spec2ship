---
name: MADR Decision Records
description: "This skill should be used when the user asks to 'create ADR', 'document decision',
  'record architectural choice', 'write decision record', 'capture technical decision'.
  Provides MADR templates and patterns for consistent decision documentation."
version: 0.2.0
---

# MADR Decision Records

## Purpose

MADR (Markdown Any Decision Records) is a lean template for recording decisions. This skill provides patterns for documenting architectural and technical decisions in a consistent, reviewable format.

## When to Use This Skill

- Making significant technical decisions
- Choosing between alternatives
- Documenting constraints and trade-offs
- Recording decisions for future reference
- During Roundtable convergence

## Core Concepts

- **Context-Decision-Consequences**: Every ADR captures why, what, and impact
- **Alternatives Considered**: Document rejected options to prevent revisiting
- **Status Lifecycle**: proposed → accepted → deprecated/superseded
- **Immutability**: ADRs are append-only; supersede rather than modify

## ADR Naming Convention (MADR Official)

```
NNNN-title-with-dashes.md

Examples:
0001-component-separation.md
0002-inline-orchestration.md
0015-api-versioning-strategy.md
```

**Rules**:
- 4-digit zero-padded number (supports up to 9,999 ADRs)
- Lowercase title with dashes as word separators
- `.md` extension
- Sequential numbering

## MADR Template (Official Format)

```markdown
# {Short Title of Solved Problem and Solution}

## Status

{proposed | accepted | deprecated | superseded by [ADR-NNNN](NNNN-slug.md)}

## Context and Problem Statement

{Describe the context and problem statement, e.g., in free form using two to three sentences or in the form of an illustrative story. You may want to articulate the problem in form of a question.}

## Decision Drivers

- {decision driver 1, e.g., a force, facing concern, ...}
- {decision driver 2, e.g., a force, facing concern, ...}
- ...

## Considered Options

- {title of option 1}
- {title of option 2}
- {title of option 3}
- ...

## Decision Outcome

Chosen option: "{title of option 1}", because {justification. e.g., only option which meets k.o. criterion decision driver | which resolves force {force} | ... | comes out best (see below)}.

### Consequences

- Good, because {positive consequence, e.g., improvement of one or more desired qualities, ...}
- Bad, because {negative consequence, e.g., compromising one or more desired qualities, ...}
- Neutral, because {neutral consequence, e.g., no impact on desired qualities, ...}

## Pros and Cons of the Options

### {title of option 1}

{example | description | pointer to more information | ...}

- Good, because {argument a}
- Good, because {argument b}
- Neutral, because {argument c}
- Bad, because {argument d}
- ...

### {title of option 2}

{example | description | pointer to more information | ...}

- Good, because {argument a}
- Good, because {argument b}
- Neutral, because {argument c}
- Bad, because {argument d}
- ...

## More Information

{You might want to provide additional evidence/confidence for the decision outcome here and/or document the team agreement on the decision and/or define when/how this decision should be realized and if/when it should be re-visited. Links to other decisions and resources might appear here as well.}
```

## Status Lifecycle

```
proposed → accepted → [deprecated | superseded]
    ↓
  rejected
```

| Status | Meaning |
|--------|---------|
| proposed | Under discussion, not yet decided |
| accepted | Decision made and in effect |
| deprecated | No longer applicable |
| superseded | Replaced by newer decision (link to new ADR) |
| rejected | Considered but not chosen |

## Minimal Template

For simpler decisions, use this minimal variant:

```markdown
# {Title}

## Status

{status}

## Context and Problem Statement

{context}

## Decision Outcome

Chosen option: "{option}", because {justification}.

### Consequences

- Good, because {positive}
- Bad, because {negative}
```

## Quick Reference Examples

### Technology Choice ADR

```markdown
# Use PostgreSQL for Primary Database

## Status

accepted

## Context and Problem Statement

We need a database for user data and application state. Which database should we use?

## Decision Drivers

- ACID transactions required
- Complex query support needed
- Team familiarity
- Proven reliability at scale

## Considered Options

- PostgreSQL
- MongoDB
- MySQL

## Decision Outcome

Chosen option: "PostgreSQL", because it provides strong ACID guarantees, excellent query capabilities, and the team has production experience with it.

### Consequences

- Good, because mature ecosystem with excellent tooling
- Good, because team already familiar
- Bad, because requires operational knowledge for scaling
- Neutral, because hosting costs similar to alternatives
```

### Architecture Pattern ADR

```markdown
# Adopt Event-Driven Architecture for Async Operations

## Status

proposed

## Context and Problem Statement

Some operations are long-running and shouldn't block API responses. How should we handle asynchronous operations?

## Considered Options

- Synchronous with timeout
- Background jobs with polling
- Event-driven with message queue

## Decision Outcome

Chosen option: "Event-driven with message queue", because it provides decoupling, scalability, and built-in retry handling.

### Consequences

- Good, because services are decoupled
- Good, because scales horizontally
- Bad, because adds infrastructure complexity
- Bad, because debugging distributed flows is harder
```

## Integration with S2S

In Spec2Ship projects:

| Scope | Location | Format |
|-------|----------|--------|
| **Internal/WIP** | `.s2s/decisions/` | `NNNN-slug.md` |
| **Public/Stable** | `docs/architecture/decisions/` | `NNNN-slug.md` |

- Internal decisions: exploratory, work-in-progress, implementation details
- Public decisions: stable, significant for contributors, curated
- Roundtable discussions may produce ADR candidates
- Plans reference relevant ADRs

## ADR Index Template

For `decisions/README.md`:

```markdown
# Architecture Decision Records

| # | Decision | Status | Date |
|---|----------|--------|------|
| [0001](0001-slug.md) | Title | accepted | YYYY-MM-DD |
| [0002](0002-slug.md) | Title | accepted | YYYY-MM-DD |

## Status Legend

- **accepted** — Currently in effect
- **proposed** — Under discussion
- **deprecated** — No longer applicable
- **superseded** — Replaced by another ADR
- **rejected** — Considered but not adopted
```

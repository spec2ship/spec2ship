---
name: MADR Decision Records
description: "This skill should be used when the user asks to 'create ADR', 'document decision',
  'record architectural choice', 'write decision record', 'capture technical decision'.
  Provides MADR templates and patterns for consistent decision documentation."
version: 0.1.0
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

## MADR Template

```markdown
# {Title}

**Status**: {proposed | accepted | deprecated | superseded by ADR-XXX}
**Date**: {YYYY-MM-DD}
**Deciders**: {list of people involved}

## Context

{Describe the situation that requires a decision. What is the problem? What constraints exist?}

## Decision

{State the decision clearly. What was chosen?}

## Consequences

### Positive
- {benefit 1}
- {benefit 2}

### Negative
- {trade-off 1}
- {trade-off 2}

## Alternatives Considered

### Option A: {name}
{description}
- Pro: {advantage}
- Con: {disadvantage}

### Option B: {name}
{description}
- Pro: {advantage}
- Con: {disadvantage}

## Related Decisions
- {ADR-XXX}: {title and relationship}
```

## ADR Naming Convention

```
{YYYYMMDD}-{HHMMSS}-{slug}.md

Examples:
20241228-143022-api-versioning.md
20241228-150000-authentication-approach.md
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
| superseded | Replaced by newer decision |
| rejected | Considered but not chosen |

## Quick Reference Examples

### Technology Choice ADR
```markdown
# Use PostgreSQL for Primary Database

**Status**: accepted
**Date**: 2024-12-28

## Context
We need a database for user data and application state.
Requirements: ACID transactions, complex queries, proven reliability.

## Decision
Use PostgreSQL 15+ as our primary database.

## Consequences

### Positive
- Mature, well-documented
- Strong ecosystem (pgAdmin, extensions)
- Team familiarity

### Negative
- Requires operational knowledge
- Scaling requires more effort than NoSQL

## Alternatives Considered

### MongoDB
- Pro: Flexible schema, easy horizontal scaling
- Con: Eventual consistency, less query power
```

### Architecture Pattern ADR
```markdown
# Adopt Event-Driven Architecture for Async Operations

**Status**: proposed
**Date**: 2024-12-28

## Context
Some operations are long-running and shouldn't block API responses.
Users need feedback on operation status.

## Decision
Implement event-driven architecture using message queue for async operations.

## Consequences

### Positive
- Decoupled services
- Better scalability
- Retry handling built-in

### Negative
- Added complexity
- Eventual consistency
- Debugging is harder
```

## Integration with S2S

In Spec2Ship projects:
- ADRs go in `docs/decisions/`
- README.md contains ADR index and template
- Roundtable discussions produce ADRs
- Plans reference relevant ADRs
- Use consistent ID format

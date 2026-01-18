# Architecture Decision Records

This directory contains public Architecture Decision Records (ADRs) for Spec2Ship.

## Index

*No public ADRs yet. Significant decisions will be promoted here from internal development.*

<!-- Template for future entries:
| # | Decision | Status | Date |
|---|----------|--------|------|
| [0001](0001-slug.md) | Title | accepted | YYYY-MM-DD |
-->

## Status Legend

- **accepted**: currently in effect
- **proposed**: under discussion
- **deprecated**: no longer applicable
- **superseded**: replaced by another ADR
- **rejected**: considered but not adopted

## About ADRs

We use [MADR](https://adr.github.io/madr/) (Markdown Any Decision Records) format:
- Filename: `NNNN-slug.md` (4-digit zero-padded number)
- Captures context, decision, and consequences
- Immutable once accepted (supersede rather than modify)

### Internal vs Public

- **Public ADRs** (this folder): Stable decisions significant for contributors
- **Internal ADRs** (`.s2s/decisions/`): Work-in-progress, exploratory, implementation details

Significant internal decisions may be promoted to public ADRs after stabilization.

## Template

```markdown
# {Short Title}

## Status

{proposed | accepted | deprecated | superseded by [NNNN](NNNN-slug.md)}

## Context and Problem Statement

{Describe the context and problem. Why do we need to make a decision?}

## Considered Options

- Option A
- Option B
- Option C

## Decision Outcome

Chosen option: "{option}", because {justification}.

### Consequences

- Good, because {positive consequence}
- Bad, because {negative consequence}
```

---

*See also: [Architecture Overview](../README.md) | [MADR Skill](../../../skills/madr-decisions/SKILL.md)*

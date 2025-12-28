# Architecture Decision Records

This directory contains Architecture Decision Records (ADRs) using the MADR format.

## Decision Index

| Date | ID | Title | Status |
|------|----|----|--------|
| | | | |

## Status Definitions

| Status | Meaning |
|--------|---------|
| **proposed** | Under discussion, not yet decided |
| **accepted** | Decision made and active |
| **deprecated** | No longer applies, superseded |
| **superseded** | Replaced by another decision |

## Creating New Decisions

Use the s2s command:

```
/s2s:decision:new "topic"
```

Or with roundtable discussion:

```
/s2s:decision:new "topic" --roundtable
```

## MADR Template

When creating ADRs manually, use this format:

---

# {YYYYMMDD-HHMMSS-title}

## Status

{proposed | accepted | deprecated | superseded by [ADR-xxx](link)}

## Context

What is the issue that we're seeing that is motivating this decision or change?

## Decision

What is the change that we're proposing and/or doing?

## Consequences

What becomes easier or more difficult to do because of this change?

### Positive

- {Positive consequence}

### Negative

- {Negative consequence}

### Neutral

- {Neutral consequence}

## Options Considered

### Option 1: {Name}

{Description}

**Pros:**
- {Pro}

**Cons:**
- {Con}

### Option 2: {Name}

{Description}

**Pros:**
- {Pro}

**Cons:**
- {Con}

## Decision Outcome

Chosen option: "{Option Name}", because {justification}.

## Participants

- {Name/Role} - {Date}

## Related

- {Link to related ADR, requirement, or document}

---

## References

- [MADR Format](https://adr.github.io/madr/)
- [ADR GitHub Organization](https://adr.github.io/)

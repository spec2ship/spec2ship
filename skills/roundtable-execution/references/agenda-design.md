# Design Workflow Agenda

This file defines the required topics for `/s2s:design` roundtable sessions.

## Purpose

Ensures comprehensive architecture coverage by mandating discussion of key design areas before conclusion.

---

## Required Topics

```yaml
REQUIRED_TOPICS:
  - id: "high-level-arch"
    name: "High-level architecture and patterns"
    description: "Overall system structure, architectural style, key patterns"
    critical: true
    questions:
      - "What architectural style fits best (monolith, microservices, modular monolith)?"
      - "What are the major system components at the highest level?"
      - "Which design patterns should guide the implementation?"
      - "How does this architecture align with the requirements?"

  - id: "components"
    name: "Component boundaries and responsibilities"
    description: "Define what each component does and how they relate"
    critical: true
    questions:
      - "What are the main components and their responsibilities?"
      - "How are component boundaries defined?"
      - "What are the dependencies between components?"
      - "How do we ensure loose coupling?"

  - id: "data-flow"
    name: "Data flow and storage"
    description: "How data moves through the system and where it's stored"
    critical: false
    questions:
      - "What is the primary data storage approach?"
      - "How does data flow through the system?"
      - "What are the key data entities and relationships?"
      - "How do we handle data consistency?"

  - id: "tech-choices"
    name: "Technology choices and rationale"
    description: "Languages, frameworks, databases, and why"
    critical: false
    questions:
      - "What technology stack should we use?"
      - "What are the trade-offs of our technology choices?"
      - "Do we have the expertise for these technologies?"
      - "How do these choices affect long-term maintainability?"

  - id: "integration"
    name: "Integration points and APIs"
    description: "External systems, API design, communication patterns"
    critical: false
    questions:
      - "What external systems do we integrate with?"
      - "What API style should we use (REST, GraphQL, gRPC)?"
      - "How do components communicate (sync, async, events)?"
      - "What are the integration security requirements?"
```

---

## Coverage Tracking

The facilitator tracks coverage as:

| Status | Meaning |
|--------|---------|
| **covered** | Topic adequately discussed, architecture decision made |
| **partial** | Topic mentioned but needs more depth or decision pending |
| **pending** | Topic not yet discussed |

---

## Conclusion Rules

**Cannot conclude if:**
- Any `critical: true` topic is `pending`
- Both critical topics are `partial`

**Can conclude when:**
- All critical topics are `covered`
- Non-critical topics are at least `partial` or explicitly deferred

---

## Question Prioritization

When generating questions:
1. Address `pending` critical topics first
2. Then `partial` critical topics
3. Then `pending` non-critical topics
4. Only then allow ADR generation or conclusion

---

## ADR Generation Trigger

When all critical topics are `covered`:
- Facilitator may recommend `next_action: "conclude"`
- Output includes architecture decisions ready for ADR format
- Each major decision becomes an ARCH-NNN record

---

*Used by: roundtable-execution skill, design.md command*

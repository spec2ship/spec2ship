# Design Workflow Agenda

This file defines the required topics for `/s2s:design` roundtable sessions.

## Purpose

Ensures comprehensive architecture coverage by mandating discussion of key design areas before conclusion.
Focuses on **HOW** to implement the requirements defined in `/s2s:specs`.

---

## Required Topics

```yaml
topics:
  - id: "high-level-arch"
    name: "High-level architecture and patterns"
    description: "Overall system structure, architectural style, key patterns"
    critical: true
    done_when:
      criteria:
        - "Architectural style chosen (monolith, microservices, etc.)"
        - "Major system boundaries identified"
        - "Key design patterns selected"
        - "Architecture aligns with requirements"
      min_decisions: 1
    exploration: "Are there other architectural patterns or styles we should consider?"
    questions:
      - "What architectural style fits best (monolith, microservices, modular monolith)?"
      - "What are the major system components at the highest level?"
      - "Which design patterns should guide the implementation?"
      - "How does this architecture align with the requirements?"

  - id: "components"
    name: "Component boundaries and responsibilities"
    description: "Define what each component does and how they relate"
    critical: true
    done_when:
      criteria:
        - "All major components identified"
        - "Each component has clear responsibility"
        - "Dependencies between components mapped"
        - "Coupling assessed (loose is preferred)"
      min_decisions: 1
    exploration: "Are there other components we should define or split?"
    questions:
      - "What are the main components and their responsibilities?"
      - "How are component boundaries defined?"
      - "What are the dependencies between components?"
      - "How do we ensure loose coupling?"

  - id: "data-flow"
    name: "Data flow and storage"
    description: "How data moves through the system and where it's stored"
    critical: false
    done_when:
      criteria:
        - "Primary data storage approach defined"
        - "Data flow between components documented"
        - "Key data entities identified"
      min_decisions: 1
    exploration: "Are there other data flows or storage needs we should consider?"
    questions:
      - "What is the primary data storage approach?"
      - "How does data flow through the system?"
      - "What are the key data entities and relationships?"
      - "How do we handle data consistency?"

  - id: "tech-choices"
    name: "Technology choices and rationale"
    description: "Languages, frameworks, databases, and why"
    critical: false
    done_when:
      criteria:
        - "Technology stack defined"
        - "Trade-offs documented"
        - "Team expertise considered"
      min_decisions: 1
    exploration: "Are there alternative technologies we should evaluate?"
    questions:
      - "What technology stack should we use?"
      - "What are the trade-offs of our technology choices?"
      - "Do we have the expertise for these technologies?"
      - "How do these choices affect long-term maintainability?"

  - id: "integration"
    name: "Integration points and APIs"
    description: "External systems, API design, communication patterns"
    critical: false
    done_when:
      criteria:
        - "External integrations identified"
        - "API style chosen"
        - "Communication patterns defined"
      min_decisions: 0
    exploration: "Are there other integration points or APIs we need?"
    questions:
      - "What external systems do we integrate with?"
      - "What API style should we use (REST, GraphQL, gRPC)?"
      - "How do components communicate (sync, async, events)?"
      - "What are the integration security requirements?"
```

---

## Coverage Tracking

The facilitator tracks coverage as:

| Status | Meaning | Next Action |
|--------|---------|-------------|
| **open** | Topic not yet discussed | Prioritize if critical |
| **partial** | Topic mentioned but DoD not met | Continue or defer |
| **closed** | Definition of Done criteria met | Move to next topic |

---

## Closure Rules

### Cannot close topic if:
- Any `done_when.criteria` not addressed
- Fewer decisions than `min_decisions` made
- Open conflicts blocking the topic

### Can close topic when:
- All `done_when.criteria` addressed
- At least `min_decisions` architecture decisions made
- No blocking conflicts

---

## Session Conclusion Rules

### Cannot conclude session if:
- Any `critical: true` topic is `open`
- Both critical topics are `partial` with unmet DoD

### Can conclude session when:
- All critical topics are `closed`
- Non-critical topics are at least `partial` or explicitly deferred
- Facilitator recommends `next: "conclude"`

---

## Question Prioritization

When generating questions, facilitator should:

1. Address `open` critical topics first
2. Then `partial` critical topics (focus on unmet DoD criteria)
3. Then `open` non-critical topics
4. Then `partial` non-critical topics
5. Use `exploration` prompt to gather additional insights
6. Only allow conclusion when closure rules are met

---

## ADR Generation

When a topic closes with architecture decisions:
- Each major decision becomes an ARCH-* artifact
- ARCH-* artifacts will be formatted as ADRs in output phase
- Include: context, decision, options considered, consequences

---

## Artifact Types for Design

| Type | Prefix | Description |
|------|--------|-------------|
| Architecture Decision | ARCH-* | Major architectural choices |
| Component Definition | COMP-* | Component responsibilities |
| Open Question | OQ-* | Unresolved questions |
| Conflict | CONF-* | Disagreements between participants |

---

*Used by: roundtable-execution skill, design.md command*
*Participants: software-architect, security-champion, technical-lead, devops-engineer*

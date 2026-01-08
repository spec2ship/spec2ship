# Specs Workflow Agenda

This file defines the required topics for `/s2s:specs` roundtable sessions.

## Purpose

Ensures comprehensive requirements coverage focused on **WHAT** the system should do (not HOW).
This is for functional and non-functional requirements only - architecture decisions belong in `/s2s:design`.

---

## Required Topics

```yaml
topics:
  - id: "user-workflows"
    name: "User workflows and use cases"
    description: "What users need to accomplish - primary interaction flows"
    critical: true
    done_when:
      criteria:
        - "Primary user personas identified"
        - "Entry/exit conditions for each workflow defined"
        - "Happy path documented"
        - "Error recovery paths identified"
      min_requirements: 2
    exploration: "Are there other user workflows or edge cases we should consider?"
    questions:
      - "Who are the main users and what are their goals?"
      - "What are the primary user workflows?"
      - "What tasks must users be able to complete?"
      - "What is the typical user journey?"

  - id: "functional-requirements"
    name: "Functional requirements"
    description: "What the system must DO - features and behaviors"
    critical: true
    done_when:
      criteria:
        - "Core mechanics/features defined"
        - "Each requirement has measurable acceptance criteria"
        - "Input/output for each feature specified"
      min_requirements: 3
    exploration: "Are there other features or behaviors we should consider?"
    questions:
      - "What are the must-have features for MVP?"
      - "What business operations must the system support?"
      - "What inputs does the system accept and what outputs does it produce?"
      - "What are the key system behaviors?"

  - id: "business-rules"
    name: "Business rules and constraints"
    description: "Domain logic, validation rules, and business constraints"
    critical: false
    done_when:
      criteria:
        - "Domain-specific constraints captured"
        - "Validation rules for data defined"
        - "State transitions documented"
      min_requirements: 1
    exploration: "Are there other business rules or domain constraints?"
    questions:
      - "What business rules must be enforced?"
      - "What validation rules apply to data?"
      - "What are the state transitions and their conditions?"
      - "What domain-specific constraints exist?"

  - id: "nfr-measurable"
    name: "Non-functional requirements (measurable)"
    description: "Quality criteria expressed as WHAT (metrics), not HOW (solutions)"
    critical: false
    done_when:
      criteria:
        - "Performance targets defined with numbers"
        - "Availability/reliability targets set"
        - "Capacity requirements specified"
      min_requirements: 1
    exploration: "Are there other quality requirements we should specify?"
    questions:
      - "What response time is acceptable? (e.g., < 2 seconds)"
      - "What availability is required? (e.g., 99.9%)"
      - "How many concurrent users must be supported?"
      - "What security certifications or compliance is needed?"
    note: "Express as measurable criteria, NOT as technical solutions. 'Response < 2s' not 'use caching'."

  - id: "acceptance-criteria"
    name: "Acceptance criteria"
    description: "How we'll know requirements are met - testable conditions"
    critical: false
    done_when:
      criteria:
        - "Each critical requirement has acceptance criteria"
        - "Criteria are testable/verifiable"
      min_requirements: 0
    exploration: "Are there edge cases or test scenarios we should add?"
    questions:
      - "What are the acceptance criteria for key requirements?"
      - "How will we test each requirement?"
      - "What edge cases must be handled?"

  - id: "out-of-scope"
    name: "Out of scope"
    description: "Explicit exclusions to prevent scope creep"
    critical: false
    done_when:
      criteria:
        - "Expected but excluded features documented"
        - "Future phase items identified"
      min_requirements: 0
    exploration: "Is there anything else users might expect that we're not providing?"
    questions:
      - "What features are explicitly NOT in scope?"
      - "What might users expect that we won't provide?"
      - "What is deferred to future phases?"
```

---

## WHAT vs HOW Guidance

Specs should focus on **WHAT**, not **HOW**:

| Topic | WHAT (Specs) | HOW (Design) |
|-------|--------------|--------------|
| Performance | "Response time < 2s" | "Use Redis caching" |
| Security | "Must support MFA" | "Implement TOTP with authenticator app" |
| Scalability | "Support 10K concurrent users" | "Use horizontal scaling with K8s" |
| Data | "Must store user preferences" | "Use PostgreSQL with JSON columns" |

If discussion drifts into HOW, the facilitator should note it for design phase and refocus on WHAT.

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
- Fewer requirements than `min_requirements` generated
- Open conflicts blocking the topic

### Can close topic when:
- All `done_when.criteria` addressed
- At least `min_requirements` consensus requirements generated
- No blocking conflicts (open questions may be deferred)

---

## Session Conclusion Rules

### Cannot conclude session if:
- Any `critical: true` topic is `open`
- Both critical topics are `partial` with unmet DoD

### Can conclude session when:
- All critical topics are `closed`
- Non-critical topics are at least `partial` or explicitly skipped
- Facilitator recommends `next: "conclude"`

---

## Question Prioritization

When generating questions, facilitator should follow the **single-topic focus rule**:

1. Select ONE topic per round (no mixing)
2. Address topics in priority order (order in YAML = priority)
3. Each topic gets at least one dedicated round
4. Use `exploration` prompt to gather additional insights
5. Only allow conclusion when closure rules are met

**Pacing guidance**:
- Topics at top of list = higher priority = address earlier
- But priority ≠ urgency. Take time for depth on each topic.

---

## Artifact Types for Specs

| Type | Prefix | Description |
|------|--------|-------------|
| Functional Requirement | REQ-* | What the system does |
| Business Rule | BR-* | Domain logic constraints |
| Non-Functional Requirement | NFR-* | Quality/performance criteria |
| Open Question | OQ-* | Unresolved questions |
| Conflict | CONF-* | Disagreements between participants |
| Exclusion | EX-* | Explicitly out of scope |

---

*Used by: roundtable-execution skill, specs.md command*
*Participants: product-manager, business-analyst, qa-lead*

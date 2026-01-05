# Specs Workflow Agenda

This file defines the required topics for `/s2s:specs` roundtable sessions.

## Purpose

Ensures comprehensive requirements coverage focused on **WHAT** the system should do (not HOW).
This is for functional and non-functional requirements only - architecture decisions belong in `/s2s:design`.

---

## Required Topics

```yaml
REQUIRED_TOPICS:
  - id: "user-workflows"
    name: "User workflows and use cases"
    description: "What users need to accomplish - primary interaction flows"
    critical: true
    questions:
      - "Who are the main users and what are their goals?"
      - "What are the primary user workflows?"
      - "What tasks must users be able to complete?"
      - "What is the typical user journey?"

  - id: "functional-requirements"
    name: "Functional requirements"
    description: "What the system must DO - features and behaviors"
    critical: true
    questions:
      - "What are the must-have features for MVP?"
      - "What business operations must the system support?"
      - "What inputs does the system accept and what outputs does it produce?"
      - "What are the key system behaviors?"

  - id: "business-rules"
    name: "Business rules and constraints"
    description: "Domain logic, validation rules, and business constraints"
    critical: false
    questions:
      - "What business rules must be enforced?"
      - "What validation rules apply to data?"
      - "What are the state transitions and their conditions?"
      - "What domain-specific constraints exist?"

  - id: "nfr-measurable"
    name: "Non-functional requirements (measurable)"
    description: "Quality criteria expressed as WHAT (metrics), not HOW (solutions)"
    critical: false
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
    questions:
      - "What are the acceptance criteria for key requirements?"
      - "How will we test each requirement?"
      - "What edge cases must be handled?"

  - id: "out-of-scope"
    name: "Out of scope"
    description: "Explicit exclusions to prevent scope creep"
    critical: false
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

| Status | Meaning |
|--------|---------|
| **covered** | Topic adequately discussed, consensus reached |
| **partial** | Topic mentioned but needs more depth |
| **pending** | Topic not yet discussed |

---

## Conclusion Rules

**Cannot conclude if:**
- Any `critical: true` topic is `pending`
- Both critical topics are `partial`

**Can conclude when:**
- All critical topics are `covered`
- Non-critical topics are at least `partial` or explicitly skipped

---

## Question Prioritization

When generating questions:
1. Address `pending` critical topics first
2. Then `partial` critical topics
3. Then `pending` non-critical topics
4. Only then allow free exploration or conclusion

---

*Used by: roundtable-execution skill, specs.md command*
*Participants: product-manager, business-analyst, qa-lead*

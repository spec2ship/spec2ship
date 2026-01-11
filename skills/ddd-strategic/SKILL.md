---
name: DDD Strategic Patterns for Domain Modeling
description: "This skill should be used when the user asks to 'model the domain',
  'identify bounded contexts', 'map domain relationships', 'run event storming',
  'define ubiquitous language', 'analyze domain complexity'. Provides DDD strategic patterns for requirements and design."
version: 1.0.0
---

# DDD Strategic Patterns for Domain Modeling

## Purpose

Domain-Driven Design (DDD) strategic patterns help teams understand complex business domains and define clear boundaries between system components. This skill focuses on strategic patterns used during requirements and architecture discussions, not implementation-level tactical patterns.

## When to Use This Skill

- During specs workflow to understand domain complexity
- Identifying system boundaries in design workflow
- Clarifying terminology and concepts
- Analyzing integrations between systems
- Decomposing monoliths or designing microservices

## Core Concepts

- **Domain**: The subject area the software addresses
- **Subdomain**: A coherent part of the overall domain
- **Bounded Context**: A boundary within which a domain model is defined and applicable
- **Ubiquitous Language**: Shared vocabulary between developers and domain experts
- **Context Map**: Visual representation of relationships between bounded contexts

---

## Subdomains

Not all parts of a domain are equally important:

| Type | Importance | Investment | Example |
|------|------------|------------|---------|
| **Core** | Competitive advantage | High - build custom | Recommendation engine, Pricing algorithm |
| **Supporting** | Necessary but not differentiating | Medium - build or buy | Reporting, Notifications |
| **Generic** | Common across industries | Low - buy or use SaaS | Authentication, Payments, Email |

### Subdomain Identification Questions

- What makes our business unique? → Core
- What do we need but doesn't differentiate us? → Supporting
- What does every company in our industry need? → Generic

---

## Bounded Contexts

A Bounded Context is a semantic boundary where terms have specific meanings.

### Key Properties

| Property | Description |
|----------|-------------|
| **Linguistic** | Same term can mean different things in different contexts |
| **Team** | Often aligned with team ownership |
| **Deployment** | Can be deployed independently |
| **Data** | Owns its data, doesn't share database |

### Example: "Customer" in Different Contexts

| Context | Customer Means | Key Attributes |
|---------|---------------|----------------|
| Sales | Lead/Prospect | Contact info, Pipeline stage, Deal size |
| Billing | Account | Payment method, Invoices, Credit limit |
| Support | User | Tickets, SLA, Satisfaction score |
| Shipping | Recipient | Address, Delivery preferences |

**Insight**: Each context has its own `Customer` model. Don't force a "universal customer" entity.

---

## Context Mapping

Context maps show how bounded contexts relate to each other.

### Relationship Patterns

| Pattern | Direction | Description | Use When |
|---------|-----------|-------------|----------|
| **Partnership** | ⟷ | Teams coordinate closely | Mutual dependency, aligned goals |
| **Shared Kernel** | ⟷ | Shared code/model subset | Limited overlap, high trust |
| **Customer-Supplier** | ← | Downstream depends on upstream | Clear dependency direction |
| **Conformist** | ← | Downstream adopts upstream model | No influence over upstream |
| **Anticorruption Layer (ACL)** | ← | Translation layer protects downstream | Upstream model doesn't fit |
| **Open Host Service** | → | Upstream exposes public API | Multiple consumers |
| **Published Language** | → | Documented interchange format | External consumers |
| **Separate Ways** | ✗ | No integration | Costs outweigh benefits |

### Context Map Diagram

```
┌─────────────────┐     Partnership      ┌─────────────────┐
│   Sales         │◄──────────────────►│   Marketing     │
└────────┬────────┘                     └─────────────────┘
         │
         │ Customer-Supplier
         ▼
┌─────────────────┐     ACL            ┌─────────────────┐
│   Billing       │◄───────────────────│  Legacy ERP     │
└────────┬────────┘                     └─────────────────┘
         │
         │ Open Host Service
         ▼
┌─────────────────┐
│   Reporting     │ (Conformist)
└─────────────────┘
```

---

## Ubiquitous Language

A shared vocabulary that is:
- Used consistently in code, documentation, and conversations
- Defined within a specific bounded context
- Evolved collaboratively with domain experts

### Building Ubiquitous Language

| Activity | Output |
|----------|--------|
| Domain expert interviews | Term definitions, Business rules |
| Event Storming | Events, Commands, Aggregates |
| Example mapping | Concrete scenarios, Edge cases |
| Glossary creation | Canonical definitions |

### Language Conflicts Signal Context Boundaries

When the same word means different things to different people:
- **Option A**: Clarify within one context (refine language)
- **Option B**: Recognize two contexts exist (split)

---

## Event Storming

A collaborative workshop technique for domain exploration.

### Event Storming Elements

| Color | Element | Description | Question |
|-------|---------|-------------|----------|
| 🟧 Orange | Domain Event | Something that happened | "What happened?" |
| 🟦 Blue | Command | Trigger for an event | "What caused this?" |
| 🟨 Yellow | Actor | Who issues the command | "Who did this?" |
| 🟪 Purple | Policy | Reactive logic | "When this happens, then..." |
| 🟩 Green | Read Model | Information needed | "What info was needed?" |
| 🟥 Pink | External System | Outside integration | "Who else is involved?" |
| 🔴 Red | Hot Spot | Problem/Question | "Something's unclear here" |
| 🟫 Tan | Aggregate | Consistency boundary | "What data changes together?" |

### Event Storming Flow

```
[Actor] ──triggers──> [Command] ──causes──> [Domain Event]
                                                  │
                                                  ▼
                                            [Policy] ──may trigger──> [Command]
```

### Big Picture Event Storming Output

1. Timeline of domain events
2. Identified bounded contexts (clustered events)
3. Hot spots (unknowns, conflicts)
4. Key policies and business rules

---

## Domain Complexity Heuristics

### Conway's Law Consideration

> "Organizations produce designs that mirror their communication structures."

**Implication**: Bounded context boundaries should consider team structure.

### Complexity Indicators

| Signal | Possible Issue |
|--------|---------------|
| Same term, different meanings | Missing context boundary |
| Long coordination cycles | Too many cross-context dependencies |
| Large shared database | Contexts not properly separated |
| Frequent breaking changes | Insufficient ACL protection |
| "We need to sync with Team X first" | Partnership or Customer-Supplier needed |

---

## Domain Modeling in Roundtables

### Questions for specs Workflow

- What are the core business capabilities?
- Where does complexity live? (Core subdomains)
- What terms do domain experts use?
- Are there ambiguous terms that mean different things?
- What events matter to the business?

### Questions for design Workflow

- How should we partition the system?
- Which contexts need to communicate?
- What integration patterns fit each relationship?
- Where do we need anticorruption layers?
- What can we buy vs. build?

### Artifacts to Produce

| Workflow | Artifact | Purpose |
|----------|----------|---------|
| specs | Subdomain classification | Investment decisions |
| specs | Glossary / Ubiquitous Language | Shared vocabulary |
| specs | Domain Events list | Business capability mapping |
| design | Context Map | Integration architecture |
| design | Context boundaries | Service/module design |

---

## Anti-Patterns to Flag

| Anti-Pattern | Problem | Better Approach |
|--------------|---------|-----------------|
| **Universal Entity** | "Customer" used everywhere same way | Separate models per context |
| **Shared Database** | All services read/write same tables | Each context owns its data |
| **Big Ball of Mud** | No clear boundaries | Identify contexts, draw lines |
| **Anemic Domain Model** | Logic in services, dumb data objects | (Tactical - but flag if seen) |
| **Distributed Monolith** | Microservices but tightly coupled | Proper context boundaries first |

---

## Quick Reference: Strategic vs Tactical DDD

| Level | Focus | Roundtable Relevance |
|-------|-------|---------------------|
| **Strategic** | Contexts, Maps, Subdomains | ✅ High - discuss in specs/design |
| **Tactical** | Entities, Aggregates, Repositories | ⚠️ Low - implementation detail |

This skill focuses on **strategic patterns** for roundtable discussions.

---

## References

- Eric Evans: Domain-Driven Design (2003) - The Blue Book
- Vaughn Vernon: Implementing Domain-Driven Design (2013)
- Alberto Brandolini: Introducing EventStorming (2021)
- Context Mapping: https://github.com/ddd-crew/context-mapping
- DDD Crew Patterns: https://github.com/ddd-crew

---
name: arc42 Architecture Templates
description: "This skill should be used when the user asks to 'document architecture', 'create arc42 section',
  'design component structure', 'write building blocks view', 'create context diagram'.
  Provides arc42 templates and patterns for standardized architecture documentation."
version: 0.1.0
---

# arc42 Architecture Templates

## Purpose

arc42 is a template for architecture documentation. This skill provides patterns and structure for documenting software architecture in a standardized, stakeholder-friendly way.

## When to Use This Skill

- Creating initial architecture documentation
- Documenting component boundaries
- Describing system interfaces
- Recording architectural decisions
- Communicating with stakeholders

## Core Concepts

- **12 Sections**: arc42 organizes architecture into 12 standardized sections covering context, building blocks, runtime, deployment, and quality
- **Decomposition Levels**: Systems decompose into Context (L0) → Containers (L1) → Components (L2)
- **Black/White Box**: External view (interfaces only) vs internal view (structure revealed)
- **Stakeholder Focus**: Documentation tailored for different audiences (developers, operators, business)

## arc42 Sections Quick Reference

| # | Section | Purpose | When to Use |
|---|---------|---------|-------------|
| 1 | Introduction | Goals, stakeholders, constraints | Project setup |
| 2 | Constraints | Technical/organizational limits | Initial design |
| 3 | Context | System boundaries, external interfaces | System scoping |
| 4 | Solution Strategy | Key decisions, technology choices | Architecture decisions |
| 5 | Building Blocks | Components, modules, structure | Design documentation |
| 6 | Runtime View | Scenarios, sequences, flows | Behavior documentation |
| 7 | Deployment | Infrastructure, nodes, mapping | Operations planning |
| 8 | Crosscutting | Security, logging, error handling | Quality implementation |
| 9 | Decisions | ADRs, rationale | Decision tracking |
| 10 | Quality | Quality goals, scenarios | Quality assurance |
| 11 | Risks | Technical risks, debt | Risk management |
| 12 | Glossary | Terms, definitions | Communication |

## Building Blocks Structure

```
Level 0: System Context
├── Your System (white box)
├── External System A
├── External System B
└── User

Level 1: Container View
├── Web Application
├── API Service
├── Database
└── Message Queue

Level 2: Component View (per container)
├── Controller Layer
├── Service Layer
├── Repository Layer
└── Domain Models
```

## Quick Templates

### Component Documentation
```markdown
### {Component Name}

**Purpose**: {one-line description}

**Responsibilities**:
- {responsibility 1}
- {responsibility 2}

**Interfaces**:
- `{interface}`: {description}

**Dependencies**:
- Uses: {component names}
- Used by: {component names}
```

### Interface Documentation
```markdown
### {Interface Name}

**Type**: {REST API | Event | gRPC | etc.}
**Protocol**: {HTTP | AMQP | etc.}

**Operations**:
| Operation | Input | Output | Description |
|-----------|-------|--------|-------------|
| {name} | {type} | {type} | {description} |
```

## References

For detailed patterns and examples, see:
- `references/building-blocks.md`
- `references/runtime-view.md`
- `references/deployment-view.md`
- `examples/sample-component.md`

## Integration with S2S

In Spec2Ship projects:
- Architecture docs go in `docs/architecture/`
- Use README.md for overview (Section 1-3)
- Use components.md for building blocks (Section 5)
- Use runtime.md for scenarios (Section 6)
- Use deployment.md for infrastructure (Section 7)
- ADRs go in `docs/decisions/` (Section 9)

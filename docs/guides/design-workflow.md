# Design Workflow Guide

The design workflow uses a roundtable discussion to define architecture for your project.

## Overview

```bash
/s2s:design [--strategy <name>] [--participants <list>] [--verbose] [--interactive] [--diagnostic]
```

**Purpose**: Design how to build through collaborative discussion.

**Output**: `docs/architecture/` (ADRs, components, interfaces)

## Prerequisites

1. Project initialized with `/s2s:init`
2. Requirements defined with `/s2s:specs` (recommended but not required)
3. `.s2s/CONTEXT.md` populated with project description

## Default Configuration

| Setting | Value |
|---------|-------|
| Strategy | `debate` |
| Participants | software-architect, technical-lead, devops-engineer |
| Minimum rounds | 3 |

## What Gets Discussed

The roundtable covers these architecture topics (agenda):

1. **Architecture Style** - Monolith vs microservices, patterns
2. **Component Structure** - Building blocks, responsibilities
3. **Interfaces** - APIs, contracts, integration points
4. **Data Architecture** - Storage, schemas, data flow
5. **Deployment Architecture** - Infrastructure, scaling
6. **Cross-cutting Concerns** - Security, logging, monitoring

## Running the Workflow

### Basic Usage

```bash
/s2s:design
```

The roundtable will:
1. Load requirements from `docs/specifications/` if available
2. Generate architecture questions based on context
3. Collect perspectives from participants (debate format)
4. Synthesize into architecture decisions
5. Continue until all topics are covered (minimum 3 rounds)

### With Options

```bash
# See detailed output
/s2s:design --verbose

# Control each round manually
/s2s:design --interactive

# Use consensus instead of debate
/s2s:design --strategy consensus-driven

# Add security perspective
/s2s:design --participants +security-champion
```

## Understanding the Debate Strategy

The default `debate` strategy structures discussion as Pro vs Con:

### Phases

1. **Opening** - Each side presents initial position
2. **Rebuttal** - Respond to opposing arguments
3. **Closing** - Final statements
4. **Synthesis** - Facilitator summarizes and decides

### How It Works

```
Round 1 (Opening)
├── Architect (Pro): "Microservices because..."
├── Tech Lead (Con): "Monolith because..."
└── DevOps (Pro): "Supports scaling..."

Round 2 (Rebuttal)
├── Architect: "Responding to complexity concerns..."
├── Tech Lead: "The scaling argument ignores..."
└── DevOps: "Deployment complexity is manageable..."

Round 3 (Synthesis)
└── Facilitator: Creates ARCH-001 decision record
```

## Understanding the Output

### During Discussion

After each round, you'll see:
- Round number and phase
- Participant positions (Pro/Con)
- Key arguments
- Emerging decisions

### Final Output

The `docs/architecture/` folder contains:

```
docs/architecture/
├── decisions/
│   ├── ARCH-001-architecture-style.md
│   ├── ARCH-002-data-storage.md
│   └── ...
├── components.md
└── interfaces.md
```

### Decision Record Format (MADR)

```markdown
# ARCH-001: Architecture Style

## Status
Accepted

## Context
We need to decide on the overall architecture style...

## Decision
We will use a modular monolith with clear boundaries...

## Consequences
### Positive
- Simpler deployment
- Easier debugging

### Negative
- Requires discipline to maintain boundaries

## Participants
- Software Architect (Pro): Advocated for microservices
- Technical Lead (Con): Advocated for monolith
- DevOps Engineer (Pro): Supported microservices for scaling
```

## Interactive Mode

With `--interactive`, you can control the debate:

```
Round 2 Complete (Rebuttal Phase)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Topic: Architecture Style
Pro arguments: 3
Con arguments: 4
Emerging consensus: Modular monolith

What would you like to do?
› continue - Proceed to closing arguments
  skip     - Skip to next topic
  exit     - Save and exit
```

## Handling Conflicts

In debate strategy, conflicts are expected and valuable:

1. **Both positions recorded** with full rationale
2. **Facilitator synthesizes** considering all arguments
3. **Decision documented** with dissenting views
4. **Trade-offs explicit** in the ADR

## Tips for Better Results

### Before Running

1. **Complete specs first** - Architecture should address requirements
2. **Have constraints ready** - Budget, timeline, team skills
3. **Know your priorities** - Performance vs cost vs time-to-market

### During Discussion

1. **Use interactive mode** for important decisions
2. **Add security-champion** for security-sensitive systems
3. **Let the debate play out** - disagreement produces better decisions

### After Completion

1. **Review ADRs** - Check decisions make sense
2. **Validate the session** - `/s2s:session:validate`
3. **Proceed to planning** - `/s2s:plan --new "feature"`

## Alternative Strategies

### Consensus-Driven

Better for teams that prefer collaborative decision-making:

```bash
/s2s:design --strategy consensus-driven
```

Focuses on finding agreement rather than debating positions.

### Six Hats

For comprehensive analysis of complex decisions:

```bash
/s2s:design --strategy six-hats
```

Examines each decision from 6 perspectives (facts, emotions, risks, benefits, creativity, process).

## Troubleshooting

### "Missing project context"

Run `/s2s:init` first to create CONTEXT.md.

### Architecture too abstract

Add more technical constraints to CONTEXT.md before re-running.

### Debate goes in circles

Use `--interactive` and skip to synthesis, or change to `--strategy consensus-driven`.

### Missing security perspective

```bash
/s2s:design --participants +security-champion
```

---

*See also: [Specs Workflow](./specs-workflow.md) | [Plan Workflow](./plan-workflow.md)*

# Core Concepts

This section explains the key concepts behind Spec2Ship.

## Contents

| Concept | Description |
|---------|-------------|
| [Workflows](./workflows.md) | The six-phase development lifecycle |
| [Roundtable](./roundtable.md) | Multi-agent collaborative discussions |
| [Strategies](./strategies.md) | Different facilitation approaches |
| [Agents](./agents.md) | Specialized AI participants |
| [Sessions](./sessions.md) | Persistent discussion state |

## Overview

Spec2Ship guides software development through structured **workflows**, using **roundtable** discussions where multiple AI **agents** collaborate using configurable **strategies** to produce better outcomes than a single AI could achieve alone.

```
┌─────────────────────────────────────────────────────────────┐
│                      WORKFLOW                               │
│  init → brainstorm → specs → design → plan → execute        │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                     ROUNDTABLE                              │
│  Facilitator orchestrates discussion rounds                 │
│  Participants provide domain expertise                      │
│  Strategy defines how discussion proceeds                   │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                      SESSION                                │
│  Persistent state: artifacts, positions, decisions          │
│  Can be paused, resumed, validated                          │
└─────────────────────────────────────────────────────────────┘
```

## Key Principles

### 1. Multi-Agent Collaboration

Instead of asking one AI for answers, Spec2Ship creates a discussion between specialized agents:
- **Product Manager**: User value and priorities
- **Software Architect**: System structure and patterns
- **QA Lead**: Quality and edge cases
- **Security Champion**: Security and compliance
- ...and more

### 2. Anti-Sycophancy

Agents are designed to disagree constructively:
- Each agent anchors to their domain principles
- Premature consensus is explicitly discouraged
- Confidence scores reflect context quality
- Dissent is valued and recorded

### 3. Structured Output

Discussions produce structured artifacts:
- **Requirements** (REQ-*): What the system must do
- **Architecture Decisions** (ARCH-*): How the system is structured
- **Open Questions** (OQ-*): Unresolved items
- **Conflicts** (CONF-*): Disagreements to resolve

### 4. Session Persistence

All discussions are saved and can be:
- **Resumed** after interruption
- **Validated** for consistency
- **Audited** for decision history

---

*Next: [Workflows](./workflows.md)*

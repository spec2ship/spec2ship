# Roundtable v2

The Roundtable is Spec2Ship's multi-agent discussion system for collaborative decision-making.

## Overview

Roundtable enables AI agents with different perspectives to discuss topics, identify consensus, resolve conflicts, and produce structured outputs (requirements, architecture decisions, etc.).

## Key Features

- **Multiple Strategies**: Standard, Disney, Debate, Consensus-Driven, Six Hats
- **Configurable Participants**: Per workflow type (specs, tech, discover, brainstorm)
- **Escalation Triggers**: Human-in-the-loop when needed
- **Session Persistence**: Resume interrupted discussions
- **Parallel Execution**: Blind voting to prevent sycophancy

## Quick Start

```bash
# Start a roundtable discussion
/s2s:roundtable:start "API versioning strategy"

# Use specific strategy
/s2s:roundtable:start "Feature prioritization" --strategy disney

# List all sessions
/s2s:roundtable:list

# Resume a session
/s2s:roundtable:resume
```

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│ COMMAND start.md (Executor)                                     │
├─────────────────────────────────────────────────────────────────┤
│ 1. Load config + strategy skill                                 │
│ 2. Create session file                                          │
│ 3. Loop:                                                        │
│    a. Task(facilitator) → generate question                    │
│    b. Task(participants) → responses (parallel)                │
│    c. Task(facilitator) → synthesize                           │
│    d. Batch write session file                                  │
│    e. Check escalation triggers                                 │
│ 4. Generate output (ADR, requirements, etc.)                    │
└─────────────────────────────────────────────────────────────────┘
```

## Documentation Index

### Configuration
- [Configuration Guide](./configuration.md) - Config options and defaults
- [Glossary](./glossary.md) - Terminology definitions

### Strategies
- [Strategy Overview](./strategies/overview.md)
- [Standard](./strategies/standard.md) - Round-robin discussion
- [Disney](./strategies/disney.md) - Dreamer/Realist/Critic
- [Debate](./strategies/debate.md) - Pro vs Con
- [Consensus-Driven](./strategies/consensus-driven.md) - Fast convergence
- [Six Hats](./strategies/six-hats.md) - De Bono's method
- [Creating New Strategies](./strategies/creating-new.md)

### Architecture
- [Flow Diagrams](./architecture/flow.md)
- [Components](./architecture/components.md) - Command vs Agent vs Skill
- [Session File Schema](./architecture/session-file.md)

### Research
- [Literature Review](./research/literature.md) - LLM multi-agent research
- [Known Limitations](./research/limitations.md) - Sycophancy, echo chambers
- [Mitigations](./research/mitigations.md) - How we address limitations

### Examples
- [Simple Brainstorm](./examples/simple-brainstorm.md)
- [Specs Workflow](./examples/specs-workflow.md)
- [Tech Decision](./examples/tech-decision.md)

## Design Principles

1. **Context Isolation**: Agents receive context in prompt, don't read files
2. **Blind Voting**: Parallel execution prevents agents seeing each other's responses
3. **Batch Write**: Session file updated only at end of round
4. **Facilitator Decides, Command Executes**: Clear separation of concerns
5. **Strategy as Skill**: Facilitation logic is configurable, not hardcoded

## Related Commands

| Command | Description |
|---------|-------------|
| `/s2s:specs` | Requirements gathering via roundtable |
| `/s2s:design` | Architecture design via roundtable |
| `/s2s:roundtable:start` | Start ad-hoc discussion |
| `/s2s:roundtable:resume` | Continue paused session |
| `/s2s:roundtable:list` | View all sessions |

---
*Part of Spec2Ship - AI-assisted software development*

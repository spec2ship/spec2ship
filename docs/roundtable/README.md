# Roundtable v3

The Roundtable is Spec2Ship's multi-agent discussion system for collaborative decision-making.

## Overview

Roundtable enables AI agents with different perspectives to discuss topics, identify consensus, resolve conflicts, and produce structured outputs (requirements, architecture decisions, etc.).

## Key Features

- **Multiple Strategies**: Standard, Disney, Debate, Consensus-Driven, Six Hats
- **Configurable Participants**: Per workflow type (specs, design, brainstorm)
- **Escalation Triggers**: Human-in-the-loop when needed
- **Session Persistence**: Resume interrupted discussions
- **Parallel Execution**: Blind voting to prevent sycophancy
- **Layered Orchestration**: Commands delegate to Orchestrator Agent (v3)

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

## Architecture (v3)

```
┌─────────────────────────────────────────────────────────────────┐
│ WORKFLOW COMMANDS (specs.md, design.md, brainstorm.md)          │
│ • Workflow-specific setup and post-processing                   │
│ • Delegates via SlashCommand:/s2s:roundtable:start              │
└──────────────────────────────┬──────────────────────────────────┘
                               │ SlashCommand
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│ COMMAND start.md (Session Lifecycle)                            │
│ • Creates session file .s2s/sessions/{id}.yaml                  │
│ • Launches Orchestrator Agent                                   │
│ • Batch writes results from orchestrator                        │
│ • Generates output document                                     │
└──────────────────────────────┬──────────────────────────────────┘
                               │ Task Agent
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│ ORCHESTRATOR AGENT (orchestrator.md)                            │
│ • Executes roundtable discussion loop                           │
│ • Launches Facilitator for questions/synthesis                  │
│ • Launches Participants in parallel (blind voting)              │
│ • Returns structured YAML for batch write                       │
│ • Has skills: roundtable-strategies                             │
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
*Part of Spec2Ship Roundtable v3 - AI-assisted software development*

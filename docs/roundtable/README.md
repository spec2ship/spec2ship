# Roundtable v4.4.1

The Roundtable is Spec2Ship's multi-agent discussion system for collaborative decision-making.

## Overview

Roundtable enables AI agents with different perspectives to discuss topics, identify consensus, resolve conflicts, and produce structured outputs (requirements, architecture decisions, etc.).

## Key Features

- **Multiple Strategies**: Standard, Disney, Debate, Consensus-Driven, Six Hats
- **Configurable Participants**: Per workflow type (specs, design, brainstorm)
- **Escalation Triggers**: Human-in-the-loop when needed
- **Session Persistence**: Resume interrupted discussions
- **Parallel Execution**: Blind voting to prevent sycophancy
- **Inline Orchestration**: Loop logic in command (v4 - Claude Code compliant)
- **Agenda Tracking** (v4.2): Required topics for specs/design workflows
- **Per-Round Persistence** (v4.4.1): Session file written after each round

## Flags

| Flag | Description |
|------|-------------|
| `--verbose` | Include full participant responses in session file |
| `--interactive` | Ask user after each round: continue/skip/pause |
| `--strategy` | Override strategy (standard/disney/debate/consensus-driven/six-hats) |
| `--participants` | Override default participants |

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

## Architecture (v4)

> **Key Constraint**: Claude Code subagents cannot spawn other subagents.
> Solution: Orchestration logic is **inline in start.md**, not a separate agent.

```
┌─────────────────────────────────────────────────────────────────┐
│ WORKFLOW COMMANDS (specs.md, design.md, brainstorm.md)          │
│ • Workflow-specific setup and post-processing                   │
│ • Delegates via SlashCommand:/s2s:roundtable:start              │
└──────────────────────────────┬──────────────────────────────────┘
                               │ SlashCommand
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│ COMMAND start.md (Session + Inline Orchestration)               │
│                                                                 │
│ PHASE 1: Setup                                                  │
│ • Creates session file .s2s/sessions/{id}.yaml                  │
│ • Auto-detects strategy from topic keywords                     │
│                                                                 │
│ PHASE 2: Discussion Loop (INLINE)                               │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ For each round:                                             │ │
│ │ 0. Display agenda status (v4.4.1)                           │ │
│ │ 1. Task(facilitator) → generate question                    │ │
│ │ 2. Task(participants) → parallel responses (blind voting)   │ │
│ │    → Store responses for verbose mode                       │ │
│ │ 3. Task(facilitator) → synthesize                           │ │
│ │ 4. Write round to session file (IMMEDIATE)                  │ │
│ │ 5. Display recap to terminal                                │ │
│ │ 6. If interactive: AskUserQuestion (EVERY round)            │ │
│ │ 7. Evaluate next_action (continue/phase/conclude/escalate)  │ │
│ └─────────────────────────────────────────────────────────────┘ │
│                                                                 │
│ PHASE 3: Completion                                             │
│ • Generates output document (ADR, requirements, architecture)   │
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
6. **Inline Orchestration**: Loop logic in command for Claude Code compliance

## Related Commands

| Command | Description |
|---------|-------------|
| `/s2s:specs` | Requirements gathering via roundtable |
| `/s2s:design` | Architecture design via roundtable |
| `/s2s:roundtable:start` | Start ad-hoc discussion |
| `/s2s:roundtable:resume` | Continue paused session |
| `/s2s:roundtable:list` | View all sessions |

---
*Part of Spec2Ship Roundtable v4 - AI-assisted software development*

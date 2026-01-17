# Roundtable System

The Roundtable is Spec2Ship's multi-agent discussion system for collaborative decision-making.

## Overview

Roundtable enables AI agents with different perspectives to discuss topics, identify consensus, resolve conflicts, and produce structured outputs (requirements, architecture decisions, etc.).

## Key Features

- **Multiple Strategies**: Standard, Disney, Debate, Consensus-Driven, Six Hats
- **12 Participant Agents**: Domain experts with anti-sycophancy measures
- **Blind Voting**: Parallel execution prevents agents seeing each other's responses
- **Session Persistence**: Resume discussions anytime
- **Agent Resume**: Continuity across rounds with context reconciliation
- **Diagnostic Mode**: Built-in validation and anomaly detection

## Quick Start

```bash
# Start a roundtable discussion
/s2s:roundtable "API versioning strategy"

# Use specific strategy
/s2s:roundtable "Feature prioritization" --strategy disney

# List all sessions
/s2s:session:list

# Resume a session
/s2s:roundtable --session
```

## Flags

| Flag | Description |
|------|-------------|
| `--verbose` | Include full participant responses in session file |
| `--interactive` | Ask user after each round: continue/skip/exit |
| `--diagnostic` | Enable debugging and anomaly detection |
| `--strategy` | Override strategy (standard/disney/debate/consensus-driven/six-hats) |
| `--participants` | Override default participants |

## Architecture

> **Key Constraint**: Claude Code subagents cannot spawn other subagents.
> Solution: Orchestration logic is **inline in workflow commands**.

```
┌─────────────────────────────────────────────────────────────┐
│ WORKFLOW COMMANDS (specs.md, design.md, brainstorm.md)      │
│ • Workflow-specific setup and post-processing               │
│ • Inline roundtable orchestration loop                      │
└──────────────────────────────┬──────────────────────────────┘
                               │
              For each round:  │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│ 1. FACILITATOR → generate question + participant context    │
│ 2. PARTICIPANTS → parallel responses (blind voting)         │
│ 3. FACILITATOR → synthesize, create/update artifacts        │
│ 4. SESSION FILE → updated with round data                   │
│ 5. DISPLAY → recap shown to user                            │
│ 6. EVALUATE → continue/phase/conclude/escalate              │
└─────────────────────────────────────────────────────────────┘
```

## Documentation

### Core Concepts

- [Roundtable Concept](../concepts/roundtable.md) - How roundtables work
- [Strategies](../concepts/strategies.md) - Facilitation approaches
- [Agents](../concepts/agents.md) - Participant roles
- [Sessions](../concepts/sessions.md) - Session management

### Configuration

- [Configuration Guide](./configuration.md) - Config options and defaults

### Strategies

- [Strategy Overview](./strategies/overview.md) - All strategies compared

### Research

- [Mitigations](./research/mitigations.md) - How we address LLM limitations

## Participant Agents

| Agent | Primary Workflow | Focus |
|-------|------------------|-------|
| product-manager | specs | User value, priorities |
| business-analyst | specs | Domain modeling, use cases |
| qa-lead | specs | Quality, testability |
| ux-researcher | specs | User needs, accessibility |
| software-architect | design | System structure, patterns |
| technical-lead | design | Implementation feasibility |
| devops-engineer | design | Deployment, operations |
| security-champion | design | Threat modeling, OWASP |

## Design Principles

1. **Context Isolation**: Participants receive context in prompt, don't read files
2. **Blind Voting**: Parallel execution prevents anchoring bias
3. **Critical Stance**: Agents resist premature consensus
4. **Session as Truth**: Single session file contains all state
5. **Strategy as Skill**: Facilitation logic is configurable
6. **Inline Orchestration**: Loop logic in command for Claude Code compliance

## Related Commands

| Command | Description |
|---------|-------------|
| `/s2s:specs` | Requirements gathering via roundtable |
| `/s2s:design` | Architecture design via roundtable |
| `/s2s:brainstorm` | Creative exploration via roundtable |
| `/s2s:roundtable` | Start ad-hoc discussion |
| `/s2s:roundtable --session` | Resume active session |
| `/s2s:session:list` | View all sessions |
| `/s2s:session:validate` | Check session consistency |

---

*Part of Spec2Ship - From Specs to Ship*

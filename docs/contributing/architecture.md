# Architecture Overview

This document provides a high-level overview of Spec2Ship's architecture for contributors.

## Component Structure

```
spec2ship/
├── .claude/                  # Claude context and guidelines
│   ├── CLAUDE.md             # Main context file
│   ├── guidelines/           # Conventions and patterns
│   └── decisions/            # Architecture decisions (SAD-*)
├── .claude-plugin/           # Plugin manifest
├── commands/                 # Slash commands (/s2s:*)
│   ├── init.md
│   ├── specs.md
│   ├── design.md
│   ├── brainstorm.md
│   ├── plan/                 # Plan subcommands
│   ├── session/              # Session subcommands
│   └── roundtable/           # Roundtable subcommands
├── agents/                   # AI agents
│   ├── roundtable/           # Discussion participants
│   ├── exploration/          # Codebase analysis
│   └── validation/           # Session validation
├── skills/                   # Knowledge bases
│   ├── roundtable-execution/ # How to run roundtables
│   ├── roundtable-strategies/# Facilitation strategies
│   ├── arc42-templates/      # Architecture templates
│   ├── iso25010-requirements/# Quality model
│   └── ...
├── templates/                # File templates
├── docs/                     # Documentation
└── examples/                 # Sample outputs
```

## Component Types

### Commands

Slash commands that users invoke directly.

**Location**: `commands/*.md`

**Characteristics**:
- Orchestrate workflows
- Parse arguments
- Manage state
- Invoke agents
- Write output files

**Example**: `commands/specs.md` orchestrates the specs roundtable.

### Agents

Specialized AI participants invoked by commands.

**Location**: `agents/*/*.md`

**Types**:
- **Facilitator**: Orchestrates roundtable discussions
- **Participants**: Domain experts (product-manager, architect, etc.)
- **Exploration**: Analyze codebases
- **Validation**: Check session consistency

**Key constraint**: Subagents cannot spawn other subagents.

### Skills

Knowledge bases loaded on demand.

**Location**: `skills/*/SKILL.md`

**Characteristics**:
- Provide domain knowledge
- Third-person descriptions
- Progressive disclosure (references/, examples/)
- Max ~2,000 words in SKILL.md

## Roundtable Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    WORKFLOW COMMAND                         │
│              (specs.md, design.md, brainstorm.md)           │
│                                                             │
│  • Validates prerequisites                                  │
│  • Creates session file                                     │
│  • Executes roundtable loop                                 │
│  • Writes output documents                                  │
└─────────────────────────────────────────────────────────────┘
                           │
              For each round:
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ 1. FACILITATOR (question)                                   │
│    • Generates discussion question                          │
│    • Prepares participant context                           │
│    • Uses: Task(roundtable-facilitator)                     │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. PARTICIPANTS (parallel, blind voting)                    │
│    • Receive context (no file access)                       │
│    • Provide domain perspectives                            │
│    • Uses: Task(roundtable-{participant}) × N               │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. FACILITATOR (synthesis)                                  │
│    • Synthesizes responses                                  │
│    • Creates/updates artifacts                              │
│    • Decides next action                                    │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. COMMAND (update session)                                 │
│    • Writes round to session file                           │
│    • Updates metrics                                        │
│    • Displays recap to user                                 │
└─────────────────────────────────────────────────────────────┘
```

## Key Design Decisions

### SAD-001: Component Separation

| Component | Purpose | When to Use |
|-----------|---------|-------------|
| **Commands** | Workflow orchestration | User-facing operations |
| **Agents** | Specialized tasks | Domain expertise |
| **Skills** | Knowledge on-demand | Standards, patterns |

### SAD-002: Inline Orchestration

Orchestration logic is inline in commands, not in a separate agent.

**Reason**: Claude Code subagents cannot spawn other subagents.

### SAD-003: Agent Tiers

| Tier | Model | Use Case |
|------|-------|----------|
| **Critical** | opus | Facilitator decisions |
| **Default** | inherit | Most agents |
| **Fast** | haiku | Simple validation |

### SAD-004: Participant Context

Participants receive all context inline (no file access):
- Prevents inconsistent context
- Enables blind voting
- Reduces token overhead

### SAD-005: Session as Source of Truth

Single session file contains all state:
- Embedded artifacts (not separate files)
- Round summaries
- Agent state for resume
- Metrics

## Data Flow

```
CONTEXT.md (project info)
     │
     ▼
config.yaml (settings)
     │
     ▼
COMMAND (orchestrator)
     │
     ├──► Facilitator (question)
     │         │
     │         ▼
     │    participant_context
     │         │
     │         ▼
     ├──► Participants (parallel)
     │         │
     │         ▼
     │    responses[]
     │         │
     │         ▼
     ├──► Facilitator (synthesis)
     │         │
     │         ▼
     │    artifacts, next_action
     │         │
     ▼         ▼
SESSION FILE (state.yaml)
     │
     ▼
OUTPUT DOCS (requirements.md, etc.)
```

## Extending the System

| Extension | How |
|-----------|-----|
| New agent | Create `agents/roundtable/{name}.md` |
| New skill | Create `skills/{name}/SKILL.md` |
| New strategy | Add to `skills/roundtable-strategies/` |
| New command | Create `commands/{name}.md` |

See [Extending Spec2Ship](../extending/) for detailed guides.

---

*See also: [Development Setup](./development.md) | [Extending](../extending/)*

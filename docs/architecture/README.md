# Architecture Overview

This document provides a high-level overview of Spec2Ship's architecture for contributors.

## Component Structure

```
spec2ship/
├── .claude/                  # Claude context and guidelines
│   ├── CLAUDE.md             # Main context file
│   └── guidelines/           # Conventions and patterns
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

## Key Design Principles

| Principle | Description |
|-----------|-------------|
| **Component Separation** | Commands orchestrate, Agents provide expertise, Skills provide knowledge |
| **Inline Orchestration** | Roundtable loop runs in commands (subagents can't spawn subagents) |
| **Model Tiers** | Critical tasks use opus, most use inherited model, simple tasks use haiku |
| **Context Passing** | Participants receive inline context (no file access, enables blind voting) |
| **Session as Truth** | Single session file contains all state and artifacts |

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

## Architecture Decisions

Significant architecture decisions are documented as ADRs in [`decisions/`](./decisions/).

For detailed design rationale, see the [ADR index](./decisions/README.md).

---

*See also: [Contributing](../../CONTRIBUTING.md) | [Extending](../extending/)*

# Spec2Ship (s2s)

AI-assisted development framework for the full software lifecycle — from specifications to shipping.

## Overview

Spec2Ship automates software development workflows using Claude Code:

- **Init**: Analyze and configure your project with smart detection
- **Brainstorm**: Creative ideation with multi-agent roundtables
- **Spec**: Define requirements through collaborative discussions
- **Design**: Create architecture with expert perspectives
- **Plan**: Generate and execute implementation plans

## Features

- **Smart Initialization**: Detects existing project structure and adapts accordingly
- **Roundtable Discussions**: Multi-agent discussions with 5 facilitation strategies
- **Creative Brainstorming**: Disney strategy (Dreamer → Realist → Critic)
- **Implementation Plans**: Structured plans with task tracking
- **Standards-Based**: Templates based on arc42, ISO 25010, MADR

## Installation

```bash
# Add marketplace
/plugin marketplace add spec2ship/spec2ship

# Install plugin
/plugin install s2s
```

## Workflow

```
┌──────────────┐     ┌──────────────┐     ┌──────────┐
│     init     │ ──► │  brainstorm  │ ──► │   specs  │
│              │     │  (optional)  │     │          │
│ Analyze &    │     │ Creative     │     │ Define   │
│ configure    │     │ ideation     │     │ what     │
└──────────────┘     └──────────────┘     └──────────┘
                                                │
              ┌─────────────────────────────────┘
              ▼
       ┌──────────────┐     ┌──────────────┐
       │    design    │ ──► │     plan     │
       │              │     │              │
       │ Architect    │     │ Generate &   │
       │ how          │     │ execute      │
       └──────────────┘     └──────────────┘
```

## Quick Start

```bash
# 1. Initialize your project
/s2s:init

# 2. (Optional) Brainstorm ideas
/s2s:brainstorm "new feature ideas"

# 3. Define specifications
/s2s:specs

# 4. Design architecture
/s2s:design

# 5. Generate implementation plans
/s2s:plan

# 6. Start working on a plan
/s2s:plan:start "plan-id"

# 7. Complete the plan
/s2s:plan:complete
```

## Commands

### Workflow Commands

| Command | Description |
|---------|-------------|
| `/s2s:init` | Initialize or update project (smart: detect → setup → context) |
| `/s2s:brainstorm "topic"` | Creative ideation with Disney strategy |
| `/s2s:specs` | Define requirements via roundtable |
| `/s2s:design` | Design architecture via roundtable |
| `/s2s:plan` | Generate implementation plans (smart) |

### Init Sub-commands

| Command | Description |
|---------|-------------|
| `/s2s:init:detect` | Analyze project (read-only) |
| `/s2s:init:setup` | Create .s2s/ structure |
| `/s2s:init:context` | Update CONTEXT.md only |

### Plan Sub-commands

| Command | Description |
|---------|-------------|
| `/s2s:plan:create "topic"` | Create single plan explicitly |
| `/s2s:plan:list` | List all plans |
| `/s2s:plan:start "id"` | Start working on a plan |
| `/s2s:plan:complete` | Complete current plan |

### Roundtable Sub-commands

| Command | Description |
|---------|-------------|
| `/s2s:roundtable:start "topic"` | Start generic roundtable |
| `/s2s:roundtable:start "topic" --strategy disney` | With specific strategy |
| `/s2s:roundtable:list` | List sessions |
| `/s2s:roundtable:resume "id"` | Resume session |

### Roundtable Strategies

| Strategy | Phases | Best For |
|----------|--------|----------|
| `standard` | 1 | General discussions |
| `disney` | 3 (dreamer, realist, critic) | Creative solutions |
| `debate` | 3 (opening, rebuttal, closing) | Option evaluation |
| `consensus-driven` | 3 | Fast decisions |
| `six-hats` | 7 | Comprehensive analysis |

## Re-running Init

The `/s2s:init` command is safe to re-run:

- **No changes detected**: Reports "Project is up to date"
- **New files detected**: Proposes updating CONTEXT.md
- **Major changes**: Offers to reinitialize with confirmation

## Documentation

- [Roundtable Overview](docs/roundtable/README.md)
- [Configuration Guide](docs/roundtable/configuration.md)
- [Strategy Reference](docs/roundtable/strategies/overview.md)
- [Architecture](docs/roundtable/architecture/components.md)

## License

MIT License - see [LICENSE](LICENSE)

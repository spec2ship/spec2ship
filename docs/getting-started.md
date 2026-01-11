# Getting Started with Spec2Ship

This guide walks you through installing Spec2Ship and creating your first project.

## Prerequisites

- [Claude Code](https://claude.ai/claude-code) CLI installed and configured
- Git (for version control integration)

## Installation

```bash
# Add the plugin from GitHub
/plugin marketplace add https://github.com/spec2ship/spec2ship.git

# Install as 's2s'
/plugin install s2s@spec2ship
```

## Quick Start

### 1. Initialize Your Project

Navigate to your project directory and run:

```bash
/s2s:init
```

This will:
- Detect your project's tech stack
- Create `.s2s/` folder with configuration
- Generate a `CONTEXT.md` describing your project
- Create a `CLAUDE.md` for AI context

### 2. Define Requirements

Start a collaborative requirements session:

```bash
/s2s:specs
```

A roundtable of AI agents will discuss and define:
- User personas and workflows
- Functional requirements
- Non-functional requirements
- Business rules

Output: `docs/specifications/requirements.md`

### 3. Design Architecture

Once requirements are defined:

```bash
/s2s:design
```

The roundtable discusses and produces:
- Architecture decisions
- Component definitions
- Interface specifications

Output: `docs/architecture/`

### 4. Create Implementation Plan

```bash
/s2s:plan:create "feature-name"
```

Generates a step-by-step implementation plan based on specs and architecture.

### 5. Start Implementation

```bash
/s2s:plan:start
```

Begin working through the plan with AI guidance.

## Project Structure

After initialization, your project will have:

```
your-project/
├── .s2s/                    # S2S working directory
│   ├── config.yaml          # Configuration
│   ├── state.yaml           # Current state
│   ├── CONTEXT.md           # Project context
│   ├── sessions/            # Roundtable sessions
│   └── plans/               # Implementation plans
├── CLAUDE.md                # AI context file
└── docs/                    # Generated documentation
    ├── specifications/
    └── architecture/
```

## Common Commands

| Command | Description |
|---------|-------------|
| `/s2s:init` | Initialize or update project |
| `/s2s:specs` | Define requirements |
| `/s2s:design` | Design architecture |
| `/s2s:brainstorm "topic"` | Creative exploration |
| `/s2s:plan:create "name"` | Create implementation plan |
| `/s2s:plan:list` | List all plans |
| `/s2s:plan:start` | Start working on a plan |
| `/s2s:session` | Show current roundtable session |
| `/s2s:session:list` | List all sessions |

## CLI Flags

Most commands support these flags:

| Flag | Description |
|------|-------------|
| `--verbose` | Include detailed output in session files |
| `--interactive` | Pause after each round for user input |
| `--diagnostic` | Enable debugging output |
| `--strategy <name>` | Override default strategy |
| `--participants <list>` | Override default participants |

## Next Steps

- [Concepts](./concepts/) - Understand how Spec2Ship works
- [Workflow Guides](./guides/) - Detailed guides for each workflow
- [Configuration](./reference/configuration.md) - Customize behavior
- [Extending](./extending/) - Add custom agents and strategies

---

*See also: [Command Reference](./reference/commands.md)*

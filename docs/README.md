# Spec2Ship Documentation

Spec2Ship is a Claude Code plugin that automates the software development lifecycle: from specifications through planning, implementation, and shipping.

## Quick Start

```bash
# Initialize a new project
/s2s:init

# Define requirements through collaborative roundtable
/s2s:specs

# Design architecture
/s2s:design

# Create implementation plan
/s2s:plan:create "feature-name"

# Start working on a plan
/s2s:plan:start
```

## Documentation

### For Users

| Guide | Description |
|-------|-------------|
| [Getting Started](./getting-started.md) | Installation and first project setup |
| [Concepts](./concepts/) | Core concepts: workflows, roundtable, strategies |
| [Workflow Guides](./guides/) | Step-by-step guides for each workflow |
| [Command Reference](./reference/commands.md) | All `/s2s:*` commands |
| [Configuration](./reference/configuration.md) | Config options and customization |

### For Contributors

| Guide | Description |
|-------|-------------|
| [Contributing](../CONTRIBUTING.md) | Development setup and guidelines |
| [Architecture](./architecture/) | System architecture overview |
| [Extending Spec2Ship](./extending/) | Add agents, skills, and strategies |

### Deep Dives

| Topic | Description |
|-------|-------------|
| [Roundtable System](./roundtable/) | Multi-agent discussion system |
| [Strategies](./roundtable/strategies/) | Facilitation strategies (Disney, Debate, etc.) |

## Core Workflows

```
/s2s:init          Define project context
     │
     ▼
/s2s:brainstorm    Explore ideas (optional)
     │
     ▼
/s2s:specs         Define requirements via roundtable
     │
     ▼
/s2s:design        Design architecture via roundtable
     │
     ▼
/s2s:plan:create   Create implementation plan
     │
     ▼
/s2s:plan:start    Execute plan with guidance
```

## Key Features

- **AI Roundtables**: Multiple AI agents discuss and debate to produce better outcomes
- **Anti-Sycophancy**: Agents are designed to disagree constructively
- **Session Persistence**: Pause and resume discussions
- **Multiple Strategies**: Disney (creative), Debate, Consensus-Driven, Six Hats
- **Extensible**: Add custom agents, skills, and strategies

## Examples

See [examples/](../examples/) for sample outputs from Spec2Ship workflows.

---

*Spec2Ship - From Specs to Ship*

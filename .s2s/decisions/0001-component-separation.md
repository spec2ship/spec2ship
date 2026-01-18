# Component Separation: Commands vs Agents vs Skills

## Status

accepted

## Context and Problem Statement

Spec2Ship needs a clear architecture for organizing its various parts. Without clear separation, the codebase would become difficult to maintain and extend. How should we organize user-facing operations, AI capabilities, and reusable knowledge?

## Decision Drivers

- Need clear mental model for contributors
- Want easy extensibility (add new capabilities independently)
- Separation of concerns (orchestration vs expertise vs knowledge)
- Claude Code plugin constraints

## Considered Options

- Single component type for everything
- Two types: Commands and Agents
- Three types: Commands, Agents, and Skills

## Decision Outcome

Chosen option: "Three types: Commands, Agents, and Skills", because each has a distinct purpose and lifecycle.

| Component | Purpose | Location | When to Use |
|-----------|---------|----------|-------------|
| **Commands** | Workflow orchestration | `commands/*.md` | User-facing operations with phases, state |
| **Agents** | Specialized tasks | `agents/*/*.md` | Domain expertise, parallelizable work |
| **Skills** | Knowledge on-demand | `skills/*/SKILL.md` | Standards, patterns, templates |

### Consequences

- Good, because clear mental model for contributors
- Good, because easy to extend (add new agent, skill, or command independently)
- Good, because separation of concerns (orchestration vs expertise vs knowledge)
- Bad, because some duplication across components
- Neutral, because requires documentation of component boundaries

## Pros and Cons of the Options

### Single component type

Everything is a "module" or "plugin".

- Good, because simple mental model
- Bad, because unclear boundaries
- Bad, because harder to maintain as codebase grows

### Two types: Commands and Agents

Commands for user interaction, Agents for everything else.

- Good, because simpler than three types
- Bad, because conflates knowledge bases with active agents
- Bad, because skills would need tool access they don't need

### Three types: Commands, Agents, and Skills

Distinct separation based on purpose and capabilities.

- Good, because each type has clear purpose
- Good, because skills don't need tools (pure knowledge)
- Good, because agents are stateless domain experts
- Good, because commands handle state and orchestration

## More Information

This decision enables the roundtable architecture where:
- Commands orchestrate the discussion flow
- Agents provide domain expertise (participants, facilitator)
- Skills provide templates and standards (MADR, arc42, etc.)

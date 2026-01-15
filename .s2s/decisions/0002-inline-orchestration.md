# Inline Orchestration in Commands

## Status

accepted

## Context and Problem Statement

Roundtable discussions need orchestration: creating sessions, running rounds, invoking participants, synthesizing results. Where should this orchestration logic live?

During development, we discovered a critical Claude Code limitation: **subagents cannot spawn other subagents**.

## Decision Drivers

- Claude Code constraint: subagents cannot spawn subagents
- Need clear ownership of roundtable flow
- Want facilitator to focus on facilitation, not orchestration
- Minimize complexity while maintaining flexibility

## Considered Options

- Separate orchestrator agent
- Inline orchestration in workflow commands
- Orchestration in facilitator agent

## Decision Outcome

Chosen option: "Inline orchestration in workflow commands", because Claude Code subagents cannot spawn other subagents.

The workflow commands (`specs.md`, `design.md`, `brainstorm.md`) contain the roundtable loop inline. The facilitator agent handles question generation and synthesis, but the command manages the loop.

### Consequences

- Good, because commands have full control over the roundtable loop
- Good, because avoids subagent spawning limitation
- Good, because simpler debugging (single execution context)
- Good, because facilitator focuses on facilitation, not mechanics
- Bad, because some code duplication across workflow commands
- Bad, because commands are larger and more complex
- Neutral, because clear separation between facilitation (agent) and orchestration (command)

## Pros and Cons of the Options

### Separate orchestrator agent

A dedicated agent that coordinates the roundtable flow.

- Good, because single place for orchestration logic
- Good, because commands stay simple
- Bad, because cannot spawn participant agents (Claude Code limitation)
- Bad, because adds another agent layer

### Inline orchestration in workflow commands

Commands contain the roundtable loop directly.

- Good, because works within Claude Code constraints
- Good, because commands own their entire workflow
- Bad, because duplication across specs.md, design.md, brainstorm.md
- Neutral, because `roundtable-execution` skill provides shared patterns

### Orchestration in facilitator agent

Facilitator manages the loop in addition to facilitation.

- Good, because consolidates roundtable knowledge
- Bad, because cannot spawn participant agents (Claude Code limitation)
- Bad, because mixing concerns (facilitation + orchestration)

## More Information

The `roundtable-execution` skill provides shared patterns and templates to reduce duplication across workflow commands while keeping orchestration inline.

Related: [0001-component-separation](0001-component-separation.md)

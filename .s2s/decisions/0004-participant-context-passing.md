# Participant Context Passing

## Status

accepted

## Context and Problem Statement

Roundtable participants need context about the project, current discussion state, and agenda to provide meaningful input. How should context be provided to participant agents?

## Decision Drivers

- Participants have `tools: []` (no file access by design)
- Need consistent context across all participants
- Want to enable "blind voting" (participants don't see each other's responses)
- Minimize token overhead
- Prevent inconsistent state between participants

## Considered Options

- File-based context (participants read files)
- Inline context (full context in prompt)
- Hybrid (some inline, some file-based)

## Decision Outcome

Chosen option: "Inline context (full context in prompt)", because participants have no tools and consistency is critical.

All context is passed inline in the participant prompt:
- Project context snapshot
- Current round question
- Relevant artifacts
- Agenda items

### Consequences

- Good, because prevents inconsistent context between participants
- Good, because enables blind voting (no cross-participant visibility)
- Good, because participants don't need tool access
- Good, because context is atomic per round
- Bad, because larger prompts (more tokens)
- Neutral, because requires careful context preparation by facilitator

## Pros and Cons of the Options

### File-based context

Participants read `.s2s/CONTEXT.md` and session files.

- Good, because smaller prompts
- Good, because participants can explore
- Bad, because requires tool access (breaks isolation)
- Bad, because context may change during round
- Bad, because participants could see each other's work

### Inline context

Full context embedded in participant prompt.

- Good, because atomic, consistent context
- Good, because no tool access needed
- Good, because enables blind voting
- Bad, because larger prompts
- Neutral, because facilitator prepares context snapshot

### Hybrid approach

Some context inline, some via file reads.

- Good, because balances prompt size and consistency
- Bad, because complex to implement
- Bad, because partial isolation

## More Information

The facilitator prepares `participant_context` YAML that is passed VERBATIM to each participant:

```yaml
participant_context:
  project_summary: "..."
  current_round: 3
  question: "What risks do you see?"
  artifacts_snapshot:
    - id: REQ-001
      summary: "..."
  your_role: "software-architect"
```

This context is identical for all participants in a round, enabling independent parallel responses.

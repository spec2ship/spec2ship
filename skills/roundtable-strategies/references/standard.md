# Standard Strategy

The standard round-robin strategy provides balanced, equal participation from all participants.

## Configuration

```yaml
defaults:
  participation: "parallel"
  phases:
    - name: "discussion"
      prompt_suffix: |
        Provide your perspective on this topic.
        Be direct and specific.
        State your confidence level (0.0-1.0).
      participants: "all"
  consensus:
    policy: "weighted_majority"
    threshold: 0.6
    max_attempts_per_conflict: 3

validation:
  requires_sequential_phases: false
  min_participants: 2
```

## How It Works

### Round Structure

1. **Facilitator** presents the question/topic
2. **All participants** respond in parallel (blind voting)
3. **Facilitator** synthesizes responses, identifies consensus and conflicts
4. If conflicts exist, new round with focused question
5. Repeat until consensus or max attempts

### Parallel Participation

In standard strategy, all participants respond simultaneously:
- Prevents sycophancy (agents don't see each other's responses)
- Ensures independent thinking
- Faster execution (parallel Task calls)

### Consensus Detection

After each round:
1. Extract position from each response
2. Group similar positions
3. If >threshold agree → consensus reached
4. If not → identify conflict, formulate clarifying question

## Prompt Template

The facilitator uses this template for participant prompts:

```
You are {participant.role}. {participant.description}

=== ROUND {round_number} ===
Topic: {topic}
Question: {current_question}

=== YOUR EXPERTISE ===
{participant.expertise}

=== SYNTHESIS OF PREVIOUS ROUNDS ===
{synthesis_of_previous_rounds}

=== CURRENT CONSENSUS ===
{consensus_points}

=== OPEN CONFLICTS ===
{conflicts}

---
Provide your perspective. Include:
1. Your position (clear statement)
2. Rationale (why you believe this)
3. Confidence (0.0-1.0)
4. Dependencies (what this depends on)
```

## When to Use

- General technical discussions
- Architecture reviews
- Requirement validation
- Any topic needing balanced input

## Strengths

- Fair: all voices have equal weight
- Fast: parallel execution
- Mitigates groupthink via blind voting

## Limitations

- May not converge on complex topics
- Doesn't separate creative from critical thinking
- All participants speak on every round (could be noisy)

## Strategy hooks

No per-round hooks. Algorithm runs with workflow defaults from PROFILE.

This strategy emits no strategy-specific fields at the Phase 2 hook points:
- Step 2.3c (participant response): no `*_role` field added to participant dumps.
- Step 2.6a (round summary): no `*_phase` field added to `rounds[]` entries.

Facilitator instructions at Step 2.2c skip override population for this strategy (per `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/strategy-hooks.md` §8 future-wiring contract).

# Consensus-Driven Strategy

Optimized for fast convergence toward agreement. Uses proposal-refinement cycles.

## Configuration

```yaml
defaults:
  participation: "parallel"
  phases:
    - name: "proposal"
      prompt_suffix: |
        Propose a specific solution to this problem.
        Be concrete - not "we could do X", but "we should do X because Y".
        State your confidence level.
      participants: "all"

    - name: "refinement"
      prompt_suffix: |
        Review the proposals. Can you support any of them?
        If you can mostly support but have concerns, suggest modifications.
        If you fundamentally disagree, explain the blocking concern.
      participants: "all"
      context:
        include_full_history: true

    - name: "convergence"
      prompt_suffix: |
        Given the refined proposals, which can you support?
        Express: support, stand-aside (disagree but won't block), or block.
        If blocking, state minimum change needed.
      participants: "all"
      context:
        include_full_history: true

  consensus:
    policy: "consent"  # No blocks = consensus
    threshold: null
    max_attempts_per_conflict: 2

validation:
  requires_sequential_phases: true
  min_participants: 2
```

## How It Works

### Consent vs Consensus

Traditional consensus: everyone must agree (unanimous).
Consent-based: no one blocks (disagreement allowed if not blocking).

This strategy uses **consent**:
- **Support**: I agree with this proposal
- **Stand-aside**: I disagree but won't block (noted for record)
- **Block**: This is unacceptable, cannot proceed

### Phase Flow

1. **Proposal Round**
   - All participants propose solutions (parallel)
   - Proposals are specific and actionable
   - Each includes rationale and confidence

2. **Refinement Round**
   - Participants review all proposals
   - Suggest modifications to make proposals acceptable
   - Identify blocking concerns early

3. **Convergence Round**
   - Final position: support, stand-aside, or block
   - If blocks exist: identify minimum change needed
   - If no blocks: consensus reached

4. **Iteration** (if needed)
   - Facilitator reformulates proposal based on feedback
   - New convergence round
   - Max 2 iterations before escalation

## Prompt Template

### Proposal Round
```
You are {participant.role}.

=== TOPIC ===
{topic}

=== CONTEXT ===
{relevant_context}

=== YOUR EXPERTISE ===
{participant.expertise}

---
PROPOSAL MODE

Propose a specific solution:
1. What exactly should we do? (concrete, actionable)
2. Why this approach? (rationale)
3. Confidence level (0.0-1.0)
4. Key assumption this depends on

Be decisive. "We should X because Y", not "We could consider X".
```

### Refinement Round
```
=== PROPOSALS RECEIVED ===
{all_proposals}

---
REFINEMENT MODE

For each proposal:
1. Can you support it as-is?
2. If mostly support but have concerns, what modification would address them?
3. If fundamental disagreement, what is the blocking concern?

Focus on finding common ground.
```

### Convergence Round
```
=== REFINED PROPOSALS ===
{refined_proposals}

---
CONVERGENCE MODE

For the leading proposal, state your position:

- SUPPORT: I agree with this approach
- STAND-ASIDE: I disagree but won't block (explain why noted)
- BLOCK: This is unacceptable (explain minimum change needed)

Only block if you have a fundamental objection.
```

## Consent Detection

```yaml
# After convergence round
if all positions are SUPPORT or STAND-ASIDE:
  consensus = reached
  output includes stand-asides as noted concerns
else:
  extract blocking concerns
  facilitator reformulates proposal
  new convergence round
```

## When to Use

- Time-sensitive decisions
- When perfect agreement isn't required
- Teams with established trust
- Operational decisions vs strategic ones

## Strengths

- Fast convergence
- Respects minority concerns (stand-asides recorded)
- Clear decision criteria (no blocks = proceed)
- Avoids endless discussion

## Limitations

- May pressure people to stand-aside rather than block
- Less thorough exploration than other strategies
- Requires trust that blocks will be respected
- Not ideal for highly consequential decisions

## Research Basis

Based on Sociocracy and Holacracy consent-based decision making. Adapted for LLM multi-agent context with explicit position states.

## Strategy hooks

No per-round hooks. Algorithm runs with workflow defaults from PROFILE.

This strategy emits no strategy-specific fields at the Phase 2 hook points:
- Step 2.3c (participant response): no `*_role` field added to participant dumps.
- Step 2.6a (round summary): no `*_phase` field added to `rounds[]` entries.

The consent-based consensus logic described above (`policy: "consent"`, `max_attempts_per_conflict: 2`) operates at session conclusion (Phase 3 scope), not as per-round Phase 2 hooks. Therefore it is NOT covered by the Phase 2 hook contract documented in `strategy-hooks.md`.

Facilitator instructions at Step 2.2c skip override population for this strategy.

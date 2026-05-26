# Debate Strategy

Structured adversarial discussion with Pro and Con positions to thoroughly evaluate proposals.

## Configuration

```yaml
defaults:
  participation: "parallel"  # Within each side
  phases:
    - name: "opening"
      prompt_suffix: |
        Present your strongest arguments for your assigned position.
        Be persuasive but factual.
        Reference concrete evidence where possible.
      participants: "assigned"  # Pro or Con based on assignment

    - name: "rebuttal"
      prompt_suffix: |
        Address the opposing side's arguments directly.
        Point out weaknesses in their reasoning.
        Defend your position against their attacks.
      participants: "assigned"
      context:
        include_full_history: true

    - name: "closing"
      prompt_suffix: |
        Summarize your strongest points.
        Acknowledge any valid points from the opposition.
        Make your final case.
      participants: "assigned"
      context:
        include_full_history: true

  consensus:
    policy: "facilitator_judgment"  # Facilitator synthesizes winner
    threshold: null  # Not applicable
    max_attempts_per_conflict: 1  # One debate round

validation:
  requires_two_sides: true
  min_participants_per_side: 1
  side_assignment: "automatic"  # or "facilitator"
```

## How It Works

### Side Assignment

Before debate begins, participants are assigned sides:
- **Pro**: Arguments in favor of the proposal
- **Con**: Arguments against the proposal

Assignment can be:
- **Automatic**: Based on participant role (e.g., architect = Pro, QA = Con)
- **Facilitator**: Facilitator assigns based on topic

### Debate Structure

1. **Opening Statements** (parallel within sides)
   - Pro side presents case for proposal
   - Con side presents case against
   - No interaction yet

2. **Rebuttal** (parallel within sides)
   - Each side addresses opponent's arguments
   - Points out flaws in reasoning
   - Provides counter-evidence

3. **Closing Statements** (parallel within sides)
   - Final summary
   - Acknowledge valid opposing points
   - Strongest final argument

4. **Facilitator Synthesis**
   - Analyzes both sides
   - Weighs arguments
   - Produces balanced recommendation

## Prompt Template

### Pro Opening
```
You are {participant.role} arguing FOR the proposal.

=== PROPOSAL ===
{topic}

=== YOUR EXPERTISE ===
{participant.expertise}

---
DEBATE MODE - PRO POSITION

Present your strongest arguments FOR this proposal:
1. Key benefits
2. Supporting evidence
3. How it addresses the problem
4. Why alternatives are inferior

Be persuasive but honest. Reference specifics.
```

### Con Opening
```
You are {participant.role} arguing AGAINST the proposal.

=== PROPOSAL ===
{topic}

=== YOUR EXPERTISE ===
{participant.expertise}

---
DEBATE MODE - CON POSITION

Present your strongest arguments AGAINST this proposal:
1. Key risks and costs
2. Evidence of problems
3. What could go wrong
4. Why alternatives might be better

Be persuasive but fair. Reference specifics.
```

### Rebuttal (Pro)
```
=== PRO OPENING ===
{pro_opening}

=== CON OPENING ===
{con_opening}

---
REBUTTAL - Respond to the Con arguments.
- Address their key points directly
- Provide counter-evidence
- Defend your position
```

### Facilitator Synthesis
```
=== DEBATE SUMMARY ===

PRO ARGUMENTS:
{pro_summary}

CON ARGUMENTS:
{con_summary}

---
As facilitator, synthesize this debate:
1. Strongest Pro arguments
2. Strongest Con arguments
3. Key trade-offs
4. Your recommendation with rationale
```

## When to Use

- Evaluating controversial architectural decisions
- Comparing two viable approaches
- Stress-testing a proposed design
- When stakeholders have strong opposing views

## Strengths

- Forces consideration of opposing viewpoints
- Surfaces hidden assumptions
- Produces clear trade-off analysis
- Prevents echo chamber

## Limitations

- Binary (Pro/Con) - may miss nuanced middle ground
- Can feel adversarial
- Requires clear proposal to debate
- Not suitable for open-ended exploration

## Research Basis

Structured debate is a proven technique for evaluating options. In LLM contexts, adversarial setups help mitigate sycophancy by forcing agents into opposing roles.

## Strategy hooks

Facilitator-driven, LLM-emergent. Phase 4 chose Option B; current policy is `facilitator_emergent` (LLM picks Pro/Con role values; field names provided via hook_overrides). Promote to deterministic rule once empirical baseline sample size justifies.

### Hook fields emitted

| Hook | Phase 2 step | Field added |
|------|--------------|-------------|
| Pro/Con role assignment | Step 2.3c (participant response) | `debate_role: "pro" \| "con"` (top-level in participant dump's `response`) |
| Debate phase tracking | Step 2.6a (round summary entry) | `debate_phase: "opening" \| "rebuttal" \| "closing" \| "synthesis"` (optional in `rounds[].` entry) |

### Current state (post Phase 4 wiring, 2026-05-21)

Both `debate_role` and `debate_phase` are emitted by the facilitator agent through LLM interpretation of the strategy context. The wiring path runs through Option B: `commands/roundtable.md` PHASE 1 reads this doc's § Strategy hooks, populates `hook_overrides.participant_response.debate_role.policy = "facilitator_emergent"` in `session.yaml`, and the facilitator/participant agents consume the dict via the 3-branch dispatch in `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/strategy-hook-resolution.md`. The "automatic" Pro/Con side assignment referenced in §How It Works above is realised by LLM choice at session start under the `facilitator_emergent` policy, not by a fixed rule.

A future deterministic policy table for Pro/Con assignment (Option B refinement) may be added below this section as data once empirical baselines justify it.

For full hook contract details (field types, source, behaviour), see `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/strategy-hooks.md` §3 (`participant_response.debate_role`) and §4 (`round_summary.debate_phase`). Architectural decision recorded in ADR-0011 Phase 4 addendum.

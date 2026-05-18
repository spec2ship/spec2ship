# Disney Creative Strategy

> **Algorithmic implementation**: `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/disney-phase-machine.md`. This file is the human-facing strategy description (mindsets, prompts, when-to-use); the machine doc is the canonical algorithmic spec consumed by `phase-2-core.md` Step 2.10.

Based on Walt Disney's creative process, this strategy separates ideation, planning, and critique into distinct phases.

## Configuration

```yaml
defaults:
  participation: "parallel"  # Within each phase
  phases:
    - name: "dreamer"
      prompt_suffix: |
        Think BIG. No constraints. What would be ideal?
        Ignore technical limitations for now.
        Focus on possibilities, not problems.
        What would delight users?
      participants: "all"
      context:
        include_synthesis_only: true
        hide_conflicts: true  # Don't show criticisms yet

    - name: "realist"
      prompt_suffix: |
        Given the dreamer ideas, how would we actually build this?
        Focus on practical implementation.
        What resources, timeline, dependencies?
        Keep the vision but ground it in reality.
      participants: "all"
      context:
        include_full_history: true  # See dreamer ideas

    - name: "critic"
      prompt_suffix: |
        What could go wrong?
        What are the risks?
        What have we missed?
        Be constructive but thorough.
      participants: "all"
      context:
        include_full_history: true  # See both previous phases

  consensus:
    policy: "weighted_majority"
    threshold: 0.6
    max_attempts_per_conflict: 2  # Per phase

validation:
  requires_sequential_phases: true
  min_participants: 2
  phase_order: ["dreamer", "realist", "critic"]
```

## How It Works

### Phase 1: Dreamer

**Mindset**: "What if anything were possible?"

The Dreamer phase focuses purely on ideation:
- No technical constraints
- No budget limitations
- No criticism allowed
- Wild ideas encouraged

The facilitator prompts participants to imagine the ideal solution without worrying about feasibility.

### Phase 2: Realist

**Mindset**: "How do we actually do this?"

The Realist phase takes dreamer ideas and makes them practical:
- Timeline and milestones
- Resource requirements
- Technical approach
- Dependencies and risks

Participants see the dreamer output and ground it in reality.

### Phase 3: Critic

**Mindset**: "What could go wrong?"

The Critic phase stress-tests the realistic plan:
- Risk identification
- Edge cases
- Security concerns
- Maintenance burden

Constructive criticism that improves the plan, not just negativity.

## Prompt Template (by phase)

### Dreamer Prompt
```
You are {participant.role} in DREAMER mode.

=== TOPIC ===
{topic}

=== YOUR EXPERTISE ===
{participant.expertise}

---
DREAMER MODE: Think big! No constraints. What would be ideal?
- Ignore technical limitations
- Focus on what would delight users
- Propose bold ideas
- Don't criticize your own ideas yet

Provide 2-3 bold ideas with brief descriptions.
```

### Realist Prompt
```
You are {participant.role} in REALIST mode.

=== TOPIC ===
{topic}

=== DREAMER IDEAS ===
{dreamer_phase_synthesis}

=== YOUR EXPERTISE ===
{participant.expertise}

---
REALIST MODE: How do we actually build this?
- Take the dreamer ideas and make them practical
- Consider timeline, resources, dependencies
- Identify the MVP version
- Keep the vision but ground it in reality

For each viable idea, provide implementation approach.
```

### Critic Prompt
```
You are {participant.role} in CRITIC mode.

=== TOPIC ===
{topic}

=== DREAMER IDEAS ===
{dreamer_phase_synthesis}

=== REALIST PLANS ===
{realist_phase_synthesis}

=== YOUR EXPERTISE ===
{participant.expertise}

---
CRITIC MODE: What could go wrong?
- Identify risks and failure modes
- Note security or privacy concerns
- Highlight maintenance burden
- Suggest mitigations for each concern

Be constructive - improve the plan, don't just criticize.
```

## When to Use

- New feature design
- Product innovation sessions
- Creative problem solving
- When you need to separate ideation from criticism

## Strengths

- Protects creative thinking from early criticism
- Ensures practical evaluation happens
- Catches risks before implementation
- Well-understood, proven methodology

## Limitations

- Takes longer (3 sequential phases)
- May generate ideas that don't survive realist phase
- Requires discipline to stay in role per phase

## Research Basis

Based on the Disney Creative Strategy attributed to Robert Dilts' modeling of Walt Disney's creative process. Widely used in NLP and creative facilitation.

## Strategy hooks

Phase progression determined by `disney-phase-machine.md` via Step 2.10 (Phase Transition). No Step 2.2c per-round overrides emitted; facilitator skips override population for this strategy.

The Disney phase machine is gated on `PROFILE.has_phase_transition: true` (set only for the `brainstorm` workflow profile). When the facilitator returns `next: "phase"`, `phase-2-core.md` Step 2.10 delegates to `disney-phase-machine.md` for transition logic.

For full algorithmic spec (state machine, transitions, gating conditions), see `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/disney-phase-machine.md`.

# Six Thinking Hats Strategy

Based on Edward de Bono's Six Thinking Hats method. Forces comprehensive analysis by separating thinking modes.

## Configuration

```yaml
defaults:
  participation: "sequential"  # Participants cycle through hats
  phases:
    - name: "blue-hat-opening"
      prompt_suffix: |
        Define the focus and objectives.
        What question are we answering?
        What outcome do we need?
      participants: ["facilitator"]

    - name: "white-hat"
      prompt_suffix: |
        Facts only. No opinions.
        What information do we have?
        What information do we need?
        What are the gaps?
      participants: "all"
      context:
        include_synthesis_only: true

    - name: "red-hat"
      prompt_suffix: |
        Emotions and intuition only.
        What's your gut feeling about this?
        What concerns you intuitively?
        No justification needed.
      participants: "all"
      context:
        include_synthesis_only: true

    - name: "black-hat"
      prompt_suffix: |
        Caution and critical judgment.
        What could go wrong?
        What are the risks?
        Why might this fail?
      participants: "all"
      context:
        include_full_history: true

    - name: "yellow-hat"
      prompt_suffix: |
        Optimism and benefits.
        What are the advantages?
        Why would this work?
        What's the best-case scenario?
      participants: "all"
      context:
        include_full_history: true

    - name: "green-hat"
      prompt_suffix: |
        Creativity and alternatives.
        What other options exist?
        Can we modify the proposal?
        What's a completely different approach?
      participants: "all"
      context:
        include_full_history: true

    - name: "blue-hat-closing"
      prompt_suffix: |
        Process conclusion.
        Summarize what we learned from each hat.
        What's the recommendation?
        What are the next steps?
      participants: ["facilitator"]
      context:
        include_full_history: true

  consensus:
    policy: "facilitator_synthesis"
    threshold: null
    max_attempts_per_conflict: 1  # Single pass through hats

validation:
  requires_sequential_phases: true
  min_participants: 2
  phase_order: ["blue-hat-opening", "white-hat", "red-hat", "black-hat", "yellow-hat", "green-hat", "blue-hat-closing"]
```

## The Six Hats

| Hat | Color | Focus | Thinking Mode |
|-----|-------|-------|---------------|
| **Blue** | Process | Organization, meta-thinking | "What are we discussing?" |
| **White** | Facts | Information, data | "What do we know?" |
| **Red** | Emotions | Feelings, intuition | "What do we feel?" |
| **Black** | Caution | Risks, problems | "What could go wrong?" |
| **Yellow** | Optimism | Benefits, value | "What could go right?" |
| **Green** | Creativity | Alternatives, ideas | "What else is possible?" |

## How It Works

### Sequential Hat Phases

Unlike other strategies, Six Hats is strictly sequential:
1. All participants wear the same hat at the same time
2. Complete one hat before moving to next
3. Order matters: facts before emotions, caution before optimism

### Blue Hat Role

The Blue Hat (facilitator) has special responsibilities:
- **Opening**: Define focus, set agenda
- **Transitions**: Signal hat changes, summarize each phase
- **Closing**: Synthesize all perspectives, form recommendation

### Phase Execution

Within each hat phase:
1. Facilitator announces the hat
2. All participants respond in parallel (wearing same hat)
3. Facilitator synthesizes before next hat
4. No mixing of hat perspectives in a single response

## Prompt Template (by hat)

### White Hat
```
You are {participant.role} wearing the WHITE HAT.

=== TOPIC ===
{topic}

=== FOCUS (from Blue Hat) ===
{blue_hat_focus}

---
WHITE HAT MODE: Facts and information only.

Provide:
1. What facts do we know about this topic?
2. What data do we have?
3. What information is missing?
4. What assumptions are we making?

NO opinions, NO judgments, NO emotions. Just facts.
```

### Red Hat
```
You are {participant.role} wearing the RED HAT.

=== TOPIC ===
{topic}

=== FACTS (from White Hat) ===
{white_hat_synthesis}

---
RED HAT MODE: Emotions and intuition only.

Share:
1. What's your gut feeling about this?
2. What excites you?
3. What worries you intuitively?
4. What does your experience tell you?

No justification needed. Just feelings.
```

### Black Hat
```
You are {participant.role} wearing the BLACK HAT.

=== TOPIC ===
{topic}

=== PREVIOUS HAT SUMMARIES ===
{hat_summaries}

---
BLACK HAT MODE: Caution and critical judgment.

Identify:
1. What are the risks?
2. What could go wrong?
3. What are the weaknesses?
4. Why might this fail?

Be thorough but constructive.
```

### Yellow Hat
```
You are {participant.role} wearing the YELLOW HAT.

=== TOPIC ===
{topic}

=== PREVIOUS HAT SUMMARIES ===
{hat_summaries}

---
YELLOW HAT MODE: Optimism and benefits.

Identify:
1. What are the benefits?
2. What value does this create?
3. Why would this succeed?
4. What's the best-case outcome?

Be genuinely optimistic, not just countering Black Hat.
```

### Green Hat
```
You are {participant.role} wearing the GREEN HAT.

=== TOPIC ===
{topic}

=== PREVIOUS HAT SUMMARIES ===
{hat_summaries}

---
GREEN HAT MODE: Creativity and alternatives.

Explore:
1. What other approaches exist?
2. How could we modify the proposal?
3. What's a completely different solution?
4. What haven't we considered?

Think outside the box.
```

## When to Use

- Complex decisions with many dimensions
- When team tends toward groupthink
- When emotions are affecting judgment
- Comprehensive risk/benefit analysis

## Strengths

- Separates emotional from logical thinking
- Ensures all perspectives are considered
- Reduces conflict (everyone wears same hat)
- Structured and thorough

## Limitations

- Time-consuming (7 phases)
- Rigid structure may feel forced
- Requires discipline to stay in role
- Not ideal for quick decisions

## Research Basis

Edward de Bono's "Six Thinking Hats" (1985). Widely used in business and education. Adapted for LLM context with explicit phase separation and parallel within-phase execution.

In LLM multi-agent research, the PTFA framework (2024) showed heterogeneous thinking styles improve problem-solving by 47% over homogeneous approaches.

## Strategy hooks

No per-round overrides (wiring deferred to future phase, no empirical baseline yet).

### Documented contract (not yet exercised)

Six-hats has never been exercised in dogfood. The hook contract below is documented for completeness; wiring is blocked on baseline acquisition.

| Hook | Phase 2 step | Field added |
|------|--------------|-------------|
| Hat role assignment | Step 2.3c (participant response) | `hat_role: "white" \| "red" \| "black" \| "yellow" \| "green" \| "blue"` |
| Hat phase tracking | Step 2.6a (round summary entry) | `hat_phase: "blue-opening" \| "white-hat" \| "red-hat" \| "black-hat" \| "yellow-hat" \| "green-hat" \| "blue-closing"` |

### Status

- **No empirical baseline**: `/s2s:design --strategy six-hats` has never been run; structural behaviour is unverified.
- **Prerequisite for wiring**: capture an empirical baseline by running `/s2s:design --strategy six-hats --verbose --diagnostic` on dogfood and freezing a structural summary in `.s2s/test-baselines/`.
- **Wiring deferred** until baseline exists. The opening line phrase `"No per-round overrides"` signals the facilitator at Step 2.2c to skip override population in the meantime (per `strategy-hooks.md` §8 future-wiring contract).

For full hook contract details, see `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/strategy-hooks.md` §5 (`participant_response.hat_role`) and §6 (`round_summary.hat_phase`).

# Creating a New Roundtable Strategy

This guide explains how to add a new facilitation strategy to the roundtable system.

## Overview

Strategies define how roundtable discussions are conducted. Each strategy specifies:
- Participation mode (parallel or sequential)
- Phases (single or multi-phase)
- Consensus policy
- Prompt modifications per phase

## File Location

Create your strategy at:
```
skills/roundtable-strategies/references/{strategy-name}.md
```

## Strategy File Structure

```markdown
# {Strategy Name} Strategy

## Overview
{Brief description of when and why to use this strategy}

## Configuration

```yaml
defaults:
  participation: "parallel" | "sequential"
  max_rounds_per_phase: 3
  phases:
    - name: "{phase-1}"
      prompt_suffix: |
        {Instructions for this phase}
      participants: "all" | ["specific", "list"]
      context:
        show_previous_phases: false
        show_conflicts: true
    - name: "{phase-2}"
      prompt_suffix: |
        {Instructions for this phase}
      participants: "all"
      context:
        show_previous_phases: true
        show_conflicts: true
  consensus:
    policy: "weighted_majority" | "unanimous" | "facilitator_judgment"
    threshold: 0.6

validation:
  requires_sequential_phases: true | false
  min_participants: 2
  max_attempts_per_conflict: 3
```

## Phase Details

### Phase 1: {Phase Name}
{Detailed description}

### Phase 2: {Phase Name}
{Detailed description}

## Facilitator Guidance
{How facilitator should adapt behavior for this strategy}

## Example Session
{Sample flow with example questions and responses}
```

## Step-by-Step Process

### Step 1: Define Strategy Purpose

Decide:
- What problem does this strategy solve?
- When should users choose it?
- How does it differ from existing strategies?

### Step 2: Choose Participation Mode

| Mode | Use When |
|------|----------|
| `parallel` | Independent perspectives needed, prevent sycophancy |
| `sequential` | Building on ideas, iterative refinement |

### Step 3: Define Phases

For single-phase strategies (like Standard):
```yaml
phases:
  - name: "discussion"
    prompt_suffix: |
      Provide your perspective on this topic.
```

For multi-phase strategies (like Disney):
```yaml
phases:
  - name: "ideation"
    prompt_suffix: |
      Focus on creative ideas. No constraints.
    context:
      show_conflicts: false
  - name: "evaluation"
    prompt_suffix: |
      Evaluate the ideas practically.
    context:
      show_previous_phases: true
```

### Step 4: Set Consensus Policy

| Policy | Description |
|--------|-------------|
| `simple_majority` | >50% agree |
| `weighted_majority` | Confidence-weighted, threshold configurable |
| `unanimous` | All must agree |
| `consent` | No strong objections |
| `facilitator_judgment` | Facilitator decides (for Debate) |

### Step 5: Add Auto-Detection Keywords

Edit `skills/roundtable-strategies/SKILL.md` to add your strategy to the auto-detection table:

```markdown
## Strategy Auto-Detection

| Keywords | Strategy |
|----------|----------|
| creative, brainstorm, ideation | disney |
| compare, evaluate, vs | debate |
| {your-keywords} | {your-strategy} |
```

### Step 6: Test the Strategy

```bash
# Test with explicit strategy flag
/s2s:roundtable "Test topic" --strategy {your-strategy}

# Test auto-detection
/s2s:roundtable "Topic with your-keywords"
```

## Example: Creating a "Structured Debate" Strategy

```markdown
# Structured Debate Strategy

## Overview
A formal debate with timed speaking positions and structured rebuttals.
Use when evaluating contentious decisions with clear alternatives.

## Configuration

```yaml
defaults:
  participation: "parallel"
  phases:
    - name: "opening"
      prompt_suffix: |
        Present your opening position on this topic.
        State your main argument clearly.
        You have one chance to make your case.
      participants: "all"
      context:
        show_previous_phases: false
    - name: "rebuttal"
      prompt_suffix: |
        Review the opening statements from others.
        Address their strongest points.
        Defend your position.
      participants: "all"
      context:
        show_previous_phases: true
    - name: "closing"
      prompt_suffix: |
        Make your final argument.
        Summarize why your position is strongest.
      participants: "all"
      context:
        show_previous_phases: true
  consensus:
    policy: "facilitator_judgment"
    threshold: null

validation:
  requires_sequential_phases: true
  min_participants: 2
```

## When to Use
- Evaluating major architectural decisions
- Comparing technology alternatives
- Assessing controversial proposals
```

## Checklist

- [ ] Created `references/{strategy}.md` with configuration
- [ ] Defined participation mode
- [ ] Defined phases with prompt_suffix
- [ ] Set consensus policy
- [ ] Added validation rules
- [ ] Updated SKILL.md with auto-detection keywords
- [ ] Tested with explicit --strategy flag
- [ ] Tested auto-detection

---
*See [README.md](./README.md) for other extension guides*

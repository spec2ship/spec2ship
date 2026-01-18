---
name: Roundtable Strategies
description: "This skill should be used when starting a roundtable session, facilitating technical discussions,
  or orchestrating multi-agent deliberations. Provides facilitation strategies including standard round-robin,
  Disney creative method, structured debate, consensus-driven, and Six Thinking Hats.
  Auto-detect: When topic mentions 'creative', 'innovation', 'new feature' → disney.
  When topic mentions 'vs', 'compare', 'evaluate', 'choose' → debate.
  When topic mentions 'urgent', 'fast', 'quick', 'asap' → consensus-driven.
  When topic mentions 'comprehensive', 'thorough', 'all angles', 'deep analysis' → six-hats."
version: 1.1.0
---

# Roundtable Strategies

## Purpose

This skill provides facilitation strategies for s2s Roundtable sessions. Each strategy defines how participants interact, what phases the discussion follows, and how consensus is reached.

## When to Use This Skill

- Starting a `/s2s:roundtable` session
- Running `/s2s:specs` requirements gathering
- Running `/s2s:design` architecture design
- Custom brainstorming or decision-making sessions

## Strategy Auto-Detection

When no strategy is specified, analyze the topic for keywords to recommend appropriate strategy:

| Keywords in Topic | Recommended Strategy | Reason |
|-------------------|---------------------|--------|
| creative, innovation, new, brainstorm, ideation | **disney** | Creative ideation benefits from Dreamer→Realist→Critic flow |
| vs, compare, evaluate, choose, decide, between | **debate** | Comparing options needs Pro/Con analysis |
| urgent, fast, quick, asap, time-sensitive | **consensus-driven** | Speed-focused, converging quickly |
| comprehensive, thorough, all angles, deep, complete | **six-hats** | Complete analysis from all perspectives |
| *(no match)* | **standard** | Balanced default for most discussions |

### Auto-Detection Example

```
Topic: "Creative approach for new authentication feature"
        ^^^^^^^^         ^^^
        creative         new

→ Recommended: disney strategy
```

## Available Strategies

| Strategy | Best For | Phases | Participation |
|----------|----------|--------|---------------|
| **standard** | General discussions, balanced input | Single phase, multiple rounds | parallel |
| **disney** | Creative problem-solving, innovation | 3 phases: Dreamer, Realist, Critic | sequential (phases) |
| **debate** | Evaluating controversial options | 2 sides: Pro vs Con | parallel (per side) |
| **consensus-driven** | Fast decision-making | Converging rounds | parallel |
| **six-hats** | Comprehensive analysis | 6 thinking modes | sequential |

---

## Workflow-Specific Defaults

Each workflow has a recommended default strategy and participant set:

| Workflow | Default Strategy | Default Participants | Rationale |
|----------|------------------|---------------------|-----------|
| **specs** | consensus-driven | PM, UX-Researcher, BA, QA | Requirements need broad agreement, not debate |
| **design** | debate | Architect, Security, TechLead, DevOps | Architecture trade-offs benefit from Pro/Con analysis |
| **brainstorm** | disney (forced) | Variable (--participants) | Creative exploration requires Dreamer→Realist→Critic |

### Artifact Types by Workflow

| Workflow | Primary Artifacts | Secondary Artifacts |
|----------|-------------------|---------------------|
| **specs** | REQ-*, BR-*, NFR-* | OQ-*, CONF-*, EX-* |
| **design** | ARCH-*, COMP-*, INT-* | ADR-*, OQ-*, CONF-* |
| **brainstorm** | IDEA-*, RISK-*, MIT-* | OQ-* |

### Strategy-Workflow Compatibility

| Strategy | specs | design | brainstorm |
|----------|-------|--------|------------|
| **standard** | ✓ | ✓ | - |
| **consensus-driven** | ✓ (default) | ✓ | - |
| **debate** | ✓ | ✓ (default) | - |
| **disney** | - | - | ✓ (forced) |
| **six-hats** | ✓ | ✓ | - |

**Note**: Brainstorm workflow ALWAYS uses disney strategy regardless of --strategy flag.

## Strategy Selection Guide

### Use `standard` when:
- You need balanced perspectives from all participants
- The topic doesn't require specialized phases
- Time is limited and you want direct input

### Use `disney` when:
- Exploring creative solutions
- Building new features or products
- You need to separate ideation from criticism

### Use `debate` when:
- Evaluating trade-offs between options
- The decision is controversial or polarizing
- You want to stress-test a proposal

### Use `consensus-driven` when:
- Speed is important
- The group needs to converge quickly
- Previous rounds have narrowed options

### Use `six-hats` when:
- Comprehensive analysis is needed
- You want to avoid groupthink
- The topic has emotional and logical dimensions

## Configuration Integration

Strategies are loaded via `config.yaml`:

```yaml
roundtable:
  strategy: "disney"  # Loads skills/roundtable-strategies/disney.md

  # Optional overrides (warning if conflicts with strategy)
  overrides:
    participation: "sequential"
```

## Strategy File Structure

Each strategy file (`standard.md`, `disney.md`, etc.) defines:

```yaml
defaults:
  participation: "parallel"  # How participants interact
  phases:
    - name: "phase-name"
      prompt_suffix: "Additional instructions for this phase"
      participants: "all"  # or specific list
  consensus:
    policy: "weighted_majority"
    threshold: 0.6
validation:
  requires_sequential_phases: false
  min_participants: 2
```

## Reference Files

- **`references/standard.md`** - Standard round-robin details
- **`references/disney.md`** - Disney Creative Strategy details
- **`references/debate.md`** - Structured debate details
- **`references/consensus-driven.md`** - Fast convergence details
- **`references/six-hats.md`** - De Bono's Six Hats details

## Quick Reference

### Participation Modes

| Mode | Behavior | Mitigates |
|------|----------|-----------|
| `parallel` | All respond simultaneously | Sycophancy, echo chambers |
| `sequential` | One at a time, sees previous | Enables building on ideas |
| `targeted` | Facilitator picks who speaks | Focused expertise |

### Consensus Policies

| Policy | Description |
|--------|-------------|
| `simple_majority` | >50% agreement |
| `weighted_majority` | Confidence-weighted votes |
| `unanimous` | All must agree |

### Escalation

When consensus fails after `max_attempts`, escalate to user with:
- All positions clearly presented
- Trade-offs explained
- Facilitator recommendation (if configured)

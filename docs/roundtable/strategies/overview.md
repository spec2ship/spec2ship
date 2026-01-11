# Strategy Overview

Roundtable strategies define how discussions are facilitated, including participant interaction patterns, phases, and consensus mechanisms.

## Available Strategies

| Strategy | Phases | Participation | Best For |
|----------|--------|---------------|----------|
| Standard | 1 (discussion) | Parallel | General discussions |
| Disney | 3 (dreamer, realist, critic) | Sequential phases | Creative solutions |
| Debate | 3 (opening, rebuttal, closing) | Parallel per side | Option evaluation |
| Consensus-Driven | 3 (proposal, refinement, convergence) | Parallel | Fast decisions |
| Six Hats | 7 (blue, white, red, black, yellow, green, blue) | Sequential | Comprehensive analysis |

## Participation Modes

### Parallel
- All participants respond simultaneously
- Prevents sycophancy (no one sees others' responses)
- Faster execution
- Used by: Standard, Debate (per side), Consensus-Driven

### Sequential
- Participants respond one at a time
- Can build on previous responses
- Used by: Disney (between phases), Six Hats

### Targeted
- Facilitator decides who speaks
- Based on topic relevance
- Can be combined with parallel/sequential

## Strategy Selection Guide

```
┌─────────────────────────────────────────────────────────────────┐
│ What kind of discussion?                                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Creative / Exploratory?                                        │
│  └─ YES → Disney (separate ideation from criticism)            │
│                                                                 │
│  Choosing between options?                                      │
│  └─ YES → Debate (Pro/Con evaluation)                          │
│                                                                 │
│  Need quick decision?                                           │
│  └─ YES → Consensus-Driven (fast convergence)                  │
│                                                                 │
│  Complex with many dimensions?                                  │
│  └─ YES → Six Hats (comprehensive analysis)                    │
│                                                                 │
│  General discussion?                                            │
│  └─ YES → Standard (balanced input)                            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Strategy Structure

Each strategy is defined in a skill file with:

```yaml
defaults:
  participation: "parallel"  # How participants interact
  phases:
    - name: "phase-name"
      prompt_suffix: "Additional instructions"
      participants: "all"  # or specific list
  consensus:
    policy: "weighted_majority"
    threshold: 0.6

validation:
  requires_sequential_phases: false
  min_participants: 2
```

## Consensus Policies

| Policy | Description | Threshold |
|--------|-------------|-----------|
| `simple_majority` | >50% agree | N/A |
| `weighted_majority` | Confidence-weighted | 0.6 default |
| `unanimous` | All must agree | N/A |
| `consent` | No blocks | N/A |
| `facilitator_judgment` | Facilitator synthesizes | N/A |

## Workflow Type Defaults

Different workflows default to different strategies:

| Workflow | Default Strategy | Rationale |
|----------|------------------|-----------|
| `specs` | consensus-driven | Fast requirement agreement |
| `design` | debate | Evaluate architectural options |
| `brainstorm` | disney | Creative ideation |

## Creating Custom Strategies

See [Creating New Strategies](../../extending/new-strategy.md) for guidance on building custom facilitation strategies.

---
*For detailed information on each strategy, see individual strategy documentation.*

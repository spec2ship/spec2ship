# Roundtable Configuration

Configuration for roundtable behavior is stored in `.s2s/config.yaml`.

## Full Configuration Schema

```yaml
roundtable:
  # === STRATEGY ===
  # Default facilitation strategy
  # Loaded from skills/roundtable-strategies/references/{strategy}.md
  strategy: "standard"  # standard | disney | debate | consensus-driven | six-hats

  # === STRATEGY OVERRIDES (optional) ===
  # Override strategy defaults - warning displayed if conflicts
  # overrides:
  #   participation: "sequential"  # Override parallel default

  # === PARTICIPANTS ===
  participants:
    # Default participants when not specified by workflow
    default:
      - software-architect
      - technical-lead

    # Participants per workflow type
    by_workflow_type:
      specs:
        - product-manager
        - software-architect
        - qa-lead
      design:
        - software-architect
        - technical-lead
        - devops-engineer
      brainstorm:
        - product-manager
        - software-architect
        - technical-lead
        - devops-engineer

  # === ESCALATION ===
  escalation:
    enabled: true
    triggers:
      # Escalate after N failed consensus attempts per conflict
      no_consensus_after_attempts: 3

      # Escalate if any participant confidence below threshold
      confidence_below: 0.5

      # Escalate on these keywords in topic/responses
      critical_keywords:
        - security
        - must-have
        - blocking
        - legal

    # How to present escalation to user
    presentation:
      show_all_positions: true
      show_rationale: true
      facilitator_recommendation: true
```

## Configuration Options

### Strategy

The default facilitation strategy:

| Value | Description | Best For |
|-------|-------------|----------|
| `standard` | Round-robin, equal voices | General discussions |
| `disney` | Dreamer → Realist → Critic | Creative solutions |
| `debate` | Pro vs Con | Evaluating options |
| `consensus-driven` | Fast convergence | Quick decisions |
| `six-hats` | De Bono's method | Comprehensive analysis |

### Participants

Available participant agents:

| Agent | Perspective | Expertise |
|-------|-------------|-----------|
| `product-manager` | Business value | User needs, priorities |
| `software-architect` | Architecture | Structure, patterns |
| `technical-lead` | Implementation | Tech stack, code |
| `qa-lead` | Quality | Testing, edge cases |
| `devops-engineer` | Operations | Deploy, infrastructure |

### Escalation Triggers

| Trigger | Description |
|---------|-------------|
| `no_consensus_after_attempts` | Number of rounds before escalating unresolved conflict |
| `confidence_below` | Minimum confidence (0.0-1.0) before escalation |
| `critical_keywords` | Topics requiring human decision |

## Override from Command Line

Command line flags override config values:

```bash
# Override strategy
/s2s:roundtable:start "topic" --strategy disney

# Override participants
/s2s:roundtable:start "topic" --participants architect,devops

# Workflow-specific
/s2s:specs --strategy consensus-driven
/s2s:design --strategy debate
```

## Per-Project Customization

Each project can have its own config in `.s2s/config.yaml`. The template at `templates/project/config.yaml` provides defaults.

## Strategy Skill Files

Strategy behavior is defined in skill files:

```
skills/roundtable-strategies/
├── SKILL.md                      # Overview
└── references/
    ├── standard.md               # Standard strategy details
    ├── disney.md                 # Disney strategy details
    ├── debate.md                 # Debate strategy details
    ├── consensus-driven.md       # Consensus-driven details
    └── six-hats.md               # Six Hats details
```

Each strategy skill defines:
- Default participation mode
- Phases (if any)
- Consensus policy
- Validation rules

---
*See [Glossary](./glossary.md) for terminology definitions.*

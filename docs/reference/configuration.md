# Configuration Reference

Spec2Ship configuration is stored in `.s2s/config.yaml`.

## Full Configuration Schema

```yaml
# .s2s/config.yaml

roundtable:
  # === LIMITS ===
  limits:
    min_rounds: 3        # Minimum rounds before concluding
    max_rounds: 20       # Maximum rounds before force-conclude

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
        - business-analyst
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
      # Escalate if same conflict persists for N rounds
      max_rounds_per_conflict: 3

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

# === OUTPUT FORMATS (optional) ===
# format:
#   specs: "srs-lite"      # Output format for /s2s:specs
#   design: "arc42-lite"   # Output format for /s2s:design

# === STRATEGY OVERRIDES (optional) ===
# strategy_by_workflow:
#   specs: "consensus-driven"
#   design: "debate"
#   brainstorm: "disney"
```

## Configuration Sections

### Limits

| Option | Default | Description |
|--------|---------|-------------|
| `min_rounds` | 3 | Minimum rounds before concluding |
| `max_rounds` | 20 | Maximum rounds before force-conclude |

### Participants

Configure which agents participate in each workflow:

| Workflow | Default Participants |
|----------|---------------------|
| `specs` | product-manager, business-analyst, qa-lead |
| `design` | software-architect, technical-lead, devops-engineer |
| `brainstorm` | product-manager, software-architect, technical-lead, devops-engineer |

**Available agents**:
- `product-manager` - User value, priorities
- `business-analyst` - Domain modeling, use cases
- `qa-lead` - Quality, testing, edge cases
- `ux-researcher` - User needs, accessibility
- `software-architect` - System structure, patterns
- `technical-lead` - Implementation, tech stack
- `devops-engineer` - Deployment, infrastructure
- `security-champion` - Threat modeling, OWASP
- `documentation-specialist` - API docs, guides
- `claude-code-expert` - Plugin architecture
- `oss-community-manager` - Open source focus

### Escalation

| Trigger | Default | Description |
|---------|---------|-------------|
| `max_rounds_per_conflict` | 3 | Rounds before escalating unresolved conflict |
| `confidence_below` | 0.5 | Minimum confidence before escalation |
| `critical_keywords` | security, must-have, blocking, legal | Keywords requiring human decision |

### Output Formats

Optional format overrides for generated documentation:

| Format | Description |
|--------|-------------|
| `srs-lite` | Simplified SRS format (default for specs) |
| `srs-full` | Full IEEE 830 format |
| `arc42-lite` | Essential arc42 sections (default for design) |
| `arc42-full` | Complete arc42 template |

## Command Line Overrides

Command line flags take precedence over config:

```bash
# Override strategy
/s2s:specs --strategy debate

# Override participants
/s2s:design --participants architect,security-champion

# Add to defaults
/s2s:specs --participants +ux-researcher
```

## Priority Order

1. Command line flags (highest)
2. `.s2s/config.yaml`
3. Built-in defaults (lowest)

## Environment Variables

| Variable | Description |
|----------|-------------|
| `S2S_VERBOSE` | Enable verbose mode by default |
| `S2S_INTERACTIVE` | Enable interactive mode by default |

## Project Template

New projects get configuration from `templates/project/config.yaml`. Customize this template for organization-wide defaults.

---

*See also: [Commands](./commands.md) | [Concepts: Sessions](../concepts/sessions.md)*

# Extending Spec2Ship

This guide explains how to extend Spec2Ship with new strategies, skills, and agents.

## Extension Types

| Extension | Description | Guide |
|-----------|-------------|-------|
| **Agent** | New roundtable participant role | [new-agent.md](./new-agent.md) |
| **Skill** | New knowledge base (patterns, standards) | [new-skill.md](./new-skill.md) |
| **Strategy** | New roundtable facilitation method | [new-strategy.md](./new-strategy.md) |

## Quick Reference

### Add a New Agent

1. Create `agents/roundtable/{agent-name}.md`
2. Set `tools: []` (agents receive context inline)
3. Add required sections:
   - Workflow-Specific Focus
   - Strategy-Specific Behavior
   - Critical Stance
4. Use supported color (blue, cyan, green, orange, purple, red, yellow)
5. Test with `/s2s:roundtable:start "topic" --participants your-agent`

### Add a New Skill

1. Create `skills/{skill-name}/SKILL.md`
2. Use third-person description with trigger phrases
3. Keep under 2,000 words
4. Optionally add `references/` and `examples/`
5. Reference from agents: `skills: skill-name`

### Add a New Strategy

1. Create `skills/roundtable-strategies/references/{strategy}.md`
2. Define: participation mode, phases, consensus policy
3. Add auto-detection keywords to `SKILL.md`
4. Test with `/s2s:roundtable:start "topic" --strategy {strategy}`

## Architecture Context

```
Spec2Ship Extension Points
───────────────────────────

agents/
├── roundtable/               ◄── Add participants here
│   ├── facilitator.md        # Orchestrator (don't modify)
│   ├── product-manager.md
│   ├── software-architect.md
│   └── {your-agent}.md       ◄── New agent
└── validation/
    └── session-observer.md

skills/
├── roundtable-strategies/    ◄── Add strategies here
│   ├── SKILL.md
│   └── references/
│       ├── standard.md
│       ├── disney.md
│       └── {your-strategy}.md   ◄── New strategy
│
├── arc42-templates/          ◄── Add knowledge skills here
├── iso25010-requirements/
├── threat-modeling/
├── ddd-strategic/
└── {your-skill}/             ◄── New skill
    └── SKILL.md

commands/                     ◄── Add commands here (advanced)
├── {your-command}.md
└── {your-command}/
    └── subcommand.md
```

## Existing Extensions

### Participant Agents (12)

| Agent | Primary Workflow | Skills |
|-------|------------------|--------|
| product-manager | specs | - |
| business-analyst | specs | ddd-strategic |
| qa-lead | specs | iso25010-requirements |
| ux-researcher | specs | - |
| software-architect | design | arc42-templates |
| technical-lead | design | - |
| devops-engineer | design | arc42-templates |
| security-champion | design | threat-modeling |
| documentation-specialist | override | - |
| claude-code-expert | override | - |
| oss-community-manager | override | - |

### Skills (8)

| Skill | Used By |
|-------|---------|
| roundtable-execution | workflow commands |
| roundtable-strategies | workflow commands, facilitator |
| arc42-templates | architect, devops |
| iso25010-requirements | qa-lead |
| threat-modeling | security-champion |
| ddd-strategic | business-analyst |
| madr-decisions | facilitator |
| conventional-commits | git-commit skill |

### Strategies (5)

| Strategy | Phases | Default In |
|----------|--------|------------|
| standard | 1 | - |
| disney | 3 | brainstorm |
| debate | 4 | design |
| consensus-driven | 3 | specs |
| six-hats | 7 | - |

## Best Practices

### For Agents

- Set `tools: []` - agents receive context inline
- Add all required sections (Workflow-Specific, Strategy-Specific, Critical Stance)
- Define unique perspective (don't overlap with existing agents)
- Use supported colors only
- Test in roundtable sessions

### For Skills

- Keep SKILL.md under 2,000 words
- Use progressive disclosure (references/)
- Include 3-5 trigger phrases
- Third-person description
- No enforcement - skills provide context only

### For Strategies

- Define clear phase boundaries
- Include consensus policy
- Document when to use
- Test with different topics

## Testing Extensions

```bash
# Test a new agent
/s2s:roundtable:start "Test topic" --participants your-agent --verbose

# Test a new strategy
/s2s:roundtable:start "Test topic" --strategy your-strategy --verbose

# Test skills loading (agent will have access to declared skills)
/s2s:design --verbose
```

---

*Part of Spec2Ship Documentation*

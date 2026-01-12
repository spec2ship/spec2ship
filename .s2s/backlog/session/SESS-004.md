# SESS-004: Workflow Configuration Wizard

**Status**: draft
**Priority**: low
**Category**: Session
**Created**: 2026-01-11
**Updated**: 2026-01-11

## Context

Currently, roundtable configuration (rounds, participants, strategy) is either default or specified via command flags. Users unfamiliar with s2s options may not know what to configure.

A wizard would:
- Guide users through configuration options
- Explain what each option does
- Generate appropriate config for their use case

## Proposal

### 1. Wizard Trigger

- `/s2s:specs --wizard` or `/s2s:wizard specs`
- First-time run could suggest wizard mode

### 2. Wizard Questions

- Project type: (web app, API, library, CLI, etc.)
- Team size: (solo, small team, large team)
- Formality level: (lightweight, standard, formal)
- Time constraint: (quick, thorough)

### 3. Generated Config

```yaml
# Based on wizard answers:
roundtable:
  strategy: "consensus-driven"  # For small teams
  limits:
    min_rounds: 2  # Quick mode
    max_rounds: 5
  participants:
    exclude: ["devops-engineer"]  # Solo projects
```

### 4. Save Preferences

- Store in `.s2s/config.yaml` for future sessions
- Allow override per-session

### Files to Create/Modify
- `commands/wizard.md` (new) or add --wizard to existing commands
- `.s2s/config.yaml` template

## Acceptance Criteria

- [ ] Wizard can be triggered with flag
- [ ] All key configuration options covered
- [ ] Config is generated and saved
- [ ] Subsequent runs use saved config

## Related

- Related to: INIT-001 (structure options)
- Related to: RT-003 (Roundtable templates)
- Supersedes: Old P2-9

## Open Questions

- Should wizard be a separate command or flag on workflow commands?
- How to balance thoroughness vs. cognitive load?
- Should wizard suggest based on project analysis?

## Notes

The wizard could also suggest appropriate roundtable templates (RT-003) based on answers.

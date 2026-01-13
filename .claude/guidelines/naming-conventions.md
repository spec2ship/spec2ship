# Naming Conventions

This document defines naming patterns for all Spec2Ship identifiers.

---

## Artifact IDs

Format: `{TYPE}-{NNN}`

| Type | Prefix | Example |
|------|--------|---------|
| Requirement | REQ | REQ-001, REQ-042 |
| Business Rule | BR | BR-001, BR-015 |
| Non-Functional Requirement | NFR | NFR-001, NFR-008 |
| Exclusion | EX | EX-001, EX-003 |
| Open Question | OQ | OQ-001, OQ-012 |
| Conflict | CONF | CONF-001, CONF-005 |
| Architecture Decision | ARCH | ARCH-001, ARCH-023 |
| Component | COMP | COMP-001, COMP-010 |
| Interface | INT | INT-001, INT-007 |
| Idea | IDEA | IDEA-001, IDEA-050 |
| Risk | RISK | RISK-001, RISK-018 |
| Mitigation | MIT | MIT-001, MIT-020 |

**Rules**:
- Always 3 digits, zero-padded
- Sequential within session, type-scoped
- IDs are immutable once assigned

---

## Session IDs

Format: `{YYYYMMDD}-{workflow}-{project-slug}`

Examples:
- `20260110-specs-elfgiftrush`
- `20260115-design-spec2ship`
- `20260120-brainstorm-new-feature`

**Rules**:
- Date is session start date
- Workflow is one of: specs, design, brainstorm
- Project slug is lowercase, hyphenated

---

## Plan IDs

Format: `{YYYYMMDD}-{HHMMSS}-{slug}`

Examples:
- `20241228-143022-user-auth`
- `20260105-091500-api-refactor`

**Rules**:
- Timestamp is plan creation time
- Slug is descriptive, lowercase, hyphenated
- Max 30 characters for slug

---

## Branch Names

Format: `feature/F{NN}-{slug}`

Examples:
- `feature/F01-user-auth`
- `feature/F12-payment-integration`

**Rules**:
- Two-digit feature number, zero-padded
- Slug matches plan slug
- Used for implementation tracking

---

## File Paths

### Session Files
```
.s2s/sessions/{session-id}.yaml           # Main session file
.s2s/sessions/{session-id}/               # Verbose dumps folder
.s2s/sessions/{session-id}/rounds/        # Per-round traces
```

### Configuration
```
.s2s/config.yaml                          # Project configuration
.s2s/state.yaml                           # Current state
.s2s/CONTEXT.md                           # Project context
```

### Output Documents
```
docs/specifications/requirements.md        # specs output
docs/architecture/                         # design output
docs/brainstorm/                          # brainstorm output
```

---

## Command Structure

Format: `/s2s:{category}:{operation}`

Examples:
- `/s2s:init`
- `/s2s:specs`
- `/s2s:plan:create`
- `/s2s:roundtable:start`
- `/s2s:session:validate`

**Rules**:
- Top-level commands: init, specs, design, brainstorm, plan
- Subcommands: category:operation
- Flags: --flag-name (kebab-case)

---

## Agent Names

Format: `roundtable-{role}` or `{category}-{function}`

Roundtable:
- `roundtable-facilitator`
- `roundtable-product-manager`
- `roundtable-software-architect`

Exploration:
- `project-detector`
- `codebase-analyzer`
- `requirements-mapper`

---

## YAML Field Names

Use snake_case for all YAML fields:

```yaml
# Correct
workflow_type: specs
done_when:
  min_requirements: 3
agent_state:
  last_round: 2

# Wrong
workflowType: specs
doneWhen:
  minRequirements: 3
agentState:
  lastRound: 2
```

---

## Architecture Decision Records

Format: `NNNN-{slug}.md` (MADR official format)

Examples:
- `0001-component-separation.md`
- `0006-session-embedded-artifacts.md`

**Rules**:
- 4-digit zero-padded number, sequential
- Lowercase slug, hyphenated
- Use MADR format (Markdown Any Decision Records)
- Internal ADRs: `.s2s/decisions/`
- Public ADRs: `docs/architecture/decisions/`

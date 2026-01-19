# Consistency Checks (CONS-*)

Detailed definitions for consistency checks. These verify that the 4 workflow commands (specs, design, brainstorm, roundtable) maintain consistent patterns and behavior.

---

## Target Commands

| Command | File | Lines (approx) |
|---------|------|----------------|
| specs | commands/specs.md | ~1640 |
| design | commands/design.md | ~1600 |
| brainstorm | commands/brainstorm.md | ~1600 |
| roundtable | commands/roundtable.md | ~360 (delegates to skill) |

---

## CONS-001: Session ID Format

| Property | Value |
|----------|-------|
| **Severity** | medium |
| **Comparison** | All 4 commands |

### Purpose

All commands should generate session IDs in the same format for consistency and predictability.

### Expected Format

```
{YYYYMMDD}-{HHMMSS}-{workflow_type}-{topic-slug}
```

**Examples**:
- `20260118-143022-specs-user-authentication`
- `20260118-150000-design-api-architecture`
- `20260118-160000-brainstorm-new-features`
- `20260118-170000-roundtable-code-review`

### Verification

1. Find session ID generation in each command
2. Extract the format pattern used
3. Compare patterns across commands
4. Flag differences

### Evidence Schema

```yaml
check: CONS-001
status: pass | fail
comparison:
  specs.md:
    pattern: "{YYYYMMDD}-{HHMMSS}-specs-{slug}"
    line: 234
  design.md:
    pattern: "{YYYYMMDD}-{HHMMSS}-design-{slug}"
    line: 230
  brainstorm.md:
    pattern: "{YYYYMMDD}-{HHMMSS}-brainstorm-{slug}"
    line: 228
  roundtable.md:
    pattern: "{YYYYMMDD}-{HHMMSS}-roundtable-{slug}"
    line: 207
differences: []
```

---

## CONS-002: Snapshot Structure

| Property | Value |
|----------|-------|
| **Severity** | medium |
| **Comparison** | All 4 commands |

### Purpose

All commands should create snapshot files with the same structure for consistency.

### Expected Files

| File | Required Fields |
|------|-----------------|
| context-snapshot.yaml | source, project_name, description, objectives, constraints, scope |
| config-snapshot.yaml | source, verbose, interactive, strategy, limits, escalation, participants |
| agenda.yaml | source, workflow, topics[] |

### Verification

1. Find snapshot generation sections in each command
2. Extract the fields being written
3. Compare field lists across commands
4. Flag missing or extra fields

### Evidence Schema

```yaml
check: CONS-002
status: pass | fail
files:
  context-snapshot:
    specs.md: ["source", "project_name", "description", "objectives", "constraints", "scope"]
    design.md: ["source", "project_name", "description", "objectives", "constraints", "scope"]
    brainstorm.md: ["source", "project_name", "description", "objectives", "constraints"]  # Missing scope?
    roundtable.md: ["source", "project_name", "description"]  # Minimal?
  config-snapshot:
    # ... similar comparison
differences:
  - file: "brainstorm.md"
    snapshot: "context-snapshot"
    issue: "Missing 'scope' field"
```

---

## CONS-003: Resume Logic

| Property | Value |
|----------|-------|
| **Severity** | high |
| **Comparison** | All 4 commands |

### Purpose

Resume logic should work the same across commands. This is critical for session recovery.

### Key Elements

| Element | Purpose |
|---------|---------|
| agent_state.facilitator.agent_id | Resume facilitator agent |
| agent_state.facilitator.last_round | Know current position |
| agent_state.facilitator.last_action | Know last completed step |
| agent_state.participants.{id} | Resume participant agents |
| Session status detection | Detect active vs closed |
| Resume parameter passing | Pass agent_id to Task |

### Expected Pattern

```markdown
**IF** agent_state.facilitator.agent_id exists:
- Pass resume: true to facilitator Task
- Pass agent_id for continuation
**ELSE**:
- Start fresh facilitator agent
```

### Verification

1. Find resume-related code in each command
2. Compare the logic flow:
   - How is existing session detected?
   - How is agent_state used?
   - What parameters passed to Task?
3. Flag differences in logic

### Evidence Schema

```yaml
check: CONS-003
status: pass | fail
comparison:
  specs.md:
    has_resume_logic: true
    agent_state_used: true
    resume_parameter: true
    lines: [345-380]
  design.md:
    has_resume_logic: true
    agent_state_used: true
    resume_parameter: true
    lines: [340-375]
  brainstorm.md:
    has_resume_logic: true
    agent_state_used: true
    resume_parameter: true
    lines: [338-373]
  roundtable.md:
    has_resume_logic: false  # Delegates to skill
    agent_state_used: false
    resume_parameter: false
    notes: "Relies on skill for resume logic"
differences:
  - command: "roundtable.md"
    issue: "Less detailed resume logic than inline commands"
    severity: high
```

---

## CONS-004: Verbose Dump Format

| Property | Value |
|----------|-------|
| **Severity** | medium |
| **Comparison** | All 4 commands |

### Purpose

Verbose dumps (when --verbose is used) should have consistent naming and structure.

### Expected Naming

```
{round:3d}-{phase:2d}-{actor}.yaml

Examples:
001-01-facilitator-question.yaml
001-02-product-manager.yaml
001-02-business-analyst.yaml
001-03-facilitator-synthesis.yaml
```

### Expected Structure

**Facilitator dumps**:
```yaml
round: 1
phase: 1  # or 3
actor: "facilitator"
timing:
  started_at: "..."
  completed_at: "..."
tokens:
  input: N
  output: N
prompt: "..."
response: "..."
```

**Participant dumps**:
```yaml
round: 1
phase: 2
actor: "{participant-id}"
timing: {...}
tokens: {...}
input:
  question: "..."
  context: {...}
result: {...}
```

### Verification

1. Find verbose dump generation in each command
2. Compare naming patterns
3. Compare field structures
4. Flag inconsistencies

### Evidence Schema

```yaml
check: CONS-004
status: pass | fail
comparison:
  naming_pattern:
    specs.md: "{round:3d}-{phase:2d}-{actor}.yaml"
    design.md: "{round:3d}-{phase:2d}-{actor}.yaml"
    brainstorm.md: "{round:3d}-{phase:2d}-{actor}.yaml"
    roundtable.md: "delegates to skill"
  structure_consistent: true | false
differences: []
```

---

## CONS-005: Error Handling

| Property | Value |
|----------|-------|
| **Severity** | high |
| **Comparison** | All 4 commands |

### Purpose

Error handling should be consistent across commands for predictable behavior.

### Expected Patterns

| Error | Expected Handling |
|-------|-------------------|
| Session file write failure | STOP immediately, report error |
| Facilitator Task failure | Use fallback question, continue |
| Participant Task failure | Continue with remaining participants |
| Config file missing | Use defaults, warn user |
| Session not found | Clear error message, suggest action |

### Reference

See: `skills/roundtable-execution/references/error-handling.md`

### Verification

1. Find error handling sections in each command
2. Compare handling for each error type
3. Flag missing or different handling

### Evidence Schema

```yaml
check: CONS-005
status: pass | fail
comparison:
  session_write_failure:
    specs.md: "STOP"
    design.md: "STOP"
    brainstorm.md: "STOP"
    roundtable.md: "delegates to skill"
  facilitator_failure:
    specs.md: "fallback question"
    design.md: "fallback question"
    brainstorm.md: "fallback question"
    roundtable.md: "delegates to skill"
  participant_failure:
    specs.md: "continue with others"
    design.md: "continue with others"
    brainstorm.md: "continue with others"
    roundtable.md: "delegates to skill"
differences: []
```

---

## CONS-006: Diagnostic Mode

| Property | Value |
|----------|-------|
| **Severity** | medium |
| **Comparison** | All 4 commands |

### Purpose

Diagnostic mode (--diagnostic flag) should work consistently across commands.

### Expected Behavior

1. Parse `--diagnostic` flag
2. Force `verbose = true` when diagnostic is enabled
3. Invoke session-observer agent after each round
4. Generate diagnostic report at session end

### Reference

See: `skills/roundtable-execution/references/diagnostic.md`

### Verification

1. Check --diagnostic flag parsing in each command
2. Check verbose forcing logic
3. Check observer invocation
4. Flag differences

### Evidence Schema

```yaml
check: CONS-006
status: pass | fail
comparison:
  flag_parsing:
    specs.md: true
    design.md: true
    brainstorm.md: true
    roundtable.md: true
  force_verbose:
    specs.md: true
    design.md: true
    brainstorm.md: true
    roundtable.md: true
  observer_invocation:
    specs.md: "inline"
    design.md: "inline"
    brainstorm.md: "inline"
    roundtable.md: "via diagnostic.md reference"
differences: []
```

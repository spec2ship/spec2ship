# Check Registry

Master list of all development checks and tests. Each check has a unique ID, severity, and reference to its full definition.

---

## INST-* (Instruction Quality)

Verify that command/agent files follow s2s patterns and guidelines.

| ID | Name | Severity | Target | Definition |
|----|------|----------|--------|------------|
| INST-001 | Imperative Voice | medium | commands | inst-checks.md |
| INST-002 | Explicit Tool Usage | high | commands | inst-checks.md |
| INST-003 | No Ambiguity | medium | commands | inst-checks.md |
| INST-004 | Template Alignment | medium | commands | inst-checks.md |
| INST-005 | Config Not Hardcoded | high | commands | inst-checks.md |
| INST-006 | ADR Compliance | high | commands, agents | inst-checks.md |

**Invoked by**: `/s2s:dev:check --instructions` or `/s2s:dev:check --all`

---

## CONS-* (Consistency)

Verify consistency across the 4 workflow commands (specs, design, brainstorm, roundtable).

| ID | Name | Severity | Comparison | Definition |
|----|------|----------|------------|------------|
| CONS-001 | Session ID Format | medium | All 4 commands | cons-checks.md |
| CONS-002 | Snapshot Structure | medium | All 4 commands | cons-checks.md |
| CONS-003 | Resume Logic | high | All 4 commands | cons-checks.md |
| CONS-004 | Verbose Dump Format | medium | All 4 commands | cons-checks.md |
| CONS-005 | Error Handling | high | All 4 commands | cons-checks.md |
| CONS-006 | Diagnostic Mode | medium | All 4 commands | cons-checks.md |

**Invoked by**: `/s2s:dev:check --consistency` or `/s2s:dev:check --all`

---

## RES-* (Resume Capability)

Verify that sessions can be correctly resumed from any interruption point.

| ID | Name | Severity | Interruption Point | Definition |
|----|------|----------|-------------------|------------|
| RES-001 | Facilitator agent_id | critical | After question | res-checks.md |
| RES-002 | Participant agent_ids | high | After responses | res-checks.md |
| RES-003 | last_round Tracking | critical | After each round | res-checks.md |
| RES-004 | last_action Tracking | high | After each step | res-checks.md |
| RES-005 | Resume Parameter | high | On resume | res-checks.md |
| RES-006 | Delta Calculation | medium | On resume | res-checks.md |
| RES-007 | Context Reconstruction | critical | On resume | res-checks.md |

**Invoked by**: `/s2s:dev:test --resume` or `/s2s:dev:test --all`

---

## EDGE-* (Edge Cases)

Verify handling of edge cases and error scenarios.

| ID | Name | Severity | Scenario | Definition |
|----|------|----------|----------|------------|
| EDGE-001 | Empty Session Resume | medium | 0 rounds completed | edge-scenarios.md |
| EDGE-002 | Mid-Round Resume | high | Interrupted during round | edge-scenarios.md |
| EDGE-003 | Partial Participant Failure | medium | Some participants fail | edge-scenarios.md |
| EDGE-004 | Max Rounds Reached | medium | Hit max_rounds limit | edge-scenarios.md |
| EDGE-005 | Early Topic Closure | medium | All topics closed before min | edge-scenarios.md |
| EDGE-006 | Escalation Handling | high | User decision required | edge-scenarios.md |
| EDGE-007 | YAML Special Characters | medium | Quotes, colons, pipes | edge-scenarios.md |

**Invoked by**: `/s2s:dev:test --edge` or `/s2s:dev:test --all`

---

## Severity Levels

| Level | Description | Action |
|-------|-------------|--------|
| critical | Must pass before release | Block release |
| high | Should pass, investigate failures | Review before release |
| medium | Nice to have, warnings acceptable | Document known issues |

---

## Quick Reference

**Check commands**:
```bash
/s2s:dev:check --instructions    # INST-* only
/s2s:dev:check --consistency     # CONS-* only
/s2s:dev:check --all             # INST-* + CONS-*
```

**Test commands**:
```bash
/s2s:dev:test --resume           # RES-* only
/s2s:dev:test --edge             # EDGE-* only
/s2s:dev:test --all              # RES-* + EDGE-*
```

**Full validation**:
```bash
/s2s:dev:check --all && /s2s:dev:test --all
```

# Check Registry

Master list of all development checks and tests. Each check has a unique ID, severity, and reference to its full definition.

---

## ENV-* (Environment)

Verify s2s project environment is correctly configured. These are **fully automatable** via bash commands.

| ID | Name | Severity | Command | Definition |
|----|------|----------|---------|------------|
| ENV-001 | S2S Directory | critical | `test -d .s2s` | roundtable-tests.md |
| ENV-002 | CONTEXT.md Populated | high | `! grep -q "Project description" .s2s/CONTEXT.md` | roundtable-tests.md |
| ENV-003 | Config Exists | critical | `test -f .s2s/config.yaml` | roundtable-tests.md |
| ENV-004 | Roundtable Config | high | `grep -q "^roundtable:" .s2s/config.yaml` | roundtable-tests.md |
| ENV-005 | No Active Sessions | medium | `! grep -l 'status: active' .s2s/sessions/*.yaml 2>/dev/null` | roundtable-tests.md |
| ENV-006 | Participant Agents | high | `ls agents/roundtable/*.md \| wc -l` >= 10 | roundtable-tests.md |
| ENV-007 | Agenda Files | medium | `test -f skills/roundtable-execution/references/agenda-specs.md` | roundtable-tests.md |

**Invoked by**: `/s2s:dev:check --env` or `/s2s:dev:check --all`

---

## VAL-RT-* (Session Validation)

Verify session file structure and consistency. **Automatable** via YAML parsing.

| ID | Name | Severity | Check | Definition |
|----|------|----------|-------|------------|
| VAL-RT-001 | Session File Structure | critical | Required fields present | roundtable-tests.md |
| VAL-RT-002 | Artifact Embedding | high | artifacts_created exist in artifacts.* | roundtable-tests.md |
| VAL-RT-003 | Agenda/Phase Consistency | high | current_phase matches phases[].status | roundtable-tests.md |
| VAL-RT-004 | Metrics Consistency | medium | rounds_completed == len(rounds[]) | roundtable-tests.md |
| VAL-RT-005 | Verbose Dumps | medium | rounds/*.yaml files exist | roundtable-tests.md |

**Invoked by**: `/s2s:dev:test --validate` or `/s2s:dev:test --all`

**Note**: VAL-RT-* checks require a session file path as input.

---

## CTX-* (Context Propagation)

Verify that context flows correctly from facilitator to participants. **Automatable** on verbose dumps.

| ID | Name | Severity | Check | Definition |
|----|------|----------|-------|------------|
| CTX-001 | Facilitator Returns Context | critical | participant_context in question dump | roundtable-tests.md |
| CTX-002 | No context_files Pattern | critical | No deprecated context_files | roundtable-tests.md |
| CTX-003 | Context Content Complete | high | project_summary, relevant_artifacts present | roundtable-tests.md |
| CTX-004 | Exploration Prompt Passed | medium | exploration field in participant input | roundtable-tests.md |
| CTX-005 | Context Consistency | high | All participants get same shared context | roundtable-tests.md |

**Invoked by**: `/s2s:dev:test --context` or `/s2s:dev:test --all`

**Prerequisite**: Session must have been run with `--verbose` flag.

**Related**: BUG-003 (context_files → inline context fix)

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
| INST-007 | Frontmatter Completeness | high | commands, agents, skills | inst-checks.md |
| INST-008 | Subagent Spawning Prohibition | critical | agents | inst-checks.md |
| INST-009 | Skill Third Person Voice | medium | skills | inst-checks.md |
| INST-010 | Skill Progressive Disclosure | medium | skills | inst-checks.md |
| INST-011 | Core Inline vs Reference Extensions | high | skills | inst-checks.md |

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
| CONS-007 | Plugin File Locations | medium | All skills | cons-checks.md |

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

**Additional tests**: See `roundtable-tests.md` for RES-RT-* test cases (TECH-002 baseline)

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

**Additional tests**: See `roundtable-tests.md` for EDGE-RT-*, VAL-RT-*, DIAG-RT-* test cases (TECH-002 baseline)

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
/s2s:dev:check --env             # ENV-* only
/s2s:dev:check --instructions    # INST-* only
/s2s:dev:check --consistency     # CONS-* only
/s2s:dev:check --all             # ENV-* + INST-* + CONS-*
```

**Test commands**:
```bash
/s2s:dev:test --validate         # VAL-RT-* only
/s2s:dev:test --context          # CTX-* only (requires --verbose session)
/s2s:dev:test --resume           # RES-* only
/s2s:dev:test --edge             # EDGE-* only
/s2s:dev:test --all              # VAL-RT-* + CTX-* + RES-* + EDGE-*
```

**Full validation**:
```bash
/s2s:dev:check --all && /s2s:dev:test --all
```

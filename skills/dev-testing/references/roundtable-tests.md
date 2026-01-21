# Roundtable Test Baseline

Test baseline for TECH-002 (roundtable command unification). Documents current behavior to ensure no regression during refactoring.

---

## Document purpose

This document serves as **TEST SPECIFICATION** and **REGRESSION BASELINE** for TECH-002.

| Role | Description |
|------|-------------|
| **Specification** | Defines expected behavior and acceptance criteria |
| **Regression baseline** | Reference for before/after comparison |
| **Manual guide** | Provides steps for tests that cannot be automated |

### Relationship with other components

```
roundtable-tests.md (THIS FILE)
│
├── Test cases (ENV-*, VAL-RT-*, CTX-*, RES-RT-*, etc.)
│   │
│   ├── ✅ IMPLEMENTED ──────► Run via /s2s:dev:check or /s2s:dev:test
│   │   ├── ENV-* (7)        → /s2s:dev:check --env
│   │   └── VAL-RT-* (5)     → /s2s:dev:test --validate
│   │
│   ├── pending (auto) ──────► Ready to implement
│   │   └── CTX-* (5)        → Context propagation (verbose dumps)
│   │
│   ├── semi ────────────────► Manual setup, then automated check
│   │   └── RES-RT-* state checks
│   │
│   └── manual ──────────────► Human judgment required
│       └── DIAG-RT-*, some EDGE-RT-*
│
└── Baseline results ────────► Reference for regression testing
```

### Automation status legend

| Status | Meaning | Command |
|--------|---------|---------|
| `✅ implemented` | Fully automated in dev-validator | `/s2s:dev:check` or `/s2s:dev:test` |
| `semi` | Requires manual setup, then automated check | Manual + dev-validator |
| `manual` | Requires human judgment or interactive testing | Human only |

---

## Overview

| Command | Lines | Features | Status |
|---------|-------|----------|--------|
| specs.md | ~1740 | Full inline implementation | Reference |
| design.md | ~1628 | Full inline implementation | Reference |
| brainstorm.md | ~1625 | Full inline + Disney phases | Reference |
| roundtable.md | ~366 | Relies on skill | Needs alignment |

---

## Feature matrix

| Feature | specs | design | brainstorm | roundtable |
|---------|-------|--------|------------|------------|
| Auto-detect active sessions | ✅ | ✅ | ✅ | ✅ |
| --new flag | ✅ | ✅ | ✅ | ✅ |
| --session flag | ✅ | ✅ | ✅ | ✅ |
| Resume (agent_id tracking) | ✅ | ✅ | ✅ | ⚠️ in skill |
| Validation (Step 2.6b) | ✅ | ✅ | ✅ | ❌ |
| Diagnostic (Step 2.6c, 3.0) | ✅ | ✅ | ✅ | ⚠️ partial |
| --verbose flag | ✅ | ✅ | ✅ | ✅ |
| --interactive flag | ✅ | ✅ | ✅ | ✅ |
| Context snapshots | ✅ | ✅ | ✅ | ❌ |
| Agenda from skill | ✅ | ✅ | ❌ phases | ❌ |
| Phase tracking | ❌ | ❌ | ✅ Disney | ⚠️ skill |
| Output generation | ✅ inline | ✅ inline | ✅ inline | ⚠️ skill |

---

## Environment checks (ENV-*)

**Status**: ✅ IMPLEMENTED in dev-validator | **Run**: `/s2s:dev:check --env`

| ID | Check | Command | Expected |
|----|-------|---------|----------|
| ENV-001 | .s2s/ exists | `test -d .s2s` | exit 0 |
| ENV-002 | CONTEXT.md populated | `! grep -q "Project description" .s2s/CONTEXT.md` | exit 0 |
| ENV-003 | config.yaml exists | `test -f .s2s/config.yaml` | exit 0 |
| ENV-004 | config has roundtable section | `grep -q "^roundtable:" .s2s/config.yaml` | exit 0 |
| ENV-005 | No active sessions | `! grep -l 'status: active' .s2s/sessions/*.yaml 2>/dev/null` | exit 0 (or no files) |
| ENV-006 | Participant agents exist | `ls agents/roundtable/*.md \| wc -l` | >= 10 |
| ENV-007 | Agenda files exist | `test -f skills/roundtable-execution/references/agenda-specs.md` | exit 0 |

---

## Command-specific acceptance criteria

### specs.md

**Automation**: `semi` - Requires running the command, then checking results.

**Prerequisites** (automation: `auto`):
- [ ] ENV-001: `.s2s/` directory exists
- [ ] ENV-002: `.s2s/CONTEXT.md` populated (not placeholder)
- [ ] Check if `.s2s/requirements.md` exists (warning case)

**Smart source detection** (automation: `manual` - requires observing UI):
- [ ] Detects recent brainstorm sessions (last 7 days)
- [ ] Detects active ideas in `.s2s/ideas.md`
- [ ] Detects planned items in `.s2s/BACKLOG.md`
- [ ] Asks user to select sources or start fresh

**Session management** (automation: `auto` after session exists):
- [ ] Session ID format: `{YYYYMMDD}-specs-{slug}`
- [ ] Session file exists: `.s2s/sessions/{session-id}.yaml`
- [ ] Session file has `workflow_type: "specs"`

**Phase 1 outputs** (automation: `auto`):
- [ ] Session folder: `.s2s/sessions/{session-id}/`
- [ ] If --verbose: `rounds/` subfolder exists
- [ ] `context-snapshot.yaml` exists
- [ ] `config-snapshot.yaml` exists
- [ ] Session file has required fields (see VAL-RT-001)

**Phase 3 outputs** (automation: `auto`):
- [ ] `.s2s/requirements.md` generated
- [ ] Session status = "closed"
- [ ] `timing.closed_at` is set

**Artifact types**: REQ-*, BR-*, NFR-*, EX-*, OQ-*, CONF-*

**Default participants**: product-manager, ux-researcher, business-analyst, qa-lead

---

### design.md

**Automation**: `semi`

**Prerequisites** (automation: `auto`):
- [ ] ENV-001: `.s2s/` directory exists
- [ ] Check if `.s2s/requirements.md` exists (warning if missing)
- [ ] Check if `.s2s/architecture.md` exists (warning case)

**Session management** (automation: `auto`):
- [ ] Session ID format: `{YYYYMMDD}-design-{slug}`
- [ ] Session file has `workflow_type: "design"`

**Phase 1 outputs** (automation: `auto`):
- [ ] Same as specs (snapshots, session file)

**Phase 3 outputs** (automation: `auto`):
- [ ] `.s2s/architecture.md` generated
- [ ] ADR files in `.s2s/decisions/` (count > 0 if decisions made)
- [ ] Session status = "closed"

**Artifact types**: ARCH-*, COMP-*, INT-*, OQ-*, CONF-*

**Default participants**: software-architect, security-champion, technical-lead, devops-engineer

---

### brainstorm.md

**Automation**: `semi`

**Prerequisites** (automation: `auto`):
- [ ] ENV-001: `.s2s/` directory exists
- [ ] Can work with minimal CONTEXT.md

**Session management** (automation: `auto`):
- [ ] Session ID format: `{YYYYMMDD}-brainstorm-{slug}`
- [ ] Session file has `workflow_type: "brainstorm"`
- [ ] Session file has `current_phase` field
- [ ] Session file has `phases[]` array

**Phase tracking** (automation: `auto`):
- [ ] `current_phase` is one of: dreamer, realist, critic
- [ ] `phases[].status` values are valid (pending, active, completed)

**Phase 3 outputs** (automation: `auto`):
- [ ] `.s2s/ideas.md` updated (new IDEA-* entries)
- [ ] Session summary file exists
- [ ] Session status = "closed"

**Artifact types**: IDEA-*, RISK-*, MIT-*, OQ-*, CONF-*

**Default participants**: product-manager, software-architect, technical-lead, devops-engineer

---

### roundtable.md

**Automation**: `semi`

**Prerequisites** (automation: `auto`):
- [ ] ENV-001: `.s2s/` directory exists

**Session management** (automation: `auto`):
- [ ] Session ID format: `{timestamp}-roundtable-{slug}`
- [ ] Session file has `workflow_type: "roundtable"`

**Gap analysis** (to be fixed in TECH-002 Phase 4):
- ❌ Missing: context-snapshot.yaml creation
- ❌ Missing: config-snapshot.yaml creation
- ❌ Missing: inline validation step (2.6b)
- ⚠️ Partial: diagnostic (relies on skill reference)

---

## Resume test cases (RES-RT-*)

**Automation**: `semi` - Requires manual interruption, then automated state check.

### How to test resume (manual procedure)

```bash
# 1. Start session
/s2s:{workflow} "test topic" --new --verbose

# 2. Wait for round 1 to complete (or interrupt mid-round)

# 3. Clear context
/compact

# 4. Resume
/s2s:{workflow} --session {session-id}

# 5. Verify resume behavior
```

### RES-RT-001: After facilitator question

**Automation**: `semi`

**Setup**: Interrupt after facilitator returns question (before participants)

**Automated checks after interruption**:
```bash
# Check agent_id is saved
grep "agent_id:" .s2s/sessions/{id}.yaml | grep -v "null"
# Expected: at least facilitator.agent_id is set

# Check last_action
grep "last_action:" .s2s/sessions/{id}.yaml
# Expected: "question"
```

**Resume verification** (manual): Observe that participants are called, not facilitator again.

---

### RES-RT-002: After participant responses

**Automation**: `semi`

**Setup**: Interrupt after participants respond, before synthesis

**Automated checks**:
```bash
# Check participant agent_ids saved
grep -A5 "participants:" .s2s/sessions/{id}.yaml | grep "agent_id"
# Expected: agent_ids for participants who responded

# Check verbose files exist (if --verbose)
ls .s2s/sessions/{id}/rounds/*-02-*.yaml
# Expected: files for each participant who responded
```

---

### RES-RT-003: After synthesis, before session write

**Automation**: `semi`

**Setup**: Interrupt after synthesis returns, before Edit tool

**Automated checks**:
```bash
# Check rounds array
grep -c "round:" .s2s/sessions/{id}.yaml
# May be missing the current round

# Check verbose synthesis file
test -f .s2s/sessions/{id}/rounds/*-03-*.yaml
# Should exist if synthesis completed
```

---

### RES-RT-004: Mid-round interruption

**Automation**: `semi`

**Automated checks**: Same as RES-RT-002, expect partial data.

---

### RES-RT-005: Phase transition (brainstorm only)

**Automation**: `semi`

**Automated checks**:
```bash
# Check phase consistency
grep "current_phase:" .s2s/sessions/{id}.yaml
grep -A3 "phases:" .s2s/sessions/{id}.yaml
# Verify current_phase matches active phase in phases[]
```

---

### RES-RT-006: Output generation

**Automation**: `auto` (after session completes)

**Automated checks**:
```bash
# Check session closed
grep "status:" .s2s/sessions/{id}.yaml | head -1
# Expected: "closed"

# Check output exists (workflow-specific)
test -f .s2s/requirements.md  # specs
test -f .s2s/architecture.md  # design
test -f .s2s/ideas.md         # brainstorm (updated)
```

---

### RES-RT-007: Context reconstruction

**Automation**: `semi` - Check verbose dumps for context completeness (see CTX-* checks).

**NOTE**: With BUG-003 fix, SKILL.md now uses inline `context` instead of `context_files`.

---

## Context propagation checks (CTX-*)

**Status**: Pending implementation | **Requires**: `--verbose` flag on session

**Purpose**: Verify that context flows correctly from facilitator to participants.

These checks can only run on sessions created with `--verbose` flag, as they examine the verbose dump files.

### CTX-001: Facilitator returns participant_context

**Automation**: `auto` (on verbose dumps)

**Check**: Facilitator question dump contains `participant_context.shared` block.

```bash
DUMP=".s2s/sessions/{id}/rounds/001-01-facilitator-question.yaml"

# Check participant_context exists in response
grep -q "participant_context:" $DUMP && echo "PASS" || echo "FAIL: Missing participant_context"

# Check shared sub-block exists
grep -q "shared:" $DUMP && echo "PASS" || echo "FAIL: Missing shared block"

# Check required keys in shared
for key in project_summary relevant_artifacts open_conflicts open_questions recent_rounds; do
  grep -q "${key}:" $DUMP && echo "PASS: $key" || echo "FAIL: Missing $key"
done
```

**FAIL indicates**: Facilitator not building participant_context (bug in facilitator.md or command)

---

### CTX-002: Participant receives context (not context_files)

**Automation**: `auto` (on verbose dumps)

**Check**: Participant dump contains `input.context` block, NOT `input.context_files`.

```bash
DUMP=".s2s/sessions/{id}/rounds/001-02-product-manager.yaml"

# Should NOT have context_files
if grep -q "context_files:" $DUMP; then
  echo "FAIL: Using deprecated context_files pattern"
else
  echo "PASS: No context_files"
fi

# Should have context block with required keys
grep -q "context:" $DUMP && echo "PASS: context block present" || echo "FAIL: Missing context"

# Check context has required keys
for key in project_summary relevant_artifacts; do
  grep -A30 "input:" $DUMP | grep -q "${key}:" && echo "PASS: $key" || echo "WARN: Missing $key in input.context"
done
```

**FAIL indicates**: Command not passing inline context to participants (BUG-003 regression)

---

### CTX-003: Context content is complete (not truncated)

**Automation**: `semi` (requires content inspection)

**Check**: Verify context contains actual content, not placeholders or truncated text.

```bash
DUMP=".s2s/sessions/{id}/rounds/001-02-product-manager.yaml"

# project_summary should have content (at least 50 chars)
PROJECT_SUMMARY_LEN=$(grep -A5 "project_summary:" $DUMP | wc -c)
[ "$PROJECT_SUMMARY_LEN" -gt 50 ] && echo "PASS: project_summary has content" || echo "WARN: project_summary may be truncated"

# relevant_artifacts should have artifact details if round > 1
ROUND=$(grep "^round:" $DUMP | awk '{print $2}')
if [ "$ROUND" -gt 1 ]; then
  grep -q "id:" $DUMP && echo "PASS: artifacts have IDs" || echo "WARN: No artifact IDs found"
fi
```

**WARN indicates**: Context may be insufficient for quality participant responses

---

### CTX-004: Exploration prompt passed to participants

**Automation**: `auto` (on verbose dumps)

**Check**: Participant dump contains `exploration` field in input.

```bash
DUMP=".s2s/sessions/{id}/rounds/001-02-product-manager.yaml"

grep -q "exploration:" $DUMP && echo "PASS" || echo "FAIL: Missing exploration prompt"
```

**FAIL indicates**: Facilitator's exploration prompt not forwarded to participants

---

### CTX-005: Context consistency across participants

**Automation**: `auto` (on verbose dumps)

**Check**: All participants in same round receive identical shared context.

```bash
ROUND="001"
SESSION_DIR=".s2s/sessions/{id}/rounds"

# Extract project_summary from each participant dump
for f in $SESSION_DIR/${ROUND}-02-*.yaml; do
  echo "=== $(basename $f) ==="
  grep -A3 "project_summary:" $f | head -4
done

# Visual inspection: all should match
# For automation: hash comparison
HASH1=$(grep -A3 "project_summary:" $SESSION_DIR/${ROUND}-02-product-manager.yaml | md5)
HASH2=$(grep -A3 "project_summary:" $SESSION_DIR/${ROUND}-02-qa-lead.yaml | md5)
[ "$HASH1" = "$HASH2" ] && echo "PASS: Consistent context" || echo "FAIL: Inconsistent context"
```

**FAIL indicates**: Command building different context for different participants (blind voting violation)

---

### How to run CTX-* checks

**Prerequisite**: Session must have been run with `--verbose` flag.

```bash
# 1. Run a session with verbose
/s2s:specs "test topic" --new --verbose

# 2. After completion (or interruption), run context checks
# (Manual for now - to be added to /s2s:dev:test)

SESSION_ID="20260121-specs-test"
SESSION_DIR=".s2s/sessions/$SESSION_ID"

# CTX-001: Facilitator context
grep -q "participant_context:" $SESSION_DIR/rounds/001-01-facilitator-question.yaml

# CTX-002: No context_files
! grep -q "context_files:" $SESSION_DIR/rounds/001-02-*.yaml

# CTX-003: Content present
grep -A5 "project_summary:" $SESSION_DIR/rounds/001-02-product-manager.yaml

# CTX-004: Exploration present
grep "exploration:" $SESSION_DIR/rounds/001-02-*.yaml

# CTX-005: Consistency (visual)
diff <(grep -A3 "project_summary:" $SESSION_DIR/rounds/001-02-product-manager.yaml) \
     <(grep -A3 "project_summary:" $SESSION_DIR/rounds/001-02-qa-lead.yaml)
```

---

## Validation test cases (VAL-RT-*)

**Status**: ✅ IMPLEMENTED in dev-validator | **Run**: `/s2s:dev:test --validate`

### VAL-RT-001: Session file structure

**Automated check** (bash + grep):
```bash
SESSION=".s2s/sessions/{id}.yaml"

# Required top-level fields
for field in id workflow_type topic status timing participants agent_state artifacts rounds metrics; do
  grep -q "^${field}:" $SESSION && echo "PASS: $field" || echo "FAIL: $field"
done
```

---

### VAL-RT-002: Artifact embedding

**Automated check**:
```bash
# Extract artifacts_created from last round
CREATED=$(grep -A1 "artifacts_created:" $SESSION | tail -1)

# For each ID, verify it exists in artifacts section
# (requires YAML parser for full automation)
```

---

### VAL-RT-003: Agenda/phase consistency

**Automated check**:
```bash
# For specs/design: check agenda status
grep -A2 "agenda:" $SESSION | grep "status:"

# For brainstorm: check phases
grep "current_phase:" $SESSION
grep -B1 "status: \"active\"" $SESSION | grep "name:"
# These should match
```

---

### VAL-RT-004: Metrics consistency

**Automated check**:
```bash
# Count rounds in file
ROUNDS_IN_ARRAY=$(grep -c "^  - round:" $SESSION)

# Get metrics.rounds_completed
ROUNDS_METRIC=$(grep "rounds_completed:" $SESSION | awk '{print $2}')

# Compare
[ "$ROUNDS_IN_ARRAY" = "$ROUNDS_METRIC" ] && echo "PASS" || echo "FAIL"
```

---

### VAL-RT-005: Verbose dumps

**Automated check**:
```bash
ROUNDS_DIR=".s2s/sessions/{id}/rounds"

# For each round N, check files exist
for n in 001 002 003; do
  test -f "$ROUNDS_DIR/${n}-01-facilitator-question.yaml" || echo "MISSING: ${n}-01"
  test -f "$ROUNDS_DIR/${n}-03-facilitator-synthesis.yaml" || echo "MISSING: ${n}-03"
  # Participant files: {n}-02-{participant}.yaml
done
```

---

## Diagnostic test cases (DIAG-RT-*)

**Automation**: `manual` - Requires observing runtime output.

### DIAG-RT-001: Per-round observation

**Manual verification**:
1. Run with `--diagnostic`
2. After each round, observe terminal output
3. Expected: `[DIAGNOSTIC] Round N: {status}`

---

### DIAG-RT-002: Stop recommendation

**Manual verification**:
1. Create conditions that trigger anomaly (e.g., low confidence)
2. Observe if AskUserQuestion appears with options

---

### DIAG-RT-003: End-session report

**Manual verification**:
1. Complete session with `--diagnostic`
2. Verify final report shows per-round summary

---

## Edge case test cases (EDGE-RT-*)

| ID | Description | Automation | Check |
|----|-------------|------------|-------|
| EDGE-RT-001 | Empty session resume | `semi` | Session with 0 rounds, resume starts R1 |
| EDGE-RT-002 | Max rounds reached | `manual` | Need 20+ rounds to trigger |
| EDGE-RT-003 | Min rounds enforcement | `manual` | Observe override message |
| EDGE-RT-004 | All topics closed early | `manual` | Observe continue/conclude behavior |
| EDGE-RT-005 | Participant failure | `manual` | Requires simulating Task error |
| EDGE-RT-006 | YAML special characters | `auto` | Parse session with quotes/colons |
| EDGE-RT-007 | Large session file | `semi` | Run 10+ rounds, verify parseable |

---

## Regression tests for TECH-002

**Automation**: `semi` - Run before/after refactoring, compare results.

| ID | Description | Automation | Comparison method |
|----|-------------|------------|-------------------|
| REG-001 | Output identical | `semi` | diff output files |
| REG-002 | Session schema | `auto` | YAML schema validation |
| REG-003 | Verbose dumps | `auto` | File count and structure |
| REG-004 | Validation warnings | `manual` | Observe same warnings |
| REG-005 | Diagnostic reports | `manual` | Observe same format |

---

## Automation status summary

### ✅ Implemented (QUAL-001 Priority 1)

| Category | Count | Command | Notes |
|----------|-------|---------|-------|
| ENV-* | 7 | `/s2s:dev:check --env` | Environment verification |
| VAL-RT-* | 5 | `/s2s:dev:test --validate` | Session file validation |

### Pending (QUAL-001 Priority 2)

| Category | Count | Status | Notes |
|----------|-------|--------|-------|
| RES-RT-* state | 7 | `semi` | After manual interruption |
| CTX-* | 5 | `auto` | Verbose dump context checks (BUG-003 related) |
| REG-002, REG-003 | 2 | `semi` | Schema and file checks |
| EDGE-RT-006 | 1 | `auto` | YAML parsing |

### Manual only (Priority 3)

| Category | Count | Notes |
|----------|-------|-------|
| DIAG-RT-* | 3 | Requires runtime observation |
| EDGE-RT-002-005 | 4 | Requires specific conditions |

---

## How to run tests

### Automated tests (implemented)

**In any s2s project** (validates real sessions):
```bash
# Session validation (auto-detects most recent session)
/s2s:dev:test --validate

# Session validation on specific session
/s2s:dev:test --validate --session .s2s/sessions/{id}.yaml
```

**In s2s repository only** (plugin development):
```bash
# Environment checks (requires plugin structure)
/s2s:dev:check --env

# All checks
/s2s:dev:check --all
```

### Regression testing workflow (for TECH-002)

```bash
# 1. BEFORE refactoring: capture baseline
/s2s:dev:check --env              # Should all pass
/s2s:dev:test --validate          # Capture current state

# 2. Run a workflow and save output
/s2s:specs "regression test" --new --verbose
cp .s2s/requirements.md .s2s/baseline-requirements.md

# 3. AFTER refactoring: verify no regression
/s2s:dev:check --env              # Should still pass
/s2s:dev:test --validate          # Same results

# 4. Run same workflow and compare
/s2s:specs "regression test" --new --verbose
diff .s2s/requirements.md .s2s/baseline-requirements.md
```

### Manual tests (for DIAG-RT-*, EDGE-RT-*)

See individual test case descriptions above for manual procedures.

---

## Baseline test results (2026-01-20)

Test run on spec2ship repository (dogfooding).

### Environment verification

| Check | Result | Notes |
|-------|--------|-------|
| ENV-001 | ✅ PASS | .s2s/ exists |
| ENV-002 | ✅ PASS | CONTEXT.md populated |
| ENV-003 | ✅ PASS | config.yaml exists |
| ENV-004 | ✅ PASS | roundtable section present |
| ENV-005 | ✅ PASS | No active sessions |
| ENV-006 | ✅ PASS | 12 participant agents |
| ENV-007 | ✅ PASS | Agenda files exist |

### Session schema verification

Examined: `20260118-roundtable-artifact-state-model.yaml`

| Field | Result |
|-------|--------|
| id | ✅ PASS |
| workflow_type | ✅ PASS |
| status | ✅ PASS |
| timing | ✅ PASS |
| participants | ✅ PASS |
| agent_state | ✅ PASS |
| artifacts | ✅ PASS |
| rounds | ✅ PASS |
| metrics | ✅ PASS |

### Findings

1. **roundtable.md has agent_id tracking** via skill
2. **Schema inconsistency**: `round: N` vs `number: N` in rounds array
3. **Diagnostic embedded in rounds**: Works as expected

---

## Related

- **ADR-0011**: Roundtable command unification
- **TECH-002**: Implementation plan in BACKLOG.md
- **TEST-003**: Session resilience verification
- **BUG-003**: Context propagation fix (context_files → inline context)
- **check-registry.md**: Master list of all checks (ENV-*, VAL-RT-*, CTX-*, INST-*, CONS-*, RES-*, EDGE-*)
- **QUAL-001**: Dev tools implementation - ENV-* and VAL-RT-* now automated
- **dev-validator.md**: Agent that executes automated checks
- **test.md**: `/s2s:dev:test` command
- **check.md**: `/s2s:dev:check` command

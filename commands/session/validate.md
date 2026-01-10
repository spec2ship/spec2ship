---
description: Validate session consistency with structural and optional semantic checks.
allowed-tools: Bash(pwd:*), Bash(ls:*), Read, Edit, Glob, Grep
argument-hint: [session-id] [--level structural|deep] [--fix]
---

# Validate Session

## Context

- Current directory: !`pwd`
- Directory contents: !`ls -la`

## Interpret Context

Based on the context output above, determine:

- **S2S initialized**: If `.s2s` directory appears → "yes", otherwise → "NOT_S2S"

If S2S is initialized:
- Read `.s2s/state.yaml` to get `current_session` value

---

## Instructions

### Validate environment

If S2S initialized is "NOT_S2S":

    Error: Not an s2s project. Run /s2s:init first.

### Parse arguments

Extract from $ARGUMENTS:
- **session-id**: Session to validate (default: current_session)
- **--level**: Validation level (structural|deep). Default: structural
- **--fix**: Attempt to fix minor issues automatically

### Determine session ID

**IF** $ARGUMENTS contains a session ID:
- Use that ID

**ELSE**:
- Read `.s2s/state.yaml` and use `current_session`
- **IF** `current_session` is null:

      Error: No session specified and no active session.
      Usage: /s2s:session:validate <session-id>

### Read session file

**YOU MUST use Read tool** to read `.s2s/sessions/{session-id}.yaml`.

**IF** file doesn't exist:

    ⚠️ SESSION NOT FOUND
    Session '{session-id}' does not exist.

### Display header

    Session Validation
    ═══════════════════════════════════════

    Session:  {id}
    Workflow: {workflow_type}
    Rounds:   {metrics.rounds_completed}
    Level:    {--level or "structural"}

---

## Phase 1: Structural Checks

**These are deterministic, fast checks.**

### Check 1.1: YAML Structure Valid

Verify the session file was parsed correctly (if you're reading it, it's valid).

    ✅ YAML structure valid

### Check 1.2: Required Fields Present

Verify these top-level fields exist:
- `id`, `workflow_type`, `strategy`, `status`
- `timing.started`
- `artifacts` (with at least one sub-map)
- `agenda` (array)
- `rounds` (array)
- `metrics`

**IF** any missing:

    ⚠️ Required fields missing:
    - {list missing fields}

**ELSE**:

    ✅ Required fields present

### Check 1.3: Artifact States Valid

For each artifact in all `artifacts.*` maps, verify `status` is one of:
- Requirements/BR/NFR/EX: `active`, `amended`, `superseded`, `withdrawn`
- Open Questions/Conflicts: `open`, `resolved`

**IF** invalid state found:

    ⚠️ Invalid artifact states:
    - {ID}: status "{invalid}" not valid

**ELSE**:

    ✅ Artifact states valid

### Check 1.4: State Transitions Valid

Verify no impossible transitions occurred:
- `superseded` → any (terminal, should not change)
- `withdrawn` → any (terminal, should not change)
- `resolved` artifacts should have `resolved_round` set

**IF** invalid transition:

    ⚠️ Invalid state transitions:
    - {ID}: terminal state '{state}' was modified

**ELSE**:

    ✅ State transitions valid

### Check 1.5: References Consistent

Verify all artifact IDs referenced in `rounds[].artifacts_created` exist in `artifacts.*` maps.

**IF** orphan reference:

    ⚠️ Orphan references found:
    - Round {N}: {ID} not in artifacts

**ELSE**:

    ✅ References consistent

### Check 1.6: Round Sequence Correct

Verify:
- `rounds[]` entries have sequential `round` numbers (1, 2, 3, ...)
- Each round has `timestamp`, `topic_id`, `artifacts_created`
- `metrics.rounds_completed` equals `length(rounds[])`

**IF** sequence issue:

    ⚠️ Round sequence issues:
    - Expected round {N}, found {M}
    - metrics.rounds_completed ({X}) != rounds count ({Y})

**ELSE**:

    ✅ Round sequence correct

### Check 1.7: Metrics Consistency

Verify:
- `metrics.artifacts.total` equals sum of all artifact map sizes
- `metrics.artifacts.by_type.{type}` equals actual count for each type
- `metrics.topics.closed` equals count of agenda items with `status: "closed"`

**IF** mismatch:

    ⚠️ Metrics inconsistency:
    - artifacts.total: expected {X}, found {Y}
    - by_type.requirements: expected {X}, found {Y}
    - topics.closed: expected {X}, found {Y}

    **IF --fix**: Recalculate and update metrics

**ELSE**:

    ✅ Metrics match counts

### Structural Summary

    STRUCTURAL CHECKS
    ═══════════════════════════════════════
    {list all check results}

    Result: {PASS|PASS with warnings|FAIL}
    Errors: {count}
    Warnings: {count}

---

## Phase 2: Semantic Checks (--level deep)

**These require LLM analysis and are slower.**

**IF** level != "deep": Skip this phase.

### Check 2.1: Participant Coherence

Analyze `rounds[].participant_positions` across rounds.

Look for:
- Same participant contradicting themselves without explanation
- Positions that flip-flop without rationale

**IF** incoherence found:

    ⚠️ Participant coherence issues:
    - Round {N}: {participant} contradicts Round {M} position
      Before: "{summary}"
      After: "{summary}"
      Impact: {Low|Medium|High}

**ELSE**:

    ✅ Participant coherence

### Check 2.2: Context Integrity

Analyze each round's `participant_positions` and `synthesis_summary`.

Look for references to:
- Artifacts not yet created at that round
- Topics not yet discussed
- Information not in the provided context

**IF** integrity issue:

    ⚠️ Context integrity issues:
    - Round {N}: {participant} referenced "{artifact}"
      but it wasn't created until Round {M}
      Impact: {Low|Medium|High}

**ELSE**:

    ✅ Context integrity

### Check 2.3: Quality Assessment

Analyze artifacts for quality indicators:
- Requirements have measurable acceptance criteria
- NFRs have quantifiable targets
- Conflicts have clear positions from multiple participants

**IF** quality issues:

    ⚠️ Quality assessment:
    - {ID}: Acceptance criteria not measurable
    - {ID}: NFR target not quantifiable

**ELSE**:

    ✅ Quality assessment

### Check 2.4: Consensus Validity

For artifacts marked with `agreement: "consensus"`:
- Verify synthesis shows agreement was reached
- Verify no unresolved conflicts exist for that topic

**IF** invalid consensus:

    ⚠️ Consensus validity:
    - {ID}: Marked consensus but CONF-{X} unresolved

**ELSE**:

    ✅ Consensus validity

### Semantic Summary

    SEMANTIC CHECKS (LLM-based)
    ═══════════════════════════════════════
    {list all check results}

    Result: {PASS|PASS with warnings|FAIL}

---

## Final Output

    ─────────────────────────────────────
    VALIDATION RESULT: {PASS|PASS with N warnings|FAIL}

    {IF warnings}
    Warnings Summary:
    {list warning summaries}
    {/IF}

    {IF errors}
    Errors Summary:
    {list error summaries}
    {/IF}

### Update validation state

**YOU MUST use Edit tool NOW** to update session file:

```yaml
validation:
  last_check: "{ISO timestamp}"
  status: "{pass|warn|fail}"
  warnings:
    - round: {N}
      check: "{check name}"
      message: "{warning message}"
      impact: "{Low|Medium|High}"
```

---

## Exit Codes

| Result | Description |
|--------|-------------|
| PASS | All checks passed |
| PASS with warnings | Structural OK, minor issues found |
| FAIL | Critical issues found |

---
description: Validate session consistency with structural and optional semantic checks.
allowed-tools: Bash(pwd:*), Bash(ls:*), Read, Edit, Glob, Grep
argument-hint: [session-id] [--level structural|deep|strategy]
---

# Validate Session

## Purpose

This command **detects and documents** issues in session files. It does NOT fix data.

**CRITICAL**: Validation exists to identify problems in the **process and instructions** (commands, agents, skills), not to silently correct data. When issues are found:
1. Document the issue in the validation output
2. Analyze WHY it occurred (which step in which command?)
3. Suggest fixes to the **code/instructions**, not the data

## Context

- Current directory: !`pwd`
- Directory contents: !`ls -la`

## Interpret Context

Based on the context output above, determine:

- **S2S initialized**: If `.s2s` directory appears → "yes", otherwise → "NOT_S2S"

If S2S is initialized:
- Use Glob to find session files: `.s2s/sessions/*.yaml`

---

## Instructions

### Validate environment

If S2S initialized is "NOT_S2S":

    Error: Not an s2s project. Run /s2s:init first.

### Parse arguments

Extract from $ARGUMENTS:
- **session-id**: Session to validate (default: current_session)
- **--level**: Validation level. Default: structural
  - `structural`: Fast deterministic checks (YAML, fields, references)
  - `deep`: Adds semantic LLM-based analysis (coherence, quality)
  - `strategy`: Adds strategy-specific checks (debate phases, participant usage)

### Determine session ID

**IF** $ARGUMENTS contains a session ID:
- Use that ID

**ELSE** find active sessions:
- Use Bash: `grep -l 'status: active' .s2s/sessions/*.yaml 2>/dev/null`
- **IF** no active sessions found:

      Error: No session specified and no active session found.
      Usage: /s2s:session:validate <session-id>

- **IF** multiple active sessions:
  - List them and ask user which to validate using AskUserQuestion

- **IF** single active session:
  - Use that session

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
- `timing.started_at`
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
- Standard artifacts (REQ/BR/NFR/EX/ARCH/COMP/INT/IDEA/RISK/MIT): `active`
- Open Questions/Conflicts: `open`, `resolved`

**IF** invalid state found:

    ⚠️ Invalid artifact states:
    - {ID}: status "{invalid}" not valid

**ELSE**:

    ✅ Artifact states valid

### Check 1.4: Resolution Fields Valid

Verify resolution artifacts have proper fields:
- `resolved` status should have `resolution` field set
- `resolved` status should have `resolved_round` set
- Conflicts with resolution should have `resolution.method` set

**IF** missing resolution fields:

    ⚠️ Missing resolution fields:
    - {ID}: resolved but missing resolution data

**ELSE**:

    ✅ Resolution fields valid

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

    Root cause: Check metrics calculation in {workflow_type}.md Step 2.6
    Suggested fix: Verify count logic in session file update

**ELSE**:

    ✅ Metrics match counts

### Check 1.8: Participant Usage

Read session folder's `config-snapshot.yaml` to get configured participants.

For each round, verify:
- All configured participants appear in `participant_positions`
- OR change is documented (e.g., facilitator explicitly reduced for debate Pro/Con)

**IF** missing participants:

    ⚠️ Participant usage issues:
    - Round {N}: configured participants {list}, actual {list}
    - Missing: {list}

    Root cause: Check facilitator.md question action or command's participant handling
    Impact: {Low if documented|High if unexplained}

**ELSE**:

    ✅ Participant usage consistent

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

## Phase 3: Strategy-Specific Checks (--level strategy)

**These verify strategy execution followed documented rules.**

**IF** level != "strategy": Skip this phase.

Read the session's `strategy` field and apply the appropriate checks.

### Strategy: debate

Reference: `skills/roundtable-strategies/references/debate.md`

#### Check 3.D1: Debate Phases Followed

Debate requires 4 phases: opening → rebuttal → closing → synthesis.

Verify rounds show phase progression (may span multiple rounds per phase).

**IF** phases missing or out of order:

    ⚠️ Debate phases not followed:
    - Expected: opening → rebuttal → closing → synthesis
    - Found: {actual sequence}

    Root cause: Check facilitator.md debate strategy handling
    Reference: debate.md requires_sequential_phases

**ELSE**:

    ✅ Debate phases correct

#### Check 3.D2: Pro/Con Assignment

Debate requires explicit Pro/Con role assignment.

Verify:
- At least 2 participants (one Pro, one Con)
- Assignments documented in round's `participant_context.overrides`
- Assignments consistent across debate phases

**IF** assignment issues:

    ⚠️ Debate role assignment issues:
    - Round {N}: No Pro/Con overrides found
    - Participants not assigned sides: {list}

    Root cause: facilitator.md must assign overrides for debate strategy
    Reference: debate.md side_assignment

**ELSE**:

    ✅ Pro/Con roles assigned

#### Check 3.D3: Participant Balance

For debate, verify balanced participation:
- Each side has at least `min_participants_per_side` (default 1)
- If >2 participants configured, verify all assigned to a side OR documented as observers

**IF** imbalance:

    ⚠️ Debate participant imbalance:
    - Pro: {count} participants
    - Con: {count} participants
    - Unassigned: {list}

    Root cause: facilitator.md should assign all participants or document exclusions

**ELSE**:

    ✅ Debate participant balance OK

---

### Strategy: consensus-driven

Reference: `skills/roundtable-strategies/references/consensus-driven.md`

#### Check 3.C1: Consent Phases Followed

Consensus-driven uses: proposal → refinement → convergence.

Verify rounds show phase progression (if workflow allows).

**IF** phases unclear:

    ⚠️ VALIDATION NOTE:
    Consensus-driven phases may not be explicitly tracked in all workflows.
    Verify manually: Did rounds follow propose → refine → converge pattern?

**ELSE**:

    ✅ Consensus flow appears correct

#### Check 3.C2: All Participants Contributed

Consensus-driven requires all participants in all phases.

Verify each configured participant appears in every round's `participant_positions`.

**IF** missing contributions:

    ⚠️ Missing participant contributions:
    - Round {N}: {participant} did not contribute

    Root cause: All participants must be invoked in consensus-driven
    Impact: High (consent requires everyone's position)

**ELSE**:

    ✅ All participants contributed

#### Check 3.C3: Blocking Concerns Addressed

If any participant expressed blocking concern:
- Verify subsequent round addressed it
- OR escalation was triggered

**IF** unaddressed blocks:

    ⚠️ Blocking concerns not addressed:
    - {participant} blocked on: "{concern}"
    - No follow-up found in subsequent rounds

    Root cause: facilitator synthesis should flag blocks for next round focus

**ELSE**:

    ✅ Blocking concerns handled

---

### Strategy: disney

Reference: `skills/roundtable-strategies/references/disney.md`

#### Check 3.Y1: Disney Phases Followed

Disney requires 3 phases: dreamer → realist → critic.

Verify session's phase transitions match expected order.

**IF** phases incorrect:

    ⚠️ Disney phases not followed:
    - Expected: dreamer → realist → critic
    - Found: {actual sequence}

    Root cause: Check workflow command phase transition logic

**ELSE**:

    ✅ Disney phases correct

#### Check 3.Y2: Phase Tone Appropriate

Analyze content per phase:
- **Dreamer**: Should have creative ideas, no criticism
- **Realist**: Should have feasibility analysis
- **Critic**: Should have risks, concerns

**IF** tone mismatch:

    ⚠️ Disney phase tone issues:
    - Dreamer phase contains criticism: "{example}"
    - Critic phase lacks risk identification

    Root cause: Participant context should set phase tone via facilitator_directive

**ELSE**:

    ✅ Phase tones appropriate

#### Check 3.Y3: Artifact Flow

Verify artifacts flow between phases:
- Dreamer creates IDEA-*
- Realist references IDEA-* with feasibility notes
- Critic creates RISK-*, MIT-* referencing ideas

**IF** broken flow:

    ⚠️ Disney artifact flow issues:
    - RISK-{N} does not reference any IDEA-*
    - No feasibility assessment in realist phase

    Root cause: Check facilitator context preparation for phase continuity

**ELSE**:

    ✅ Artifact flow correct

---

### Strategy: standard

No specific structural requirements beyond general checks.

    ✅ Standard strategy: No additional checks required

---

### Strategy Summary

    STRATEGY CHECKS ({strategy})
    ═══════════════════════════════════════
    {list all strategy-specific check results}

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

# TECH-002 Phase 3 — Phase 2 Loop Uniformization (Approach A: shallow consolidation)

**Date**: 2026-05-05
**Branch**: `feature/TECH-002-phase3-uniformization`
**Approach**: A (eliminate accidental drift in-place; add canonical reference doc; defer deep extraction to Phase 7B)

---

## Goal

Bring the Phase 2 Round Execution Loop in `commands/specs.md`, `commands/design.md`, `commands/brainstorm.md` to true structural parity. Remove accidental textual drift; document the canonical algorithm so future deep extraction (Phase 7B) has a single target.

**Non-goal**: changing observable behavior. Post-Phase-3 replay of `/s2s:specs --verbose --diagnostic` in `exp43` should produce a structural fingerprint comparable to `exp42-specs-pre-phase3.md`. Findings F1/F2/F3 from the baseline doc should still be observable (or have explainable improvements).

---

## Out of scope (deferred)

- **Phase 7B**: deep extraction (turn the 3 sections into thin launchers that delegate to a single executable algorithm). Requires more confidence + a regression test cycle.
- **Out-of-scope drifts found during mapping** (track separately, NOT fixed here):
  1. `design.md` references `INT-*` artifacts (interfaces) in Phase 2 but `session-schema.md:567` does not list INT-* for design workflow. Either schema is incomplete or design is using an undocumented type.
  2. `brainstorm.md` creates `CONF-*` (conflicts) but `session-schema.md:568` does not list CONF-* for brainstorm workflow.
  3. Claude Code platform has evolved; new patterns (e.g., richer agent invocation, deferred tools) may simplify several flows. To re-evaluate when Phase 7B starts.

---

## Files

### To modify
- `commands/specs.md` — Step 2.0..2.9 (lines 452-1597, ~1146 lines)
- `commands/design.md` — Step 2.0..2.9 (lines 350-1465, ~1116 lines)
- `commands/brainstorm.md` — Step 2.0..2.9 (lines 325-1476, ~1152 lines)

### To create
- `skills/roundtable-execution/references/phase-2-core.md` — canonical algorithm reference (descriptive, not executable). Becomes target spec for Phase 7B.

### To update post-fix
- `.s2s/BACKLOG.md` — mark TECH-002 Phase 3 as completed in the rolling status block

---

## Drift fixes (exhaustive)

Each fix is bounded, structural-equivalent, and should not affect runtime behavior of the round loop.

### FIX-1: `design.md` Step 2.4 verification — restructure to canonical schema

**Where**: `commands/design.md` synthesis verbose dump, ~lines 1122-1153
**Why**: design uses `session_file_updates.artifacts_embedded:[{field, expected_ids}]`; canonical (per `verbose-dump-format.md:238-266` and matching specs/brainstorm) is `expected_artifacts:[{map, expected_keys}]` plus separate top-level keys.

**Before**:
```yaml
verification:
  session_file_updates:
    artifacts_embedded:
      - field: "artifacts.architecture_decisions"
        expected_ids: ["{ARCH-*}", ...]
      - field: "artifacts.components"
        expected_ids: ["{COMP-*}", ...]
      - field: "artifacts.interfaces"
        expected_ids: ["{INT-*}", ...]
      - field: "artifacts.open_questions"
        expected_ids: ["{OQ-*}", ...]
      - field: "artifacts.conflicts"
        expected_ids: ["{CONF-*}", ...]
    rounds_array:
      expected_round: {N}
      expected_fields: ["topic", "timestamp", "artifacts_created", "next_action"]
    agenda_status:
      topic_id: "{agenda_update.topic_id}"
      expected_status: "{agenda_update.new_status}"
  context_propagation:
    participant_context_keys:
      - "project_summary"
      - "relevant_artifacts"
      - "open_conflicts"
      - "open_questions"
      - "recent_rounds"
```

**After**:
```yaml
verification:
  expected_artifacts:
    - map: "artifacts.architecture_decisions"
      expected_keys: ["{ARCH-*}", ...]
    - map: "artifacts.components"
      expected_keys: ["{COMP-*}", ...]
    - map: "artifacts.interfaces"
      expected_keys: ["{INT-*}", ...]
    - map: "artifacts.open_questions"
      expected_keys: ["{OQ-*}", ...]
    - map: "artifacts.conflicts"
      expected_keys: ["{CONF-*}", ...]
  round_summary:
    expected_round: {N}
    required_fields:
      - "timestamp"
      - "topic_id"
      - "facilitator_question"
      - "synthesis_summary"
      - "participant_positions"
      - "artifacts_created"
      - "next_action"
  agenda_status:
    topic_id: "{agenda_update.topic_id}"
    expected_status: "{agenda_update.new_status}"
  metrics_consistency:
    rounds_completed: {N}
    artifacts_total: {sum of all artifact maps}
  context_propagation:
    participant_context_keys:
      - "project_summary"
      - "relevant_artifacts"
      - "open_conflicts"
      - "open_questions"
      - "recent_rounds"
```

### FIX-2: `design.md` Step 2.4 result — add `conflicts_resolved`

**Where**: `commands/design.md` synthesis verbose dump `result:` block, ~line 1115
**Why**: canonical (`verbose-dump-format.md:228-231`) and specs both have `conflicts_resolved: {count}`. design omits it.

**Before**:
```yaml
result:
  artifacts_proposed: {count}
  status: "closed"
```

**After**:
```yaml
result:
  artifacts_proposed: {count}
  conflicts_resolved: {count}
  status: "closed"
```

### FIX-3: `brainstorm.md` Step 2.4 result — add `conflicts_resolved`

**Where**: `commands/brainstorm.md` synthesis verbose dump `result:` block, ~line 1102-1104
**Why**: same as FIX-2; canonical schema includes `conflicts_resolved`.

**Before/After**: identical pattern to FIX-2.

### FIX-4: `brainstorm.md` Step 2.3 verbose dump response — add missing fields

**Where**: `commands/brainstorm.md` participant response verbose dump, ~lines 854-860
**Why**: brainstorm participant schema (line 815-840) DOES return `rationale`, `concerns`, `suggestions`. The dump section omits them — they go uncaptured. specs/design dumps include them.

**Before**:
```yaml
response:
  participant: "{participant-id}"
  position: "{full response}"
  confidence: {0.0-1.0}
  ideas: [...]
  risks: [...]
  mitigations: [...]
```

**After**:
```yaml
response:
  participant: "{participant-id}"
  position: "{full response}"
  rationale: [...]
  confidence: {0.0-1.0}
  concerns: [...]
  suggestions: [...]
  ideas: [...]
  risks: [...]
  mitigations: [...]
```

### FIX-5: `specs.md` Step 2.3 verbose dump header comment — uniform "Role"

**Where**: `commands/specs.md` participant dump header, line 962
**Why**: specs uses `# Round {N} - {Participant Role} Response`; design/brainstorm use `# Round {N} - {Role} Response`. Cosmetic alignment.

**Before**: `# Round {N} - {Participant Role} Response`
**After**: `# Round {N} - {Role} Response`

### FIX-6: `specs.md` Step 2.9 — full min_rounds enforcement block

**Where**: `commands/specs.md` Step 2.9, lines 1590-1593
**Why**: specs uses hardcoded `< 3` (not config-driven) and lacks the user-visible warning. design/brainstorm use the canonical block. Risk: hardcoded 3 ignores `limits.min_rounds` from config.

**Before**:
```
#### Step 2.9: Evaluate Next Action

- If `round_number < 3` AND `next == "conclude"`: Override to "continue"
- Based on `next`: continue loop, conclude, or handle escalation
```

**After**:
```
#### Step 2.9: Evaluate Next Action (CRITICAL)

**MANDATORY min_rounds enforcement:**

```
IF round_number < min_rounds (from config) AND next == "conclude":
  OVERRIDE next to "continue"
  Display: "⚠️ min_rounds not reached ({round_number}/{min_rounds}), continuing..."
```

Then evaluate based on `next`:
- **continue**: Loop back to Step 2.1
- **conclude**: Proceed to Phase 3
- **escalate**: Ask user with AskUserQuestion, then continue or conclude
```

> **Behavior note**: this changes `specs` from hardcoded 3 to `limits.min_rounds`. Default `min_rounds` in config is currently `3`, so behavior is preserved. If user has overridden `min_rounds` in `.s2s/config.yaml`, specs will now respect it (which is the documented contract anyway). Worth a single line in CHANGELOG/release notes when going to main.

---

## File creation: `phase-2-core.md`

**Path**: `skills/roundtable-execution/references/phase-2-core.md`

**Status**: descriptive (not executable). Reference for Phase 7B deep-extraction; can also be linked from each command's Phase 2 header for readers who want the canonical algorithm.

**Structure**:
1. **Purpose & current state** — what this is, what it isn't (yet)
2. **Workflow profiles** — table of parameters per workflow_type:
   - `topic_pattern` (e.g., `"Requirements definition for {project name}"`)
   - `state_phase` (e.g., `"requirements"`, `"design"`, `"{current_phase}"`)
   - `participants` list
   - `artifact_types` map (id_prefix → schema location)
   - `axis_kind` (`agenda` for specs/design vs `disney_phase` for brainstorm)
3. **Round Loop algorithm** — Step 2.0..2.9 in canonical form, parameterized references
4. **Workflow-specific addenda**:
   - specs: agenda topics, artifact types, participants
   - design: agenda topics, artifact types, participants
   - brainstorm: Disney phase machine + Step 2.6d Phase Transition
5. **Cross-reference table** — which lines in each command implement which step
6. **Phase 7B handoff notes** — what would change to make this executable

---

## Execution order

| # | Step | Risk |
|---|------|------|
| 1 | Create `phase-2-core.md` (additive) | none |
| 2 | FIX-1 design.md verification (largest single edit) | low (no consumer parses verification) |
| 3 | FIX-2 design.md result | trivial |
| 4 | FIX-3 brainstorm.md result | trivial |
| 5 | FIX-4 brainstorm.md response dump fields | trivial |
| 6 | FIX-5 specs.md dump header | trivial |
| 7 | FIX-6 specs.md Step 2.9 | low (default min_rounds=3 → behavior preserved) |
| 8 | Verify with grep that the 3 commands are now structurally aligned | mechanical |
| 9 | Update `.s2s/BACKLOG.md` (mark Phase 3 done in TECH-002 status block) | trivial |
| 10 | Single commit with all changes (Conventional: `refactor(commands): …`) | clean |

---

## Verification post-fix

After all fixes applied, run these greps to confirm convergence:

```bash
# All 3 commands should use expected_artifacts (no session_file_updates.artifacts_embedded leftover)
grep -n "session_file_updates\|artifacts_embedded" commands/

# All 3 should have conflicts_resolved in their result block (search synthesis sections)
grep -A2 "result:$" commands/specs.md commands/design.md commands/brainstorm.md | grep "conflicts_resolved"

# specs Step 2.9 should reference min_rounds, not "< 3"
grep -A8 "Step 2.9" commands/specs.md | grep -E "min_rounds|< 3"

# brainstorm verbose dump should now mention rationale/concerns/suggestions
grep -B1 -A3 "ideas: \[\\.\\.\\.\\]" commands/brainstorm.md | head -20
```

Expected: every grep returns either nothing-of-concern or the new canonical strings.

**Behavioral verification (deferred until user wants)**: replay `/s2s:specs --verbose --diagnostic` in `exp43` (no topic, same OQ answers as exp42), then compare against `exp42-specs-pre-phase3.md` baseline. Structural fingerprint should match. F1/F2/F3 findings status:
- F1 (verification block in dump): now uniform across workflows ✓
- F2 (session-observer invoked only at end-session): unchanged — Step 2.6c activation pattern not touched in Phase 3 (candidate for Phase 7B)
- F3 (residual Disney leak / wording): unchanged — same reason as F2

---

## Commit strategy

Single commit on `feature/TECH-002-phase3-uniformization`, message:

```
refactor(commands): align Phase 2 verification/result/min_rounds across specs/design/brainstorm

- design Step 2.4 verification: switch to canonical expected_artifacts schema, add round_summary + metrics_consistency
- design + brainstorm Step 2.4 result: add conflicts_resolved
- brainstorm Step 2.3 dump: add missing rationale/concerns/suggestions
- specs Step 2.3 dump header: align to "{Role} Response"
- specs Step 2.9: replace hardcoded < 3 with min_rounds (from config) + warning display
- add skills/roundtable-execution/references/phase-2-core.md as canonical algorithm reference

No behavior change for default config (min_rounds=3). Defers deep extraction to Phase 7B.

Refs: TECH-002 Phase 3
```

---

## Risk register

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Verification block consumer breaks | very low | Verified `round-validation.md` does NOT parse verification fields; reads session directly |
| Behavioral drift in specs Step 2.9 | low | min_rounds default = 3, equivalent to hardcoded; documented in commit |
| Verbose dump filename/content schema break | very low | Filenames untouched; only inner YAML keys reorganized to canonical |
| Replay regression (exp43 vs exp42 structural delta) | low-medium | Acceptable; expected delta documented (F1 normalized, F2/F3 unchanged) |
| Out-of-scope INT-* / CONF-* inconsistencies hide | medium | Tracked in this plan's "Out of scope" section + follow-up backlog item |

---

## Done criteria

- [ ] All 6 drift fixes applied
- [ ] `phase-2-core.md` created and reviewed
- [ ] Verification greps return expected results
- [ ] BACKLOG updated
- [ ] Single commit pushed to `feature/TECH-002-phase3-uniformization`
- [ ] User confirms before any merge to develop (no auto-merge)

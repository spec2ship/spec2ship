# exp45: /s2s:roundtable native pre-Phase-4 smoke test baseline

**Captured**: 2026-05-20
**Plugin version**: spec2ship branch `feature/TECH-002-phase4-roundtable-master` (no commands/skills/agents modifications vs `develop @ 3043c1a`, functionally PRE-Phase-4)
**Dogfood worktree**: `~/Repositories/ElfGiftRush_s2s/exp45/` at commit `af9af48` (post `/s2s:init` scaffold baseline)
**Command**: `/s2s:roundtable "Phase 4 smoke test" --diagnostic`
**Smoke depth**: Option 2 (Setup + 1 round only) chosen by user; plugin auto-aborted at Phase 1 before any round
**Profile-gap handling**: Option 3 (Abort - profile gap is the test result) chosen by user

---

## Outcome classification (per Phase 4 plan §4.0 step 7 taxonomy)

**Outcome: (c) graceful**

| Aspect | Result |
|--------|--------|
| (a) Works fine | NO |
| (b) Silent broken | NO (no hallucination; explicit abort) |
| (c) Hard error / blocked | **YES, with graceful behavior**: plugin LLM detected profile gap proactively, asked user how to proceed, aborted cleanly when user selected Option 3 |
| session.yaml well-formed | YES (closed with `close_reason: aborted_profile_gap`, `smoke_test:` block with full findings) |
| Diagnostic dump generated | YES (`rounds/000-00-diagnostic-abort.yaml` with full profile_resolution + findings) |
| Agents spawned | 0 |
| Rounds executed | 0 |
| Artifacts emitted | 0 |
| state.json | Cleared (`active_session: null`) |

## Architectural finding

**The plugin runtime LLM provided definitive resolution data**:

1. **Profile gap is structural, not transient**: `profiles/roundtable.yaml` does not exist; only `specs.yaml`, `design.yaml`, `brainstorm.yaml` are present.
2. **phase-2-core.md §1 requires PROFILE for active workflow_type**: confirms our audit §7.1 static analysis prediction empirically.
3. **Affected steps** (more specific than static analysis prediction):
   - Step 2.2b: `PROFILE.artifact_types`, `PROFILE.state_phase`, `PROFILE.progress.axis`
   - Step 2.4b: `PROFILE.progress.synthesis_input_fields`, `PROFILE.progress.synthesis_output_field`
   - Step 2.5: `PROFILE.artifact_types[].prefix/session_key` lookup
   - Step 2.6a: `PROFILE.round_summary.tag_field`
   - Step 2.6c: `PROFILE.artifact_types[]` for metrics by_type
4. **SKILL.md L178 commitment confirmed**: `roundtable-execution/SKILL.md` line 178 already states `commands/roundtable.md (the latter still uses pre-7B inline pattern; Phase 4 will align it)`. Pre-existing Phase 4 commitment from Phase 7B docs.

## Plugin's remediation recommendation (Option A, drives Phase 4 pivot)

Plugin explicitly recommended **Option A**: create `profiles/roundtable.yaml` with concrete spec:
- `artifact_types: [OQ, CONF]` (no primary artifacts; secondary only)
- `progress.axis: agenda` with single `main` topic
- `participants.default` from `config.yaml.roundtable.participants.default`

Plugin rationale (verbatim): *"Smallest scope, makes roundtable.md a first-class consumer of phase-2-core.md alongside specs/design/brainstorm."*

## Decision: Phase 4 plan pivot from Approach 4 → Option ε

The smoke test outcome + SKILL.md L178 pre-existing commitment + plugin's concrete spec INVALIDATE the previous Approach 4 rationale (which assumed `profiles/roundtable.yaml` would be "semi-fictional" and require schema extension). The plugin runtime gives us:
- Concrete schema (uses existing fields, no extension)
- Minimal artifact_types (OQ + CONF only)
- Existing agenda axis with single topic (no new "free_form" axis needed)

Phase 4 plan revised (post smoke test, 2026-05-20) to adopt **Option ε** (Approach 1 with plugin spec): create `profiles/roundtable.yaml` in §4.1 step 6, eliminate §4.4b MVF, eliminate Phase 9 deferral, fully resolve generic-mode in Phase 4.

## Captured artifacts (frozen for Phase 4.5 regression comparison)

### session.yaml (closed state)

Key fields preserved from the smoke test session file:

```yaml
id: "20260520-073735-roundtable-phase-4-smoke-test"
workflow_type: "roundtable"
topic: "Phase 4 smoke test"
strategy: "standard"
status: "closed"
close_reason: "aborted_profile_gap"

participants:
  - software-architect
  - technical-lead

agent_state:
  facilitator:
    agent_id: null
    last_round: 0
    last_action: null

artifacts:
  decisions: {}
  open_questions: {}
  conflicts: {}

agenda:
  - topic_id: "main"
    status: "open"
    coverage: []

rounds: []

metrics:
  rounds_completed: 0
  artifacts:
    total: 0
    by_type: {}
  tokens:
    total: 0
    by_round: []

smoke_test:
  goal: "Verify /s2s:roundtable end-to-end with --diagnostic after TECH-002 Phase 7B"
  finding: "ABORT - profile gap blocks roundtable-execution skill"
  blocker_classification: "design"
  recommendation: "A - smallest scope, makes roundtable.md a first-class consumer of phase-2-core.md alongside specs/design/brainstorm"
  cross_refs:
    - "SKILL.md L178: '(the latter still uses pre-7B inline pattern; Phase 4 will align it)'"
    - "phase-2-core.md §5: 'Strategy hooks wiring deferred to Phase 4 (Option A/B/C decision)'"
```

### diagnostic-abort dump structure

`rounds/000-00-diagnostic-abort.yaml`:
- `actor: "orchestrator"`, `action: "phase-1-abort"`
- `profile_resolution.attempted_path: "${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/profiles/roundtable.yaml"`
- `profile_resolution.exists: false`
- `findings` array with 2 entries: `missing_profile` (severity: blocker) + `command_skill_contract_mismatch` (severity: design)
- `recommendation: "Stop for investigation"`

## Post-Phase-4 expected outcome

After Phase 4 ships with `profiles/roundtable.yaml` (Option ε), the same `/s2s:roundtable "topic" --diagnostic` invocation should:
- Load `profiles/roundtable.yaml` successfully (no abort)
- Proceed with full Phase 2 execution via phase-2-core.md
- Produce session.yaml with `status: completed`, populated artifacts (OQ/CONF as defined in profile), Phase 3 output rendered
- NO `smoke_test:` block, NO `close_reason: aborted_profile_gap`

This file (pre-Phase-4 baseline) is the "before" state; Phase 4.5 captured the "after" state in `.s2s/test-baselines/exp45-roundtable-native-post-phase4.md` (2026-05-21).

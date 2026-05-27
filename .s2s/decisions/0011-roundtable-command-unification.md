# ADR-0011: Roundtable command unification

**Status**: accepted (2026-05-17 — after Phase 7B regression replay passed)
**Date**: 2026-01-20 (proposed); 2026-05-17 (accepted)
**Deciders**: s2s development team

## Context

The roundtable workflow is implemented in multiple commands with significant code duplication:

| Command | Lines | Purpose |
|---------|-------|---------|
| specs.md | ~1740 | Requirements gathering |
| design.md | ~1628 | Architecture design |
| brainstorm.md | ~1625 | Creative ideation |
| roundtable.md | ~366 | Generic roundtable |

### Current problems

1. **Paradox**: Commands declare `skills: roundtable-execution` and say "Follow skill EXACTLY", but implement everything inline (and better than the skill)

2. **Skill is incomplete**: roundtable-execution (803 lines) lacks:
   - Resume capability (agent_id tracking, Task resume)
   - Validation step (2.6b)
   - Diagnostic step (2.6c, 3.0)

3. **Commands diverge**: While structurally similar, specs/design/brainstorm have:
   - Different artifact types (REQ/BR vs ARCH/COMP vs IDEA/RISK)
   - Different output formats (SRS vs architecture+ADR vs ideas.md)
   - Different prerequisites (CONTEXT.md vs requirements.md)
   - Slightly different facilitator prompts

4. **Token waste**: ~800 tokens for skill that's largely ignored

5. **roundtable.md is underpowered**: Relies on skill but skill is incomplete

### Analyzed components

| Component | Lines/cmd | Extractable | Method | Token savings |
|-----------|-----------|-------------|--------|---------------|
| Resume | ~150 | Partial | Document pattern | Low |
| Validation (2.6b) | ~40 | Yes | session-qa agent | Medium |
| Diagnostic (2.6c, 3.0) | ~80 | Already done | session-observer agent | N/A |
| Output generation | ~150-200 | Yes | Skill per workflow | High |
| Artifact schemas | ~100 | Partial | Reference file | Medium |
| Facilitator prompts | ~200 | Difficult | Workflow-specific | N/A |

## Decision

Adopt a **hybrid approach**:

1. **Commands remain authoritative** for execution
2. **roundtable-execution becomes reference library** (not execution guide)
3. **Output generation extracted** to on-demand skills
4. **Validation uses session-qa agent**
5. **Progressive unification** in phases

### Architecture target

```
specs.md / design.md / brainstorm.md (~600-800 lines)
├── Prerequisite check (workflow-specific)
├── Configuration + parameters
├── Shared execution structure (Phase 2)
└── Reference to output skill (Phase 3)

roundtable.md (~400-500 lines)
├── Generic roundtable
└── Same execution structure

SKILLS (loaded on-demand via Read):
├── roundtable-core/ - Overview only (slim)
├── output-specs/ - SRS pseudo-code
├── output-design/ - Architecture + ADR pseudo-code
└── output-brainstorm/ - Ideas.md pseudo-code

AGENTS (called via Task when flags present):
├── session-qa - Validation
└── session-observer - Diagnostic
```

### Implementation phases

**Phase 0: Test baseline**
- Location: `skills/dev-testing/references/roundtable-tests.md`
- Create acceptance criteria for each command
- Document expected behavior
- Prerequisite for all other phases

**Phase 1: Output extraction** (linked to IDEA-010)
- Create `skills/output-specs/`, `output-design/`, `output-brainstorm/`
- Commands read skill via `Read` tool (not frontmatter)
- ~450 lines removed from commands

**Phase 2: Validation consolidation**
- Verify session-qa can do Step 2.6b checks
- Commands call `Task(session-qa)` instead of inline
- ~120 lines simplified

**Phase 3: Phase 2 uniformization**
- Map all differences between commands
- Eliminate accidental divergences
- Parameterize necessary differences

**Phase 4: roundtable.md alignment**
- Add missing features to roundtable.md
- Verify `--workflow-type` produces correct output
- Simplify workflow commands to wrappers

**Phase 5: Skill cleanup** (linked to DEBT-001)
- Decide skill role: documentation vs execution
- Slim to overview + references
- Target: under 2000 words

### Priority matrix

| Phase | Impact | Risk | Order |
|-------|--------|------|-------|
| 0 | - | - | Required first |
| 5 | Low | Low | 1st (unblocks DEBT-001) |
| 1 | High | Medium | 2nd |
| 2 | Medium | Medium | 3rd |
| 3 | High | Medium | 4th |
| 4 | Medium | High | Last |

## Consequences

### Positive

- Reduced code duplication (~40% fewer lines in commands)
- Single source of truth for execution logic
- Easier maintenance (change once, affects all)
- roundtable.md gains full capabilities
- Clear separation: commands = what, skills = reference

### Negative

- Refactoring risk (must not break current behavior)
- Requires comprehensive test suite first
- Phased approach means temporary inconsistency

### Risks

| Risk | Mitigation |
|------|------------|
| Breaking existing commands | Phase 0 test suite |
| Token regression | Measure before/after each phase |
| Incomplete extraction | Small incremental changes |

## Related

- **IDEA-008**: Reduce code duplication in workflow commands (this ADR promotes it)
- **IDEA-010**: Unified export command (Phase 1 prepares for this)
- **DEBT-001**: Reduce roundtable-execution word count (Phase 5)
- **TEST-003**: Session resilience verification (Phase 0 extends this)

## Notes

This analysis was performed by comparing:
- `skills/roundtable-execution/SKILL.md` (803 lines)
- `commands/specs.md` (1740 lines)
- `commands/design.md` (1628 lines)
- `commands/brainstorm.md` (1625 lines)
- `commands/roundtable.md` (366 lines)

Key finding: Commands have MORE features than the skill they claim to follow.

---

## Phase 7B addendum (2026-05-17)

Phase 7B "deep extraction" landed on branch `feature/TECH-002-phase7b-deep-extraction`. The original ADR proposed a "Core Inline + Skill Reference" hybrid; Phase 7B realized it concretely via the **executable-skill-reference pattern**:

### Pattern: executable skill reference

A command Reads a skill reference document (`skills/X/references/Y.md`) and follows its step-by-step instructions, with workflow-specific values supplied by a profile YAML loaded into conversation context as `PROFILE`. The skill reference doc is **profile-aware** (uses `{{profile.X}}` placeholders + `IF profile.X == "..."` conditional sections) so a single document executes correctly across multiple workflows.

For TECH-002 Phase 7B, this was applied to Phase 2 Round Execution Loop:
- Single source: `skills/roundtable-execution/references/phase-2-core.md` (executable, ~870 lines).
- Profile YAMLs: `skills/roundtable-execution/profiles/{specs,design,brainstorm}.yaml`.
- Caller pattern: ~28-line invocation in each command (load profile → set runtime context → Read+follow phase-2-core.md).
- Sub-references: `artifact-schemas/{type}.md` (12 files), `disney-phase-machine.md`, `strategy-hooks.md`.

### Line count impact (vs original ADR analysis)

| File | Original (Jan 2026) | After Phase 6 | After Phase 7B (this) | After Phase 8 (target) |
|------|---------------------|----------------|------------------------|------------------------|
| specs.md | 1740 | 1727 | **600** (-1127) | ~150 |
| design.md | 1628 | 1607 | **536** (-1071) | ~150 |
| brainstorm.md | 1625 | 1575 | **482** (-1093) | ~150 |
| roundtable.md | 366 | 437 | 437 (unchanged; Phase 4) | ~600 (master) |
| SKILL.md | 803 | 1002 | **178** (-824) | ~178 (unchanged in Phase 8) |
| phase-2-core.md | n/a | n/a (descriptive only) | **871** (new executable) | unchanged |
| Total commands+SKILL | 6162 | 6348 | 2233 (-65%) | ~1228 |

### Decisions resolved by Phase 7B

- **Extraction contract** (`phase-2-core.md` §3 + plan `Appendix C`): profile-load + read+follow pattern with named runtime variables in caller scope. Validated via 7B.3.5 feasibility prototype on Step 2.1.
- **FIX-S1 (BUG-013)**: persist session-observer output to `rounds/{NNN}-04-session-observer.yaml`. Anchors LLM commitment to Step 2.6c. Verified across all 3 workflows in 7B.7.
- **Strategy hooks contract** (`strategy-hooks.md`): inventory of strategy-specific variations (debate_role, debate_phase for debate; phase machine for disney; hat_role/hat_phase deferred for six-hats). Hooks are additive; wiring deferred to Phase 7.
- **SKILL.md role**: thin overview pointing to phase-2-core.md as authoritative execution source. Phase 1 (init) and Phase 3 (close) remain inline in each command — out of scope for 7B; thin-launcher conversion deferred to Phase 8.

### Regression coverage

Phase 7B introduced regression tests via dogfood: `.s2s/test-baselines/exp43-*` (pre-7B baselines) and `.s2s/test-baselines/exp44-*-post-phase7b.md` (post-7B verification). All 3 workflows verified for schema invariants. Side-effect noted: post-FIX-S1 sessions tend to run 0-2 more rounds than baselines (observer "Continue" feedback extends sessions); classified as non-regression.

### Remaining phases

Phase 7 (strategy skill consolidation), Phase 4 (roundtable.md as master), Phase 8 (thin launchers) remain. Until those land, do not release v0.4.0 → main: the architectural promise of TECH-002 is only ~⅔ delivered by 7B.

---

## Phase 7-lite addendum (2026-05-18)

Phase 7 was re-scoped to **Phase 7-lite** after a 4-round plan review (round #4 macro, recorded in `.s2s/plans/20260517-tech002-phase7-strategy-consolidation.md` §3). The original "Phase 7-full" proposal (facilitator Reads strategy doc at Step 2.2c, Option A) was deferred to Phase 4. Phase 7-lite delivers documentation hardening only.

### Decision: defer runtime wiring to Phase 4

The original Phase 7 plan proposed Option A (LLM-mediated facilitator Read at Step 2.2c). Macro review #4 surfaced three blocking concerns:

1. **Option A does not eliminate LLM emergence** — it shifts the emergence from "interpret STRATEGY string" to "interpret STRATEGY string + Read doc and interpret prose markdown". The original Phase 7 problem statement is not solved by Option A.
2. **R1 (Pro/Con assignment shift) is highly likely** — empirical observation in exp44 is one LLM sample; nondeterminism likely produces inconsistent role mapping across runs. If R1 fallback triggers, Phase 7's wiring delivers minimal runtime value.
3. **Regression cannot differentiate working from silently-broken wiring** — a passing exp45 replay could mean Read+apply worked, OR that it silently did nothing and the LLM emerged identical output. No positive verification was feasible without significant additional work.

Phase 4 has the right architectural seam to revisit (once roundtable.md becomes master and commands are simplified). Phase 7-lite delivers the precondition (formalized strategy docs in uniform consumable shape).

### Phase 7-lite deliverables

Four concrete documentation wins, ~3.5 hours total:

1. **Strategy doc formalization**: 5 strategy reference docs (`{standard,consensus-driven,debate,disney,six-hats}.md`) gain uniform `## Strategy hooks` sections (~10-25 lines each). Opening lines drawn from a 4-phrase skip-trigger-compatible set, so Phase 4 can pick any Option A/B/C without further phrasing edits.
2. **SKILL.md dedup**: `roundtable-strategies/SKILL.md` workflow defaults + artifact-types tables gain explicit "authoritative source: profiles/" disclaimers (drift prevention); version bump 1.1.0 → 1.2.0. Two drift items resolved: `ADR-*` clarified as Phase 3 output (not in-session) for design; `CONF-*` added to brainstorm secondary.
3. **Step 2.6d → Step 2.10 rename**: resolves Phase 7B post-merge 3-way doc inconsistency (§2 layout vs §4 invariant vs §2.9b dispatch). 18 sites updated across 6 files; the block is now placed AFTER Step 2.9 in §2 layout, matching the runtime dispatch sequence. No runtime change.
4. **disney.md ↔ disney-phase-machine.md cross-link**: bidirectional banners at file top; phase names verified consistent (dreamer/realist/critic).

### Pattern: skill as authoritative reference + deferred runtime consumption

Phase 7-lite extends the ADR-0011 hybrid pattern: `roundtable-strategies/` is now declared the authoritative reference for strategy hook contracts in documentation form. Runtime consumption pattern (Option A LLM-mediated Read / Option B command-side parsing / Option C structured YAML configs) is deliberately deferred to Phase 4 where the architectural seam is cleaner.

This is a deliberate deviation from the original ADR-0011 §Decision text "roundtable-execution becomes reference library (not execution guide)" — Phase 7B already extended `roundtable-execution` to execution-guide role via `phase-2-core.md` (executable skill reference pattern); Phase 7-lite stops short of extending the same pattern to `roundtable-strategies/`. Phase 4 may complete the extension or pick a different approach (Option B or C).

### Strategy data resolution hierarchy clarified (out of 7-lite scope, flagged for Phase 4)

7.0 audit §7.3 surfaced an architectural observation not previously documented: commands resolve runtime strategy from `config.yaml.roundtable.strategy.by_workflow_type.{workflow}`, NOT from `profile.yaml.default_strategy`. The latter field appears documentation-only despite `profile-schema.md:115` describing it as "required for Phase 1 strategy resolution". Phase 4 wiring decision must clarify the resolution hierarchy (likely: CLI `--strategy` → `config.yaml.by_workflow_type` → `profile.default_strategy` fallback → SKILL.md table documentation).

### Remaining phases (updated)

- **Phase 4 (next, ~3-4h)**: roundtable.md as master + Option A/B/C wiring decision for strategy hook consumption. Plan to be drafted using `20260517-tech002-phase7-strategy-consolidation.md` as a structural template; §3 must include explicit Option A/B/C decision matrix.
- **Phase 8 (after Phase 4, ~2-3h)**: thin launcher conversion (specs/design/brainstorm → ~150 lines each).
- **Six-hats wiring (prerequisite-blocked)**: requires empirical baseline acquisition first. Separate task, not a Phase 7-lite or Phase 4 follow-up.

Until Phase 4 + 8 land, do NOT release v0.4.0 → main. TECH-002's architectural promise (thin launchers + skill-as-source-of-truth) is only ~⅔ delivered by 7B + 7-lite.

---

## Phase 4 addendum (2026-05-21)

Phase 4 landed on branch `feature/TECH-002-phase4-roundtable-master` (forked from develop @ `3043c1a` post Phase 7-lite PR #15 merge). Plan at `.s2s/plans/20260518-tech002-phase4-roundtable-master.md`; audit at `.s2s/plans/20260518-tech002-phase4-4.0-audit.md`; pre/post baselines at `.s2s/test-baselines/exp45-roundtable-native-{pre,post}-phase4.md`.

### Option B chosen for strategy-hook wiring

Per plan §3.1 decision matrix (8 criteria), **Option B (command-side deterministic parser)** chosen over Option A (LLM-mediated facilitator Read) and Option C (structured YAML configs in `config.yaml`):

- **A rejected**: does not eliminate LLM emergence (shifts from "interpret STRATEGY string" to "interpret STRATEGY string + Read doc + parse prose"); R1 fallback (Pro/Con assignment shift) remains likely. Same concerns that re-scoped Phase 7-full to 7-lite.
- **C rejected**: pushes strategy mechanics into config.yaml, conflating user customization with strategy implementation. Violates D3 hierarchy where `config.yaml` is user-canonical and strategy docs are plugin-canonical.
- **B chosen**: deterministic resolution in `commands/roundtable.md` Phase 1 via `strategy-hook-resolution.md` fixture (anchor-table of opening-line regexes → override dicts). Single point of resolution; output is structured dict written to `session.yaml.agent_state.facilitator.hook_overrides`. Backward-compat via Branch 3 (absent field → LLM-emergent fallback for pre-Phase-4 sessions).

### D3 strategy resolution hierarchy codified

Per plan §3.3:

```
CLI --strategy (user explicit)
  ↓ if not set
config.yaml.roundtable.strategy.by_workflow_type.{workflow}  (user canonical)
  ↓ if not set
profiles/{workflow}.yaml.default_strategy  (plugin fallback)
  ↓ if missing entirely
ERROR: report bug (plugin profile should always have default_strategy)
```

**Override that wins over all**: `profiles/{workflow}.yaml.strategy_constraints.forced == true` (only `brainstorm.yaml` currently uses this, forcing Disney). Codified in `skills/roundtable-execution/references/strategy-resolution.md` (4 worked examples) + `roundtable-strategies/SKILL.md` v1.3.0 (new "Strategy resolution hierarchy" section with ASCII diagram + roundtable row added to defaults table). `templates/project/config.yaml` and all 4 `profiles/*.yaml` carry comment headers cross-referencing the hierarchy.

### Option ε pivot: generic-mode resolved in Phase 4

Pre-Phase-4 plan assumed `profiles/roundtable.yaml` would be "semi-fictional" and required schema extension; generic-mode roundtable was deferred to a hypothetical Phase 9. The 2026-05-20 smoke test (`.s2s/plans/20260518-tech002-phase4-4.0-audit.md` §7, baseline `.s2s/test-baselines/exp45-roundtable-native-pre-phase4.md`) inverted this:

1. **Outcome (c) graceful**: plugin runtime LLM detected the profile gap proactively and aborted cleanly (no silent broken behavior).
2. **SKILL.md L178 pre-existing commitment**: `roundtable-execution/SKILL.md` line 178 already stated "(the latter still uses pre-7B inline pattern; Phase 4 will align it)".
3. **Plugin provided concrete spec**: roundtable.yaml schema fits existing fields (no extension needed): `artifact_types: [OQ, CONF]` (review #5 A2 added DEC for backward-compat with current session.yaml init `decisions: {}` slot), `progress.axis: agenda` single `main` topic, `participants.default` from `config.yaml`.

**Pivot**: Approach 4 (defer to Phase 9) abandoned; Approach 1 (Option ε) adopted with plugin's authoritative spec. Phase 4 creates `profiles/roundtable.yaml` (~70 lines, all existing schema fields) and `/s2s:roundtable` native becomes a first-class consumer of `phase-2-core.md` alongside specs/design/brainstorm. Phase 9 ELIMINATED.

**Post-pivot validation** (§4.5 Step 1, exp45 post-Phase-4 baseline): `/s2s:roundtable "Generic discussion test..." --diagnostic` completes 3 rounds cleanly, emits 9 artifacts (4 DEC + 4 OQ + 1 CONF), session closes with `status: closed`, no `smoke_test:` block, no `close_reason: aborted_profile_gap`. Pre/post diff inventoried in `.s2s/test-baselines/exp45-roundtable-native-post-phase4.md`.

### phase-2-core.md Step 2.2c modification: 3-branch dispatch

Step 2.2c reads `session.yaml.agent_state.facilitator.hook_overrides` and dispatches:

- **Branch 1** (`hook_overrides.skip == true`): pass `{skip: true}` to facilitator; no per-round overrides emitted. Triggered by strategies declaring no hooks (standard, consensus-driven, disney, six-hats).
- **Branch 2** (policy dict present): pass full dict; facilitator populates `participant_context.overrides.{participant-id}.{field}` per policy. Triggered by debate (initial policy `facilitator_emergent` preserves current LLM behavior; can be promoted to deterministic rule once exp45+ samples accumulate, see plan §8).
- **Branch 3** (field absent in session.yaml): do NOT include `hook_overrides:` key in agent input; facilitator falls back to LLM-emergent inference. **Backward-compat path only** for pre-Phase-4 sessions resumed via `--session {id}`. Any Phase 4+ session has the field populated by the parser.

Anchor fixture frozen at `.s2s/plans/20260518-tech002-phase4-4.2-fixture.md` (5 assertions: 4 strategies → `{skip: true}`, debate → policy dict). Runtime parser exercised implicitly across 8 §4.5 dogfood runs with no parse-error abort.

### `roundtable-strategies/` asymmetry note

Per plan §4.1 and the Phase 7-lite addendum extension: `roundtable-execution/` is **executable via Read** (the executable-skill-reference pattern, where `phase-2-core.md` is consumed at runtime via Read by `commands/roundtable.md`). `roundtable-strategies/` is **parsed by the command, documentation-only at runtime** (Option B parser Reads the strategy doc, extracts `## Strategy hooks` opening line, matches against the fixture, then proceeds; facilitator does NOT Read strategy docs at runtime). This asymmetry is intentional: it keeps strategy docs human-authored markdown without forcing them into executable form, while still being deterministic.

### CI anchor drift check

`skills/dev-testing/references/strategy-hook-anchor-check.md` ships an executable bash drift detector that, for each of 5 strategy docs, asserts the opening line of `## Strategy hooks` matches one of the 5 fixture regexes. Verified clean against all 5 strategies at §4.2 ship time. Invocation documented in script header; future strategy doc edits run the script as a regression gate before any commit.

### Drift fixes + pointer sharpening

- `commands/roundtable.md` keyword auto-detect table gained a disclaimer ("hints only; profile YAML is the source of truth"); inline phase enumeration (previously line 194-199 area, with phase-name drift for `consensus-driven` and `six-hats`) removed in favor of a structured Round Execution Loop that dispatches through `phase-2-core.md`.
- `agents/roundtable/facilitator.md`: 3 strategy-doc pointers sharpened from whole-file references to `#strategy-hooks` anchors (lines 533/594/622 area).
- `roundtable-execution/SKILL.md:178` updated from "(the latter still uses pre-7B inline pattern; Phase 4 will align it)" to "(aligned in TECH-002 Phase 4 via uniform dispatch + profiles/roundtable.yaml)". **SKILL.md L178 commitment honored**.
- `output-generation/SKILL.md` extended to v1.1.0: description + dispatch table support `workflow_type=roundtable` via new `skills/output-generation/references/roundtable-summary.md` (mirror of `brainstorm.md` pattern). Closes the analogous output-template gap that would have aborted Phase 3 for roundtable native post-Phase-4 (review #5 A1 fix).

### Line count impact (Phase 4 actual)

| File | After Phase 7B | After Phase 7-lite | After Phase 4 | Target (Phase 8) |
|------|----------------|---------------------|---------------|------------------|
| `commands/roundtable.md` | 437 | 437 | **479** (+42 master expansion) | ~600 |
| `commands/specs.md` | 600 | 600 | 600 (unchanged) | ~150 |
| `commands/design.md` | 536 | 536 | 536 (unchanged) | ~150 |
| `commands/brainstorm.md` | 482 | 482 | 482 (unchanged) | ~150 |
| New: `profiles/roundtable.yaml` | — | — | **+70** | — |
| New: `output-generation/references/roundtable-summary.md` | — | — | **+140** | — |
| New: `roundtable-execution/references/strategy-resolution.md` | — | — | **+91** | — |
| New: `roundtable-execution/references/strategy-hook-resolution.md` | — | — | **+74** | — |
| New: `dev-testing/references/strategy-hook-anchor-check.md` | — | — | **+85** | — |

Phase 4 added master capability (roundtable.md +42 lines, well under 520 budget) and 5 new reference/profile/output files. Phase 8 will shrink specs/design/brainstorm to ~150 lines each.

### Regression coverage (§4.5)

8-run dogfood across 7 worktrees (`ElfGiftRush_s2s/exp45..exp52`); Step 7 implicit via Step 2. All PASS. Plan §4.5 carries the full scoreboard with strategy + branch + artifact counts per step. Post-Phase-4 baseline frozen at `.s2s/test-baselines/exp45-roundtable-native-post-phase4.md`.

### Diagnostic findings (4, all pre-existing, non-blocking)

Surfaced during §4.5 dogfood; documented in plan §8 for post-Phase-4 hardening:

1. **agent-resume gap**: `phase-2-core.md` Step 2.2a/2.3a `Task.resume: "{agent_id}"` expectation doesn't match Claude Code's SendMessage-by-name harness. Workaround: cold-start each round via Agent spawn with full canonical YAML context (self-sufficient). Doc fix: phase-2-core.md should clarify resume is Task-tool optional optimization; cold-start is the fallback.
2. **R1 observer false-positive on empty-by-design artifact maps**: round-1 session-observer raises a finding when an artifact_type (e.g. NFR) has 0 entries because the topic didn't surface them. Empty maps are valid per profile schema. Fix: observer should distinguish "empty by design" from "empty by failure".
3. **token-tracker.sh exit 1 quirk**: init step returns exit 1 despite valid output. Cosmetic only.
4. **session_id timestamp format divergence**: master path (Steps 6, 8) generates `{date}-{HHMMSS}-{workflow}-{slug}`; direct path (Steps 3-5) generates `{date}-{workflow}-{slug}`. Both correctly carry the workflow_type prefix per §4.3 (not a regression). Fix: unify to `{date}-{HHMMSS}` form in both paths (matches Plan ID convention; collision-safe).

### Decisions resolved by Phase 4

- **Option A/B/C wiring** (deferred from 7-lite to Phase 4 §242): Option B chosen, implemented, validated.
- **D3 strategy resolution hierarchy** (flagged at 7-lite §242): codified across 4 surfaces (SKILL.md, profile-schema.md, config.yaml, strategy-resolution.md reference).
- **roundtable.md master capability** (original ADR target architecture): delivered for all 4 workflow types via uniform dispatch through `phase-2-core.md`.
- **`profiles/roundtable.yaml` existence** (smoke-test blocker): file created per plugin runtime spec; native `/s2s:roundtable` no longer aborts.

### Remaining phases (after Phase 4)

- **Phase 8 (next, ~2-3h)**: thin launcher conversion (specs/design/brainstorm → ~150 lines each). Mechanical work; Phase 4 made the master capable for all 4 workflows including roundtable native. Regression replay target: structurally-equivalent output vs exp45-post-phase4 baseline (for roundtable native) and exp44-post-phase7b baselines (for specs/design/brainstorm).
- **Six-hats wiring (prerequisite-blocked)**: empirical baseline acquisition still required. Phase 4's Option B parser makes this a configuration change only (add a deterministic anchor policy to `strategy-hook-resolution.md`); no architectural work.
- **Backward-compat resume probe** (deferred from §4.5): pre-Phase-4 session resume via Branch 3 should be verified visibly. Non-blocking for PR; Branch 3 logic statically reviewed during §4.2 step 3.

v0.4.0 → main release remains gated on Phase 8. Phase 4 alone delivers user-visible master path (native `/s2s:roundtable` works; `/s2s:roundtable --workflow-type X` routes through master) but does not shrink the inline launchers yet.

---

## Phase 8 addendum (2026-05-26)

**Plan**: `.s2s/plans/20260521-tech002-phase8-thin-launchers.md` (drafted 2026-05-21, self-review rounds 1-2 applied same day).
**8.0 audit**: `.s2s/plans/20260521-tech002-phase8-8.0-audit.md`.
**Branch**: `feature/TECH-002-phase8-thin-launchers`.

Phase 8 is the final step of the TECH-002 command-unification arc. It collapses `commands/{specs,design,brainstorm}.md` into thin launchers and finishes the master generalization Phase 4 started.

### Substantive finding (round-1 self-review)

Phase 4 made the master's PHASE 2 (round loop) profile-driven but left PHASE 0+1 (auto-detect + session setup) roundtable-shaped. Static + empirical audit (3 Phase 4 master-path sessions: exp49/exp51/exp52) showed:
- master created NO snapshot files (`config-snapshot.yaml`, `context-snapshot.yaml`), although `phase-2-core.md` §2.0/§3 documents them as canonical inputs (flags, limits, escalation, project context)
- session-file skeleton was roundtable-shaped (artifacts `{decisions, open_questions, conflicts}`, `agenda` single `main`, missing `metrics.by_state` / `metrics.topics` / `validation:`)
- `workflow_type` literal was "soft-broken" at 5 sites (the LLM substituted by inference)

`phase-2-core.md` L859 anticipated this: *"Phase 1 (init, profile-aware Phase 1 setup) and Phase 3 (output generation) remain inline in each command. They are out of scope for 7B; cleanup deferred to Phase 8."* Phase 8 owns that cleanup.

### Pattern 1 (decision)

Handoff mechanism: the thin launcher Read-and-follows `commands/roundtable.md`. Architecturally identical to the way commands Read `phase-2-core.md`. Matches the BACKLOG target architecture (roundtable.md = fat master ~600; others = thin launchers). Pattern 2 (extract the master's orchestration into a shared skill reference) was rejected: re-opens the master 2 weeks after Phase 4 stabilized it for no behavioral gain; recorded as the documented escalation if Pattern 1 proves brittle in practice.

### Deliverables

**8.1 master generalization** (the keystone, `roundtable.md` 479 → 592 lines, ≤600):
- profile-driven PHASE 0+1 (folder + 3 snapshots + skeleton from `PROFILE`)
- `progress.axis` discriminant: `agenda` produces `agenda:` + `metrics.topics`; `disney_phase` produces `phases:`/`current_phase:` + `metrics.phases`
- `topic` resolved per `PROFILE.topic.source` (cli-arg vs `pattern`-synthesized); "Validate topic" prompts only when `source == cli-arg.topic`
- 5 workflow_type literal sites parametrized (L260 session file, L323 banner, L346/352 resume state.json, L108 grep, L75 fast-path scope)
- `## Invocation modes` contract note: native vs delegated entry + handoff variables
- PHASE 3 caller block aligned to read flags from `config-snapshot.yaml` per `phase-2-core.md` §3 (removes the undocumented in-context shortcut)
- PHASE 4 Step 4.3 wired to consume `OUTPUT_MERGE_MODE` / `OUTPUT_FORMAT` / `FOCUS_AREA`

**8.2-8.4 thin launchers**:
- `commands/specs.md` 600 → 172 (≤180); Smart Source Detection kept inline
- `commands/design.md` 536 → 114 (≤150)
- `commands/brainstorm.md` 482 → 78 (≤130)
- Each launcher keeps only workflow-specific prep (prereq gate, source detection, existing-output, `--skip-roundtable` mode) and delegates with a minimal handoff: `WORKFLOW_TYPE` + the values the master cannot derive (`INPUT_SOURCES`, `OUTPUT_MERGE_MODE`, `OUTPUT_FORMAT`, `FOCUS_AREA`)
- Resume (`--session`) delegates to the master immediately; the launcher's prerequisite gate runs only on the new-session path

**8.5 regression replay** (dogfood `ElfGiftRush_s2s/exp53..exp57`, **5/5 PASS**):

| Step | Worktree | Run | Strategy | Key Phase 8 check |
|------|----------|-----|----------|--------------------|
| 1 | exp53 | `/s2s:specs --diagnostic` | consensus-driven | snapshots created; topic synthesized `"Requirements definition for ElfGiftRush"`; agenda 6 topics; 12 REQ / 10 BR / 7 NFR / 11 EX / 12 OQ |
| 2 | exp54 | `/s2s:design --diagnostic` | debate | snapshots created; topic `"Architecture design for ElfGiftRush"`; debate_sides + hook_overrides Branch 2; 13 ARCH / 9 COMP / 1 INT / 1 OQ / 1 CONF + 13 ADR |
| 3 | exp55 | `/s2s:brainstorm "..." --diagnostic` | disney (forced) | NO `agenda.yaml`; `progress.axis: disney_phase` produces `current_phase:` + `phases:` + `metrics.phases` (discriminant validated); 17 IDEA / 18 RISK / 18 MIT / 3 OQ |
| 4 | exp56 | `/s2s:roundtable "..." --diagnostic` (native) | standard | snapshots NOW created for native too (pre-Phase-8 they were missing); additive `by_state` / `topics` / `validation`; 5 DEC / 4 OQ / 2 CONF |
| 5 | exp57 | `/s2s:specs --skip-roundtable` | n/a | launcher inline path: no session dir, no state.json; `requirements.md` generated directly |

**Final LOC table**:

| File | Pre-Phase-4 | Post-Phase-4 | Post-Phase-8 |
|------|-------------|--------------|--------------|
| `commands/specs.md` | 1717 | 600 | **172** |
| `commands/design.md` | 1607 | 536 | **114** |
| `commands/brainstorm.md` | 1575 | 482 | **78** |
| `commands/roundtable.md` | 402 | 479 | **592** |
| **Total** | **5301** | **2097** | **956** |

Beats BACKLOG target (~1050).

### Phase 4 finding #4 resolved

Phase 4 §8 finding #4 (session_id timestamp format divergence between master and direct paths) is **resolved** by Phase 8: there is no direct path anymore. All four workflows generate session ids through the master's `{YYYYMMDD}-{HHMMSS}-{workflow_type}-{slug}` format.

### Architecture, end state

- `commands/roundtable.md` (592 lines): master orchestrator. PHASE 0 (auto-detect, scoped to workflow_type) + PHASE 1 (profile-driven session setup) + PHASE 3 (`phase-2-core.md` delegation) + PHASE 4 (completion). Runs natively (`/s2s:roundtable`) or delegated (Read-and-followed by a thin launcher).
- `commands/{specs,design,brainstorm}.md` (172 / 114 / 78 lines): thin launchers. Workflow-specific prep + `--skip-roundtable` inline path + handoff to master.
- `skills/roundtable-execution/profiles/{workflow}.yaml` (4 files): single source of truth for workflow shape. Drives PHASE 0+1 session setup and PHASE 2 round loop.
- `skills/roundtable-execution/references/phase-2-core.md` (881 lines): canonical round-loop algorithm, untouched by Phase 8.

### Remaining

- **Backward-compat resume probe** (deferred from Phase 4 plan §6 line 431 + Phase 8 plan §8.5 step 3): not exercised in §8.5 dogfood. Edge case (pre-Phase-8 native roundtable sessions are rare; pre-Phase-8 specs/design/brainstorm sessions already had snapshots, so resume works). Tracked as non-blocking follow-up.
- **3 unrelated Phase 4 diagnostic findings** still open: agent-resume gap (reproduced in exp54; harness fallback works), R1 observer false-positive on empty artifact maps, token-tracker.sh exit 1 quirk. Post-v0.4.0 hardening.
- **Six-hats wiring**: still prerequisite-blocked on baseline acquisition.

v0.4.0 is now ready for `develop → main` release. Phase 8 was the 6th and final item in milestone v0.4.0.

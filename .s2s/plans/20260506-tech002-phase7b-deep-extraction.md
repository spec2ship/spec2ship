# TECH-002 Phase 7B — Phase 2 Deep Extraction

**Plan ID**: `20260506-tech002-phase7b-deep-extraction`
**Branch**: `feature/TECH-002-phase7b-deep-extraction`
**Forked from**: `develop` @ `0274b4a` (post-Phase 3)
**Author**: Claude (Opus 4.7) + Francesco
**Status**: approved (final review passed 2026-05-11)
**Created**: 2026-05-06
**Last reviewed**: 2026-05-11
**Predecessor plan**: `.s2s/plans/20260505-tech002-phase3-uniformization.md`
**Target spec**: `skills/roundtable-execution/references/phase-2-core.md` §4 handoff notes

---

## 1. Goal

Turn the descriptive `phase-2-core.md` into an executable single-source for Phase 2 Round Loop, so that `/s2s:specs`, `/s2s:design`, `/s2s:brainstorm` no longer carry ~1100 lines of duplicated inline algorithm each. This is the architectural promise of TECH-002 that Phase 3 only set up.

**Non-goals** (deferred):
- Full thin-launcher conversion (Phase 8 — `~150 lines per command`)
- `roundtable.md` as workflow master (Phase 4)
- Strategy skill consolidation (Phase 7)

This plan is scoped strictly to **extraction**. Visible code-volume reduction lands in 7B.4b (~3300 lines removed across 3 commands, Phase 2 inline body excised). Further reduction to ~150-line thin launchers (Phase 1/3 stripping) lands in Phase 8.

## 2. Inputs and constraints

### What we know
- Phase 3 eliminated drift across the 3 commands (PR #13 @ `0274b4a`).
- Canonical reference exists: `skills/roundtable-execution/references/phase-2-core.md` (264 lines, descriptive).
- Workflow profiles table (§1) captures all *necessary* per-workflow differences.
- `roundtable-strategies` skill exists but is not actually consumed by commands (declared, not used).
- We have a specs regression baseline: `exp42-specs-pre-phase3.md` + `exp43-specs-post-phase3.md`.

### What we DON'T have (risks for blast radius)
- **No design baseline**. `/s2s:design --verbose --diagnostic` has never been replayed against a frozen artifact set. Phase 7B will modify design.md → without a baseline we can't prove behavioral equivalence.
- **No brainstorm baseline**. Same problem.
- **No measure of how Claude Code platform has evolved** since TECH-002 design (Jan 2026). Re-baseline is point 6 of the handoff notes.

### Hard constraints
- Public repo: raw replay artifacts stay in `ElfGiftRush_s2s` (per `feedback_test_data_split.md`).
- Atomic PRs: Phase 3 was 1 small PR. Phase 7B should be ≤ 2 PRs (extraction + cleanup).
- No behavioral regression vs current state on the specs path (verifiable).
- Behavioral parity on design/brainstorm paths must be argued structurally (no baseline yet).

## 3. Approach evaluation

### Option A — pure extraction (recommended)

Extract `phase-2-core.md` to executable. Commands are modified to **Read** the extracted file at the start of Phase 2 and follow its instructions, replacing inline pseudocode. Profile is selected via `workflow_type` argument injection.

- ✅ Single PR, contained blast radius.
- ✅ Commands shrink to ~600 lines each (~3300 total lines removed) but not yet "thin launchers" (~150 each).
- ✅ Phase 8 becomes a small subsequent PR (just stripping init/close into helpers).
- ⚠ Pattern: "command Reads skill reference and follows it" is already used (round-validation, token-tracking) — proven approach.
- ⚠ Risk: the executable form must handle ALL parameterizations correctly. One bug = 3 workflows broken.

### Option B — extraction + thin-launcher in one shot

Combine Phase 7B + 8: extract the algorithm AND convert commands to ~150-line thin launchers in the same PR.

- ✅ Single big PR delivers the headline architectural change.
- ❌ Bigger blast radius: harder to bisect if regression appears.
- ❌ Mixes two concerns: "is the extraction correct?" AND "is the launcher wiring correct?"
- ❌ Violates the lesson from Phase 3: small atomic PRs > one large PR.

### Option C — extraction + thin-launcher for ONE command only

Pilot the full pattern on `specs.md` only (we have a baseline there). `design.md` and `brainstorm.md` stay inline until baselines exist.

- ✅ Lowest blast radius, highest confidence.
- ✅ Validates the full pattern (extraction + launcher) end-to-end.
- ❌ Leaves the other two commands inconsistent — drift risk re-emerges.
- ❌ Multi-PR sequence: 7B-pilot, then 7B-rest, then 8.

### Recommendation: **Option A**

Reasons:
1. Phase 3 paved the way — drift is gone, profile differences are explicit.
2. The "Read+follow reference" pattern is already established for smaller modules (token-tracking, round-validation). Scaling it to Phase 2 is incremental, not novel.
3. Blast radius is bounded: if extraction has a bug, we revert one PR.
4. Phase 8 (thin launchers) becomes mechanical after 7B succeeds — strip Phase 1 and Phase 3 sections, leave the existing skeleton.
5. Acquiring design/brainstorm baselines is a prerequisite *anyway*, regardless of A/B/C.

## 4. Sub-phases

The work is split into 9 sub-phases (7B.0 through 7B.7, with 7B.3.5 inserted as contract design and 7B.4 split into 7B.4a/4b). 7B.0–7B.3.5 are prep/research; 7B.4–7B.6 are the actual extraction; 7B.7 is the final regression replay.

Smoke tests are interleaved between 7B.4a/4b and after 7B.4b to catch breakage early instead of accumulating risk to the final replay.

### 7B.0 — Re-baseline platform + audit Phase 1/3 drift (research, ~1.5h)

**Goal**:
- Confirm the extraction approach is still optimal given Claude Code evolution since Jan 2026.
- Audit Phase 1 (init) and Phase 3 (close) sections of the 3 commands for residual drift, since these stay inline post-7B.

**Actions**:
1. Audit Claude Code platform additions: deferred tools, scheduled wakeups, richer agent-invocation primitives, plugin features, skill auto-invocation.
2. Specifically check: is there a new way to "compose" a command from a skill that's better than `Read` + follow? (e.g., command frontmatter `extends:` field, skill execution semantics).
3. Decision point: if a better primitive exists, revise §3 approach. Otherwise proceed with Option A as-is.
4. Audit Phase 1 sections in `commands/{specs,design,brainstorm}.md` for drift (similar to Phase 3 mapping but for Phase 1 only). Same for Phase 3 (close-session) sections.
5. Classify any drift found: necessary (workflow-specific) vs accidental.
6. Scope decision (G16 threshold):
   - If accidental drift fixes total ≤ ~30 lines per command and ≤ 6 fixes total: include in 7B (do them now while context is fresh).
   - Otherwise: defer to Phase 8 (where Phase 1/3 are already in scope for thin-launcher conversion).
7. Decide handling of `roundtable-execution/SKILL.md` (G10): does it reference `phase-2-core.md` post-7B or stay independent?
   - Default: SKILL.md becomes a thin overview pointing to `phase-2-core.md` for execution details, eliminating the SKILL.md ↔ commands drift (Step 2.10/2.11 included). This converts the BACKLOG "out-of-scope" item into in-scope.
   - Fallback: if SKILL.md restructure exceeds 1h, defer to Phase 4 (current BACKLOG plan).
8. Decide ADR strategy (G15): does the extracted-module pattern warrant a new ADR or an update to ADR-0011?
   - Default: append a section to ADR-0011 documenting the executable-skill-reference pattern.

**Deliverable**:
- Appendix A in this plan: platform re-baseline findings.
- Appendix B in this plan: Phase 1/3 drift audit report.
- Appendix D in this plan: SKILL.md handling decision + ADR strategy.

### 7B.1 — Acquire design + brainstorm baselines (regression prep, ~30min)

**Goal**: have structural fingerprints for design and brainstorm BEFORE we modify them.

**Pre-condition**: spec2ship plugin must be installed from the post-Phase 3 commit. Since develop @ `0274b4a` and the current feature branch (pre-changes) point to the same code state, either works. Verify with `git log -1 --oneline` before running.

**Actions**:
1. In `ElfGiftRush_s2s` create worktrees `exp43-design` and `exp43-brainstorm` (naming aligned to exp43 = post-Phase 3, even though specs's exp43 was first).
2. Run `/s2s:design --verbose --diagnostic` and `/s2s:brainstorm --verbose --diagnostic` against the same project context used for exp42/exp43 specs.
3. Generate structural summaries → commit in `spec2ship/.s2s/test-baselines/exp43-{design,brainstorm}-pre-phase7b.md` (public-safe, schema invariants only). Note: specs baseline is `exp43-specs-post-phase3.md` — different naming because it served a different role. Future Phase 7B baselines all follow `exp43-{workflow}-pre-phase7b.md` pattern.
4. Commit raw artifacts in `ElfGiftRush_s2s` (private).

**Deliverable**: 2 new structural summaries in `.s2s/test-baselines/`.

### 7B.2 — Investigate F2 (session-observer activation, ~30min)

**Goal**: understand why Step 2.6c is consistently skipped at runtime BEFORE extracting.

**Why before extraction**: the abstraction we extract should fix or explicitly document this — otherwise we extract a broken spec.

**Actions**:
1. Read current Step 2.6c text in all 3 commands.
2. Compare against `session-observer` agent activation pattern.
3. Hypothesis check: is it conditional on `--diagnostic` flag? Is the `Use the session-observer agent` invocation pattern correct?
4. Identify root cause: runtime quirk vs spec ambiguity.

**Deliverable**:
- If runtime quirk: file BUG entry, leave 2.6c as-is in extraction (preserve current behavior).
- If spec ambiguity: fix the activation pattern in the extracted module.

### 7B.3 — Profile YAML schema (~1h)

**Goal**: define the per-workflow profile data that the extracted algorithm consumes.

**Actions**:
1. Design schema for `skills/roundtable-execution/profiles/{specs,design,brainstorm}.yaml` capturing every cell in §1 of `phase-2-core.md`.
2. Schema fields: `workflow_type`, `topic_pattern`, `state_phase`, `participants[]`, `artifact_types[]`, `progress_axis`, `agenda_count_default`, `synthesis_input_progress_field`, `synthesis_output_progress_field`, `round_summary_tag`, `next_values[]`, `has_phase_transition`, `display_block_style`.
3. Validate: every behavioral difference observed in commands maps to ONE profile field.
4. Update `phase-2-core.md` §1 to match the schema (table → schema).

**Deliverable**: 3 profile YAML files + schema doc.

### 7B.3.5 — Design extraction contract (~1h, prerequisite for 7B.4)

**Goal**: specify concretely how a command invokes the extracted Phase 2 module, before writing the executable form.

**Decision points (to be resolved here, not in 7B.4)**:

1. **Profile injection mechanism**: how does `workflow_type` reach `phase-2-core.md`?
   - **Option I**: command sets shell variable `WORKFLOW_TYPE`, phase-2-core.md references it explicitly.
   - **Option II**: command embeds the profile literally before Reading phase-2-core.md (load → inline → follow).
   - **Option III**: command says "Read profiles/{workflow}.yaml as PROFILE, then Read phase-2-core.md and apply PROFILE".
   - Evaluate vs current Read-and-follow patterns (token-tracking, round-validation): which mechanism do they use? Match for consistency.

2. **Placeholder syntax**: `{{profile.field}}` literal substitution vs narrative reference ("the workflow_type from the loaded profile") vs prose with "see profile" pointers.
   - LLM-followability matters more than parser-cleanliness here.

3. **Runtime flag visibility**: how `--verbose`, `--diagnostic`, `--interactive` reach the extracted module (see §11 Runtime flag plumbing).

4. **Return semantics**: what happens after Step 2.9 dispatches `conclude`? Where does control return — back to the command for Phase 3 invocation, or does phase-2-core.md call into Phase 3? Default: control returns to command.

5. **Resume semantics preservation**: how `agent_state.facilitator.agent_id` resume logic survives the extraction. The extracted module must read+update session state correctly.

**Feasibility prototype (G12)** — gate before 7B.4:

The current "Read+follow" pattern is proven on token-tracking.md (262 lines) and round-validation.md (81 lines). Phase 2 extraction targets ~500 lines, an unproven scale. Validate before committing to full rewrite:

1. Extract ONLY Step 2.1 to a temporary file `references/_proto-step-2-1.md` (descriptive → executable form, with chosen plumbing mechanism from decisions 1-3 above).
2. Modify `commands/specs.md` Step 2.1 only to consume the prototype file via the proposed contract.
3. Run a quick dogfood test in `ElfGiftRush_s2s/exp44-proto-specs` (1 round only).
4. Verify: dump file produced correctly, state.json updated, T1 checkpoint fires, profile values applied correctly.

**Pass**: proceed with 7B.4 using the validated mechanism.
**Fail**: identify which plumbing option failed, revise contract, iterate. If 3 iterations fail, trigger Fallback B (§7).
**Cleanup mechanism**: prototype changes go on an ephemeral commit on the feature branch (subject prefix `prototype:`). After validation, `git revert <prototype-sha>` to undo the changes; the revert commit documents the experiment. Do NOT amend or reset — preserve audit trail. The temp file `_proto-step-2-1.md` is deleted by the revert. Only `Appendix C` of this plan retains the design lessons.

**Deliverable**:
- Appendix C in this plan: a concrete example showing Step 2.1 in extracted form, with all decisions made explicit. This becomes the template for 7B.4.
- Feasibility prototype outcome documented (pass/fail + observations).

### 7B.4a — Rewrite phase-2-core.md as executable (~3-4h)

**Goal**: turn the descriptive reference into instructions a command can Read and execute. Commands are NOT yet modified at this sub-phase.

**Actions**:
1. Rewrite `phase-2-core.md` from "this is what happens" to "do this".
2. Apply parameterization mechanism per the decision in 7B.3.5 (default: profile-loaded via Read + conditional sections for runtime flags per §11 Option III).
3. Embed step-by-step instructions identical to today's commands but profile-aware.
4. Cross-link to extracted sub-modules (artifact-schemas/, disney-phase-machine.md from 7B.5).
5. Validate against §10 contract invariants by walk-through.

**Spec walk-through 1** (G13 — renamed from "smoke test" because it's not a runtime test, ~15min):
1. Pick `workflow_type=specs` profile.
2. Walk through phase-2-core.md step by step (2.0 → 2.9).
3. For each step, verify: (a) all `{{profile.X}}` references resolve, (b) all conditional sections (IF --verbose, IF --diagnostic) have defined behavior, (c) every output mentioned in §10 contract invariants is produced.
4. Repeat for `design` and `brainstorm` profiles (especially: brainstorm has 2.6d phase transition; verify it triggers correctly).
5. Identify and fix any "dangling" references or unresolved placeholders before 7B.4b touches the commands.

No code change to commands yet.

**Deliverable**: `phase-2-core.md` v2 (executable, ~400-500 lines). Commands still have inline Phase 2 (untouched).

### 7B.4b — Wire commands to consume phase-2-core.md (~3-4h)

**Goal**: replace inline Phase 2 in the 3 commands with the contract invocation.

**Actions**:
1. Each command's Phase 2 section becomes a short invocation matching the contract (per 7B.3.5 worked example):
   - Load profile from `skills/roundtable-execution/profiles/{workflow_type}.yaml`.
   - Read `skills/roundtable-execution/references/phase-2-core.md`.
   - Execute its instructions with the loaded profile and runtime flags.
2. Remove the inline Phase 2 body from `commands/specs.md`, `commands/design.md`, `commands/brainstorm.md`.
3. Preserve Phase 1 (init), Phase 3 (close), and command-specific pre/post hooks inline (those are out of scope for 7B).
4. If 7B.0 scope decision included Phase 1/3 drift fixes, apply them here too.

**Smoke test 2** (G13, ~15min): run `/s2s:specs --verbose --diagnostic` for 1 round only in `ElfGiftRush_s2s/exp44-smoke-specs`. Quick check vs exp43 specs baseline:
- Phase 2 produces dump files in `rounds/`.
- state.json updates correctly.
- T1/T2/T3 checkpoints fire.
- Resume keys saved.

**Pass**: proceed to 7B.5/7B.6.
**Fail**: do NOT continue to 7B.5/7B.6 — investigate and fix or revert. Avoid stacking changes on a broken base.

**Deliverable**: 3 commands shrunk by ~1000-1100 lines each (Phase 2 body removed). Contract invocation documented at the top of each command's Phase 2 section.

### 7B.5 — Extract artifact schemas + Disney machine (~1-2h)

**Goal**: factor out sub-modules absorbed into `phase-2-core.md` during 7B.4a, to keep the executable module under ~500 lines (R7).

**Source-of-truth after 7B.4a/b**: artifact schemas and Disney phase machine now live INSIDE `phase-2-core.md` (absorbed from the commands during 7B.4a). 7B.5 splits them out to their own reference files for readability.

**Actions**:
1. Identify the artifact schema blocks inside `phase-2-core.md`. Inventory: REQ, BR, NFR, EX, OQ, CONF (specs); ARCH, COMP, INT, OQ, CONF (design); IDEA, RISK, MIT, OQ, CONF (brainstorm). Total: 11 unique types (CONF and OQ shared across workflows).
2. Move each schema to `references/artifact-schemas/{type}.md` (11 files).
3. Replace inline schemas in `phase-2-core.md` with: "For artifact type `{TYPE}`, Read `references/artifact-schemas/{type}.md`."
4. Same treatment for Disney phase machine: extract Step 2.6d body to `references/disney-phase-machine.md`. Reference from `phase-2-core.md` Step 2.6d.
5. Spec walk-through 1.5: re-verify §10 contract invariants still hold after extraction (no field lost).

**Deliverable**:
- `references/artifact-schemas/` directory with one file per type.
- `references/disney-phase-machine.md`.
- `phase-2-core.md` now ~300-400 lines (down from ~500 in 7B.4a).

### 7B.6 — Strategy hooks contract (~1h)

**Goal**: define hook points in `phase-2-core.md` where strategy can inject variation, WITHOUT yet implementing the wiring (Phase 7 territory).

**Scope clarification (G11)**:
- **In 7B.6**: define WHERE strategy variations inject (the hook points in the executable module) and document the contract.
- **In Phase 7** (later): strategy skill consolidation actually populates the hooks. Until then, current inline strategy behavior is replicated by the extracted module reading the same defaults.
- This means 7B.6 produces a **placeholder + contract**, not a working strategy injection. The behavior is unchanged because the strategy still comes from the same source (currently inline → soon `roundtable-strategies/`).

**Actions**:
1. Inventory current strategy-specific behavior:
   - `debate` strategy in design: optional `debate_phase` field in round summary.
   - `disney` strategy in brainstorm: phase machine (already extracted in 7B.5).
   - `six-hats`: no current command-level customization.
2. Define hook points in `phase-2-core.md` where strategy can inject variation. Naming convention: `{{strategy.X}}` references and inline "IF strategy is debate: also include `debate_phase` in round_summary" conditional sections (matching §11 Option III pattern).
3. Document where strategy data CURRENTLY comes from (inline command default) vs where it WILL come from (Phase 7: `roundtable-strategies/references/{strategy}.md`).
4. Verify: debate strategy still produces `debate_phase` field in design output (no behavior change).

**Deliverable**: documented strategy hook points in `phase-2-core.md` + handoff note in plan §9 for Phase 7 wiring.

### 7B.7 — Verification (regression replay, ~1h)

**Goal**: prove no behavioral regression vs the 3 baselines from 7B.1.

**Actions**:
1. In `ElfGiftRush_s2s` create `exp44-{specs,design,brainstorm}` worktrees on the post-7B branch.
2. Run each workflow with `--verbose --diagnostic`.
3. Generate structural fingerprints, compare to `exp43-*-pre-phase7b.md` baselines.
4. Document deltas in `spec2ship/.s2s/test-baselines/exp44-*-post-phase7b.md`.

**Pass criteria** (explicit thresholds — G8):
- Schema invariants **identical** (artifact key shapes, dump file naming, verification block structure, state.json shape). Hard equality, no tolerance.
- `rounds_completed` count: **exact match** with baseline (LLM stops at same min_rounds/max_rounds boundary).
- `artifacts.total` count: **±2** vs baseline (LLM nondeterminism allowance per session).
- `tokens.total`: **informational only**, no threshold (varies with prompt/response length).
- Dump file count per round: **exact match** (3 + N_participants per round).
- Step 2.6c invocation count: **must not regress** below F2 baseline (specs: 1/4 in exp43; design/brainstorm: TBD in 7B.1).
- Token checkpoint capture file (`tokens.csv` or equivalent): **exact** T1/T2/T3 sequence per round.

**Fail criteria** (revert and re-investigate):
- Any schema mismatch.
- Lost dump files or new structural drift.
- Step 2.6c regression below F2 baseline.
- Resume failure on a pre-7B in-progress session (G7).
- Min_rounds enforcement broken (round count below configured min when LLM tries to conclude early).

## 5. Risk register

| # | Risk | Likelihood | Impact | Mitigation |
|---|------|-----------|--------|------------|
| R1 | Profile schema misses a workflow nuance, causing latent drift | medium | high | 7B.3 explicit mapping audit; design.md/brainstorm.md baselines from 7B.1 catch it |
| R2 | Executable form has a placeholder bug breaking all 3 workflows | low | critical | 7B.7 regression replay against 3 baselines (specs+design+brainstorm) |
| R3 | F2 (session-observer) turns out to require platform-level fix beyond our control | medium | low | 7B.2 documents and accepts current behavior; F2 stays known-issue |
| R4 | Claude Code newer features (7B.0) suggest different approach mid-plan | low | medium | 7B.0 is gate to §3 approach selection; revise plan if needed |
| R5 | Commands shrink from ~1700 to ~600 lines; review burden of 1100-line deletion is large | medium | low | Split into 2 PRs if needed: 7B.0-7B.4b (extraction + wiring) + 7B.5-7B.6 (sub-extractions) |
| R6 | Strategy hooks reveal that current `debate_phase` handling is itself drift, not necessary | low | medium | 7B.6 inventory step exposes this; treat as out-of-scope follow-up |
| R7 | Extracted phase-2-core.md exceeds ~500 lines and becomes hard to read | low | low | Use sub-references for sub-modules (artifact schemas already extracted in 7B.5) |
| R8 | LLM cannot reliably follow ~500-line executable Read-and-follow doc (untested scale) | medium | high | 7B.3.5 feasibility prototype on Step 2.1 only; if it fails, revise mechanism before full rewrite |
| R9 | SKILL.md restructure (G10 in-scope option) blows up 7B.0 timebox and delays start of 7B.4 | medium | medium | 7B.0 fallback: defer SKILL.md restructure to Phase 4; document deferral in Appendix D |

## 6. Done criteria

- [ ] 7B.0 platform re-baseline documented; Phase 1/3 drift audit done; SKILL.md handling decision made; ADR strategy decided; approach confirmed or revised.
- [ ] 7B.1 design + brainstorm baselines committed in `.s2s/test-baselines/` (public structural; raw in `ElfGiftRush_s2s`).
- [ ] 7B.2 F2 root cause documented (BUG entry or extraction fix).
- [ ] 7B.3 profile YAML schema + 3 profile files committed.
- [ ] 7B.3.5 extraction contract documented with worked example AND feasibility prototype passed.
- [ ] 7B.4a `phase-2-core.md` executable form complete; smoke test 1 passed.
- [ ] 7B.4b commands shrink ~1000+ lines each; Phase 2 sections are short invocations matching the contract; smoke test 2 passed.
- [ ] 7B.5 artifact schemas extracted (11 type files); Disney machine extracted.
- [ ] 7B.6 strategy hook points defined in `phase-2-core.md`; `debate_phase` field still emitted by design+debate (no behavior change).
- [ ] 7B.7 exp44 replay vs exp43 baselines: structural invariants match for all 3 workflows within thresholds (§7B.7).
- [ ] **Contract invariants (§10) verified**: dump naming, state.json shape, T1/T2/T3 sequence, resume logic, min_rounds, auto-detect, frontmatter all preserved.
- [ ] **In-progress session resume tested (G7)**: a session started pre-7B can resume on the post-7B branch (state.json forward-compat).
- [ ] `roundtable-execution/SKILL.md` aligned with `phase-2-core.md` per 7B.0 decision (or deferral documented).
- [ ] `.claude/CLAUDE.md` Component Guidelines updated to reflect phase-2-core.md being executable.
- [ ] `.claude/s2s-development.md` updated with the executable-skill-reference pattern (G14 — BACKLOG had this for Phase 8, moved up to Phase 7B).
- [ ] ADR-0011 updated (or new ADR created) per 7B.0 decision.
- [ ] BACKLOG.md updated: Phase 7B ✅, current state advanced; out-of-scope items resolved or re-tracked.
- [ ] Memory: update `project_tech002_progress.md` with Phase 7B done; consider new feedback memory if extraction pattern is reusable.
- [ ] PR opened against `develop` with structural summary linking to 3 exp44 fingerprints.

## 7. PR strategy

**Default**: 1 PR (`feature/TECH-002-phase7b-deep-extraction` → `develop`).

**Fallback A** (if R5 materializes — review burden too large): split into 2 PRs:
- PR-A: 7B.0–7B.4b (extraction core + command wiring + smoke tests passed)
- PR-B: 7B.5–7B.6 (artifact schemas + strategy hooks) — depends on PR-A merged

**Fallback B** (if R8 materializes): pivot to Option C from §3 (pilot specs only), then iterate on design/brainstorm in subsequent PRs.

Concrete triggers for Fallback B:
- 7B.3.5 prototype fails 3+ iterations with different plumbing options.
- Smoke test 2 in 7B.4b reveals systematic LLM "drift" from `phase-2-core.md` instructions (e.g., skipped steps, hallucinated fields) that can't be fixed by prompt clarification.
- 7B.7 specs replay passes but design and/or brainstorm fail with schema mismatches that trace back to LLM-following issues (not bugs in our extraction).

If triggered: stop, revert 7B.4b for design+brainstorm only, ship Phase 7B as specs-only; open Phase 7B.2 ticket for design+brainstorm with revised approach.

All PRs targeted at v0.4.0 milestone (still in develop, not yet released to main).

**Internal commit checkpoints** (regardless of PR strategy):
- Commit after 7B.0, 7B.1, 7B.2, 7B.3, 7B.3.5 (research/prep — bisectable)
- Commit after 7B.4a (executable doc, no command changes — should not break anything)
- Commit after 7B.4b + smoke test 2 passed (commands now consume — biggest single change)
- Commit after 7B.5, 7B.6 (sub-extractions)
- Commit after 7B.7 (test-baselines + final docs)

## 8. Out-of-scope follow-ups (tracked, not actioned)

- `session-schema.md` completeness for design `INT-*` and brainstorm `CONF-*` (predates Phase 7B).
- SKILL.md vs commands divergence on Step 2.10/2.11: in scope IFF 7B.0 picks the default option (SKILL.md becomes thin overview). If 7B.0 picks the fallback, this stays deferred to Phase 4.
- `verification:` block emission instability (mark as MANDATORY in Phase 7B as side-benefit, but full fix requires runtime investigation).

## 9. Exit pointer

Successor plan after Phase 7B merges:
- Phase 7 (strategy skill consolidation) — make commands actually USE roundtable-strategies.
- Phase 4 (roundtable.md as master) — `roundtable.md` becomes the entry that all workflows funnel through.
- Phase 8 (thin launcher conversion) — strip remaining Phase 1+3 boilerplate from specs/design/brainstorm.

After 4+8: target architecture from BACKLOG.md achieved. v0.4.0 → main.

## 10. Contract invariants (must NOT change)

The extracted module must preserve the following observable contract. Any of these breaking is grounds for revert.

### Filesystem contract
- Session folder layout: `.s2s/sessions/{session-id}/{state.json, session.yaml, rounds/, ...}`.
- Verbose dump naming: `rounds/{NNN}-{PP}-{actor}.yaml` per `verbose-dump-format.md` (NNN=3-digit round, PP=2-digit phase, actor=facilitator-question / facilitator-synthesis / participant-id).
- Artifact embedding: artifacts inside `session.yaml` under `artifacts.{type}` map (per ADR-0008/0010), NOT separate files.

### State contract
- `state.json` shape: same fields, same nesting. Fast-path read by auto-detect (Phase 6) must keep working.
- `agent_state.facilitator.{agent_id, last_round, last_action}` resume keys preserved.
- `agent_state.participants.{id}.{agent_id, last_round}` resume keys preserved.

### Algorithm contract
- Step ordering 2.0 → 2.1 → 2.2 → 2.3 → 2.4 → 2.5 → 2.6 → 2.6b → 2.6c → 2.6d (brainstorm) → 2.7 → 2.8 → 2.9 unchanged.
- Token checkpoint sequence T1 (after 2.2) → T2 (after 2.3) → T3 (after 2.4) per round.
- Min_rounds enforcement at Step 2.9 (added in Phase 3 — DO NOT lose).
- Step 2.0 Context Capacity Check fires every round.
- Resume conditions for facilitator and participants per `phase-2-core.md` §2.

### User-facing contract
- Command frontmatter: `description`, `allowed-tools`, `argument-hint` unchanged.
- CLI flag semantics: `--verbose`, `--diagnostic`, `--interactive`, `--strategy`, `--participants` (brainstorm) unchanged.
- Round recap display structure (2.7) unchanged.
- Interactive prompts (2.8) unchanged.
- Escalation prompt (2.9) unchanged.

### Output contract
- Verbose dump field structure: header comment, `round/phase/actor/action/started_at/completed_at`, `input/response` as YAML objects, `result`, `tokens`, optional `verification` per workflow.
- Synthesis verification block: `expected_artifacts`, `round_summary`, `agenda_status` OR `phases_status`, `metrics_consistency`, `context_propagation`.

## 11. Runtime flag plumbing (G3 decision)

The 4 commands parse CLI flags and need to expose them to the extracted module. Three options:

### Option I — Bash-exported variables + explicit references
Command runs a small bash snippet to parse `$ARGUMENTS` and `export VERBOSE_FLAG=true`, etc. The extracted module then says "check `$VERBOSE_FLAG`". Pro: state survives across tool calls. Con: not how Claude Code skills are typically authored — most skills use prose conditionals.

### Option II — Profile + runtime override map
Profile YAML has `runtime: {verbose: false, diagnostic: false, interactive: false}` defaults; command overrides them per invocation. `phase-2-core.md` references `profile.runtime.X`. Pro: data-driven, single source. Con: muddles static profile config with per-invocation flags.

### Option III — Conditional sections in extracted module
Command says "running with --verbose" inline before invoking phase-2-core.md. Module has sections "IF the command was invoked with --verbose: write dump file...". Pro: matches how current commands are written. Con: requires the LLM to "remember" the flag state across the read.

**Decision**: resolve in 7B.3.5 with concrete experiment. Default lean: **Option III** (conditional sections), because it matches current proven patterns in spec2ship (e.g., `verbose-dump-format.md` already has "IF `verbose_flag == true`" idioms).

## 12. Backward compatibility (G7)

### In-progress sessions
A session started on develop (pre-7B) must resume on the post-7B branch. Concrete test procedure (post-7B.4b, before 7B.7):

1. In `ElfGiftRush_s2s` create worktree `exp44-resume-test`.
2. Install spec2ship plugin from `develop` (pre-7B): `/plugin marketplace add ...#develop` then `/plugin install s2s@spec2ship`.
3. Start a session: `/s2s:specs --verbose --diagnostic`, complete 2 full rounds, then `/s2s:session:close` or exit.
4. Note the session-id; verify `state.json` exists with `status: in_progress` and `agent_state.facilitator.agent_id` populated.
5. Uninstall: `/plugin marketplace remove spec2ship`; reinstall from feature branch: `/plugin marketplace add ...#feature/TECH-002-phase7b-deep-extraction` then `/plugin install s2s@spec2ship`.
6. Resume: `/s2s:specs` (auto-detect should pick up the in-progress session).
7. Continue for 1 more round.

**Pass criteria**:
- Resume detects the in-progress session (auto-detect from `state.json`).
- Round 3 uses the same `agent_id` for facilitator as Round 2 (continuation, not fresh).
- `state.json` shape is unchanged after Round 3.
- Dump files for Round 3 land in the same `rounds/` folder as Rounds 1-2.

**Fail criteria**: any of the above failing means state.json schema changed in 7B; revert.

### Plugin marketplace consumers
spec2ship is installed as a plugin. Any user with v0.3.x installed who updates to v0.4.0 (with 7B applied) should not see breaking changes. Since v0.4.0 is develop-only and not yet released, this is informational; ensure changelog notes the architectural shift before v0.4.0 → main.

---

## Appendix A — 7B.0 platform re-baseline findings

*(To be filled during 7B.0 execution.)*

## Appendix B — 7B.0 Phase 1/3 drift audit

*(To be filled during 7B.0 execution.)*

## Appendix C — 7B.3.5 extraction contract worked example

*(To be filled during 7B.3.5 execution. Will contain a full Step 2.1 in extracted form, demonstrating profile injection, placeholder syntax, and runtime flag access. Also: feasibility prototype outcome — pass/fail + observations.)*

## Appendix D — SKILL.md handling and ADR strategy

*(To be filled during 7B.0 execution. Will contain: SKILL.md restructure plan or deferral note; ADR-0011 update or new ADR draft.)*

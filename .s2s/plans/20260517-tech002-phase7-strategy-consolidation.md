# TECH-002 Phase 7: strategy skill consolidation

**Plan ID**: `20260517-tech002-phase7-strategy-consolidation`
**Branch**: `feature/TECH-002-phase7-strategy-consolidation`
**Forked from**: `develop` @ `35cdf10` (post Phase 7B PR #14 merge)
**Author**: Claude (Opus 4.7) + Francesco
**Status**: draft (awaiting review)
**Created**: 2026-05-17
**Predecessor plan**: `.s2s/plans/20260506-tech002-phase7b-deep-extraction.md`
**Contract source**: `skills/roundtable-execution/references/strategy-hooks.md` (Phase 7B.6, 2026-05-16)

---

## 1. Goal

Make `roundtable-strategies/` the **source of truth** for strategy-specific Phase 2 behavior. Today (post 7B), commands declare `skills: roundtable-strategies` but never Read the strategy reference docs. Strategy effects (Pro/Con assignment, debate phase, hat role) emerge from the LLM interpreting `STRATEGY` as a string, with the strategy docs sitting unused.

After Phase 7:
- The 5 strategy reference docs (`references/{standard,consensus-driven,debate,disney,six-hats}.md`) formally declare their hook contract per `strategy-hooks.md` §3-§6.
- `phase-2-core.md` Step 2.2c instructs the facilitator to Read the active strategy doc and apply its policy.
- `disney.md` cross-links to `disney-phase-machine.md` so the human-facing strategy doc and the algorithmic state machine are explicitly bound.
- The 3-way doc inconsistency on Step 2.6d positioning in `phase-2-core.md` is resolved.

### Non-goals (deferred)
- **Six-hats wiring**. No empirical baseline exists (six-hats has never been used in dogfood). Wiring without a baseline is unverifiable. Phase 7 documents the contract for six-hats but does not wire it. Tracked in §8.
- **Phase 4 (roundtable.md as master)**. Out of scope. Phase 4 depends on Phase 7 done.
- **Phase 8 (thin launchers)**. Out of scope.
- **Formal `debate-phase-machine.md`** analogous to `disney-phase-machine.md`. Phase 7 formalizes the debate phase progression as a contract in `debate.md` but does not extract a separate algorithmic state machine. Deferred to a follow-up if needed.

## 2. Inputs and constraints

### What we know
- `strategy-hooks.md` (Phase 7B.6, 136 lines) inventories 5 strategies and 4 hooks (debate_role, debate_phase, hat_role, hat_phase) plus the Disney machine (already extracted).
- `phase-2-core.md` Step 2.2c, 2.3c, 2.6a already document the hook points descriptively. They reference `strategy-hooks.md` but do NOT instruct any "Read strategy doc" action.
- 5 strategy reference docs exist: `consensus-driven.md` (176), `debate.md` (183), `disney.md` (184), `six-hats.md` (261), `standard.md` (100). Total 904 lines. Content is human-facing (prompt templates, "how it works", "when to use"), not contract-shaped.
- `roundtable-strategies/SKILL.md` (181 lines, v1.1.0) has workflow defaults table (lines 64-68) + artifact types table (lines 70-76) + strategy-workflow compatibility table. Workflow defaults and artifact types DUPLICATE values in `profiles/{workflow}.yaml` (`default_strategy`, `participants.default`, `artifact_types[].prefix`). This duplication is addressed in sub-phase 7.1b.
- Only `commands/roundtable.md:194` currently does `Read .../roundtable-strategies/references/{strategy}.md` at command level (with inline phase enumeration). The specs/design/brainstorm commands do not. Phase 7 introduces a different pattern (facilitator-level Read at Step 2.2c). Phase 4 (roundtable.md as master) will reconcile the two patterns; Phase 7 must not break the existing command-level Read in `roundtable.md`.

### What we have as baselines
- `.s2s/test-baselines/exp44-specs-post-phase7b.md`: specs+consensus-driven, 5 rounds, no strategy hooks active.
- `.s2s/test-baselines/exp44-design-post-phase7b.md`: design+debate, 4 rounds, **16/16 debate_role** + **4/4 debate_phase** verified.
- `.s2s/test-baselines/exp44-brainstorm-post-phase7b.md`: brainstorm+disney, 3 rounds, Disney machine extraction verified.

These are the regression targets for Phase 7. The debate hook fields are the critical preservation contract.

### Hard constraints
- **Behavioral parity on debate path**: design+debate must still produce `debate_role` in every participant dump and `debate_phase` in every round summary after Phase 7. Structural ratio: `debate_role` count = rounds × participants; `debate_phase` count = rounds. exp44 baseline was 16/16 and 4/4 at 4 rounds. If Phase 7 formalizes the assignment policy and that changes Pro/Con distribution, that is a regression.
- **No change to Disney machine**: `disney-phase-machine.md` algorithmic behavior unchanged. Brainstorm replay must preserve phase progression (`dreamer → realist → critic`, no skipped or duplicated phase); `rounds_completed` within ±1 of exp44 baseline (3 rounds) is acceptable per §10 invariant.
- **Commands stay thin**. Phase 7 should NOT add Read-strategy logic at command level. The wiring lives inside `phase-2-core.md` (facilitator agent), preserving the ~600-line command size achieved in 7B.4b.
- **Atomic PR**. Single PR target develop, milestone v0.4.0.

## 3. Approach evaluation

### Option A: facilitator reads strategy doc inside phase-2-core.md Step 2.2c (recommended)

The facilitator agent, at Step 2.2c (facilitator question prep), Reads `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-strategies/references/{{STRATEGY}}.md` to learn the active strategy's hook policy. The facilitator then emits `participant_context.overrides` populated per that policy. Step 2.3c and Step 2.6a remain as today (consumers of the hook values).

- Commands unchanged (still thin per 7B.4b).
- Strategy doc becomes the single source of policy.
- Behavior change is localized to one step (2.2c), bounded blast radius.
- One Read per round (~180 lines), no caching assumed. Cost bounded and acceptable.

### Option B: command reads strategy doc, injects into PROFILE-like context

Each command, after loading PROFILE, Reads the active strategy doc and merges its hook config into a `STRATEGY_CONFIG` runtime variable consumed by `phase-2-core.md`. The facilitator then uses `STRATEGY_CONFIG` without re-reading.

- Pro: facilitator stays unchanged; hooks visible at command level.
- Con: makes commands less thin (adds ~10-20 lines each), partially undoing 7B.4b.
- Con: adds a new runtime variable type. More moving parts.

### Option C: per-strategy YAML profile (analogous to workflow profile)

Extract strategy config to YAML (`strategies/{strategy}.yaml`) matching a schema like `profile-schema.md`. Commands load both PROFILE and STRATEGY_PROFILE.

- Pro: most structured, machine-parseable, validatable.
- Con: largest refactor: requires schema design + 5 YAML files + 5 doc rewrites + command wiring changes.
- Con: heavier than the actual problem. The strategy hooks are 4 fields across 2 hook points. YAML is overkill.

### Recommendation: Option A

Reasons:
1. Minimal blast radius. Only `phase-2-core.md` Step 2.2c and the 5 strategy doc files change.
2. Commands stay at their post-7B size.
3. Pattern "agent Reads reference doc" is already established for facilitator/participant agents within Phase 2.
4. The Disney precedent supports this: `phase-2-core.md` Step 2.6d (renamed to Step 2.10 in sub-phase 7.5) already does `Read .../disney-phase-machine.md`. Phase 7 extends the same pattern to Step 2.2c for the active strategy doc.
5. Token cost: Step 2.2c fires every round. One Read per round of ~180 lines (active strategy doc), so 3-5 Reads per session in practice. No session-level caching mechanism assumed. Cost bounded and acceptable.

## 4. Sub-phases

The work splits into 8 sub-phases (7.0 through 7.6, with 7.1b inserted between 7.1 and 7.2). 7.0-7.2 are audit + doc formalization. 7.1b deduplicates `SKILL.md` workflow defaults. 7.3-7.4 wire the algorithm. 7.5 renames Step 2.6d → 2.10 across docs. 7.6 is the regression replay.

**Execution order vs sub-phase ID**: sub-phase IDs are stable for referencing, but execution order is: 7.0 → 7.1 → 7.1b → 7.2 → **7.5** → 7.3 → 7.4 → 7.6. 7.5 (Step 2.6d → 2.10 rename) MUST run before 7.3 and 7.4 because the latter two write `Step 2.10` references that depend on the rename being committed in `phase-2-core.md`.

**Total estimated time**: ~7 hours (1.5 + 2 + 0.5 + 0.5 + 0.5 + 1 + 0.25 + 1).

### 7.0: audit strategy docs vs hook contract (research, ~1.5h)

**Goal**: produce a gap matrix per `strategy-hooks.md` §3-§6, extract empirical Pro/Con mapping from exp44 dumps, and confirm facilitator agent file integration path.

**Actions**:
1. For each of the 5 strategy docs, identify which hooks apply and what is already documented vs missing.
2. Specifically:
   - `standard.md`: no hooks. Verify the doc says so explicitly.
   - `consensus-driven.md`: no hooks. Same.
   - `debate.md`: needs explicit Pro/Con assignment policy (currently "automatic OR facilitator" in YAML config block, no concrete rule). Needs explicit `debate_phase` progression contract (currently has opening/rebuttal/closing/synthesis but not tied to round numbers or facilitator decision criteria).
   - `disney.md`: machine already extracted to `disney-phase-machine.md`. Doc should cross-reference it explicitly.
   - `six-hats.md`: untested. Document hook contract for future; mark as deferred wiring.
3. Identify whether `consensus-driven.md` defines any consensus-related hooks that should be formalized (weighted_majority threshold, max_attempts) and whether they belong in profile (workflow level) or strategy (strategy level).
4. Output: gap matrix as a markdown table in this plan or in a 7.0 audit file under `.s2s/`.
5. **Extract empirical Pro/Con mapping from exp44 raw dumps**:
   - **Worktree state**: ensure `ElfGiftRush_s2s` worktree is at branch `exp44-design-post-phase7b` (commit `94afe10`); checkout if not.
   - **Inspect** each round's participant dump (`rounds/{NNN}-02-participant-{role}.yaml`), extract `debate_role` field per `(participant_id, round_index)`.
   - **Output**: empirical map in table form (4 rounds × 4 participants = 16 cells). This is the input to 7.1 `debate.md` policy formalization (R1 mitigation).
   - **Fallback trigger**: if the map is inconsistent across rounds (same participant flipping Pro/Con), invoke R1 fallback in 7.1 (document as "facilitator-driven, no fixed policy").
6. **Reconcile with `commands/roundtable.md:194`**: document the current command-level Read pattern (loads `{strategy}.md` and enumerates phases inline). Phase 7's facilitator-level Read at Step 2.2c must coexist with this; Phase 4 will reconcile. Note any contradiction risk.
7. **Confirm facilitator agent file integration**: verify `agents/roundtable/facilitator.md` frontmatter has `tools: Read, Glob` (it does) and `skills: roundtable-strategies` (it does). Decide whether 7.3 needs an explicit edit to `facilitator.md` body or whether the agent inherits the Read instruction from `phase-2-core.md` Step 2.2c. Default assumption: agent inherits; flag if 7.0 finds gap.
8. **Audit `roundtable-strategies/SKILL.md` workflow defaults vs `profiles/{workflow}.yaml`**: identify duplicated fields (default_strategy, participants.default, artifact_types). Confirm current values match (drift check). Output feeds 7.1b decision.

**Exit condition**: gap matrix produced; empirical Pro/Con map captured (or R1 mitigation triggered); facilitator integration path confirmed; SKILL.md duplication audit complete; per-strategy task list for 7.1 written.

### 7.1: formalize strategy hook contracts in {strategy}.md files (doc, ~2h)

**Goal**: each strategy reference doc gains a `## Strategy hooks` section consumable by `phase-2-core.md` Step 2.2c.

**Actions**:
1. **`debate.md`**: add `## Strategy hooks` section formalizing:
   - **Pro/Con assignment policy**: per-participant role-based mapping derived from empirical exp44 observation (per 7.0 step 5). **IF** exp44 dumps show stability (same participant keeps the same `debate_role` end-to-end), codify as a fixed `{role → debate_role}` table. **IF** exp44 dumps show round-by-round flipping, fall back to documenting "facilitator-driven, no fixed policy" per R1 fallback and skip codifying a table.
   - **Debate phase progression**: **default mapping** `round 1 → opening`, `round 2 → rebuttal`, `round 3 → closing`, `round 4+ → synthesis`. **Fallback policy** for short sessions (sessions that conclude before round 4): if session concludes at round 2, the round 2 phase is `closing`; at round 3, round 3 is `closing` (rebuttal skipped or merged into closing). Codify as a decision table; facilitator may override for edge cases (justification logged in synthesis).
   - **Hook fields emitted**: `debate_role` (participant), `debate_phase` (round summary).
   - **Policy is data, not code**: `debate.md` declares the assignment table + phase progression table as DATA. The generic Read+extract+apply pseudo-code lives once in `phase-2-core.md` Step 2.2c (see Appendix B for shape). Do NOT duplicate pseudo-code per strategy doc.
2. **`disney.md`**: add explicit cross-reference block pointing to `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/disney-phase-machine.md` as the algorithmic source. Mark `disney.md` itself as the human-facing strategy guide; the machine doc as the algorithmic spec. ALSO add a `## Strategy hooks` section with content: "Phase progression determined by `disney-phase-machine.md` via Step 2.10 (Phase Transition). No Step 2.2c per-round overrides emitted; facilitator skips override population for this strategy." This satisfies the done-criteria uniformity requirement (all 5 strategy docs have the section) and signals the facilitator at Step 2.2c to skip overrides.
3. **`consensus-driven.md`** and **`standard.md`**: add `## Strategy hooks` section stating explicitly "No per-round hooks. Algorithm runs with workflow defaults from PROFILE." Avoid future doubt.
4. **`six-hats.md`**: add `## Strategy hooks` section. **Opening line MUST be**: `"No per-round overrides (wiring deferred to future phase — no empirical baseline yet)."` This phrasing matches the facilitator skip-trigger in 7.3 step 3 ("no per-round overrides") so the agent skips override population correctly. Below the opening line, document the `hat_role` and `hat_phase` contract per `strategy-hooks.md` §5-§6 as descriptive prose (future-wiring spec), but the opening line is the operative signal.

**Exit condition**: all 5 strategy docs have a `## Strategy hooks` section. Each section is self-contained enough for `phase-2-core.md` Step 2.2c to consume.

### 7.1b: reconcile SKILL.md workflow defaults with profile YAMLs (doc, ~30min)

**Goal**: remove the silent duplication between `roundtable-strategies/SKILL.md` and `profiles/{workflow}.yaml` without breaking SKILL.md's standalone readability.

**Context**: `roundtable-strategies/SKILL.md` "Workflow-Specific Defaults" table (lines 64-68) and "Artifact Types by Workflow" table (lines 70-76) duplicate `default_strategy`, `participants.default`, `artifact_types[].prefix` from `profiles/{workflow}.yaml`. Drift between the two sources is currently invisible and would compound over time.

**Decision (pinned)**: keep SKILL.md tables (useful for human readers, no plugin runtime depends on them) but add explicit "authoritative source" disclaimer pointing to the profile YAMLs. Stripping the tables would harm skill discoverability; pointer prevents drift escalation.

**Actions**:
1. Edit `roundtable-strategies/SKILL.md` "Workflow-Specific Defaults" section: add a header note above the table — `> **Authoritative source**: profile YAMLs in roundtable-execution/profiles/{workflow}.yaml. The table below is a human-readable summary; if it drifts, the YAML is correct.`
2. Same treatment for "Artifact Types by Workflow" section.
3. Verify the tables match current PROFILE values (drift check from 7.0 step 8). Reconcile any discrepancy to match the YAML.
4. Bump `roundtable-strategies/SKILL.md` `version` field from `1.1.0` to `1.2.0` (additive: contract sections added in 7.1, disclaimer added in 7.1b).

**Exit condition**: SKILL.md duplicated tables have explicit "summary, not authoritative" disclaimers; values match PROFILE; version bumped to 1.2.0.

### 7.2: update strategy-hooks.md inventory (doc, ~30min)

**Goal**: align the inventory document with the formalized strategy docs from 7.1.

**Actions**:
1. Update `strategy-hooks.md` §1 strategy inventory: each row now points to a concrete `## Strategy hooks` section in `{strategy}.md` (not just a strategy doc generically).
2. Update §7 "Where strategy data CURRENTLY comes from": move debate hooks from "LLM-emergent" to "facilitator Reads `debate.md` § Strategy hooks at Step 2.2c".
3. Update §8 "Phase 2 algorithm integration": Step 2.2c now has a concrete Read + apply instruction.
4. Bump status header from "contract documentation (TECH-002 Phase 7B.6)" to `"executable contract (TECH-002 Phase 7, {YYYY-MM-DD})"` — set `YYYY-MM-DD` to today's date at commit time.

**Exit condition**: `strategy-hooks.md` reflects the wired state.

### 7.3: wire phase-2-core.md Step 2.2c (algorithm, ~1h)

**Goal**: add the facilitator Read + apply instruction at Step 2.2c.

**Actions**:
1. In `phase-2-core.md` Step 2.2c (facilitator response template), add a preamble block:
   ```
   **Before generating the response, the facilitator MUST**:
   1. Read `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-strategies/references/{{STRATEGY}}.md`.
      Note: `{{STRATEGY}}` is the runtime variable from caller scope (§2.0 of phase-2-core.md), NOT `session.yaml.strategy_to_use`. For brainstorm, runtime STRATEGY is correctly forced to "disney" at Phase 1 regardless of session.yaml propagation (see §8 brainstorm strategy edge case).
   2. Locate the `## Strategy hooks` section.
   3. IF section is absent OR its opening line contains "no hooks" or "no per-round overrides", skip override population (consensus-driven, standard, disney, six-hats deferred).
   4. ELSE apply the policy to populate `participant_context.overrides` (and `round_summary.debate_phase` at Step 2.6a if applicable).
   ```
   **Read frequency**: Step 2.2c fires every round, so the Read happens once per round (~180 lines, bounded). No session-level caching mechanism is assumed.
2. Where the response schema documents `overrides`, replace the descriptive "see strategy-hooks.md" with a concrete "see {{STRATEGY}}.md § Strategy hooks".
3. Confirm Step 2.3c and Step 2.6a documentation is consistent (they consume; no change).
4. Confirm the existing Step 2.10 disney Read instruction (renamed in 7.5, executed before this sub-phase per the order in §4 intro) still works: no conflict with new Step 2.2c Read, since 2.10 is brainstorm-specific and 2.2c applies to the active strategy.
5. **Facilitator agent file**: based on 7.0 step 7 audit, decide whether `agents/roundtable/facilitator.md` needs an explicit edit. Default expectation: no edit needed because the caller (command) constructs the facilitator prompt from `phase-2-core.md` Step 2.2c text at runtime; updating Step 2.2c automatically propagates to the prompt. If 7.0 found that the agent body lacks a "follow phase-2-core.md" instruction, add it here (~5 lines).
6. **Propagation smoke test**: after editing Step 2.2c, run a minimal smoke test in dogfood (`ElfGiftRush_s2s`): `/s2s:design --strategy debate --rounds 1 --verbose`. Inspect `rounds/001-01-facilitator.yaml` (the facilitator input dump) to confirm the new Read+apply preamble text appears in the prompt the facilitator received. If absent, the caller-side prompt construction did not pick up the Step 2.2c change → debug before proceeding to 7.6 full replay.

**Exit condition**: `phase-2-core.md` Step 2.2c has the explicit Read+apply with documented frequency. Facilitator agent file integration confirmed (no edit or minimal edit). Smoke test confirms preamble propagation to facilitator prompt. A facilitator agent reading the algorithm has zero ambiguity about where strategy policy comes from.

### 7.4: cross-link disney.md and disney-phase-machine.md (doc, ~15min)

**Goal**: make the disney ownership explicit.

**Actions**:
1. In `disney.md`, add a top banner: "Algorithmic implementation: `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/disney-phase-machine.md`. This file is the human-facing strategy description."
2. In `disney-phase-machine.md`, add a reciprocal banner: "Strategy description: `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-strategies/references/disney.md`. This file is the algorithmic spec consumed by `phase-2-core.md` Step 2.10."
3. Verify no contradictory phase descriptions between the two files. Reconcile if any drift.

**Exit condition**: bidirectional cross-link; no doc drift.

### 7.5: rename Step 2.6d to Step 2.10 across phase-2-core.md (doc, ~30min)

**Goal**: resolve the 3-way mismatch deferred from Phase 7B by pinning a single canonical placement.

**Context** (from Phase 7B post-merge review):
- Document layout §2: 2.6c → 2.7 → 2.8 → 2.6d → 2.9 (2.6d at line 780)
- §4 invariant declaration: 2.6c → 2.6d → 2.7 → 2.8 → 2.9
- §2.9b dispatch table: 2.6d fires from Step 2.9 when `next == "phase"`, i.e., 2.9 → 2.6d → loop

Runtime behavior is correct (brainstorm replay PASS, exact rounds match). The bug is documentation clarity.

**Decision (pinned)**: rename Step 2.6d to **Step 2.10 (Phase Transition)** and place it AFTER Step 2.9 in §2 document layout. Rationale: §2.9b dispatch is the authoritative runtime sequence (`next == "phase" → run 2.10 → loop`). Numbering as `2.10` (not `2.9.5`) avoids decimal-decimal ambiguity and follows the post-2.9 dispatch position naturally.

**Actions**:
1. In `phase-2-core.md` §2 document layout: move the Step 2.6d block to after Step 2.9; renumber as Step 2.10. Section heading: `### 2.10 — Phase Transition (brainstorm only, profile.has_phase_transition)`.
2. In `phase-2-core.md` §4 invariant declaration: update sequence to `2.6c → 2.7 → 2.8 → 2.9 → (2.10 if brainstorm and next == "phase") → loop`.
3. In `phase-2-core.md` §2.9b dispatch table: replace `2.6d` with `2.10`.
4. In `disney-phase-machine.md` §6 (currently references "Step 2.6d"): update to `Step 2.10`.
5. `grep -rn "2\.6d" skills/ commands/ .s2s/` and update every remaining match (including any in `strategy-hooks.md` §8 and unrelated docs).

**Exit condition**: §2 layout, §4 invariants, §2.9b dispatch, `disney-phase-machine.md`, and `strategy-hooks.md` all reference Step 2.10. `grep -r "2\.6d" skills/ commands/` returns zero matches. No runtime change.

### 7.6: regression replay exp45 (verification, ~1h)

**Goal**: confirm Phase 7 preserves all exp44 invariants.

**Actions** (in `ElfGiftRush_s2s` dogfood worktree):
1. Create branch `exp45-specs-post-phase7` and run `/s2s:specs --verbose --diagnostic`. Compare structural summary against `exp44-specs-post-phase7b.md`. Expected: no functional delta (specs+consensus has no hooks).
2. Create branch `exp45-design-post-phase7` and run `/s2s:design --verbose --diagnostic`. Compare against `exp44-design-post-phase7b.md`. **Critical checks**:
   - `debate_role` present in every participant dump (count = `rounds × 4` per structural ratio).
   - `debate_phase` present in every round summary (count = `rounds`).
   - Debate phase progression matches the now-formalized policy (round 1 = opening, etc., with fallback for short sessions per 7.1).
3. Create branch `exp45-brainstorm-post-phase7` and run `/s2s:brainstorm --verbose --diagnostic`. Compare against `exp44-brainstorm-post-phase7b.md`. **Critical checks**:
   - Disney machine produces `dreamer → realist → critic` sequence; no skipped or duplicated phase. `rounds_completed` within ±1 of exp44 (3 rounds) per §10 tolerance.
   - Schema invariants preserved.
4. Write 3 structural summary files in `.s2s/test-baselines/exp45-{specs,design,brainstorm}-post-phase7.md` (no raw artifacts in public repo per `feedback_test_data_split.md`).

**Acceptance threshold** (stricter than 7B because Phase 7 adds no algorithmic logic):
- `rounds_completed` delta vs exp44: **≤ ±1 round** (LLM variance tolerance only). Any larger delta indicates a behavioral change and is a blocker.
- `debate_role` count in design dumps: equal to `exp45 rounds_completed × 4` participants (structural ratio; exp44 was 16/16 at 4 rounds).
- `debate_phase` count in design round summaries: equal to `exp45 rounds_completed` (one per round; exp44 was 4/4).
- Disney machine in brainstorm: **exact** dreamer → realist → critic progression, no skipped or duplicated phase.
- FIX-S1: session-observer dumps written per round (must match exp45 rounds_completed).

**Exit condition**: all 3 replays meet the acceptance thresholds above. Any blocker requires Phase 7 rework before PR.

## 5. Risk register

| ID | Risk | Likelihood | Impact | Mitigation |
|----|------|------------|--------|------------|
| R1 | Formalizing Pro/Con assignment policy in `debate.md` shifts the LLM-emergent distribution observed in exp44 | medium | high | **7.0 step 5** extracts the empirical `{participant_id, round_index → debate_role}` mapping from `ElfGiftRush_s2s` exp44 raw dumps. **7.1** encodes that mapping verbatim as the policy table in `debate.md`. **7.6** exp45 replay validates no drift. **Fallback**: if 7.0 reveals the mapping is INCONSISTENT (same participant flipping Pro/Con across rounds), defer policy formalization to a follow-up phase and document `debate.md` as "facilitator-driven, no fixed policy" instead. |
| R2 | Adding Step 2.2c facilitator Read adds latency and token cost | low | low | One Read per round of ~180 lines; ~3-5 Reads per session. No caching assumed; cost bounded. |
| R3 | Step 2.6d renumbering breaks references in `disney-phase-machine.md` or commands | low | medium | grep for all 2.6d references before edit; update all in 7.5. |
| R4 | Brainstorm replay rounds_completed shifts (exp44 had 3) | low | medium | ±1 round shift tolerated per §10 invariant. Shift > 1 round triggers investigation: Disney machine has no algorithmic change in Phase 7, so a larger shift would indicate side effect from new Step 2.2c Read (e.g., facilitator behavior change due to disney.md `## Strategy hooks` addition). |
| R5 | Consensus-driven gains accidental hook behavior because facilitator now Reads strategy doc even when no hooks apply | low | medium | 7.1 explicitly states "no hooks" in `consensus-driven.md` and `standard.md`. Facilitator instruction at 2.2c includes "if no `## Strategy hooks` section or section says 'no hooks', skip override population." |
| R6 | Six-hats wiring requested mid-Phase 7 | low | low | Documented as deferred in §1 non-goals and §8 follow-ups. Reject scope creep. |
| R7 | Plan to "formalize debate_phase progression" turns out to be observation-only (no actual machine), making the change cosmetic | medium | low | Acceptable. The cosmetic change (explicit table in `debate.md`) still removes ambiguity for the facilitator agent. If full state machine is needed, separate follow-up. |

## 6. Done criteria

- [ ] 7.0 audit gap matrix produced; empirical Pro/Con map captured from exp44 dumps; SKILL.md duplication audit complete; facilitator agent file integration confirmed.
- [ ] All 5 strategy docs have a `## Strategy hooks` section (concrete policy or explicit "no hooks").
- [ ] `debate.md` Pro/Con policy matches empirical exp44 mapping (or, if inconsistent, falls back to "facilitator-driven" per R1).
- [ ] `roundtable-strategies/SKILL.md` workflow defaults and artifact-types tables have explicit "authoritative source: profiles/" disclaimers.
- [ ] `roundtable-strategies/SKILL.md` version bumped from `1.1.0` to `1.2.0` (additive contract sections).
- [ ] `strategy-hooks.md` updated to reflect wired state (no more "LLM-emergent" for debate; references to `2.6d` updated to `2.10`).
- [ ] `phase-2-core.md` Step 2.2c has explicit Read + apply instruction with documented frequency (per round).
- [ ] Step 2.6d renamed to Step 2.10 across `phase-2-core.md` §2/§4/§2.9b, `disney-phase-machine.md`, and `strategy-hooks.md`. `grep -r "2\.6d"` in `skills/` + `commands/` returns zero matches.
- [ ] `disney.md` and `disney-phase-machine.md` cross-link bidirectionally.
- [ ] exp45 regression replay meets acceptance thresholds (see §4.7.6): rounds_completed delta ≤ ±1 vs exp44; debate hooks count consistent with rounds_completed; Disney machine progression exact.
- [ ] Critical preservation: design+debate produces `debate_role` in all participant dumps and `debate_phase` in all round summaries (count consistent with exp45 rounds_completed).
- [ ] `.s2s/BACKLOG.md` TECH-002 block: Phase 7 marked completed.
- [ ] ADR-0011 addendum updated if the strategy wiring approach diverges from this plan.
- [ ] PR opened against `develop`, milestone v0.4.0.
- [ ] Plan `Status` field updated from `draft` to `completed (PR #XX merged YYYY-MM-DD)` in final commit.

## 7. PR strategy

**Single PR**: `feature/TECH-002-phase7-strategy-consolidation` → `develop`.

Commit structure (granular, atomic, in execution order — matches §4 intro):
1. `docs(strategies): audit gap matrix + exp44 Pro/Con extraction for Phase 7` (7.0 audit output)
2. `docs(strategies): formalize hook contracts in {strategy}.md files` (7.1)
3. `docs(strategies): reconcile SKILL.md workflow defaults with profile YAMLs, bump v1.2.0` (7.1b)
4. `docs(strategies): update strategy-hooks.md to wired state` (7.2)
5. `refactor(phase-2-core): rename Step 2.6d to Step 2.10 across all docs` (7.5)
6. `feat(phase-2-core): wire Step 2.2c facilitator to Read active strategy doc` (7.3)
7. `docs(strategies,phase-2-core): cross-link disney.md ↔ disney-phase-machine.md` (7.4)
8. `docs(test-baselines): exp45 post-Phase 7 structural summaries` (7.6)
9. `docs(backlog,plan): close Phase 7` (final)

PR body must include:
- Link to plan file.
- Summary of exp45 regression deltas vs exp44 (critical: debate_role count, debate_phase count, brainstorm rounds_completed).
- Mention of deferred items (six-hats wiring, debate-phase-machine extraction).

## 8. Out-of-scope follow-ups (tracked, not actioned)

- **Six-hats wiring** (deferred, prerequisite-blocked): six-hats has never been exercised in dogfood. **Blocker**: capture an empirical baseline by running `/s2s:design --strategy six-hats --verbose --diagnostic` on dogfood, then freeze a structural summary in `.s2s/test-baselines/exp4N-design-six-hats-baseline.md`. Only after that baseline exists can six-hats be wired analogously to debate (separate task; not a Phase 7 follow-up).
- **`debate-phase-machine.md` formal extraction**: Phase 7 documents the progression as a table in `debate.md`. If future complexity (per-participant phase overrides, dynamic phase counts) demands a state machine, extract analogously to `disney-phase-machine.md`.
- **INT-* / CONF-* schema gaps in `session-schema.md`**: pre-existing drift unrelated to Phase 7.
- **`roundtable.md` stale references** to old SKILL.md pattern: Phase 4 territory.
- **Brainstorm strategy edge case**: `--strategy` non-disney is ignored at Phase 2 (correct) but propagates to `session.yaml.strategy_to_use` (cosmetic mismatch). Out of Phase 7 scope.

## 9. Exit pointer

After Phase 7 PR merges to develop:
- Update `.s2s/BACKLOG.md` TECH-002 block: Phase 7 ✅, Phase 4 becomes `in_progress`, next branch `feature/TECH-002-phase4-roundtable-master`.
- Verify `MEMORY.md` `project_tech002_progress.md` reflects new state (Phase 7B + 7 done; 4 + 8 pending).
- Do NOT release v0.4.0 → main yet. Wait for Phases 4 + 8.

Phase 4 plan should be drafted after Phase 7 merges, using this plan as a structural template.

## 10. Contract invariants (must NOT change)

Per `strategy-hooks.md` §9 (Phase 7B contract) and `.s2s/test-baselines/exp44-*-post-phase7b.md`:

- **Design + debate**: every participant dump (N rounds × 4 participants) includes `debate_role`; every round summary includes `debate_phase`. exp44 baseline: 16/16 and 4/4 at 4 rounds. exp45 must match the **structural ratio** (count = rounds × participants for `debate_role`; count = rounds for `debate_phase`), not necessarily the absolute count if rounds_completed differs within ±1 tolerance.
- **Brainstorm + disney**: phase progression sequence `dreamer → realist → critic` preserved; conclusion in critic phase; Disney machine extraction transparency holds. Strict invariant: no skipped or duplicated phase, transitions only at phase boundaries. Rounds_completed within ±1 of exp44 baseline (3 rounds; ±1 LLM variance tolerance).
- **Specs + consensus-driven**: no strategy hook fields appear (negative invariant).
- **Schema additivity**: hooks add optional fields, never remove or rename baseline fields.
- **FIX-S1**: session-observer dumps still written `{NNN}-04-session-observer.yaml` per round. Phase 7 must not break this.
- **State machine ownership**: Disney machine algorithmic source remains `disney-phase-machine.md`. Phase 7 only adds cross-links, no algorithmic change.

If any of these invariants is violated post Phase 7, that is a regression and the PR cannot merge.

---

## Appendix A: 7.0 gap matrix template

To be filled during 7.0 audit:

| Strategy | Hooks per contract | Currently in {strategy}.md | Gap | Action in 7.1 |
|----------|-------------------|----------------------------|-----|---------------|
| standard | none | n/a | — | add "no hooks" §Strategy hooks |
| consensus-driven | none | n/a | — | add "no hooks" §Strategy hooks |
| debate | debate_role, debate_phase | Pro/Con + 4 phases described prose-style | no concrete assignment policy, no round→phase mapping | add §Strategy hooks with policy table + round→phase table |
| disney | (machine) | machine extracted to disney-phase-machine.md | no cross-link, no §Strategy hooks | add cross-link banner + §Strategy hooks ("skip overrides; see disney-phase-machine.md") |
| six-hats | hat_role, hat_phase (deferred) | 6 hats described prose-style | no contract section | add §Strategy hooks marked "deferred wiring (no baseline)" |

## Appendix B: facilitator Step 2.2c pseudo-code (target shape)

After Phase 7, Step 2.2c facilitator block reads conceptually:

```
1. STRATEGY_DOC = Read(${CLAUDE_PLUGIN_ROOT}/skills/roundtable-strategies/references/{{STRATEGY}}.md)
2. HOOKS = locate "## Strategy hooks" section in STRATEGY_DOC
3. IF section absent OR HOOKS opening line contains any of:
     - "no hooks"
     - "no per-round overrides"
   THEN overrides = null  (skip override population)
4. ELSE:
     apply HOOKS policy:
       - if hook defines per-participant override (e.g., debate_role):
           populate overrides.{participant-id}.{field} per policy
       - if hook defines round-summary field (e.g., debate_phase):
           note for Step 2.6a to append
5. emit facilitator response with overrides + (deferred) round-summary hints
```

The skip-trigger phrase list MUST match the facilitator instruction in `phase-2-core.md` Step 2.2c (per §4 7.3 action 1). If new strategies are added with a deferred-wiring status, use one of these recognized phrases to ensure the facilitator skips override population.

This pseudo-code is descriptive only. The actual text in `phase-2-core.md` Step 2.2c will be prose-style instruction, not literal pseudo-code, per the existing style of `phase-2-core.md`.

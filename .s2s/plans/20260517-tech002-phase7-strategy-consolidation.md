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
- `roundtable-strategies/SKILL.md` (181 lines, v1.1.0) has workflow defaults table + strategy-workflow compatibility table. Useful, retained.
- Only `roundtable.md:194` currently does `Read .../roundtable-strategies/references/{strategy}.md`. The specs/design/brainstorm commands do not.

### What we have as baselines
- `.s2s/test-baselines/exp44-specs-post-phase7b.md`: specs+consensus-driven, 5 rounds, no strategy hooks active.
- `.s2s/test-baselines/exp44-design-post-phase7b.md`: design+debate, 4 rounds, **16/16 debate_role** + **4/4 debate_phase** verified.
- `.s2s/test-baselines/exp44-brainstorm-post-phase7b.md`: brainstorm+disney, 3 rounds, Disney machine extraction verified.

These are the regression targets for Phase 7. The debate hook fields are the critical preservation contract.

### Hard constraints
- **Behavioral parity on debate path**: design+debate must still produce 16/16 debate_role and 4/4 debate_phase after Phase 7. If Phase 7 formalizes the assignment policy and that changes Pro/Con distribution, that is a regression.
- **No change to Disney machine**: `disney-phase-machine.md` algorithmic behavior unchanged. Brainstorm replay must match exp44 exactly (3 rounds, phase progression identical).
- **Commands stay thin**. Phase 7 should NOT add Read-strategy logic at command level. The wiring lives inside `phase-2-core.md` (facilitator agent), preserving the ~600-line command size achieved in 7B.4b.
- **Atomic PR**. Single PR target develop, milestone v0.4.0.

## 3. Approach evaluation

### Option A: facilitator reads strategy doc inside phase-2-core.md Step 2.2c (recommended)

The facilitator agent, at Step 2.2c (facilitator question prep), Reads `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-strategies/references/{{STRATEGY}}.md` to learn the active strategy's hook policy. The facilitator then emits `participant_context.overrides` populated per that policy. Step 2.3c and Step 2.6a remain as today (consumers of the hook values).

- Commands unchanged (still thin per 7B.4b).
- Strategy doc becomes the single source of policy.
- Behavior change is localized to one step (2.2c), bounded blast radius.
- One Read per session at most (or per round if config changes), low token cost.

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
4. The Disney precedent supports this: `phase-2-core.md` Step 2.6d already does `Read .../disney-phase-machine.md`. Phase 7 extends the same pattern to Step 2.2c for the active strategy doc.
5. Token cost: 1 Read of ~180 lines per session at Step 2.2c (round 1 only, cacheable for subsequent rounds within the same session context).

## 4. Sub-phases

The work splits into 7 sub-phases (7.0 through 7.6). 7.0-7.2 are audit + doc formalization. 7.3-7.4 wire the algorithm. 7.5 fixes the deferred 2.6d positioning. 7.6 is the regression replay.

### 7.0: audit strategy docs vs hook contract (research, ~1h)

**Goal**: produce a gap matrix per `strategy-hooks.md` §3-§6 to know what each strategy doc must add.

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

**Exit condition**: gap matrix produced; per-strategy task list for 7.1 written.

### 7.1: formalize strategy hook contracts in {strategy}.md files (doc, ~2h)

**Goal**: each strategy reference doc gains a `## Strategy hooks` section consumable by `phase-2-core.md` Step 2.2c.

**Actions**:
1. **`debate.md`**: add `## Strategy hooks` section formalizing:
   - **Pro/Con assignment policy**: per-participant role-based mapping (or alternating fallback). Codified as a table.
   - **Debate phase progression**: explicit mapping `round_index → debate_phase`. E.g., `round 1 → opening`, `round 2 → rebuttal`, `round 3 → closing`, `round 4+ → synthesis`. With facilitator override permission documented.
   - **Hook fields emitted**: `debate_role` (participant), `debate_phase` (round summary).
   - **Facilitator instruction**: a concrete pseudo-code block the facilitator agent follows at Step 2.2c.
2. **`disney.md`**: add explicit cross-reference block pointing to `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/disney-phase-machine.md` as the algorithmic source. Mark `disney.md` itself as the human-facing strategy guide; the machine doc as the algorithmic spec.
3. **`consensus-driven.md`** and **`standard.md`**: add `## Strategy hooks` section stating explicitly "No per-round hooks. Algorithm runs with workflow defaults from PROFILE." Avoid future doubt.
4. **`six-hats.md`**: add `## Strategy hooks` section documenting `hat_role` and `hat_phase` contract per `strategy-hooks.md` §5-§6, AND mark wiring as "deferred (not yet exercised in baselines)". Document the contract so Phase 7 + 1 can wire later.

**Exit condition**: all 5 strategy docs have a `## Strategy hooks` section. Each section is self-contained enough for `phase-2-core.md` Step 2.2c to consume.

### 7.2: update strategy-hooks.md inventory (doc, ~30min)

**Goal**: align the inventory document with the formalized strategy docs from 7.1.

**Actions**:
1. Update `strategy-hooks.md` §1 strategy inventory: each row now points to a concrete `## Strategy hooks` section in `{strategy}.md` (not just a strategy doc generically).
2. Update §7 "Where strategy data CURRENTLY comes from": move debate hooks from "LLM-emergent" to "facilitator Reads `debate.md` § Strategy hooks at Step 2.2c".
3. Update §8 "Phase 2 algorithm integration": Step 2.2c now has a concrete Read + apply instruction.
4. Bump status header from "contract documentation (TECH-002 Phase 7B.6)" to "executable contract (TECH-002 Phase 7, 2026-05-XX)".

**Exit condition**: `strategy-hooks.md` reflects the wired state.

### 7.3: wire phase-2-core.md Step 2.2c (algorithm, ~1h)

**Goal**: add the facilitator Read + apply instruction at Step 2.2c.

**Actions**:
1. In `phase-2-core.md` Step 2.2c (facilitator response template), add a preamble block:
   ```
   **Before generating the response, the facilitator MUST**:
   1. Read `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-strategies/references/{{STRATEGY}}.md`.
   2. Locate the `## Strategy hooks` section.
   3. Apply the policy to populate `participant_context.overrides` (and `round_summary.debate_phase` at Step 2.6a if applicable).
   ```
2. Where the response schema documents `overrides`, replace the descriptive "see strategy-hooks.md" with a concrete "see {{STRATEGY}}.md § Strategy hooks".
3. Confirm Step 2.3c and Step 2.6a documentation is consistent (they consume; no change).
4. Confirm the existing Step 2.6d disney Read instruction still works (no conflict with new Step 2.2c Read, since 2.6d is brainstorm-specific and 2.2c applies to the active strategy).

**Exit condition**: `phase-2-core.md` Step 2.2c has the explicit Read+apply. A facilitator agent reading the algorithm has zero ambiguity about where strategy policy comes from.

### 7.4: cross-link disney.md and disney-phase-machine.md (doc, ~15min)

**Goal**: make the disney ownership explicit.

**Actions**:
1. In `disney.md`, add a top banner: "Algorithmic implementation: `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/disney-phase-machine.md`. This file is the human-facing strategy description."
2. In `disney-phase-machine.md`, add a reciprocal banner: "Strategy description: `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-strategies/references/disney.md`. This file is the algorithmic spec consumed by `phase-2-core.md` Step 2.6d."
3. Verify no contradictory phase descriptions between the two files. Reconcile if any drift.

**Exit condition**: bidirectional cross-link; no doc drift.

### 7.5: fix Step 2.6d positioning inconsistency in phase-2-core.md (doc, ~30min)

**Goal**: resolve the 3-way mismatch deferred from Phase 7B.

**Context** (from Phase 7B post-merge review):
- Document layout §2: 2.6c → 2.7 → 2.8 → 2.6d → 2.9 (2.6d at line 780)
- §4 invariant declaration: 2.6c → 2.6d → 2.7 → 2.8 → 2.9
- §2.9b dispatch table: 2.6d fires from Step 2.9 when `next == "phase"`, i.e., 2.9 → 2.6d → loop

Runtime behavior is correct (brainstorm replay PASS, exact rounds match). The bug is documentation clarity.

**Actions**:
1. Decide canonical placement. The dispatch in §2.9b is the authoritative runtime sequence (2.9 dispatches to 2.6d when phase advances, then loops). Therefore document layout should reflect: 2.6c → 2.7 → 2.8 → 2.9 → (loop or 2.6d → loop).
2. Renumber if needed: candidate is to move Step 2.6d to AFTER Step 2.9 dispatch, possibly renaming to Step 2.9.5 or Step 2.10. Decision deferred to 7.5 execution after Francesco review.
3. Align §4 invariant declaration with the canonical placement.
4. Update any cross-references within `phase-2-core.md` and in `disney-phase-machine.md` Step 6.

**Exit condition**: §2 layout, §4 invariants, §2.9b dispatch all agree on 2.6d position. No runtime change.

### 7.6: regression replay exp45 (verification, ~1h)

**Goal**: confirm Phase 7 preserves all exp44 invariants.

**Actions** (in `ElfGiftRush_s2s` dogfood worktree):
1. Create branch `exp45-specs-post-phase7` and run `/s2s:specs --verbose --diagnostic`. Compare structural summary against `exp44-specs-post-phase7b.md`. Expected: no functional delta (specs+consensus has no hooks).
2. Create branch `exp45-design-post-phase7` and run `/s2s:design --verbose --diagnostic`. Compare against `exp44-design-post-phase7b.md`. **Critical checks**:
   - 16/16 debate_role still present in participant dumps.
   - 4/4 debate_phase still present in round summaries.
   - Debate phase progression matches the now-formalized policy (round 1 = opening, etc.).
3. Create branch `exp45-brainstorm-post-phase7` and run `/s2s:brainstorm --verbose --diagnostic`. Compare against `exp44-brainstorm-post-phase7b.md`. **Critical checks**:
   - Disney machine still produces 3-round dreamer→realist→critic sequence.
   - Schema invariants preserved.
4. Write 3 structural summary files in `.s2s/test-baselines/exp45-{specs,design,brainstorm}-post-phase7.md` (no raw artifacts in public repo per `feedback_test_data_split.md`).

**Exit condition**: all 3 replays PASS WITH NOTES against exp44 baselines.

## 5. Risk register

| ID | Risk | Likelihood | Impact | Mitigation |
|----|------|------------|--------|------------|
| R1 | Formalizing Pro/Con assignment policy in `debate.md` shifts the LLM-emergent distribution observed in exp44 | medium | high | 7.1 design the policy to match the empirical exp44 distribution (architect/devops = Pro, security/tech-lead = Con OR equivalent observed). Replay validates. |
| R2 | Adding Step 2.2c facilitator Read adds latency and token cost | low | low | 1 Read per session of ~180-line file; bounded. Cache-warm for subsequent rounds in same session. |
| R3 | Step 2.6d renumbering breaks references in `disney-phase-machine.md` or commands | low | medium | grep for all 2.6d references before edit; update all in 7.5. |
| R4 | Brainstorm replay rounds_completed shifts (exp44 had 3) | low | medium | No Disney machine change planned. If observed, investigate as side effect; otherwise N/A. |
| R5 | Consensus-driven gains accidental hook behavior because facilitator now Reads strategy doc even when no hooks apply | low | medium | 7.1 explicitly states "no hooks" in `consensus-driven.md` and `standard.md`. Facilitator instruction at 2.2c includes "if no `## Strategy hooks` section or section says 'no hooks', skip override population." |
| R6 | Six-hats wiring requested mid-Phase 7 | low | low | Documented as deferred in §1 non-goals and §8 follow-ups. Reject scope creep. |
| R7 | Plan to "formalize debate_phase progression" turns out to be observation-only (no actual machine), making the change cosmetic | medium | low | Acceptable. The cosmetic change (explicit table in `debate.md`) still removes ambiguity for the facilitator agent. If full state machine is needed, separate follow-up. |

## 6. Done criteria

- [ ] 7.0 audit gap matrix produced.
- [ ] All 5 strategy docs have a `## Strategy hooks` section (concrete policy or explicit "no hooks").
- [ ] `strategy-hooks.md` updated to reflect wired state (no more "LLM-emergent" for debate).
- [ ] `phase-2-core.md` Step 2.2c has explicit Read + apply instruction.
- [ ] `disney.md` and `disney-phase-machine.md` cross-link bidirectionally.
- [ ] Step 2.6d positioning consistent across §2 layout, §4 invariant, §2.9b dispatch.
- [ ] exp45 regression replay PASS WITH NOTES for all 3 workflows.
- [ ] Critical preservation: design+debate produces 16/16 debate_role and 4/4 debate_phase.
- [ ] `.s2s/BACKLOG.md` TECH-002 block: Phase 7 marked completed.
- [ ] ADR-0011 addendum updated if the strategy wiring approach diverges from this plan.
- [ ] PR opened against `develop`, milestone v0.4.0.

## 7. PR strategy

**Single PR**: `feature/TECH-002-phase7-strategy-consolidation` → `develop`.

Commit structure (granular, atomic):
1. `docs(strategies): audit gap matrix for Phase 7` (7.0 audit output)
2. `docs(strategies): formalize hook contracts in {strategy}.md files` (7.1)
3. `docs(strategies): update strategy-hooks.md to wired state` (7.2)
4. `feat(phase-2-core): wire Step 2.2c facilitator to Read active strategy doc` (7.3)
5. `docs(strategies,phase-2-core): cross-link disney.md ↔ disney-phase-machine.md` (7.4)
6. `docs(phase-2-core): resolve Step 2.6d 3-way positioning inconsistency` (7.5)
7. `docs(test-baselines): exp45 post-Phase 7 structural summaries` (7.6)
8. `docs(backlog,plan): close Phase 7` (final)

PR body must include:
- Link to plan file.
- Summary of exp45 regression deltas vs exp44 (critical: debate_role count, debate_phase count, brainstorm rounds_completed).
- Mention of deferred items (six-hats wiring, debate-phase-machine extraction).

## 8. Out-of-scope follow-ups (tracked, not actioned)

- **Six-hats wiring**: requires empirical baseline first. Run `/s2s:design --strategy six-hats` once on dogfood to capture baseline behavior; THEN wire in a future phase. Track as a new sub-item under TECH-002 or as a standalone task.
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

- **Design + debate**: 16/16 participant dumps include `debate_role`; 4/4 round summaries include `debate_phase`.
- **Brainstorm + disney**: 3 rounds with phases `dreamer → realist → critic`, transitions at round 1→2 and 2→3, conclude in critic phase. Phase machine extraction transparency holds.
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
| disney | (machine) | machine extracted to disney-phase-machine.md | no cross-link | add cross-link banner |
| six-hats | hat_role, hat_phase (deferred) | 6 hats described prose-style | no contract section | add §Strategy hooks marked "deferred wiring (no baseline)" |

## Appendix B: facilitator Step 2.2c pseudo-code (target shape)

After Phase 7, Step 2.2c facilitator block reads conceptually:

```
1. STRATEGY_DOC = Read(${CLAUDE_PLUGIN_ROOT}/skills/roundtable-strategies/references/{{STRATEGY}}.md)
2. HOOKS = locate "## Strategy hooks" section in STRATEGY_DOC
3. IF HOOKS says "no hooks" OR section absent:
     overrides = null
4. ELSE:
     apply HOOKS policy:
       - if hook defines per-participant override (e.g., debate_role):
           populate overrides.{participant-id}.{field} per policy
       - if hook defines round-summary field (e.g., debate_phase):
           note for Step 2.6a to append
5. emit facilitator response with overrides + (deferred) round-summary hints
```

This pseudo-code is descriptive only. The actual text in `phase-2-core.md` Step 2.2c will be prose-style instruction, not literal pseudo-code, per the existing style of `phase-2-core.md`.

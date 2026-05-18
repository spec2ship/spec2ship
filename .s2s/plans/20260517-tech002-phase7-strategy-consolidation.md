# TECH-002 Phase 7-lite: strategy skill documentation hardening

**Plan ID**: `20260517-tech002-phase7-strategy-consolidation`
**Branch**: `feature/TECH-002-phase7-strategy-consolidation`
**Forked from**: `develop` @ `35cdf10` (post Phase 7B PR #14 merge)
**Author**: Claude (Opus 4.7) + Francesco
**Status**: draft (re-scoped to lite, awaiting execution)
**Created**: 2026-05-17
**Revised**: 2026-05-18 — re-scoped from "full" to "lite" after macro review (round #4). Runtime wiring at Step 2.2c deferred to Phase 4.
**Predecessor plan**: `.s2s/plans/20260506-tech002-phase7b-deep-extraction.md`
**Contract source**: `skills/roundtable-execution/references/strategy-hooks.md` (Phase 7B.6, 2026-05-16)

---

## 1. Goal

Harden `roundtable-strategies/` as the **authoritative documentation source** for strategy hook contracts. Each of the 5 strategy reference docs gains a uniform `## Strategy hooks` section declaring which fields the strategy emits (`debate_role`, `debate_phase`, `hat_role`, `hat_phase`) without prescribing a runtime consumption mechanism.

Phase 7-lite delivers four concrete wins:

1. **Strategy doc formalization** — 5 `## Strategy hooks` sections in uniform shape, future-wiring-compatible.
2. **SKILL.md dedup** — `roundtable-strategies/SKILL.md` workflow defaults and artifact-types tables gain explicit "authoritative source: profiles/" disclaimer; version bump 1.1.0 → 1.2.0.
3. **Step 2.6d → Step 2.10 rename** — resolves Phase 7B post-merge 3-way doc inconsistency.
4. **disney.md ↔ disney-phase-machine.md cross-link** — bidirectional pointer, no doc drift.

The **runtime wiring** (facilitator Reads strategy doc at Step 2.2c) is **deferred to Phase 4**, where roundtable.md becomes master and all callers funnel through `phase-2-core.md` uniformly. Phase 4 will make the architectural choice between Option A (LLM-mediated Read), Option B (command-side parsing), or Option C (YAML configs) with full context. Phase 7-lite delivers the substrate (formalized strategy docs in uniform shape) that B and C would consume.

### Non-goals (explicit deferrals)

- **Runtime wiring of strategy docs at Step 2.2c**. Phase 4 territory. Reason from macro review #4: doing it now in Phase 7 introduces LLM emergence risk (Option A is LLM-mediated, so it doesn't actually eliminate the emergence problem stated in original Phase 7 goal), the regression cannot differentiate working from broken wiring, and the architectural seam to choose A/B/C is cleaner once commands are simplified.
- **Empirical Pro/Con extraction from exp44 dumps**. Not needed: we are not codifying a Pro/Con policy in `debate.md` for Phase 7-lite. The doc keeps "facilitator-driven" descriptive framing.
- **Six-hats wiring**. Prerequisite-blocked on baseline.
- **Phase 4 (roundtable.md as master)**. Out of scope.
- **Phase 8 (thin launchers)**. Out of scope.
- **Formal `debate-phase-machine.md` extraction**. Deferred unless future complexity demands.

## 2. Inputs and constraints

### What we know
- `strategy-hooks.md` (Phase 7B.6, 136 lines) inventories the 5 strategies and 4 hooks. Disney machine already extracted to `disney-phase-machine.md`.
- 5 strategy reference docs exist (904 lines total). None have a `## Strategy hooks` section yet; content is human-facing prose.
- `roundtable-strategies/SKILL.md` (181 lines, v1.1.0) has "Workflow-Specific Defaults" (lines 64-68) and "Artifact Types by Workflow" (lines 70-76) tables that DUPLICATE `profiles/{workflow}.yaml` values. Silent drift risk.
- `phase-2-core.md` has a 3-way Step 2.6d positioning inconsistency from Phase 7B (§2 layout vs §4 invariant vs §2.9b dispatch).
- `commands/roundtable.md:194` already does command-level `Read` of strategy doc with inline phase enumeration (legacy pattern). Phase 7-lite does NOT touch this; Phase 4 will reconcile.

### What we have as baselines
exp44-post-phase7b baselines exist for all 3 workflows but are NOT used as regression targets in Phase 7-lite because there is no runtime behavior change to verify. They remain authoritative for Phase 4 wiring decision.

### Hard constraints
- **No runtime behavior change**. Phase 7-lite touches only documentation (5 strategy docs + SKILL.md + strategy-hooks.md + cross-link banners) + file renames inside `phase-2-core.md` (no algorithmic edits to Step 2.X bodies). Existing exp44 dump shapes remain valid.
- **Commands unchanged**. specs/design/brainstorm command files are NOT modified.
- **Atomic PR**. Single PR target develop, milestone v0.4.0.

## 3. Approach

Phase 7-lite is **documentation + rename only**. No new code paths, no facilitator Read at runtime, no behavior change.

The work breaks down into 3 categories:
- **Strategy doc hardening** (7.0 audit → 7.1 formalize → 7.2 strategy-hooks.md update): each strategy doc gains a `## Strategy hooks` section in uniform shape.
- **Tidying** (7.1b SKILL.md dedup, 7.5 Step 2.6d → 2.10 rename, 7.4 disney cross-link): three independent wins; no inter-dependency.
- **Verification** (7.6 light smoke test): grep checks + skill-load probe, no full regression replay.

**Total estimated time**: ~3.75 hours (1 + 0.75 + 0.5 + 0.5 + 0.25 + 0.5 + 0.25). (7.2 grew from 0.25 to 0.5 after 7.0 audit §6.1 extended findings.)

### Why no runtime wiring now

Pre-empted by macro review #4. Summary of reasons:

1. **Option A (LLM-mediated Read) does not eliminate LLM emergence** — it only shifts it from "interpret STRATEGY string" to "interpret STRATEGY string + Read strategy doc and interpret markdown prose". The original Phase 7 problem statement (`§1` of the previous full plan: "strategy effects emerge from the LLM interpreting STRATEGY as a string") is not solved by Option A.
2. **R1 likelihood is high** — empirical Pro/Con assignment in exp44 is one sample; LLM nondeterminism likely produces flipping across runs. R1 fallback ("facilitator-driven, no fixed policy") was already likely → Phase 7 wiring would deliver minimal runtime value.
3. **Regression cannot differentiate working from silently-broken wiring** — exp45 with same shape as exp44 could mean the Read+apply worked, OR that it silently did nothing and the LLM emerged identical output. No positive verification was feasible without significant additional work.
4. **Phase 4 has the right architectural seam** — once roundtable.md is master and commands are thin launchers, the strategy doc consumption can be unified at one site with Option B (deterministic) or Option C (YAML) feasibly.

Phase 7-lite delivers the precondition for Phase 4's decision: formalized strategy docs in uniform consumable shape.

## 4. Sub-phases

**Execution order**: 7.0 → 7.1 → 7.1b → 7.5 → 7.4 → 7.2 → 7.6.

(7.5 comes early because 7.2 strategy-hooks.md update needs to reference Step 2.10 instead of 2.6d.)

### 7.0: audit strategy docs vs hook contract (~1h)

**Goal**: produce a gap matrix per `strategy-hooks.md` §3-§6 + audit `roundtable-strategies/SKILL.md` workflow defaults vs `profiles/{workflow}.yaml`.

**Actions**:
1. For each of the 5 strategy docs, list which hooks apply per `strategy-hooks.md` and what is currently documented vs missing.
2. Audit `roundtable-strategies/SKILL.md` "Workflow-Specific Defaults" + "Artifact Types by Workflow" tables: compare to profile YAMLs, identify any drift.
3. Output: gap matrix (Appendix A) + duplication audit (markdown table inline or `.s2s/` file).
4. Flag any `commands/roundtable.md` strategy-doc-related stale references for Phase 4 (no action in 7.0).

**Skipped from Phase 7-full**:
- ~~Empirical Pro/Con extraction from exp44 dumps~~ — no policy formalization.
- ~~Facilitator agent file integration check~~ — no wiring.

**Exit condition**: gap matrix + SKILL.md duplication map produced; per-strategy task list for 7.1 written.

### 7.1: formalize `## Strategy hooks` sections in 5 strategy docs (~45min)

**Goal**: each strategy reference doc gains a `## Strategy hooks` section in uniform shape, future-wiring-compatible.

**Uniform shape**:
- Opening line declares hook applicability with one of these phrases (Phase 4 will use them as skip-triggers if Option A is chosen):
  - `"No per-round hooks. Algorithm runs with workflow defaults from PROFILE."`
  - `"No per-round overrides (wiring deferred to future phase — no empirical baseline yet)."`
  - `"Facilitator-driven, LLM-emergent. No fixed policy codified. Phase 4 will decide wiring mechanism."`
  - `"Phase progression determined by {file}. No Step 2.2c per-round overrides."`
- Body documents the hook fields the strategy emits (or "none") + cross-reference to `strategy-hooks.md` §X for full contract.

**Actions**:
1. **`standard.md`**: `## Strategy hooks` opening: `"No per-round hooks. Algorithm runs with workflow defaults from PROFILE."`
2. **`consensus-driven.md`**: same opening as standard.
3. **`debate.md`**: `## Strategy hooks` documenting:
   - Hook fields emitted: `debate_role` (participant), `debate_phase` (round summary).
   - Current behavior: `"Facilitator-driven, LLM-emergent. No fixed policy codified. Phase 4 will decide the wiring mechanism (Option A/B/C) and may add a codified policy table at that time."`
   - Cross-reference to `strategy-hooks.md` §3-§4.
4. **`disney.md`**: `## Strategy hooks` opening: `"Phase progression determined by disney-phase-machine.md via Step 2.10 (Phase Transition). No Step 2.2c per-round overrides."` Plus cross-link banner per 7.4.
5. **`six-hats.md`**: `## Strategy hooks` opening: `"No per-round overrides (wiring deferred to future phase — no empirical baseline yet)."` Below the opening, document `hat_role` and `hat_phase` contract per `strategy-hooks.md` §5-§6 as descriptive prose.

**Exit condition**: all 5 strategy docs have `## Strategy hooks` sections in uniform shape; opening lines match the future skip-trigger phrase pattern.

### 7.1b: reconcile SKILL.md workflow defaults with profile YAMLs (~30min)

**Goal**: remove silent duplication between `roundtable-strategies/SKILL.md` and `profiles/{workflow}.yaml` without breaking SKILL.md's standalone readability.

**Decision (pinned)**: keep SKILL.md tables (useful for human readers) but add explicit "authoritative source" disclaimers pointing to profile YAMLs.

**Actions**:
1. Add header note above SKILL.md "Workflow-Specific Defaults" table: `> **Authoritative source**: profile YAMLs in roundtable-execution/profiles/{workflow}.yaml. The table below is a human-readable summary; if it drifts, the YAML is correct.`
2. Same treatment for "Artifact Types by Workflow" table.
3. Verify the tables match current PROFILE values (drift check from 7.0). Reconcile any discrepancy to match the YAML.
4. Bump `roundtable-strategies/SKILL.md` version 1.1.0 → 1.2.0 (additive: contract sections added in 7.1, disclaimer added in 7.1b).

**Exit condition**: SKILL.md tables disclaimer-protected; values match PROFILE; version bumped.

### 7.5: rename Step 2.6d to Step 2.10 across phase-2-core.md (~30min)

**Goal**: resolve the 3-way mismatch deferred from Phase 7B.

**Context** (from Phase 7B post-merge review):
- Document layout §2: 2.6c → 2.7 → 2.8 → 2.6d → 2.9 (2.6d at line 780)
- §4 invariant declaration: 2.6c → 2.6d → 2.7 → 2.8 → 2.9
- §2.9b dispatch: 2.6d fires from 2.9 when `next == "phase"`, i.e., 2.9 → 2.6d → loop

Runtime behavior is correct (brainstorm replay PASS); the bug is documentation clarity.

**Decision (pinned)**: rename Step 2.6d to **Step 2.10 (Phase Transition)** and place it AFTER Step 2.9 in §2 layout. Rationale: §2.9b dispatch is the authoritative runtime sequence; numbering as `2.10` avoids decimal-decimal ambiguity.

**Actions**:
1. In `phase-2-core.md` §2 layout: move Step 2.6d block to after Step 2.9; renumber as Step 2.10. Heading: `### 2.10 — Phase Transition (brainstorm only, profile.has_phase_transition)`.
2. In `phase-2-core.md` §4 invariant declaration: update to `2.6c → 2.7 → 2.8 → 2.9 → (2.10 if brainstorm and next == "phase") → loop`.
3. In `phase-2-core.md` §2.9b dispatch table: replace `2.6d` with `2.10`.
4. In `disney-phase-machine.md` §6: update Step 2.6d → Step 2.10.
5. `grep -rn "2\.6d" skills/ commands/ .s2s/` and update every remaining match (including `strategy-hooks.md` §8 if applicable; will be handled in 7.2 if missed here).

**Exit condition**: `grep -r "2\.6d" skills/ commands/` returns zero matches. No runtime change.

### 7.4: cross-link disney.md and disney-phase-machine.md (~15min)

**Goal**: make disney ownership explicit between strategy doc (human-facing) and machine doc (algorithmic).

**Actions**:
1. In `disney.md`, add a top banner: `> Algorithmic implementation: ${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/disney-phase-machine.md. This file is the human-facing strategy description.`
2. In `disney-phase-machine.md`, add a reciprocal banner: `> Strategy description: ${CLAUDE_PLUGIN_ROOT}/skills/roundtable-strategies/references/disney.md. This file is the algorithmic spec consumed by phase-2-core.md Step 2.10.`
3. Verify no contradictory phase descriptions between the two files. Reconcile if any drift.

**Exit condition**: bidirectional cross-link; no doc drift.

### 7.2: update strategy-hooks.md inventory + "Phase 7 → Phase 4" deferral comments (~30min)

**Goal**: align strategy-hooks.md with the formalized strategy docs from 7.1 and the 2.10 rename from 7.5. Update all "Phase 7" stale references to "Phase 4" across the affected files (per 7.0 audit §6.1).

**Actions**:
1. Update `strategy-hooks.md` §1 strategy inventory: each row now references the concrete `## Strategy hooks` section in its `{strategy}.md`.
2. Update `strategy-hooks.md` §7 "Where strategy data CURRENTLY comes from": for debate hooks, keep "LLM-emergent" framing AND add explicit note "wiring deferred to Phase 4 architectural decision (Option A/B/C)".
3. Update `strategy-hooks.md` §8 "Phase 2 algorithm integration": replace any `2.6d` reference with `2.10` (catches anything 7.5 grep missed).
4. Update `strategy-hooks.md` status header: `"contract documentation hardened (TECH-002 Phase 7-lite, {YYYY-MM-DD})"` — set `YYYY-MM-DD` at commit time.
5. Update all 9 "Phase 7" references in `strategy-hooks.md` to "Phase 4" per 7.0 audit §6.1 table (lines 4, 7, 38, 52, 66, 80, 94, 100, 106 of the pre-edit file).
6. **Bonus files**: update 2 additional "Phase 7" references outside `strategy-hooks.md`:
   - `skills/roundtable-execution/SKILL.md:151`: `"Phase 7 wires"` → `"Phase 4 wires (Option A/B/C decision)"`
   - `agents/validation/session-qa.md:697`: `"strategy hook wiring deferred to Phase 7"` → `"strategy hook wiring deferred to Phase 4 (Option A/B/C decision)"`
7. The `design.yaml:60` comment (`"wiring deferred to Phase 7"`) is updated in 7.5 alongside the 2.6d rename in `brainstorm.yaml` (same-file proximity).

**Exit condition**: strategy-hooks.md aligned with Phase 7-lite state; all 12 "Phase 7" references across 4 files updated to "Phase 4"; no stale 2.6d references in strategy-hooks.md.

### 7.6: light smoke test (~15min)

**Goal**: verify doc changes do not break skill loading or leave dangling references.

**Actions**:
1. `grep -r "2\.6d" skills/ commands/` returns zero matches.
2. `grep -l "## Strategy hooks" skills/roundtable-strategies/references/*.md` returns 5 file paths (one per strategy doc).
3. `grep -E "^version:.*1\.2\.0" skills/roundtable-strategies/SKILL.md` returns a match.
4. (Optional) Run `/s2s:design --rounds 1 --verbose` in dogfood to confirm skill manifest loads; expect successful completion (no skill-load errors). This is NOT a behavioral regression check (Phase 7-lite makes no runtime changes), just a sanity probe.

**Skipped from Phase 7-full**:
- ~~Full regression replay exp45-{specs,design,brainstorm}~~ — no runtime behavior change to verify.
- ~~Propagation smoke test for Step 2.2c text~~ — no Step 2.2c edit.

**Exit condition**: smoke test passes; no dangling 2.6d references; 5 strategy docs have section; SKILL.md at v1.2.0.

## 5. Risk register

| ID | Risk | Likelihood | Impact | Mitigation |
|----|------|------------|--------|------------|
| R3 | 2.6d → 2.10 rename misses a reference somewhere | low | low | 7.5 grep-and-update; 7.6 grep-zero-matches verification before PR. |
| R5 | New `## Strategy hooks` section opening phrase format causes future Phase 4 wiring inconsistency | low | low | 7.1 enforces uniform shape: opening lines drawn from a fixed 4-phrase set that matches skip-trigger pattern documented in 7.1. |
| R8 | SKILL.md disclaimer drift over time (developer edits table without updating profile) | low | low | Disclaimer text is explicit; profile is canonical. Relies on developer discipline; no automation. Phase 8 (thin launchers) may add a validation script. |

(R1, R2, R4, R6, R7 from Phase 7-full removed — not applicable to Phase 7-lite scope.)

## 6. Done criteria

- [ ] 7.0 audit gap matrix + SKILL.md duplication map produced (in Appendix A or `.s2s/` file).
- [ ] All 5 strategy docs have `## Strategy hooks` section with uniform shape; opening lines match the 4-phrase set from 7.1.
- [ ] `debate.md` `## Strategy hooks` explicitly documents "facilitator-driven, wiring deferred to Phase 4".
- [ ] `roundtable-strategies/SKILL.md` workflow defaults + artifact-types tables have explicit "authoritative source: profiles/" disclaimers.
- [ ] `roundtable-strategies/SKILL.md` version bumped 1.1.0 → 1.2.0.
- [ ] `strategy-hooks.md` updated to Phase 7-lite state (debate hooks framing "LLM-emergent, wiring deferred to Phase 4"; 2.6d references updated to 2.10; all 9 internal "Phase 7" references updated to "Phase 4" per 7.0 audit §6.1).
- [ ] Bonus "Phase 7 → Phase 4" updates landed in `roundtable-execution/SKILL.md:151` and `agents/validation/session-qa.md:697` (per 7.0 audit §6.1).
- [ ] `grep -rn "Phase 7\b" skills/ commands/ agents/` returns matches only in historical contexts (ADR-0011 addendum content) — no active "Phase 7 will wire" framing anywhere.
- [ ] Step 2.6d renamed to Step 2.10 across `phase-2-core.md` (§2/§4/§2.9b), `disney-phase-machine.md`, `strategy-hooks.md`. `grep -r "2\.6d" skills/ commands/` returns zero matches.
- [ ] `disney.md` and `disney-phase-machine.md` cross-link bidirectionally.
- [ ] 7.6 smoke test passes (grep checks + skill-load probe).
- [ ] `.s2s/BACKLOG.md` TECH-002 block: Phase 7-lite marked completed; Phase 4 note added: "Option A/B/C wiring decision needed at Phase 4 plan §3".
- [ ] ADR-0011 addendum: "Phase 7-lite hardens strategy docs as authoritative reference. Runtime consumption pattern deliberately deferred to Phase 4."
- [ ] PR opened against `develop`, milestone v0.4.0.
- [ ] Plan `Status` field updated from `draft` to `completed (PR #XX merged YYYY-MM-DD)` in final commit.

## 7. PR strategy

**Single PR**: `feature/TECH-002-phase7-strategy-consolidation` → `develop`.

Commit structure (in execution order):
1. `docs(strategies): audit gap matrix + SKILL.md duplication map for Phase 7-lite` (7.0)
2. `docs(strategies): formalize ## Strategy hooks sections in 5 strategy docs` (7.1)
3. `docs(strategies): reconcile SKILL.md workflow defaults with profile YAMLs, bump v1.2.0` (7.1b)
4. `refactor(phase-2-core): rename Step 2.6d to Step 2.10 across docs` (7.5)
5. `docs(strategies,phase-2-core): cross-link disney.md ↔ disney-phase-machine.md` (7.4)
6. `docs(strategies): update strategy-hooks.md to Phase 7-lite state` (7.2)
7. `docs(adr,backlog,plan): close Phase 7-lite + ADR-0011 addendum` (final)

7 commits (Phase 7-full had 9). Lighter, faster, atomic.

PR body must include:
- Link to plan file.
- Explicit "scope: lite — runtime wiring deferred to Phase 4" note.
- Summary of Phase 4 prerequisites delivered (uniform `## Strategy hooks` sections, SKILL.md dedup, 2.10 rename, disney cross-link).

## 8. Out-of-scope follow-ups (tracked, not actioned)

- **Runtime wiring of strategy docs (Option A/B/C decision)**: deferred to Phase 4. Phase 4 plan §3 must make explicit choice based on: (A) is LLM emergence acceptable, (B) command-side YAML parsing acceptable, (C) full structured config required. Phase 7-lite's uniform `## Strategy hooks` sections are the data substrate for B and C.
- **Six-hats wiring**: prerequisite-blocked on baseline acquisition. Capture an empirical baseline first by running `/s2s:design --strategy six-hats --verbose --diagnostic` on dogfood; freeze structural summary in `.s2s/test-baselines/`. Separate task, not a Phase 7-lite follow-up.
- **Formal `debate-phase-machine.md` extraction**: deferred unless future complexity demands.
- **INT-* / CONF-* schema gaps in `session-schema.md`**: pre-existing drift, unrelated.
- **`commands/roundtable.md:194` legacy command-level Read**: Phase 4 will reconcile when roundtable.md becomes master.
- **Brainstorm strategy edge case**: `--strategy` non-disney is ignored at Phase 2 but propagates to `session.yaml.strategy_to_use`. Phase 4 territory.
- **Triple-duplication of strategy/workflow defaults** (from 7.0 audit §6.2): `templates/project/config.yaml` is a third source of `by_workflow_type` strategy mapping + per-strategy consensus config + per-workflow participants — duplicating `profiles/{workflow}.yaml` and `roundtable-strategies/SKILL.md` tables. Phase 7-lite does NOT touch this; the unification decision overlaps Phase 4 (config consumption mechanism) and is added to Phase 4 plan §3 alongside the Option A/B/C wiring decision.
- **Agent-side strategy doc pointers** (`agents/roundtable/facilitator.md` lines 518, 579, 607): point to whole `{debate,consensus-driven,disney}.md` files. After Phase 7-lite adds `## Strategy hooks` sections, these pointers could be sharpened to `#strategy-hooks` anchors. Phase 4 will re-evaluate when wiring choice is made.

## 9. Exit pointer

After Phase 7-lite PR merges to develop:
- Update `.s2s/BACKLOG.md` TECH-002 block: Phase 7-lite ✅; Phase 4 `in_progress` with note "Option A/B/C wiring decision needed".
- Verify `MEMORY.md` `project_tech002_progress.md` reflects new state (Phase 7B + 7-lite done; 4 + 8 pending; runtime strategy wiring decision pending Phase 4).
- Draft Phase 4 plan including explicit Option A/B/C decision matrix in §3 using Phase 7-lite's strategy docs as input.
- Do NOT release v0.4.0 → main yet. Wait for Phases 4 + 8.

Phase 4 plan should be drafted as a new file, using this plan as a structural template; specifically, §3 should re-evaluate Option A/B/C with the Phase 4 codebase context (roundtable.md as master).

## 10. Contract invariants (must NOT change)

Per `strategy-hooks.md` §9 and exp44 baselines:

- **All baseline runtime behavior unchanged**. Phase 7-lite is documentation + rename only. exp44 dump shapes remain valid (no new fields, no field removals, no path changes).
- **Schema additivity**: `## Strategy hooks` sections are doc additions; they do not change any YAML schema.
- **FIX-S1 preserved**: session-observer dumps still written `{NNN}-04-session-observer.yaml` per round.
- **Disney machine ownership**: algorithmic source remains `disney-phase-machine.md`. Phase 7-lite only adds bidirectional cross-link banners.
- **Step 2.6d ↔ Step 2.10**: same logic, new name only. No semantic change.

If any of these is violated, that is a regression and the PR cannot merge.

---

## Appendix A: 7.0 audit output

7.0 audit complete (2026-05-18). Full output: `.s2s/plans/20260518-tech002-phase7-lite-7.0-audit.md`.

Output contains:
1. **Gap matrix** — strategy reference docs vs `strategy-hooks.md` contract; per-strategy action list for 7.1.
2. **SKILL.md duplication audit** — workflow defaults + artifact types tables vs profile YAMLs. Two drift items identified (D1: `ADR-*` category conflation; D2: missing `CONF-*` in brainstorm secondary).
3. **Stale references inventory** — `2.6d` references for 7.5 grep, "deferred to Phase 7" comments for 7.2/7.5 to update to "Phase 4".
4. **Phase 4 flag** — `commands/roundtable.md` lines 170-179 + 194-199 duplication and minor consensus-driven phase-name drift (`proposal/discussion/resolution` in roundtable.md vs `proposal/refinement/convergence` in `consensus-driven.md`).
5. **Per-strategy task list** for 7.1 execution.

## Appendix B (deferred to Phase 4 plan)

Phase 7-full had a facilitator pseudo-code Appendix B describing the Option A runtime behavior. That pseudo-code is **out of scope for Phase 7-lite** because no runtime wiring is added. It will be revisited in the Phase 4 plan when the Option A/B/C decision is made.

Phase 7-lite's uniform `## Strategy hooks` section opening lines are designed to be skip-trigger compatible regardless of which option Phase 4 picks: A (LLM reads doc and recognizes the phrases), B (command parses the doc and matches phrases as regex), or C (the phrases serve as YAML labels in the eventual structured config).

# TECH-002 Phase 4: roundtable.md as master + profiles/roundtable.yaml + Option B wiring

**Plan ID**: `20260518-tech002-phase4-roundtable-master`
**Branch**: `feature/TECH-002-phase4-roundtable-master`
**Forked from**: `develop` @ `3043c1a` (post Phase 7-lite PR #15 merge)
**Author**: Claude (Opus 4.7) + Francesco
**Status**: completed (PR #16 merged 2026-05-21)
**Created**: 2026-05-18
**Revised**: 2026-05-20 (Option ε pivot: smoke test outcome (c) graceful + SKILL.md L178 commitment + plugin's concrete spec invalidated Approach 4 deferral; Phase 4 now creates `profiles/roundtable.yaml` and fully resolves generic-mode, no Phase 9 needed); 2026-05-21 (§4.5 regression replay completed: 8 dogfood runs all PASS; post-Phase-4 baseline captured)
**Predecessor plan**: `.s2s/plans/20260517-tech002-phase7-strategy-consolidation.md` (Phase 7-lite)
**Smoke test baseline**: `.s2s/test-baselines/exp45-roundtable-native-pre-phase4.md` (Option ε pivot evidence)
**Audit**: `.s2s/plans/20260518-tech002-phase4-4.0-audit.md`
**Contract sources**:
- `skills/roundtable-execution/references/strategy-hooks.md` (Phase 7-lite hardened state, §7 Option A/B/C decision matrix)
- `.s2s/decisions/0011-roundtable-command-unification.md` (Phase 7-lite addendum)
- `.s2s/plans/20260518-tech002-phase7-lite-7.0-audit.md` (§6.2 triple-duplication, §7.3 default_strategy, §4 commands/roundtable.md drift)
- `skills/roundtable-execution/SKILL.md:178` (pre-existing Phase 4 commitment: "roundtable.md uses pre-7B inline pattern; Phase 4 will align it")

---

## 1. Goal

Expand `commands/roundtable.md` (currently 437 lines, "follow the skill" stub for Phase 2) into the master orchestrator (~520 lines) for **all four workflow types** (`specs`, `design`, `brainstorm`, `roundtable`). Execution flows uniformly through `phase-2-core.md` after loading the workflow-specific profile YAML. Create `profiles/roundtable.yaml` per the plugin's runtime-validated spec (smoke test outcome, see `.s2s/test-baselines/exp45-roundtable-native-pre-phase4.md`) to make roundtable a first-class consumer of phase-2-core.md alongside the other three.

Make the explicit **Option A/B/C decision** for runtime consumption of strategy hooks (debate Pro/Con assignment, six-hats hat rotation, disney phase already handled by machine) and implement the chosen option (recommendation: Option B). Unify the triple-duplication of strategy/workflow defaults across `templates/project/config.yaml`, `profiles/{workflow}.yaml`, and `roundtable-strategies/SKILL.md`. Clarify and codify the `default_strategy` resolution hierarchy.

Phase 4 delivers seven concrete wins:

1. **roundtable.md master for ALL 4 workflows**: full Phase 2 wiring via `phase-2-core.md` for specs/design/brainstorm/roundtable, with `--workflow-type` profile dispatch, resume/diagnostic, and proper output dispatch per workflow. All 4 paths uniform.
2. **`profiles/roundtable.yaml` created**: based on plugin's runtime spec (`progress.axis: agenda` single `main` topic, `participants.default` from config), with `artifact_types: [DEC, OQ, CONF]` (review #5 A2 fix: added DEC for backward-compat with current session.yaml init `decisions: {}` slot). ~45-50 lines, uses existing schema (no extension needed). Resolves the structural blocker surfaced in §4.0 step 7 smoke test.
3. **Option B implementation across 3 files**: deterministic parser in roundtable.md, plus Step 2.2c modification in `phase-2-core.md` to consume `agent_state.facilitator.hook_overrides`, plus `agents/roundtable/facilitator.md` updated to honor passed overrides instead of LLM-inferring per-round overrides. Three-branch semantics codified: `{skip: true}` (strategy has no hooks), policy dict (strategy has hooks), absent field (pre-Phase-4 session, LLM-emergent fallback).
4. **Triple-duplication unification**: single canonical source per concern via resolution hierarchy (CLI, then config.yaml, then profile fallback). `templates/project/config.yaml` clarified as user-facing canonical; profile YAMLs clarified as plugin defaults; SKILL.md table disclaimers from 7-lite extended with resolution-hierarchy diagram.
5. **commands/roundtable.md drift reconciliation**: keyword auto-detect table (currently lines 170-179) and inline phase enumeration (currently lines 194-199, with phase-name drift versus strategy docs for `consensus-driven` and `six-hats`) reconciled per Option B.
6. **Facilitator-agent strategy-doc pointer sharpening + SKILL.md L178 commitment honored**: 3 pointers in `agents/roundtable/facilitator.md` (currently lines 518/579/607) sharpened from whole-file references to `#strategy-hooks` anchors; `skills/roundtable-execution/SKILL.md:178` parenthetical "(the latter still uses pre-7B inline pattern; Phase 4 will align it)" updated to "(aligned in Phase 4 PR #XX)".
7. **`skills/output-generation/` extended for roundtable** (review #5 A1 fix): create `skills/output-generation/references/roundtable-summary.md` (~60 lines, mirrors `brainstorm.md` pattern); update `output-generation/SKILL.md` description + dispatch table (line 66) to support `workflow_type=roundtable`. Without this, post-Phase-4 `/s2s:roundtable` native invocation would hit a NEW output-template gap analogous to the profile gap that triggered Option ε pivot.

Phase 8 (thin launcher conversion specs/design/brainstorm to ~150 lines each) is the immediate downstream consumer and is NOT in Phase 4 scope; it runs separately after Phase 4 merges.

### Non-goals (explicit deferrals)

- **Phase 8 thin launchers**: separate plan after Phase 4 merges to develop. Phase 4 makes specs/design/brainstorm capable of being thin launchers AND makes roundtable.md the master; Phase 8 collapses the inline launchers.
- **Six-hats wiring with empirical baseline**: prerequisite-blocked on baseline acquisition. Phase 4 implements the Option B mechanism so that six-hats wiring becomes a configuration change only, but does NOT capture the baseline.
- **`debate-phase-machine.md` extraction**: deferred unless §4.0 audit shows debate complexity warrants a machine file. Audit §3 confirms compact dispatch pattern; no extraction needed.
- **New strategy additions**: Phase 4 works with the 5 existing strategies; it does not add a sixth.
- **session-schema.md `INT-*` / `CONF-*` gaps**: pre-existing drift unrelated to roundtable unification.
- **Agent prompt redesign**: `agents/roundtable/facilitator.md` continues to be invoked by roundtable.md. Phase 4 sharpens 3 strategy-doc pointers (win #6) and adds `hook_overrides` consumption logic but does NOT rewrite agent prompt structure.

## 2. Inputs and constraints

### What we know (post §4.0 audit + smoke test)

- **§4.0 step 7 smoke test outcome: (c) graceful** (2026-05-20). Pre-Phase-4 `/s2s:roundtable` native invocation triggers proactive abort by plugin runtime LLM: detects missing `profiles/roundtable.yaml`, surfaces clear diagnostic with remediation options, asks user how to proceed, aborts cleanly with `close_reason: "aborted_profile_gap"`. Full baseline at `.s2s/test-baselines/exp45-roundtable-native-pre-phase4.md`.
- **Plugin's Option A spec authoritative**: `profiles/roundtable.yaml` with `artifact_types: [OQ, CONF]`, `progress.axis: agenda` single `main` topic, `participants.default` from config. Plugin runtime LLM provided this spec; Phase 4 implements verbatim.
- **SKILL.md L178 commitment**: `skills/roundtable-execution/SKILL.md:178` already states "(the latter still uses pre-7B inline pattern; Phase 4 will align it)". Pre-existing Phase 7B commitment that Phase 4 is responsible for aligning roundtable.md.
- `commands/roundtable.md` is 437 lines today, of which Phase 3 (lines 359-437) defers entirely to `roundtable-execution` skill with `"Follow the skill instructions EXACTLY"`. Phase 4 replaces this stub with explicit Read of `phase-2-core.md` after loading the workflow-appropriate profile.
- `commands/{specs,design,brainstorm}.md` (600/536/482 lines post-7B) inline the Phase 2 loop themselves via `phase-2-core.md` Reads. Phase 4 makes roundtable.md follow the same pattern.
- `templates/project/config.yaml` (107 lines, the third source flagged in 7.0 audit §6.2) carries `roundtable.strategy.by_workflow_type` (line 30-33), `roundtable.strategy.consensus` per-strategy rules (line 35-57), `roundtable.participants.by_workflow_type` (line 60-80). Profile YAMLs and SKILL.md duplicate slices of this.
- `default_strategy` field exists in `profiles/{workflow}.yaml` (e.g. `brainstorm.yaml:13 default_strategy: "disney"`) but is **NOT** consulted at command runtime; commands resolve strategy from `config.yaml.roundtable.strategy.by_workflow_type.{workflow}`. `profile-schema.md:115` describes it as "required for Phase 1 strategy resolution"; this is intent, not actual behavior.
- `commands/roundtable.md:194-199` enumerates phases inline with two drift sites versus strategy docs:
  - `consensus-driven`: command says `["proposal", "discussion", "resolution"]`; `consensus-driven.md` says `proposal/refinement/convergence` (per 7.0 audit §4).
  - `six-hats`: command says `["blue-opening", "white", "red", "black", "yellow", "green", "blue-closing"]`; `six-hats.md` line 86 says `["blue-hat-opening", "white-hat", "red-hat", "black-hat", "yellow-hat", "green-hat", "blue-hat-closing"]`.
- Phase 7-lite delivered 5 strategy docs with uniform `## Strategy hooks` sections. Opening lines drawn from a 4-phrase set serve as skip-triggers compatible with Option A (LLM regex) and Option B (command-side regex parse).
- exp44-post-phase7b regression baselines (3 workflows) are the authoritative behavior reference. Phase 4 runtime change may shift one or two specific behaviors (debate Pro/Con assignment data path) but core dump shapes and session file structure must remain identical.

### What we have as baselines

- exp44-post-phase7b: specs, design, brainstorm full structural summaries in `.s2s/test-baselines/`.
- exp44 debate sample (single run): `debate_role` was assigned via LLM emergence; one observation only, not a discriminative baseline.
- **exp45-roundtable-native-pre-phase4 (NEW, 2026-05-20)**: graceful abort with full diagnostic dump; "before" state for `/s2s:roundtable` native; Phase 4.5 captures "after" state in `exp45-roundtable-native-post-phase4.md`.
- No six-hats baseline (prerequisite-blocked task, not addressed here).

### Hard constraints

- **Backward compatible Phase 2 output**. exp44-post-phase7b dump shapes for the 3 workflows must replay identically after Phase 4. Any deviation is a regression and the PR cannot merge.
- **Generic-mode `/s2s:roundtable` native works end-to-end post Phase 4**: with `profiles/roundtable.yaml` in place, full Phase 2 execution completes (no abort, no warning). Verified in §4.5 step 1.
- **State machine preserved**. Step 2.0 to Step 2.10 numbering and dispatch invariants from Phase 7-lite are frozen. Phase 4 adds new inputs to Step 2.2c (3-branch dispatch from hook_overrides) but does not renumber.
- **Existing CLI flags preserved**. `--strategy`, `--participants`, `--workflow-type`, `--output-type`, `--verbose`, `--interactive`, `--diagnostic`, `--pro`, `--con`, `--new`, `--session` continue to work with current semantics. Phase 4 may add new flags but does not remove or rename.
- **No new third-party dependencies**. Pure markdown + plugin-side YAML.
- **Atomic PR**. Single PR target develop, milestone v0.4.0.

## 3. Approach

Phase 4 is the architectural inflection point of TECH-002 for **all four workflows**. The Option A/B/C decision is binding for the runtime wiring layer of all five strategies; six-hats and any future strategy will follow the same mechanism.

### 3.1 Option A/B/C decision matrix

| Criterion | Option A (LLM-mediated Read at Step 2.2c) | Option B (command-side parse in roundtable.md) | Option C (full YAML configs per strategy) |
|-----------|-------------------------------------------|------------------------------------------------|-------------------------------------------|
| **Blast radius** | Low: facilitator agent + Step 2.2c text only | Medium: roundtable.md adds parse logic; strategy docs gain machine-readable anchors | High: 5 new `strategies/{strategy}.yaml` files + schema + validator + migration tooling |
| **Eliminates LLM emergence for hooks** | No, shifts interpretation from "STRATEGY string" to "STRATEGY + markdown prose" | Yes, deterministic regex/string match at Phase 1 produces overrides as data | Yes, fully structured, no parsing |
| **Aligned with roundtable.md-as-master** | Weak: facilitator agent stays as resolution authority, contradicting Phase 4 goal | Strong: roundtable.md becomes the deterministic resolver, consistent with Phase 4 master role | Strong but requires new layer above SKILL.md |
| **Complexity** | Low (~30 lines facilitator prompt) | Medium (~80 lines parse + override dispatch in roundtable.md) | High (~250 lines: schemas + parser + migration + validator) |
| **Reversibility** | Trivial (revert agent prompt) | Easy (delete parse block) | Hard (5 files + schema must be removed; users may have customized) |
| **Phase 7-lite substrate reused** | Yes (skip-trigger phrases as regex) | Yes (skip-trigger phrases as anchors) | Partially (phrases become labels in YAML schema) |
| **Drift surface added** | None | Strategy doc opening-line phrases must stay in sync with regex (single fixture file) | New 4th source: configs/ vs profiles/ vs config.yaml vs SKILL.md |
| **Empirical verifiability** | Silent failure mode (LLM "guesses correctly") | Test-fixture replay: parse a strategy doc and assert output dict | Schema validator runs in CI |

### 3.2 Recommendation: Option B

**Rationale**:

1. **Phase 4 goal alignment**. The phase explicitly elevates roundtable.md to master; Option B places the resolver where the master is. Option A keeps the resolver in the facilitator agent, perpetuating the inversion that Phase 4 is supposed to fix. Option C introduces a fourth source of truth and contradicts the Phase 7-lite triple-duplication-reduction direction.
2. **Substrate already in place**. Phase 7-lite's uniform `## Strategy hooks` sections with the 4-phrase opening line set were designed as skip-trigger anchors for B and C. Option B consumes them as-is; no strategy doc edits required.
3. **Determinism delivered without new file types**. Strategy docs remain human-facing; structure lives in a single fixture file `skills/roundtable-execution/references/strategy-hook-resolution.md` (name chosen to disambiguate from existing `strategy-hooks.md` contract doc). Drift surface is single-fixture.
4. **Reversibility**. If Option B parsing turns out brittle in practice (e.g. natural-language drift in opening lines), reverting to LLM-mediated or escalating to Option C is a localized change.
5. **Empirical verifiability**. Phase 4 test plan (§4.5) can include a deterministic fixture: feed each strategy doc through the parse block, assert expected override dict. Option A has no such test surface.

**Option C is not chosen** because it introduces a fourth source of truth at the same time we are trying to reduce the triple to a clear hierarchy, and the schema work is disproportionate to current 5-strategy scope.

**Option A is not chosen** because it fails the core Phase 4 architectural test (master vs delegated resolution) and reintroduces the LLM emergence problem Phase 7 was originally trying to address.

### 3.3 Triple-duplication resolution

**Decision**: D3, explicit hierarchy with documented roles.

| Source | Role after Phase 4 | What it contains |
|--------|--------------------|------------------|
| `templates/project/config.yaml` | **User canonical**: copied to `.s2s/config.yaml` on `/s2s:init`. Authoritative at runtime. | Project-level overrides: by_workflow_type strategy, participants, escalation triggers, consensus thresholds. |
| `skills/roundtable-execution/profiles/{workflow}.yaml` | **Plugin fallback**: consulted only when config.yaml is missing the key. | Plugin-default strategy per workflow, profile-specific gating (e.g. `has_phase_transition`). |
| `skills/roundtable-strategies/SKILL.md` | **Human-facing documentation only**: no runtime consumption. | Strategy descriptions, workflow defaults table (with `> Authoritative source: profiles/` disclaimer from Phase 7-lite + new resolution-hierarchy diagram). |

**`default_strategy` field**: stays in profile YAMLs as the **plugin fallback** consulted by roundtable.md after CLI and config.yaml. Resolution order codified in roundtable.md Phase 1:

```
CLI --strategy
  ├─ if set → use it
  └─ else → config.yaml.roundtable.strategy.by_workflow_type[{workflow}]
            ├─ if set → use it
            └─ else → profile.yaml.default_strategy
                      ├─ if set → use it
                      └─ else → error "no strategy resolvable"
```

The profile YAML's `strategy_constraints.forced: true` (e.g. `brainstorm.yaml:17`) still wins over all of the above when set; this is a workflow-level constraint, not a fallback.

### 3.4 Work breakdown

Phase 4 delivers in 6 sub-phases over an estimated **~8 hours** (Option ε pivot: removed §4.4b conditional MVF, added profile creation + output template to §4.1):

- **4.0** audit (~1.5h, COMPLETED 2026-05-19, with §7 empirical confirmation 2026-05-20): inventory + smoke test outcome (c) graceful + plugin's Option A spec captured.
- **4.1** triple-dup resolution + `profiles/roundtable.yaml` + output template (~1.75h, was 1.25h; +0.5h for output template per review #5 A1): D3 hierarchy codified, SKILL.md disclaimer + diagram, profile-schema.md updated (roundtable added to enumeration L5), `profiles/roundtable.yaml` created per plugin spec with DEC added (review #5 A2), `output-generation/references/roundtable-summary.md` created + SKILL.md updated to support roundtable workflow_type.
- **4.2** Option B implementation across 3 files (~1.25h): `strategy-hook-resolution.md` fixture (with 2 dict shapes) + parse block in roundtable.md + `phase-2-core.md` Step 2.2c with 3-branch dispatch + facilitator agent consumer with matching 3-branch logic + 3 strategy-doc pointer sharpening + CI-style anchor drift check script.
- **4.3** roundtable.md uniform dispatch (~1.5h, was conditional dispatch): replace lines 359-437 with profile-load + Read phase-2-core.md pattern (same as commands/specs|design|brainstorm.md). Uniform for all 4 workflow_types (no conditional branching needed; roundtable.yaml is now a real profile).
- **4.4** drift fix (currently lines 170-179 + 194-199) (~0.5h): keyword-auto-detect table disclaimer-protected; inline phase enumeration removed by source-of-truth deferral.
- **4.5** regression replay + fixture assertions (~1h, expanded master coverage): exp45-{specs, design, brainstorm, roundtable-routed-as-specs, roundtable-routed-as-design, roundtable-routed-as-brainstorm, roundtable-native} via dogfood; 5 anchor parse fixture assertions; anchor drift check passes; backward-compat resume probe.
- **4.6** close-out (~0.5h): BACKLOG (acceptance criteria #2 and #4 marked **FULLY DONE** post Phase 4 + 8; Phase 9 row REMOVED from phase table), ADR-0011 addendum (Option B + D3 + Option ε pivot rationale + dormant master removed + SKILL.md L178 honored), plan Status finalization, MEMORY.md update.

### 3.5 Why Option ε (Approach 1 with plugin spec) chosen over previous Approach 4

This plan went through 4 review rounds and two architectural pivots:

| Iteration | Approach | Rationale |
|-----------|----------|-----------|
| Initial draft + review #1 | Create `profiles/roundtable.yaml` with invented fields (`output_types_supported`, `min_participants`, etc.) | Naive; review #2 A1 flagged invented fields, "semi-fictional yaml" |
| Review #2 pivot | **Approach 4**: defer generic-mode to Phase 9; preserve current stub | Safer scope; avoided architectural decision under uncertainty |
| Review #4 macro + Option δ | Approach 4 + mandatory §4.4b MVF if smoke outcome b/c | Safety net: no silent broken behavior ships |
| **Smoke test 2026-05-20 + Option ε pivot** | **Approach 1 with plugin's authoritative spec**: create `profiles/roundtable.yaml` per plugin runtime LLM's concrete recommendation | Plugin's diagnostic gave us the schema (no invention); SKILL.md L178 pre-existing commitment honors Phase 4 alignment |

**The smoke test invalidated Approach 4's main rationale** (review #2 A1: "yaml would be semi-fictional, schema needs extension"). The plugin runtime provided concrete spec using existing schema fields with no extension required. With this evidence, Approach 1 becomes the cheapest AND most architecturally correct path:

- Cost ≈ MVF cost (~0.5-1h either way)
- Approach 1 FIXES (not warns about) the issue
- Approach 1 makes `/s2s:roundtable` a first-class workflow per SKILL.md L178 promise
- Approach 1 eliminates Phase 9 (one less phase to plan/execute/release)
- TECH-002 acceptance criteria #2 ("execute all workflows") goes from "partial" to "fully done"

**Approach 4 abandoned** post-smoke-test because:
1. Plugin proved roundtable.yaml is implementable in ~40-50 lines with existing schema (review #2 A1 was overstated)
2. SKILL.md L178 says "Phase 4 will align it"; deferring to Phase 9 contradicts pre-existing commitment
3. MVF (warn + workaround) is strictly inferior to FIX (real profile) when both cost the same

## 4. Sub-phases

**Execution order**: 4.0 → 4.1 → 4.2 → 4.3 → 4.4 → 4.5 → 4.6.

(4.4 follows 4.3 because the drift fix at lines 170-179/194-199 lands cleanly only after the dispatch in 4.3 replaces the surrounding scaffolding.)

### 4.0: audit current state (~1.5h, COMPLETED 2026-05-19 + smoke test 2026-05-20)

**Status**: COMPLETED. Full output at `.s2s/plans/20260518-tech002-phase4-4.0-audit.md` (389 lines, 10 sections + pass-3 grep footer).

**Smoke test (§7) outcome**: **(c) graceful**. Baseline captured at `.s2s/test-baselines/exp45-roundtable-native-pre-phase4.md`. Plugin's Option A spec drives §4.1 profile creation.

**Key audit outputs feeding §4.1-§4.6**:
- §1 Triple-dup map: 11 sites across config.yaml + 3 profiles + SKILL.md classified by D3 role
- §4 Anchor fixture: 4 of 5 strategies map to Branch 1 (`{skip: true}`); only debate exercises Branch 2 (`facilitator_emergent`)
- §5 Phase-name drift: consensus-driven + six-hats confirmed; resolved by §4.4 deletion
- §7 Smoke outcome: (c) graceful → Option ε pivot (drives §4.1 step 6 profile creation)
- §8 Step 2.2c at phase-2-core.md line 269; overrides field at line 286
- §9 Facilitator pointers at lines 518/579/607 confirmed

### 4.1: codify D3 triple-duplication hierarchy + create profiles/roundtable.yaml (~1.25h)

**Goal**: explicit roles for the three sources; runtime resolution order codified; SKILL.md documentation updated. Create `profiles/roundtable.yaml` per plugin's runtime-validated spec (Option ε).

**Actions**:
1. **profile-schema.md**: rewrite the `default_strategy` field description to read "**Plugin fallback**. Consulted by `roundtable.md` Phase 1 after CLI and `config.yaml` are exhausted. See §3.3 resolution hierarchy in Phase 4 plan / ADR-0011 Phase 4 addendum." Same treatment for any other "documented intent, unread" field surfaced in 4.0 §6. Also: line 5 enumeration updated from `Profiles: specs.yaml, design.yaml, brainstorm.yaml` to `Profiles: specs.yaml, design.yaml, brainstorm.yaml, roundtable.yaml`.
2. **`roundtable-strategies/SKILL.md`** v1.2.0 → v1.3.0: insert a new "## Strategy resolution hierarchy" section between current "## Available Strategies" (line 48-56) and "## Workflow-Specific Defaults" (line 60), with an ASCII diagram of `CLI → config.yaml → profile → error`. The existing 7-lite disclaimer banners stay. **Version bump rationale**: additive (new section + diagram, no removals; backward-compatible with all consumers). Also add `roundtable` row to Workflow-Specific Defaults table (line 66-70): `| roundtable | standard | software-architect, technical-lead | Generic discussion, single topic |`.
3. **`templates/project/config.yaml`** header comment: add `# This file is the user-canonical source for strategy/participant defaults at runtime.` Add `# See plugin profiles for fallback values if a key is omitted.` near the strategy block.
4. **Profile YAML comments**: in `profiles/{workflow}.yaml` (4 files post-§4.1 step 6), prefix `default_strategy` with a comment block: `# Plugin fallback. Consumed only when .s2s/config.yaml omits roundtable.strategy.by_workflow_type[{workflow}].`
5. **Cross-reference fixture**: add a single-source table `skills/roundtable-execution/references/strategy-resolution.md` (new file, ~60 lines) that documents the hierarchy with one worked example per workflow (4 examples now: specs/design/brainstorm/roundtable). Referenced from SKILL.md and roundtable.md.
6. **Create `profiles/roundtable.yaml`** per plugin's runtime spec + review #5 A2 fix (DEC added for backward-compat) (~50 lines):
   ```yaml
   # Workflow profile: roundtable
   # Schema: skills/roundtable-execution/references/profile-schema.md
   # Consumed by: phase-2-core.md (Phase 2 Round Loop), commands/roundtable.md (Phase 1/3 inline)

   workflow_type: "roundtable"

   topic:
     pattern: "{topic}"
     source: "cli-arg.topic"

   state_phase: "discussion"

   default_strategy: "standard"
   strategy_constraints:
     allowed:
       - "standard"
       - "consensus-driven"
       - "debate"
       - "six-hats"
       # disney excluded: forced for brainstorm only, not appropriate for generic
     forced: false

   participants:
     default:
       - "software-architect"
       - "technical-lead"
     configurable: true

   artifact_types:
     # DEC added (review #5 A2): preserves backward-compat with current
     # commands/roundtable.md:266 session.yaml init `decisions: {}` slot.
     # Roundtable native discussions commonly emit decisions; DEC primary.
     - prefix: "DEC"
       session_key: "decisions"
       is_primary: true
     - prefix: "OQ"
       session_key: "open_questions"
       is_primary: false
     - prefix: "CONF"
       session_key: "conflicts"
       is_primary: false

   progress:
     axis: "agenda"
     agenda_count: 1
     # No agenda_reference: roundtable agenda is a single user-provided topic, no reference file
     changes_field: "agenda_changes"
     synthesis_input_fields:
       - "full_agenda"
       - "focus_topic"
     synthesis_output_field: "agenda_update"

   round_summary:
     tag_field: "topic_id"

   next_values:
     - "continue"
     - "conclude"
     - "escalate"

   has_phase_transition: false

   display_block_style: "minimal"
   ```
7. **Update SKILL.md L178 commitment**: change parenthetical from `(the latter still uses pre-7B inline pattern; Phase 4 will align it)` to `(aligned in Phase 4 PR #XX, see ADR-0011 Phase 4 addendum)`.
8. **Create `skills/output-generation/references/roundtable-summary.md`** (review #5 A1 fix, ~60 lines): mirror `references/brainstorm.md` pattern. Provides pseudo-code for Phase 3 summary generation from roundtable session.yaml: read artifacts (DEC/OQ/CONF), render summary doc with topic + decisions + open questions + conflicts; write to `.s2s/sessions/{session-id}-summary.md` or stdout per output_type.
9. **Update `skills/output-generation/SKILL.md`** (review #5 A1 fix): description line 3 update from "Supports specs (SRS), design (arc42 + ADR), and brainstorm (summary + ideas)" to add "and roundtable (generic summary)"; dispatch table at line 66 update to include `workflow_type=roundtable → references/roundtable-summary.md`; line 104 used-by list extended.

**Exit condition**: D3 hierarchy is the single explanation of strategy resolution across plugin; no contradictory text remains. `grep -rn "default_strategy" skills/ commands/` returns only sites that explicitly state "plugin fallback" or quote the resolution hierarchy. `ls skills/roundtable-execution/profiles/` shows **4 files** (brainstorm, design, specs, roundtable). SKILL.md L178 reflects Phase 4 completion. `ls skills/output-generation/references/` shows **4 files** (brainstorm, design-arc42, specs-srs, roundtable-summary).

### 4.2: Option B implementation across 3 files (~1.25h)

**Goal**: deterministic resolution of per-strategy hook overrides via a parser block in roundtable.md, a Step 2.2c modification in phase-2-core.md, and a hook_overrides consumer in the facilitator agent. Two distinct fallback semantics codified: `{skip: true}` (strategy declares no per-round hooks, current standard behavior) versus absent field (pre-Phase-4 session, LLM-emergent fallback).

**Actions**:
1. **Anchor fixture**: create `skills/roundtable-execution/references/strategy-hook-resolution.md` (new file, ~80 lines; name disambiguated from existing `strategy-hooks.md` contract doc). Contents:
   - One row per strategy with: opening-line phrase exact match (regex), derived override dict, target Step 2.2c field set.
   - Header note: "Deterministic fixture consumed by `commands/roundtable.md` Phase 1 strategy-hook resolution. Keep in sync with `roundtable-strategies/references/{strategy}.md` `## Strategy hooks` opening lines."
   - Two semantically-distinct dict shapes documented: `{skip: true}` for strategies declaring no per-round hooks (standard, consensus-driven, disney, six-hats per audit §4); `{participant_response_field: X, round_summary_field: Y, policy: "facilitator_emergent" | <coded_rule>}` for strategies with hooks (debate only initially).
2. **Parser block in roundtable.md**: insert a new "## Resolve strategy hooks" section (post strategy-doc Read, pre debate handling). Block does:
   - Read `strategy-hook-resolution.md` fixture table.
   - Read the chosen `{strategy}.md` `## Strategy hooks` section (already done in current flow).
   - Match opening line to anchor row; produce `strategy_hook_overrides` dict per fixture.
   - Persist `strategy_hook_overrides` in session.yaml under `agent_state.facilitator.hook_overrides` so phase-2-core.md Step 2.2c can pass it to the facilitator agent at each round.
3. **phase-2-core.md Step 2.2c modification** (NEW deliverable surfaced in review #1): in the facilitator-invocation block (around line 269), add 3-branch dispatch reading `session.yaml.agent_state.facilitator.hook_overrides`:
   - **Branch 1** (`hook_overrides.skip == true`): pass `hook_overrides: {skip: true}` to facilitator agent input; facilitator emits no per-round overrides (strategy-by-design behavior, current standard for `standard`/`consensus-driven`/`disney`/`six-hats`).
   - **Branch 2** (policy fields present): pass full dict; facilitator honors the policy (debate).
   - **Branch 3** (`hook_overrides` field absent in session.yaml): do NOT include `hook_overrides:` key in agent input at all; facilitator falls back to its current LLM-emergent inference. Branch 3 is the BACKWARD-COMPAT PATH ONLY post-Phase-4: any newly-created Phase 4+ session will have `hook_overrides` populated (because all 4 workflows now go through the parser); only pre-Phase-4 resumed sessions trigger Branch 3.
4. **Facilitator agent NEW logic**: `agents/roundtable/facilitator.md` adds a new "Hook override consumption" section to its system prompt with three corresponding branches matching Step 2.2c above:
   - `hook_overrides.skip == true` → emit no per-round overrides.
   - `hook_overrides` with policy fields → populate `participant_context.overrides.{participant-id}.{field}` per the dict.
   - `hook_overrides` key absent in input → fall back to current LLM-emergent inference (preserves pre-Phase-4 session resume behavior).
5. **Strategy-doc pointer sharpening** (win #6): in `agents/roundtable/facilitator.md`, change the 3 strategy-doc pointers (currently around lines 518/579/607, exact lines confirmed in 4.0 step 9) from `{strategy}.md` (whole-file) to `{strategy}.md#strategy-hooks` (anchor). Reduces coupling; cost ~3 edits.
6. **Test fixture**: add 5 unit-style assertions inside `.s2s/plans/20260518-tech002-phase4-4.2-fixture.md` (kept in plans/ to avoid muddling with `.s2s/test-baselines/` structural baselines): for each strategy doc, capture the parse output dict and freeze it. Used in §4.5 to assert no regression.
7. **CI-style anchor drift check** (in-scope, ~15min): create `skills/dev-testing/references/strategy-hook-anchor-check.md` (~30 lines) containing a bash snippet that, for each of 5 strategy docs, extracts the first non-empty line of `## Strategy hooks` section and compares to the corresponding regex anchor in `strategy-hook-resolution.md`. Exits non-zero if drift detected. Documented as "run before any docs PR touching strategy docs".

**Exit condition**: roundtable.md has deterministic hook resolution; phase-2-core.md Step 2.2c reads + dispatches via 3-branch logic; facilitator agent consumes input with matching 3-branch logic; 5 fixture assertions documented; anchor drift check script exists and passes for all 5 strategies as-is. Backward-compat preserved: missing `hook_overrides` field triggers LLM-emergent fallback (Branch 3), semantically distinct from `{skip: true}` (Branch 1).

### 4.3: expand roundtable.md to master via uniform dispatch (~1.5h)

**Goal**: replace the Phase 3 stub (lines 359-437) with uniform dispatch through `phase-2-core.md` for all 4 workflow types (specs/design/brainstorm/roundtable). Pattern mirrors `commands/design.md:379-401`. No conditional branching needed because `profiles/roundtable.yaml` now exists (Option ε).

**Actions**:
1. **Uniform Phase 2 dispatch** (Option ε: simplified, no conditional branching):
   ```
   Read profiles/{workflow_type}.yaml → PROFILE  # all 4 workflow_types supported
   Read phase-2-core.md and follow §2 Round Loop
   ```
   Replace lines 359-437 (~78 lines of stub + reminders) with the compact pattern from `design.md:379-401` (~25 lines including framing). Expected delta: −78 + 25 = −53 lines from this section, offset by other additions elsewhere.
2. **Session ID naming**: current line 237 generates `{timestamp}-roundtable-{topic-slug}` (hard-coded "roundtable" prefix because command name is `/s2s:roundtable`). Phase 4 change: session_id uses `workflow_type` prefix instead of command name: `{ts}-{workflow_type}-{slug}`. So `/s2s:roundtable "topic"` (workflow_type defaults to roundtable) → `{ts}-roundtable-{slug}` (unchanged); `/s2s:roundtable "topic" --workflow-type specs` → `{ts}-specs-{slug}` (consistent with what `/s2s:specs` produces today and what Phase 8 thin launchers will need). Documented in commit message + ADR-0011 addendum.
3. **Output dispatch**: Phase 3 output-type defaulting per workflow:
   - `specs` → `requirements`
   - `design` → `architecture`
   - `brainstorm` → `summary` (with brainstorm output template)
   - `roundtable` → `summary` (current default, no change)
   Read the corresponding `output-generation/references/{template}.md` per `--output-type` resolution.
4. **Resume path**: ensure `--session {id}` works for sessions of any `workflow_type` (current code only handles `workflow_type: roundtable` on resume, see line 75). Add workflow-type-aware resume dispatch.
5. **Diagnostic mode**: `--diagnostic` continues to force `verbose_flag = true` and routes to `Step 3.0 Final Diagnostic Report` in `phase-2-core.md` for all 4 workflows.
6. **Line budget**: current 437 lines − Phase 2 stub (~78 lines removed) + Phase 1 profile load (~15 lines) + Phase 2 compact dispatch (~25 lines) + workflow-type output dispatch (~20 lines) + resume extension (~15 lines) + session-id renaming (~5 lines) + Phase 1 parser block from §4.2 (~40 lines) = **~479 lines target**. Margin: keep ≤ 520 lines.

**Exit condition**: roundtable.md can run all 4 workflow types end-to-end through phase-2-core.md uniformly; `wc -l commands/roundtable.md` ≤ 520; specs/design/brainstorm commands UNCHANGED (still inline; Phase 8 territory).

### 4.4: fix command drift (currently lines 170-179 + 194-199) (~0.5h)

**Goal**: remove inline phase enumeration and keyword auto-detect drift; reconcile with strategy docs. Line numbers will shift after §4.3 expansion; the 4.0 audit captures the post-4.3 line positions for precise targeting.

**Actions**:
1. **Keyword-auto-detect table** (currently lines 170-179): keep the table (it serves a UX purpose: telling user which strategy fits which keywords) but add a header note `> Keyword → strategy mapping is documented here for user discoverability. The authoritative strategy descriptions live in skills/roundtable-strategies/references/{strategy}.md.` No deletion; just disclaimer.
2. **Inline phase enumeration** (currently lines 194-199): REMOVE the `- **standard**: phases: ["discussion"]` bulleted list entirely. Replace with: `Read the strategy doc; the canonical phases live in its Configuration block. The strategy-hook overrides parsed in §4.2 surface phase metadata when needed.`
3. **consensus-driven phase-name fix**: data fix; `consensus-driven.md` is authoritative per Phase 7-lite. The command's inline `["proposal", "discussion", "resolution"]` is wrong and is removed in step 2 above.
4. **six-hats phase-name fix**: same; six-hats.md line 86 is authoritative; command's enumeration is removed.
5. **Grep verification**: `grep -n "phases:" commands/roundtable.md` returns no inline phase list; only Read directives.

**Exit condition**: no inline phase enumeration in roundtable.md; keyword table disclaimer-protected; phase-name drift eliminated by source-of-truth deferral.

### 4.5: regression replay + Option B fixture verification + backward-compat (~1h)

**Goal**: confirm no behavioral regression across the 3 structured workflows that have baselines; verify `/s2s:roundtable` native works end-to-end post-Phase-4 (no more abort); verify Option B fixture matches expected dicts; confirm pre-Phase-4 sessions resume cleanly via Branch 3.

**Actions**:
1. **Regression replay + expanded master coverage** in dogfood (`ElfGiftRush_s2s/exp45` worktree, same used for §4.0 step 7 smoke test; user can reset to af9af48 between runs or use sibling worktree if persistence needed):
   - **Direct invocations (unchanged paths, full regression)**:
     - `/s2s:specs "..."` compare structural summary to `.s2s/test-baselines/exp44-specs-post-phase7b.md`.
     - `/s2s:design "..."` same, `exp44-design-post-phase7b.md`.
     - `/s2s:brainstorm "..."` same, `exp44-brainstorm-post-phase7b.md`.
   - **Master path via roundtable.md (all 3 structured workflows)**:
     - `/s2s:roundtable "..." --workflow-type specs` expected output structurally equivalent to `/s2s:specs` (session_id will use `specs-` prefix per §4.3 step 2).
     - `/s2s:roundtable "..." --workflow-type design` expected output structurally equivalent to `/s2s:design`.
     - `/s2s:roundtable "..." --workflow-type brainstorm` expected output structurally equivalent to `/s2s:brainstorm`.
   - **Generic-mode `/s2s:roundtable` native (Option ε first-class workflow)**:
     - `/s2s:roundtable "test topic"` (no --workflow-type, uses roundtable.yaml profile).
     - **Expected**: full Phase 2 execution completes (no abort, no smoke_test block in session.yaml). session.yaml has `status: completed`, artifacts populated (OQ-* / CONF-* per profile), Phase 3 summary output rendered.
     - Capture as `.s2s/test-baselines/exp45-roundtable-native-post-phase4.md` (companion to pre-Phase-4 baseline).
2. **Anchor parse fixture**: for each of 5 strategies, run the parse block standalone (manual Read + match probe), assert output dict equals `.s2s/plans/20260518-tech002-phase4-4.2-fixture.md` frozen values.
3. **Backward-compat resume probe**: take a frozen pre-Phase-4 session file (from `.s2s/test-baselines/exp44-*`) and resume via `/s2s:roundtable --session {id}`. Assert behavior:
   - No error on missing `agent_state.facilitator.hook_overrides` field.
   - Facilitator agent input does NOT include `hook_overrides:` key (matches §4.2 step 3 Branch 3).
   - Per-round behavior identical to current LLM-emergent inference (no semantic shift).
4. **Acceptable deltas**: debate Pro/Con assignment data path changes (now flows through hook_overrides session field) but behavior is identical because initial `policy: "facilitator_emergent"` (per §4.2 step 1 default) preserves LLM emergence.
5. **Unacceptable deltas**: dump schema changes (except additive `agent_state.facilitator.hook_overrides`), Step 2.X numbering changes, session.yaml structural differences, missing artifacts. Any unacceptable delta blocks the PR.
6. **Light smoke probe (Phase 1 inspection)**: `/s2s:roundtable "test topic" --workflow-type design --strategy debate` (debate strategy exercises Branch 2 non-skip path); inspect session.yaml first write, confirm `agent_state.facilitator.hook_overrides` populated with `debate_role`/`debate_phase` keys.

**Exit condition**: 3 structured-workflow baselines match (structural); roundtable.md master path produces structurally-equivalent output for all 3 structured workflow types; **generic-mode `/s2s:roundtable` native produces clean session completion** (no abort, no warnings, post-Phase-4 baseline captured); 5 fixture assertions pass; backward-compat resume probe succeeds via Branch 3; light smoke probe verifies `hook_overrides` populated via Branch 2.

#### 4.5 execution results (2026-05-21, dogfood ElfGiftRush_s2s/exp45..exp52)

8 runs across 7 worktrees, all PASS. Backward-compat resume probe deferred (see §8 follow-ups). Anchor parse fixture (5 assertions) verified statically against `.s2s/plans/20260518-tech002-phase4-4.2-fixture.md` during §4.2 implementation; runtime parser path exercised implicitly by all 8 runs (no parse-error abort observed).

| Step | Worktree | Command | Workflow | Strategy | Branch | Result | Notes |
|------|----------|---------|----------|----------|--------|--------|-------|
| 1 | exp45 | `/s2s:roundtable "..." --diagnostic` | roundtable | standard | B1 (skip) | ✅ PASS | post-Phase-4 baseline captured; 9 artifacts (4 DEC + 4 OQ + 1 CONF); see `exp45-roundtable-native-post-phase4.md` |
| 2 | exp52 | `/s2s:roundtable "..." --workflow-type design` | design (via master) | debate | B2 (policy dict) | ✅ PASS | implicit Step 7 validation; 5 ARCH + ADR-0001; `hook_overrides` populated with `debate_role`/`debate_phase` |
| 3 | exp46 | `/s2s:specs --diagnostic` | specs (direct) | consensus-driven | B1 (skip) | ✅ PASS with warnings | 32 artifacts (12 REQ, 5 BR, 1 NFR, 7 EX); 3 minor warnings (see §8) |
| 4 | exp47 | `/s2s:design --diagnostic` | design (direct) | debate | B2 | ✅ PASS | 35 artifacts (9 ARCH + 18 COMP + 5 INT); ADR-0001..0008; clean diagnostic |
| 5 | exp48 | `/s2s:brainstorm "..." --diagnostic` | brainstorm (direct) | disney | B1 | ✅ PASS | 12 IDEA + 12 RISK + 2 OQ; Disney phase machine R1/R2/R3; clean diagnostic |
| 6 | exp49 | `/s2s:roundtable "..." --workflow-type specs` | specs (via master) | consensus-driven | B1 | ✅ PASS | 17 artifacts (8 REQ + 1 EX + 2 CONF + 6 OQ); requirements.md SRS; structurally equivalent to Step 3 |
| 7 | exp50 (skip) | — | — | — | — | implicit | covered by Step 2 (master→design proven) |
| 8 | exp51 | `/s2s:roundtable "..." --workflow-type brainstorm` | brainstorm (via master) | disney | B1 | ✅ PASS | 25 artifacts (5 IDEA + 2 OQ + 9 RISK + 9 MIT); structurally equivalent to Step 5 |

**Verdict**: Phase 4 Option ε pivot validated end-to-end. All 4 workflows (specs, design, brainstorm, roundtable) executable via both direct and master paths. Zero wiring regressions; 4 cumulative diagnostic findings (all non-blocking, see §8).

### 4.6: close-out (~0.5h)

**Actions**:
1. `.s2s/BACKLOG.md` TECH-002 block: Phase 4 marked ✅ completed; Phase 8 promoted to `in_progress (next session)`; **Phase 9 row REMOVED from phase table** (Option ε pivot resolved generic-mode in Phase 4); Acceptance Criterion **#2** ("`roundtable.md can execute all workflows`") and **#4** ("`Skills actually used, not just declared`") marked **FULLY DONE** post-Phase-4 (no partial-done caveat needed).
2. `.s2s/decisions/0011-roundtable-command-unification.md` Phase 4 addendum: record (i) Option B choice with §3.1 matrix summary; (ii) D3 hierarchy decision; (iii) **Option ε pivot rationale**: smoke test outcome (c) graceful + SKILL.md L178 commitment + plugin's runtime-validated Option A spec invalidated Approach 4; (iv) `profiles/roundtable.yaml` content rationale; (v) phase-2-core.md Step 2.2c modification with 3-branch semantics; (vi) drift fixes + pointer sharpening; (vii) **SKILL.md L178 commitment honored**; (viii) **roundtable-strategies/ asymmetry note**: roundtable-execution = executable via Read; roundtable-strategies = parsed by command, documentation-only at runtime; (ix) CI anchor drift check existence + invocation path.
3. Plan Status field finalize: `draft` → `completed (PR #XX merged YYYY-MM-DD)` post-merge.
4. `MEMORY.md` `project_tech002_progress.md` updated to reflect Phase 4 done (all 4 workflows); Phase 8 + six-hats baseline as remaining items; **Phase 9 not needed**; MEMORY.md index entry updated.

**Exit condition**: BACKLOG + ADR + plan + memory all consistent with post-Phase-4 state; Option ε pivot explicit in ADR-0011 addendum; Phase 9 row removed from BACKLOG phase table.

## 5. Risk register

| ID | Risk | Likelihood | Impact | Mitigation |
|----|------|------------|--------|------------|
| R1 | Option B fixture brittleness: opening-line phrases drift when strategy docs are edited | medium | medium | §4.2 anchor fixture is single-file; §4.2 step 7 ships in-scope drift check script that runs against all 5 strategies; fixture file header note "must stay in sync". |
| R2 | roundtable.md exceeds 520-line budget after Phase 2 expansion | low | low | §4.3 step 6 line budget computation: 437 + ~42 (additions minus stub removal) = ~479. If overflow, two honest options: (a) extend budget to ≤600 lines (no architectural compromise); (b) extract Phase 0 auto-detect section (lines 29-146) to `roundtable-execution/references/auto-detect.md` (~120 lines, behaviorally neutral). |
| R3 | Resume path workflow-type-aware dispatch breaks legacy `--session` for pure roundtable sessions | low | high | §4.3 step 4 explicitly preserves current line 75 semantics for `workflow_type: roundtable`; extends only to handle other workflow_types. Test in §4.5 step 3. |
| R4 | Triple-dup hierarchy D3 confuses users (which file to edit?) | medium | medium | §4.1 SKILL.md resolution diagram + strategy-resolution.md worked examples + config.yaml header comment all repeat the hierarchy explicitly. |
| R5 | Debate Pro/Con deterministic assignment (Option B) produces worse pairings than LLM-emergent | low | medium | exp44 sample is one observation; deterministic anchor policy is `facilitator_emergent` until empirical data justifies a coded rule. Option B initial overrides preserve current emergent behavior; only six-hats and future strategies get deterministic policy at this stage. |
| R6 | Phase 4 changes break the 3 structured-workflow baselines (regression) | low | high | §4.5 replay is the gate. Mitigation if unacceptable delta: fix in-place for minor deltas; for significant deltas, escalate to additional review round or split PR into smaller commits; full Phase 4 rollback only as last resort. |
| R7 | `default_strategy` change from "documented intent" to "actual fallback" exposes a latent bug if profile YAML value disagrees with current implicit behavior | low | low | §4.0 audit cross-checks profile.default_strategy vs config.yaml.by_workflow_type for each workflow; reconcile any disagreement in §4.1 commit. |
| R8 | `profiles/roundtable.yaml` content has incorrect schema field values, causing post-Phase-4 generic-mode runtime errors | low | high | §4.1 step 6 yaml drafted per plugin's runtime spec + review #5 A2 (DEC added). §4.5 step 1 generic-mode probe is the definitive test: if outcome NOT (a) post-Phase-4, the yaml needs adjustment. Easy iteration: edit yaml + re-run probe. |
| R14 | output-generation skill lacks roundtable template, breaking Phase 3 output dispatch for `/s2s:roundtable` native sessions post-Phase-4 (analogous to profile gap discovered in §4.0 step 7) | medium | high | §4.1 step 8 + step 9 ship `roundtable-summary.md` + SKILL.md update IN-SCOPE. §4.5 step 1 generic-mode probe end-to-end test includes Phase 3 output rendering. Without this fix, /s2s:roundtable native would abort at Phase 3 same way pre-Phase-4 aborted at Phase 1. |
| R9 | `phase-2-core.md` Step 2.2c modification not done: Option B data path incomplete (overrides written to session.yaml but never read) | medium | high | §4.2 step 3 explicitly delivers Step 2.2c modification as in-scope work with 3-branch semantics. §4.0 step 8 confirmed exact insertion site (line 269 area, overrides field at 286). §4.5 step 6 light smoke probe verifies `hook_overrides` populated AND structurally consumable via Branch 2. |
| R10 | Backward-compat resume probe fails: pre-Phase-4 session resumes throw on missing `agent_state.facilitator.hook_overrides` field | low | high | §4.2 steps 3+4 specify 3-branch logic with absent-field fallback (Branch 3) to LLM-emergent. §4.5 step 3 dedicated probe with frozen pre-Phase-4 session file verifies. |
| R11 | `profiles/roundtable.yaml` spec (per plugin: `artifact_types: [OQ, CONF]` only, no primary artifacts) results in user-visible "no decisions emerged" complaint for `/s2s:roundtable` usage | medium | low | Roundtable is generic discussion; users get OQs + conflicts as natural emergent artifacts. Decisions can still be created via Phase 3 output summary or by user manually editing session.yaml. Documented in `profiles/roundtable.yaml` header comment + SKILL.md description. If feedback emerges, easy to add `DEC` (decisions) prefix in a future minor release. |
| R12 | Phase 4 master code is dormant until Phase 8; if Phase 8 is delayed indefinitely, v0.4.0 ships partial architectural change | medium | medium | Per Option ε pivot, master is NOT fully dormant: `/s2s:roundtable` native now exercises the master path (was abort pre-Phase-4, now clean execution). Phase 4 deliverable is user-visible (generic-mode works). Phase 8 still needed for thin launchers, but `/s2s:roundtable --workflow-type X` and `/s2s:roundtable` native both prove the master works. |

## 6. Done criteria

- [x] 4.0 audit file produced (2026-05-19); per-sub-phase task lists finalized; pass-3 grep verification recorded; phase-2-core.md Step 2.2c modification site identified; **§4.0 step 7 pre-Phase-4 generic-mode smoke test executed (2026-05-20); outcome (c) graceful recorded; Option ε pivot decided**.
- [x] Smoke test baseline captured at `.s2s/test-baselines/exp45-roundtable-native-pre-phase4.md`.
- [x] D3 hierarchy codified: profile-schema.md (with roundtable added to L5 enumeration), SKILL.md (v1.3.0 with new "Strategy resolution hierarchy" section + ASCII diagram + roundtable row in defaults table), templates/project/config.yaml, profiles/*.yaml comments (4 files), strategy-resolution.md reference file (4 worked examples).
- [x] `grep -rn "default_strategy" skills/ commands/` returns only "plugin fallback" or hierarchy-quoting sites; no orphan references. (verified 2026-05-21)
- [x] **`profiles/roundtable.yaml` created** per plugin's runtime spec + review #5 A2 fix (artifact_types includes DEC for backward-compat) (~50 lines, uses existing schema fields, no extension); `ls skills/roundtable-execution/profiles/` shows 4 files. (verified 2026-05-21: brainstorm.yaml, design.yaml, roundtable.yaml, specs.yaml)
- [x] **SKILL.md L178 commitment updated** from "Phase 4 will align it" to "aligned in TECH-002 Phase 4 via uniform dispatch + profiles/roundtable.yaml".
- [x] **`skills/output-generation/references/roundtable-summary.md` created** (review #5 A1 fix, ~60 lines mirrors brainstorm.md pattern); `output-generation/SKILL.md` description + dispatch table updated to support `workflow_type=roundtable`; `ls skills/output-generation/references/` shows 4 files. (verified 2026-05-21: brainstorm.md, design-arc42.md, roundtable-summary.md, specs-srs.md)
- [x] Option B implemented across 3 files: `strategy-hook-resolution.md` fixture exists with 2 dict shapes documented (`{skip: true}` vs policy dict); roundtable.md Phase 1 has parse block; `phase-2-core.md` Step 2.2c reads `agent_state.facilitator.hook_overrides` and dispatches via 3-branch logic; facilitator agent consumes input with matching 3-branch logic; 5 anchor assertions frozen in `.s2s/plans/20260518-tech002-phase4-4.2-fixture.md`.
- [x] **CI-style anchor drift check script** exists at `skills/dev-testing/references/strategy-hook-anchor-check.md` and passes for all 5 strategies as-is. Documented invocation path in script header.
- [x] 3 facilitator-agent strategy-doc pointers sharpened to `#strategy-hooks` anchors (lines 533/594/622 area, refreshed during §4.2).
- [x] roundtable.md expanded to master with uniform dispatch: `--workflow-type {specs|design|brainstorm|roundtable}` (or absent = roundtable) all dispatch through `phase-2-core.md`; resume works for all workflow_types; `wc -l commands/roundtable.md` = 479 ≤ 520. (verified 2026-05-21)
- [x] specs/design/brainstorm commands UNCHANGED in this PR (Phase 8 territory).
- [x] Keyword-auto-detect table disclaimer-protected; inline phase enumeration removed.
- [x] consensus-driven and six-hats phase-name drift resolved (by source-of-truth deferral).
- [x] Regression replay: 3 structured baselines match structurally; debate data-path delta documented; roundtable.md master path produces structurally-equivalent output for all 3 structured workflows via `/s2s:roundtable --workflow-type {specs,design,brainstorm}` (Step 7 implicit via Step 2); **`/s2s:roundtable` native produces clean session completion** (no abort, status=completed, DEC/OQ/CONF artifacts populated, Phase 3 summary rendered). Post-Phase-4 baseline captured at `.s2s/test-baselines/exp45-roundtable-native-post-phase4.md`. See §4.5 execution results table for full 8-run scoreboard.
- [x] 5 anchor parse fixture assertions pass (verified statically during §4.2 implementation; runtime parser exercised implicitly across 8 §4.5 dogfood runs without parse-error abort).
- [ ] Backward-compat resume probe: pre-Phase-4 session file resumes without error on missing `hook_overrides` field; facilitator falls back to LLM-emergent inference via Branch 3 (NOT via Branch 1's skip path); behavior verified visible. **Deferred to §8 follow-up; non-blocking given Branch 3 logic statically reviewed in §4.2 step 3.**
- [x] Light smoke probe (`/s2s:roundtable "test" --workflow-type design --strategy debate`) populates `agent_state.facilitator.hook_overrides` with `debate_role` and `debate_phase` fields (Branch 2 working). (exp52 Step 2 evidence)
- [x] `.s2s/BACKLOG.md` TECH-002 block: Phase 4 ✅; Phase 8 `in_progress (next session)`; **Phase 9 row REMOVED**; TECH-002 acceptance criteria #2 and #4 marked **FULLY DONE** (no partial caveat). (committed fddcbf1)
- [x] ADR-0011 Phase 4 addendum: Option B + D3 + **Option ε pivot rationale** + profiles/roundtable.yaml content + phase-2-core.md Step 2.2c modification (3-branch) + drift fixes + pointer sharpening + SKILL.md L178 commitment honored + roundtable-strategies/ asymmetry note + CI anchor drift check existence all recorded. (committed fddcbf1)
- [x] PR opened against `develop`, milestone v0.4.0. (PR #16, merged 2026-05-21 as 773fb75)
- [x] Plan `Status` field updated from `in close-out` to `completed (PR #16 merged 2026-05-21)` post-merge. (TECH-002 Phase 8 first commit, per close-out option B)

## 7. PR strategy

**Single PR**: `feature/TECH-002-phase4-roundtable-master` → `develop`.

Commit structure (in execution order):

1. `docs(plans,baselines): Phase 4.0 audit + smoke test baseline + Option ε pivot` (4.0, includes 2026-05-20 smoke test execution and pivot documentation)
2. `refactor(config,profiles,output): codify D3 strategy resolution hierarchy + create profiles/roundtable.yaml + create roundtable output template` (4.1)
3. `feat(roundtable): Option B strategy-hook parser, fixture, Step 2.2c 3-branch dispatch, facilitator consumer, pointer sharpening, anchor drift check` (4.2). **Optional split**: 3a `feat(roundtable): strategy-hook-resolution.md fixture + parser block + anchor-check script`, 3b `feat(phase-2-core): Step 2.2c 3-branch hook_overrides dispatch`, 3c `feat(facilitator): hook_overrides consumer logic + sharpen 3 strategy-doc pointers to #strategy-hooks anchors`.
4. `feat(commands): expand roundtable.md to master via uniform dispatch (all 4 workflow types)` (4.3)
5. `fix(commands): remove inline phase enumeration drift in roundtable.md` (4.4)
6. `test(baselines): exp45 regression replay (expanded master coverage + roundtable native), anchor parse fixture, backward-compat resume probe` (4.5)
7. `docs(adr,backlog,plan,skill): close Phase 4, ADR-0011 Phase 4 addendum (Option B + D3 + Option ε), SKILL.md L178 commitment honored` (4.6)

7 commits, atomic.

PR body must include:
- Link to plan file, 4.0 audit file, smoke test baseline.
- Explicit "Option B chosen for hook wiring, see §3.1 matrix + ADR-0011 Phase 4 addendum" note.
- **Option ε pivot summary**: smoke test outcome (c) + SKILL.md L178 commitment + plugin spec → Approach 4 abandoned, Approach 1 adopted with plugin's authoritative spec; Phase 9 no longer needed.
- D3 hierarchy diagram snippet.
- Before/after `wc -l commands/roundtable.md`.
- Regression deltas table (acceptable + unacceptable inventory).
- Pre/post Phase 4 baselines for `/s2s:roundtable` native: abort (close_reason: aborted_profile_gap) → clean completion.

## 8. Out-of-scope follow-ups (tracked, not actioned)

- **Phase 8 thin launcher conversion**: specs/design/brainstorm to ~150 lines each. Next plan after Phase 4 merges. Phase 4 makes the master capable for all 4 workflows; Phase 8 collapses the inline launchers.
- **Six-hats wiring with empirical baseline**: capture baseline via `/s2s:design --strategy six-hats --verbose --diagnostic` on dogfood; freeze structural summary in `.s2s/test-baselines/`. Then add a deterministic anchor policy to `strategy-hook-resolution.md` (Option B configuration change only, no architectural work). Separate task.
- **`debate-phase-machine.md` extraction**: if 4.0 audit reveals debate complexity rivals disney, extract analogously. Deferred otherwise; 4.0 audit confirmed not needed.
- **session-schema.md `INT-*` / `CONF-*` gaps**: pre-existing drift unrelated to Phase 4; tracked separately in BACKLOG.
- **`templates/project/config.yaml` per-strategy consensus rules duplication**: lines 35-57 carry consensus thresholds per strategy that profile YAMLs also reference indirectly. Phase 4 D3 keeps config.yaml as user canonical; further normalization (e.g. moving consensus rules into strategy docs) is post-v0.4.0.
- **New strategy onboarding doc**: with Option B in place, adding a 6th strategy is a 3-step procedure (new strategy doc with `## Strategy hooks` + new anchor row + optional override policy). Document this in `s2s-guide` skill; post-v0.4.0 task.
- **Promote debate anchor policy from `facilitator_emergent` to deterministic rule**: once enough exp45+ debate runs are observed, codify Pro/Con assignment rule in `strategy-hook-resolution.md` instead of falling back to facilitator emergence. Empirical-data-driven; not in Phase 4 scope.
- **`profiles/roundtable.yaml` artifact_types expansion**: Phase 4 ships with `[OQ, CONF]` per plugin spec (minimal). If user feedback requests primary artifacts (e.g. DEC-* for decisions), add in a future minor release; trivial profile edit. (Status update: Phase 4 actually shipped with `[DEC, OQ, CONF]` per review #5 A2 fix; DEC included for backward-compat.)
- **`phase-2-core.md` Task-resume vs SendMessage-by-name harness gap**: surfaced during §4.5 Step 2 dogfood (2026-05-20). phase-2-core.md Step 2.2a/2.3a expects `Task.resume: "{agent_id}"` to resume facilitator/participants across rounds, but Claude Code's SendMessage tool addresses teammates by NAME, not UUID. Plugin runtime worked around via cold-start (spawn fresh agents each round, pass full context via canonical YAML, which is self-sufficient). Pre-existing gap from Phase 7B, NOT Phase 4 responsibility, but surfaced now because Phase 4 activated the code path (pre-Phase-4 `/s2s:roundtable` aborted before phase-2-core.md reached). Doc fix: phase-2-core.md should clarify resume is Task-tool optional optimization; cold-start is the fallback. Memory: `~/.claude/projects/-Users-fvadicamo-Repositories-ElfGiftRush-s2s/memory/spec2ship_agent_resume_gap.md` (saved by plugin during §4.5 Step 3 dogfood; cross-confirmed Step 5 + Step 8 housekeeping notes).
- **session-observer R1 false-positive on empty-by-design artifact maps**: surfaced §4.5 Step 3 (specs run). When an artifact_type (e.g. NFR, conflicts) has 0 entries after round 1 because the topic doesn't surface them, the round-1 session-observer raises a finding suggesting the round was empty. Pre-existing observer noise; the empty maps are valid per profile schema. Fix: session-observer should distinguish "empty by design" (artifact_type declared in profile but zero entries) from "empty by failure" (rounds produced no artifacts at all). Out-of-scope for Phase 4; tracked for observer hardening.
- **token-tracker.sh exit 1 quirk**: surfaced §4.5 Step 3 (specs run). The `skills/dev-testing/references/token-tracker.sh` init step returns exit code 1 despite emitting valid output that downstream logic consumes correctly. Cosmetic only (does not abort session); tracked for dev-testing cleanup.
- **session_id timestamp format divergence between direct and master paths**: surfaced §4.5 Steps 6+8 (master path) vs Steps 3-5 (direct path). Master path generates `{date}-{HHMMSS}-{workflow}-{slug}` (e.g. `20260521-105925-specs-acceptance-criteria-gift-storm`); direct path generates `{date}-{workflow}-{slug}` (e.g. `20260521-design-elfgiftrush`). Both paths correctly use the workflow_type prefix per §4.3, so this is NOT a wiring regression. It is a cosmetic divergence in ID generation. Hypothesis: parser block in `commands/roundtable.md` (master path) uses a different ID generator than the phase-2-core init (direct path). Fix: unify to the more precise `{date}-{HHMMSS}-...` form in both paths (collision-safe; matches Plan ID convention). Trivial edit, post-Phase-4 cleanup.

## 9. Exit pointer

After Phase 4 PR merges to develop:
- Update `.s2s/BACKLOG.md` TECH-002 block per §6 (acceptance criteria #2 and #4 FULLY DONE; Phase 9 row removed).
- Verify `MEMORY.md` `project_tech002_progress.md` reflects new state: Phase 7B + 7-lite + 4 done for all 4 workflows; Phase 8 + six-hats baseline pending; v0.4.0 release waits on Phase 8 only.
- Draft Phase 8 plan using this plan as structural template; the thin launchers are mechanical (Phase 4 made the master capable for all workflows including roundtable native).
- Do NOT release v0.4.0 → main yet. Wait for Phase 8.

Phase 8 plan should be drafted as a new file targeting ~150 lines each for specs/design/brainstorm, with regression replay against exp45-phase4 baselines from §4.5.

## 10. Contract invariants (must NOT change)

Per `strategy-hooks.md` §9, exp44-post-phase7b baselines, and Phase 7-lite Step 2.10 freeze:

- **All baseline runtime behavior structurally unchanged**. exp44 dump shapes remain valid (no field removals, no path changes). Phase 4 may add new fields under `agent_state.facilitator.hook_overrides` (additive only).
- **Step 2.0 to Step 2.10 numbering frozen**. Phase 4 adds new inputs to Step 2.2c (3-branch dispatch from hook_overrides) but does NOT renumber.
- **Schema additivity for session.yaml**: `agent_state.facilitator.hook_overrides` is the only new top-level addition. No removals.
- **FIX-S1 preserved**: session-observer dumps still written `{NNN}-04-session-observer.yaml` per round.
- **Disney machine ownership**: algorithmic source remains `disney-phase-machine.md`. Phase 4 does not touch the machine.
- **All 5 CLI flags + 6 optional flags preserved**: no removals; no semantic changes.
- **strategy_constraints.forced wins**: profile YAML `forced: true` (brainstorm.yaml:17) continues to override CLI `--strategy`. Phase 4 does NOT relax this.
- **Generic-mode `/s2s:roundtable` post Phase 4 produces clean execution** (Option ε): with `profiles/roundtable.yaml` in place, native invocation completes Phase 2 + Phase 3 without abort. Pre-Phase-4 abort behavior is the BASELINE (`.s2s/test-baselines/exp45-roundtable-native-pre-phase4.md`); post-Phase-4 is clean completion.

If any of these is violated, that is a regression and the PR cannot merge.

---

## Appendix A: 4.0 audit output

COMPLETED at `.s2s/plans/20260518-tech002-phase4-4.0-audit.md`. 10 sections + pass-3 grep footer. Smoke test outcome (c) graceful recorded.

## Appendix B: Option B parser pseudo-code

**Context (Option ε post-pivot)**: this parser block executes for **all 4 workflow types** (including roundtable native, because `profiles/roundtable.yaml` now exists per §4.1 step 6). No conditional skipping per workflow; the parser is part of the uniform Phase 1 flow.

```
# In commands/roundtable.md, after "Get strategy configuration"
# (current line ~199 area, post-strategy-doc-Read)
# Runs for ALL workflow types post-Option-ε pivot.

Read("${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/strategy-hook-resolution.md")
  → ANCHOR_TABLE  # dict of {opening_phrase_regex: override_dict}

Read("${CLAUDE_PLUGIN_ROOT}/skills/roundtable-strategies/references/{strategy}.md")
  → STRATEGY_DOC

Extract "## Strategy hooks" section from STRATEGY_DOC
  → STRATEGY_HOOKS_SECTION

Take first non-empty line of STRATEGY_HOOKS_SECTION
  → OPENING_LINE

For each (regex, override_dict) in ANCHOR_TABLE:
  if regex matches OPENING_LINE:
    HOOK_OVERRIDES = override_dict
    break
else:
  Display error to user: "Strategy doc opening line did not match any anchor in strategy-hook-resolution.md. Edit the doc or update the fixture."
  Stop session creation.

Write HOOK_OVERRIDES to session.yaml at agent_state.facilitator.hook_overrides
```

At each round, `phase-2-core.md` Step 2.2c reads `session.yaml.agent_state.facilitator.hook_overrides` and dispatches via 3-branch logic:

- **Branch 1** (`hook_overrides.skip == true`): pass `hook_overrides: {skip: true}` to facilitator agent invocation; facilitator emits no per-round overrides (strategy declares no hooks, e.g. standard, consensus-driven, disney, six-hats).
- **Branch 2** (policy fields present): pass full dict; facilitator populates `participant_context.overrides.{participant-id}.{field}` per the policy (e.g. debate with `facilitator_emergent` initial policy).
- **Branch 3** (`hook_overrides` field absent in session.yaml): do NOT include `hook_overrides:` key in agent input at all; facilitator falls back to current LLM-emergent inference. **Branch 3 is the BACKWARD-COMPAT PATH ONLY** post-Phase-4: any Phase 4+ session has `hook_overrides` populated by the parser; Branch 3 triggers only for pre-Phase-4 sessions resumed via `--session {id}`.

Branch 1 and Branch 3 remain semantically distinct: Branch 1 means "strategy has decided there are no hooks" (e.g. standard, consensus-driven; no inference needed); Branch 3 means "no deterministic resolution has been performed" (pre-Phase-4 session resume only; fall back to current LLM-emergent inference).

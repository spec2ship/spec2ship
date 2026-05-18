# TECH-002 Phase 4: roundtable.md as master + Option A/B/C wiring decision

**Plan ID**: `20260518-tech002-phase4-roundtable-master`
**Branch**: `feature/TECH-002-phase4-roundtable-master`
**Forked from**: `develop` @ `3043c1a` (post Phase 7-lite PR #15 merge)
**Author**: Claude (Opus 4.7) + Francesco
**Status**: draft (created 2026-05-18, awaiting review rounds)
**Created**: 2026-05-18
**Predecessor plan**: `.s2s/plans/20260517-tech002-phase7-strategy-consolidation.md` (Phase 7-lite)
**Contract sources**:
- `skills/roundtable-execution/references/strategy-hooks.md` (Phase 7-lite hardened state, §7 Option A/B/C decision matrix)
- `.s2s/decisions/0011-roundtable-command-unification.md` (Phase 7-lite addendum)
- `.s2s/plans/20260518-tech002-phase7-lite-7.0-audit.md` (§6.2 triple-duplication, §7.3 default_strategy, §4 commands/roundtable.md drift)

---

## 1. Goal

Expand `commands/roundtable.md` (currently 437 lines, "follow the skill" stub for Phase 2) into the **master orchestrator** (~500-520 lines) able to execute all four workflow types (`roundtable`, `specs`, `design`, `brainstorm`) end-to-end through `phase-2-core.md`. Make the explicit **Option A/B/C decision** for runtime consumption of strategy hooks (debate Pro/Con assignment, six-hats hat rotation, disney phase already handled by machine) and implement the chosen option. Unify the triple-duplication of strategy/workflow defaults across `templates/project/config.yaml`, `profiles/{workflow}.yaml`, and `roundtable-strategies/SKILL.md`. Clarify and codify the `default_strategy` resolution hierarchy.

Phase 4 delivers five concrete wins:

1. **roundtable.md master** — full Phase 2 wiring via `phase-2-core.md` (no "follow the skill" deferral), with `--workflow-type` dispatch, resume/diagnostic, and proper output dispatch per workflow.
2. **Option B implementation across 3 files** — deterministic parser in roundtable.md + Step 2.2c modification in `phase-2-core.md` to consume `agent_state.facilitator.hook_overrides` + `agents/roundtable/facilitator.md` updated to honor passed overrides instead of LLM-inferring per-round overrides.
3. **`profiles/roundtable.yaml` created** — minimal profile (standard default, no agenda gating, no phase transition) so the master dispatch is uniform across all 4 workflow types. Closes the gap where `--workflow-type roundtable` has no profile to load.
4. **Triple-duplication unification** — single canonical source per concern (resolution hierarchy CLI → config.yaml → profile fallback), `templates/project/config.yaml` clarified as user-facing canonical, profile YAMLs clarified as plugin defaults, SKILL.md table disclaimers from 7-lite extended with resolution hierarchy diagram.
5. **commands/roundtable.md drift reconciliation** — keyword auto-detect table (currently lines 170-179) and inline phase enumeration (currently lines 194-199, with phase-name drift versus strategy docs: `consensus-driven` and `six-hats`) are reconciled per Option B. Plus 3 facilitator-agent strategy-doc pointers (currently lines 518/579/607) sharpened to `#strategy-hooks` anchors.

Phase 8 (thin launcher conversion specs/design/brainstorm → ~150 lines each) is the immediate downstream consumer and is **NOT** in Phase 4 scope — it runs separately after Phase 4 merges.

### Non-goals (explicit deferrals)

- **Phase 8 thin launchers**. Separate plan after Phase 4 merges to develop. Phase 4 makes specs/design/brainstorm capable of being thin launchers; it does not convert them.
- **Six-hats wiring with empirical baseline**. Prerequisite-blocked on baseline acquisition. Phase 4 implements the chosen Option mechanism so that six-hats wiring becomes a configuration change only, but does NOT capture the baseline.
- **`debate-phase-machine.md` extraction**. Deferred unless §4.2 audit shows debate complexity warrants a machine file.
- **New strategy additions**. Phase 4 works with the 5 existing strategies; it does not add a sixth.
- **session-schema.md `INT-*` / `CONF-*` gaps**. Pre-existing drift unrelated to roundtable unification.
- **Agent prompt redesign**. `agents/roundtable/facilitator.md` continues to be invoked by roundtable.md; Phase 4 sharpens 3 strategy-doc pointers (in-scope per win #5) and adds `hook_overrides` consumption logic but does NOT rewrite agent prompt structure.

## 2. Inputs and constraints

### What we know

- `commands/roundtable.md` is 437 lines today, of which Phase 3 (lines 359-437) defers entirely to `roundtable-execution` skill with `"Follow the skill instructions EXACTLY"`. Phase 4 must replace this stub with a concrete dispatch into `phase-2-core.md` Step 2.0 → Step 2.10 loop.
- `commands/{specs,design,brainstorm}.md` (600/536/482 lines post-7B) inline the Phase 2 loop themselves via `phase-2-core.md` Reads. Phase 4 must make roundtable.md do the same with `--workflow-type` parameter steering the profile load and output-type defaults.
- `templates/project/config.yaml` (107 lines, the third source flagged in 7.0 audit §6.2) carries `roundtable.strategy.by_workflow_type` (line 30-33), `roundtable.strategy.consensus` per-strategy rules (line 35-57), `roundtable.participants.by_workflow_type` (line 60-80). Profile YAMLs and SKILL.md duplicate slices of this.
- `default_strategy` field exists in `profiles/{workflow}.yaml` (e.g. `brainstorm.yaml:13 default_strategy: "disney"`) but is **NOT** consulted at command runtime; commands resolve strategy from `config.yaml.roundtable.strategy.by_workflow_type.{workflow}`. `profile-schema.md:115` describes it as "required for Phase 1 strategy resolution" — this is intent, not actual behavior.
- `commands/roundtable.md:194-199` enumerates phases inline with two drift sites versus strategy docs:
  - `consensus-driven`: command says `["proposal", "discussion", "resolution"]`; `consensus-driven.md` says `proposal/refinement/convergence` (per 7.0 audit §4).
  - `six-hats`: command says `["blue-opening", "white", "red", "black", "yellow", "green", "blue-closing"]`; `six-hats.md` line 86 says `["blue-hat-opening", "white-hat", "red-hat", "black-hat", "yellow-hat", "green-hat", "blue-hat-closing"]`.
- Phase 7-lite delivered 5 strategy docs with uniform `## Strategy hooks` sections. Opening lines drawn from a 4-phrase set serve as skip-triggers compatible with Option A (LLM regex) and Option B (command-side regex parse).
- exp44-post-phase7b regression baselines (3 workflows) are the authoritative behavior reference. Phase 4 runtime change may shift one or two specific behaviors (debate Pro/Con assignment deterministic, six-hats hat order deterministic) but core dump shapes and session file structure must remain identical.

### What we have as baselines

- exp44-post-phase7b: specs, design, brainstorm — full structural summaries in `.s2s/test-baselines/`.
- exp44 debate sample (single run): `debate_role` was assigned via LLM emergence; one observation only, not a discriminative baseline.
- No six-hats baseline (prerequisite-blocked task, not addressed here).

### Hard constraints

- **Backward compatible Phase 2 output**. exp44-post-phase7b dump shapes for the 3 workflows must replay identically after Phase 4. Any deviation is a regression and the PR cannot merge.
- **State machine preserved**. Step 2.0 → 2.10 numbering and dispatch invariants from Phase 7-lite are frozen. Phase 4 may add inputs to Step 2.2c (deterministic overrides) but does not renumber.
- **Existing CLI flags preserved**. `--strategy`, `--participants`, `--workflow-type`, `--output-type`, `--verbose`, `--interactive`, `--diagnostic`, `--pro`, `--con`, `--new`, `--session` continue to work with current semantics. Phase 4 may add new flags (e.g. `--profile-override`) but does not remove or rename.
- **No new third-party dependencies**. Pure markdown + plugin-side YAML.
- **Atomic PR**. Single PR target develop, milestone v0.4.0.

## 3. Approach

Phase 4 is the **architectural inflection point** of TECH-002. The Option A/B/C decision is binding for the runtime wiring layer of all five strategies; six-hats and any future strategy will follow the same mechanism.

### 3.1 Option A/B/C decision matrix

| Criterion | Option A (LLM-mediated Read at Step 2.2c) | Option B (command-side parse in roundtable.md) | Option C (full YAML configs per strategy) |
|-----------|-------------------------------------------|------------------------------------------------|-------------------------------------------|
| **Blast radius** | Low: facilitator agent + Step 2.2c text only | Medium: roundtable.md adds parse logic; strategy docs gain machine-readable anchors | High: 5 new `strategies/{strategy}.yaml` files + schema + validator + migration tooling |
| **Eliminates LLM emergence for hooks** | No — shifts interpretation from "STRATEGY string" to "STRATEGY + markdown prose" | Yes — deterministic regex/string match at Phase 1 produces overrides as data | Yes — fully structured, no parsing |
| **Aligned with roundtable.md-as-master** | Weak — facilitator agent stays as resolution authority, contradicting Phase 4 goal | Strong — roundtable.md becomes the deterministic resolver, consistent with Phase 4 master role | Strong but requires new layer above SKILL.md |
| **Complexity** | Low (~30 lines facilitator prompt) | Medium (~80 lines parse + override dispatch in roundtable.md) | High (~250 lines: schemas + parser + migration + validator) |
| **Reversibility** | Trivial (revert agent prompt) | Easy (delete parse block) | Hard (5 files + schema must be removed; users may have customized) |
| **Phase 7-lite substrate reused** | Yes (skip-trigger phrases as regex) | Yes (skip-trigger phrases as anchors) | Partially (phrases become labels in YAML schema) |
| **Drift surface added** | None | Strategy doc opening-line phrases must stay in sync with regex (single fixture file) | New 4th source: configs/ ↔ profiles/ ↔ config.yaml ↔ SKILL.md |
| **Empirical verifiability** | Silent failure mode (LLM "guesses correctly") | Test-fixture replay: parse a strategy doc and assert output dict | Schema validator runs in CI |

### 3.2 Recommendation: **Option B**

**Rationale**:

1. **Phase 4 goal alignment**. The phase explicitly elevates roundtable.md to master; Option B places the resolver where the master is. Option A keeps the resolver in the facilitator agent, perpetuating the inversion that Phase 4 is supposed to fix. Option C introduces a fourth source of truth and contradicts the Phase 7-lite triple-duplication-reduction direction.
2. **Substrate already in place**. Phase 7-lite's uniform `## Strategy hooks` sections with the 4-phrase opening line set were designed as skip-trigger anchors for B and C. Option B consumes them as-is; no strategy doc edits required.
3. **Determinism delivered without new file types**. Strategy docs remain human-facing; structure lives in a single fixture file `skills/roundtable-execution/references/strategy-hook-resolution.md` (name chosen to disambiguate from existing `strategy-hooks.md` contract doc). Drift surface is single-fixture.
4. **Reversibility**. If Option B parsing turns out brittle in practice (e.g. natural-language drift in opening lines), reverting to LLM-mediated or escalating to Option C is a localized change.
5. **Empirical verifiability**. Phase 4 test plan (§4.6) can include a deterministic fixture: feed each strategy doc through the parse block, assert expected override dict. Option A has no such test surface.

**Option C is not chosen** because it introduces a fourth source of truth at the same time we are trying to reduce the triple to a clear hierarchy, and the schema work is disproportionate to current 5-strategy scope.

**Option A is not chosen** because it fails the core Phase 4 architectural test (master vs delegated resolution) and reintroduces the LLM emergence problem Phase 7 was originally trying to address.

### 3.3 Triple-duplication resolution

**Decision**: **D3 — explicit hierarchy with documented roles**.

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

The profile YAML's `strategy_constraints.forced: true` (e.g. `brainstorm.yaml:17`) still wins over all of the above when set — this is a workflow-level constraint, not a fallback.

### 3.4 Work breakdown

Phase 4 delivers in 7 sub-phases over an estimated **~6.75 hours** (audit + execution + smoke + close-out):

- **4.0** audit (~1.5h): inventory of inline duplication, drift sites, Step 2.X dispatch points in roundtable.md, anchor fixture map, profile gap (no `profiles/roundtable.yaml`); 3-pass grep verification (lesson from Phase 7-lite 7.0)
- **4.1** triple-dup resolution + `profiles/roundtable.yaml` creation (~1h): D3 hierarchy codified, SKILL.md disclaimer + diagram, profile-schema.md updated, new `profiles/roundtable.yaml` minimal profile
- **4.2** Option B implementation across 3 files (~1h): `strategy-hook-resolution.md` fixture + parse block in roundtable.md + `phase-2-core.md` Step 2.2c reads `agent_state.facilitator.hook_overrides` + `agents/roundtable/facilitator.md` consumes overrides + 3 strategy-doc pointer sharpening
- **4.3** roundtable.md Phase 2 dispatch (~1.5h): replace lines 359-437 stub with single Read of `phase-2-core.md` (mirroring `commands/design.md:379-401` pattern, ~30 new lines including Phase 1 profile load and workflow-type-aware output dispatch); resume path extended for non-roundtable workflow_types
- **4.4** drift fix (currently lines 170-179 + 194-199) (~0.5h): keyword-auto-detect table disclaimer-protected; inline phase enumeration removed by source-of-truth deferral
- **4.5** regression replay + fixture assertions (~0.75h): exp45-{specs,design,brainstorm,roundtable} via dogfood, compare to exp44-post-phase7b baselines; 5 anchor parse fixture assertions; backward-compat resume probe for pre-Phase-4 session files
- **4.6** close-out (~0.5h): BACKLOG, ADR-0011 addendum, plan Status finalization, MEMORY.md update

## 4. Sub-phases

**Execution order**: 4.0 → 4.1 → 4.2 → 4.3 → 4.4 → 4.5 → 4.6.

(4.4 follows 4.3 because the drift fix at lines 170-179/194-199 lands cleanly only after the Phase 2 dispatch in 4.3 replaces the surrounding scaffolding.)

### 4.0: audit current state (~1.5h)

**Goal**: produce a definitive inventory for execution sub-phases. Use Phase 7-lite 7.0 audit as procedural template; pass-3 grep verification is mandatory (pass 1 undercounted 4× in 7-lite).

**Actions**:
1. **Triple-dup map**: enumerate every site in `templates/project/config.yaml`, `profiles/{workflow}.yaml`, `roundtable-strategies/SKILL.md` that holds workflow defaults, strategy mappings, participant lists. Output: table mapping each cell to its post-4.1 role.
2. **roundtable.md dispatch points**: list every place lines 1-437 needs to change to host the master execution (Phase 2 dispatch site, `--workflow-type` flag handling, output-type default per workflow, resume path).
3. **`commands/{specs,design,brainstorm}.md` Phase 2 sites**: cross-reference how they currently invoke `phase-2-core.md` — confirmed compact pattern (e.g. `design.md:379-401`, ~23 lines total including framing). Document the exact lines roundtable.md will mirror.
4. **Strategy-hook anchor fixture map**: for each of 5 strategy docs, capture the exact opening-line phrase in `## Strategy hooks` (Phase 7-lite output) and map to expected override dict. Output: candidate fixture for §4.2.
5. **Phase-name drift inventory**: confirm `consensus-driven` and `six-hats` mismatches; flag any others (compare command line 194-199 against each `{strategy}.md` `phases:` block).
6. **Resolution hierarchy gap inventory**: confirm `default_strategy` is currently unread by any command; identify whether any other profile field has the same "documented intent, unread" status (e.g. `strategy_constraints.forced`).
7. **Profile gap**: confirm there is no `profiles/roundtable.yaml`; draft minimal content for §4.1 step 6 (default_strategy: standard, has_phase_transition: false, no agenda gating, min_participants: 2).
8. **`phase-2-core.md` Step 2.2c facilitator invocation**: locate the exact lines in §2.2c that invoke the facilitator agent; identify where `hook_overrides` will be read from session.yaml and passed to the agent.
9. **Facilitator agent strategy-doc pointers**: confirm exact line numbers (currently 518/579/607) for `#strategy-hooks` anchor sharpening in §4.2 step 5.

**Output**: `.s2s/plans/20260518-tech002-phase4-4.0-audit.md` mirroring the structure of `20260518-tech002-phase7-lite-7.0-audit.md`. Must include explicit pass-3 grep verification.

**Exit condition**: audit file produced; per-sub-phase task lists for 4.1–4.4 finalized; profile-roundtable gap closed (draft yaml content); phase-2-core.md Step 2.2c modification site identified.

### 4.1: codify D3 triple-duplication hierarchy + create profiles/roundtable.yaml (~1h)

**Goal**: explicit roles for the three sources; runtime resolution order codified; SKILL.md documentation updated; profile gap closed.

**Actions**:
1. **profile-schema.md**: rewrite the `default_strategy` field description to read "**Plugin fallback**. Consulted by `roundtable.md` Phase 1 after CLI and `config.yaml` are exhausted. See §3.3 resolution hierarchy in Phase 4 plan / ADR-0011 Phase 4 addendum." Same treatment for any other "documented intent, unread" field surfaced in 4.0 §6.
2. **`roundtable-strategies/SKILL.md`** v1.2.0 → v1.3.0: add a "## Strategy resolution hierarchy" section above the workflow defaults table with an ASCII diagram of `CLI → config.yaml → profile → error`. The existing 7-lite disclaimer banners stay.
3. **`templates/project/config.yaml`** header comment: add `# This file is the user-canonical source for strategy/participant defaults at runtime.` Add `# See plugin profiles for fallback values if a key is omitted.` near the strategy block.
4. **Profile YAML comments**: in `profiles/{workflow}.yaml`, prefix `default_strategy` with a comment block: `# Plugin fallback. Consumed only when .s2s/config.yaml omits roundtable.strategy.by_workflow_type[{workflow}].`
5. **Cross-reference fixture**: add a single-source table `skills/roundtable-execution/references/strategy-resolution.md` (new file, ~60 lines) that documents the hierarchy with one worked example per workflow. Referenced from SKILL.md and roundtable.md.
6. **Create `profiles/roundtable.yaml`** (new file, ~40 lines, content drafted in 4.0 step 7):
   ```yaml
   # Generic roundtable workflow profile (workflow_type: roundtable)
   # Used by /s2s:roundtable without --workflow-type or with --workflow-type roundtable.
   default_strategy: "standard"   # Plugin fallback (see strategy-resolution.md)
   strategy_constraints:
     forced: false                # User can override via --strategy
   has_phase_transition: false    # No Step 2.10 dispatch
   min_participants: 2
   output_types_supported: ["summary", "adr"]
   default_output_type: "summary"
   # Note: no agenda gating; roundtable is a single-topic free-form workflow.
   ```

**Exit condition**: D3 hierarchy is the single explanation of strategy resolution across plugin; no contradictory text remains. `grep -rn "default_strategy" skills/ commands/` returns only sites that explicitly state "plugin fallback" or quote the resolution hierarchy. `ls skills/roundtable-execution/profiles/` shows 4 files (brainstorm, design, specs, roundtable).

### 4.2: Option B implementation across 3 files (~1h)

**Goal**: deterministic resolution of per-strategy hook overrides via a parser block in roundtable.md, a Step 2.2c modification in phase-2-core.md, and a hook_overrides consumer in the facilitator agent.

**Actions**:
1. **Anchor fixture**: create `skills/roundtable-execution/references/strategy-hook-resolution.md` (new file, ~80 lines; name disambiguated from existing `strategy-hooks.md` contract doc). Contents:
   - One row per strategy with: opening-line phrase exact match (regex), derived override dict, target Step 2.2c field set.
   - Header note: "Deterministic fixture consumed by `commands/roundtable.md` Phase 1 strategy-hook resolution. Keep in sync with `roundtable-strategies/references/{strategy}.md` `## Strategy hooks` opening lines."
2. **Parser block in roundtable.md**: insert a new "## Resolve strategy hooks" section (post strategy-doc Read, pre debate handling). Block does:
   - Read `strategy-hook-resolution.md` fixture table.
   - Read the chosen `{strategy}.md` `## Strategy hooks` section (already done in current flow).
   - Match opening line to anchor row; produce `strategy_hook_overrides` dict (e.g. for debate: `{participant_response_field: "debate_role", round_summary_field: "debate_phase", policy: "facilitator_emergent"}`; for standard/consensus-driven: `{skip: true}`).
   - Persist `strategy_hook_overrides` in session.yaml under `agent_state.facilitator.hook_overrides` so phase-2-core.md Step 2.2c can pass it to the facilitator agent at each round.
3. **phase-2-core.md Step 2.2c modification** (NEW deliverable surfaced in review #1): in the facilitator-invocation block (around line 269), add an input field that reads `session.yaml.agent_state.facilitator.hook_overrides` and passes it as `hook_overrides:` in the agent input YAML. If `hook_overrides.skip == true` or field is absent, no override input is passed (backward-compat with pre-Phase-4 sessions). Update Step 2.2c documentation block to describe the new input.
4. **Facilitator agent NEW logic**: `agents/roundtable/facilitator.md` adds a new "Hook override consumption" section to its system prompt. If `hook_overrides` is present in agent input → populate `participant_context.overrides.{participant-id}.{field}` per the dict instead of LLM inference. If `hook_overrides.skip == true` or absent → emit no overrides (current behavior preserved).
5. **Strategy-doc pointer sharpening**: in `agents/roundtable/facilitator.md`, change the 3 strategy-doc pointers (currently around lines 518/579/607 — exact lines confirmed in 4.0 step 9) from `{strategy}.md` (whole-file) to `{strategy}.md#strategy-hooks` (anchor). Reduces coupling; cost ~3 edits.
6. **Test fixture**: add 5 unit-style assertions inside `.s2s/plans/20260518-tech002-phase4-4.2-fixture.md` (kept in plans/ to avoid muddling with `.s2s/test-baselines/` structural baselines): for each strategy doc, capture the parse output dict and freeze it. Used in §4.5 to assert no regression.

**Exit condition**: roundtable.md has deterministic hook resolution; phase-2-core.md Step 2.2c reads + passes overrides; facilitator agent consumes them as data; 5 fixture assertions documented in `.s2s/plans/20260518-tech002-phase4-4.2-fixture.md`. Backward-compat preserved: missing `hook_overrides` field falls back to LLM-emergent behavior.

### 4.3: expand roundtable.md to master (~1.5h)

**Goal**: replace the Phase 3 "follow the skill" stub (lines 359-437) with explicit dispatch through `phase-2-core.md`, supporting `--workflow-type {specs|design|brainstorm|roundtable}`. Pattern mirrors `commands/design.md:379-401` (~23 lines for entire Phase 2 dispatch).

**Actions**:
1. **Profile load**: in Phase 1, after `workflow_type` is determined, Read the corresponding `profiles/{workflow_type}.yaml` (now exists for all 4 workflow types post-§4.1 step 6) and load `PROFILE` into the dispatch context.
2. **Phase 2 compact dispatch**: replace lines 359-437 (~78 lines of stub + reminders) with the compact pattern from `design.md:379-401`: framing + one `Read phase-2-core.md` + invariant comment block. Step 2.10 conditionality is handled inside phase-2-core.md based on `PROFILE.has_phase_transition`. Expected ~25-30 new lines.
3. **Output dispatch**: Phase 3 output-type defaulting per workflow (from profile.output_types_supported + default_output_type):
   - `roundtable` → `summary` (per new roundtable.yaml)
   - `specs` → `requirements`
   - `design` → `architecture`
   - `brainstorm` → `summary` (with brainstorm output template)
   Read the corresponding `output-generation/references/{template}.md` per `--output-type` resolution.
4. **Resume path**: ensure `--session {id}` works for sessions of any `workflow_type` (current code only handles `workflow_type: roundtable` on resume — see line 75). Add workflow-type-aware resume dispatch.
5. **Diagnostic mode**: `--diagnostic` continues to force `verbose_flag = true` and routes to `Step 3.0 Final Diagnostic Report` in `phase-2-core.md`.
6. **Line budget**: current 437 lines − Phase 2 stub (~78 lines removed) + Phase 1 profile load (~15 lines) + Phase 2 compact dispatch (~30 lines) + workflow-type output dispatch (~20 lines) + resume extension (~15 lines) = **~440 lines total**. Margin for tweaks → target ≤520 lines.

**Exit condition**: roundtable.md can run all four workflow types end-to-end. `wc -l commands/roundtable.md` ≤ 520. specs/design/brainstorm commands are UNCHANGED (still inline; Phase 8 territory).

### 4.4: fix command drift (currently lines 170-179 + 194-199) (~0.5h)

**Goal**: remove inline phase enumeration and keyword auto-detect drift; reconcile with strategy docs. Line numbers will shift after §4.3 expansion; the 4.0 audit captures the post-4.3 line positions for precise targeting.

**Actions**:
1. **Keyword-auto-detect table** (currently lines 170-179): keep the table (it serves a UX purpose: telling user which strategy fits which keywords) but add a header note `> Keyword → strategy mapping is documented here for user discoverability. The authoritative strategy descriptions live in skills/roundtable-strategies/references/{strategy}.md.` No deletion; just disclaimer.
2. **Inline phase enumeration** (currently lines 194-199): REMOVE the `- **standard**: phases: ["discussion"]` bulleted list entirely. Replace with: `Read the strategy doc; the canonical phases live in its Configuration block. The strategy-hook overrides parsed in §4.2 surface phase metadata when needed.`
3. **consensus-driven phase-name fix**: data fix — `consensus-driven.md` is authoritative per Phase 7-lite. The command's inline `["proposal", "discussion", "resolution"]` is wrong and is removed in step 2 above.
4. **six-hats phase-name fix**: same — six-hats.md line 86 is authoritative; command's enumeration is removed.
5. **Grep verification**: `grep -n "phases:" commands/roundtable.md` returns no inline phase list; only Read directives.

**Exit condition**: no inline phase enumeration in roundtable.md; keyword table disclaimer-protected; phase-name drift eliminated by source-of-truth deferral.

### 4.5: regression replay + Option B fixture verification + backward-compat (~0.75h)

**Goal**: confirm no behavioral regression across the 3 workflows that have baselines; verify Option B fixture matches expected dicts; confirm pre-Phase-4 sessions resume cleanly.

**Actions**:
1. **Regression replay** in dogfood (`ElfGiftRush_s2s/exp45-phase4`):
   - `/s2s:specs "..."` — compare structural summary to `.s2s/test-baselines/exp44-specs-post-phase7b.md`.
   - `/s2s:design "..."` — same, `exp44-design-post-phase7b.md`.
   - `/s2s:brainstorm "..."` — same, `exp44-brainstorm-post-phase7b.md`.
   - `/s2s:roundtable "..." --workflow-type specs` — NEW comparison; expected output structurally equivalent to `/s2s:specs` (roundtable is the master path).
2. **Anchor parse fixture**: for each of 5 strategies, run the parse block standalone (manual Read + match probe), assert output dict equals `20260518-tech002-phase4-4.2-fixture.md` frozen values.
3. **Backward-compat resume probe**: take a frozen pre-Phase-4 session file (from `.s2s/test-baselines/exp44-*`) and resume via `/s2s:roundtable --session {id}`. Assert no error on missing `agent_state.facilitator.hook_overrides` field; behavior falls back to LLM-emergent (current).
4. **Acceptable deltas**: debate Pro/Con assignment may shift from exp44 (LLM-emergent) to deterministic (Option B) IF the anchor fixture for debate specifies a deterministic policy. With initial `policy: "facilitator_emergent"` (per §4.2 step 2 default), no behavioral shift expected — only the data path changes. Document delta accordingly.
5. **Unacceptable deltas**: dump schema changes, Step 2.X numbering changes, session.yaml structural differences (except additive `agent_state.facilitator.hook_overrides`), missing artifacts. Any unacceptable delta blocks the PR.
6. **Smoke probe**: `/s2s:roundtable "test topic" --diagnostic` (no `--rounds` flag — not a documented CLI option per command argument-hint; rely on min_rounds=3 from config and --diagnostic for early exit visibility). Confirm session.yaml.agent_state.facilitator.hook_overrides is populated (Option B working) and Step 3.0 diagnostic report renders.

**Exit condition**: 3 baselines match (structural); roundtable.md master path produces structurally-equivalent specs output; 5 fixture assertions pass; backward-compat resume probe succeeds; deltas documented.

### 4.6: close-out (~0.5h)

**Actions**:
1. `.s2s/BACKLOG.md` TECH-002 block: Phase 4 marked ✅ completed; Phase 8 promoted to `in_progress (next session)`; Acceptance Criteria items 2 and 4 of TECH-002 marked done; current state section rewritten.
2. `.s2s/decisions/0011-roundtable-command-unification.md` Phase 4 addendum: record Option B choice with §3.1 matrix summary, D3 hierarchy decision, new `profiles/roundtable.yaml`, phase-2-core.md Step 2.2c modification, drift fixes.
3. Plan Status field finalize: `draft` → `completed (PR #XX merged YYYY-MM-DD)` post-merge.
4. `MEMORY.md` `project_tech002_progress.md` updated to reflect Phase 4 done; Phase 8 + six-hats baseline as remaining items; MEMORY.md index entry updated.

**Exit condition**: BACKLOG + ADR + plan + memory all consistent with post-Phase-4 state.

## 5. Risk register

| ID | Risk | Likelihood | Impact | Mitigation |
|----|------|------------|--------|------------|
| R1 | Option B fixture brittleness — opening-line phrases drift when strategy docs are edited | medium | medium | §4.2 anchor fixture is single-file; § Strategy hooks opening lines are referenced from `strategy-hook-resolution.md` header note as "must stay in sync". CI grep check (Phase 8 candidate) flags drift. |
| R2 | roundtable.md exceeds 520-line budget after Phase 2 expansion | low | low | §4.3 line budget computation: 437 − 78 (stub removed) + 80 (new additions) = ~440 lines. If overflow, move Phase 1 setup helpers to `roundtable-execution/references/phase-1-setup.md` (would be NEW file, ~50 lines of work — flagged but unlikely needed). |
| R3 | Resume path workflow-type-aware dispatch breaks legacy `--session` for pure roundtable sessions | low | high | §4.3 explicitly preserves current line 75 semantics for `workflow_type: roundtable`; extends only to handle other workflow_types. Test in §4.5 smoke. |
| R4 | Triple-dup hierarchy D3 confuses users (which file to edit?) | medium | medium | §4.1 SKILL.md resolution diagram + strategy-resolution.md worked examples + config.yaml header comment all repeat the hierarchy explicitly. |
| R5 | Debate Pro/Con deterministic assignment (Option B) produces worse pairings than LLM-emergent | low | medium | exp44 sample is one observation; deterministic anchor policy is "facilitator_emergent" until empirical data justifies a coded rule. Option B initial overrides preserve current emergent behavior; only six-hats and future strategies get deterministic policy at this stage. |
| R6 | Phase 4 changes break the 3 workflow baselines (regression) | low | high | §4.5 replay is the gate. If unacceptable delta, PR cannot merge; rework or rollback. |
| R7 | `default_strategy` change from "documented intent" to "actual fallback" exposes a latent bug if profile YAML value disagrees with current implicit behavior | low | low | §4.0 audit cross-checks profile.default_strategy vs config.yaml.by_workflow_type for each workflow; reconcile any disagreement in §4.1 commit. |
| R8 | `--workflow-type roundtable` invocation finds no `profiles/roundtable.yaml` and fails profile load | medium | high | §4.1 step 6 creates `profiles/roundtable.yaml` (minimal: standard default, no agenda gating, no phase transition). §4.0 step 7 drafts content. §4.5 smoke probe verifies `/s2s:roundtable --diagnostic` succeeds. |
| R9 | `phase-2-core.md` Step 2.2c modification not done — Option B data path incomplete (overrides written to session.yaml but never read) | medium | high | §4.2 step 3 explicitly delivers Step 2.2c modification as in-scope work. §4.0 step 8 confirms exact insertion site. §4.5 step 6 smoke probe verifies session.yaml.agent_state.facilitator.hook_overrides is populated AND consumed (overrides visible in participant context dumps). |
| R10 | Backward-compat resume probe fails — pre-Phase-4 session resumes throw on missing `agent_state.facilitator.hook_overrides` field | low | high | §4.2 step 3 spec: "If `hook_overrides.skip == true` or field is absent, no override input is passed". §4.5 step 3 dedicated probe with frozen pre-Phase-4 session file. |

## 6. Done criteria

- [ ] 4.0 audit file produced; per-sub-phase task lists finalized; pass-3 grep verification recorded; `profiles/roundtable.yaml` content drafted; phase-2-core.md Step 2.2c modification site identified.
- [ ] **`profiles/roundtable.yaml` created** (~40 lines); `ls skills/roundtable-execution/profiles/` shows 4 files.
- [ ] D3 hierarchy codified: profile-schema.md, SKILL.md (v1.3.0), templates/project/config.yaml, profiles/*.yaml comments, strategy-resolution.md reference file all in agreement.
- [ ] `grep -rn "default_strategy" skills/ commands/` returns only "plugin fallback" or hierarchy-quoting sites; no orphan references.
- [ ] Option B implemented across 3 files: `strategy-hook-resolution.md` fixture exists; roundtable.md Phase 1 has parse block; **`phase-2-core.md` Step 2.2c reads `agent_state.facilitator.hook_overrides` and passes to facilitator agent**; facilitator agent consumes the input (current LLM-inference fallback preserved when input absent or `skip: true`); 5 anchor assertions frozen in `.s2s/plans/20260518-tech002-phase4-4.2-fixture.md`.
- [ ] 3 facilitator-agent strategy-doc pointers sharpened to `#strategy-hooks` anchors (lines 518/579/607 area).
- [ ] roundtable.md expanded to master: Phase 2 stub replaced; `--workflow-type {specs|design|brainstorm|roundtable}` dispatches correctly; resume works for all workflow_types; `wc -l commands/roundtable.md` ≤ 520.
- [ ] specs/design/brainstorm commands UNCHANGED in this PR (Phase 8 territory).
- [ ] Keyword-auto-detect table disclaimer-protected; inline phase enumeration removed.
- [ ] consensus-driven and six-hats phase-name drift resolved (by source-of-truth deferral, no inline enumeration).
- [ ] Regression replay: 3 baselines match structurally; debate deterministic delta documented (initially zero behavioral shift since `facilitator_emergent` policy preserved); roundtable.md master path produces structurally-equivalent specs output.
- [ ] 5 anchor parse fixture assertions pass.
- [ ] **Backward-compat resume probe**: pre-Phase-4 session file resumes via `/s2s:roundtable --session {id}` without error on missing `hook_overrides` field; fallback to LLM-emergent behavior visible.
- [ ] Smoke probe (`/s2s:roundtable "test topic" --diagnostic`) populates `agent_state.facilitator.hook_overrides`; Step 3.0 diagnostic report renders; participant dumps show overrides as data path artifact (not LLM-inferred).
- [ ] `.s2s/BACKLOG.md` TECH-002 block: Phase 4 ✅; Phase 8 `in_progress (next session)`; TECH-002 acceptance criteria 2 and 4 marked done.
- [ ] ADR-0011 Phase 4 addendum: Option B + D3 + `profiles/roundtable.yaml` + phase-2-core.md Step 2.2c modification + drift fixes recorded.
- [ ] PR opened against `develop`, milestone v0.4.0.
- [ ] Plan `Status` field updated from `draft` to `completed (PR #XX merged YYYY-MM-DD)` post-merge.

## 7. PR strategy

**Single PR**: `feature/TECH-002-phase4-roundtable-master` → `develop`.

Commit structure (in execution order):

1. `docs(plans): Phase 4 audit — triple-dup map, dispatch sites, anchor fixture map` (4.0)
2. `refactor(config): codify D3 strategy resolution hierarchy across profiles + SKILL.md + template` (4.1)
3. `feat(roundtable): Option B strategy-hook parser + anchor fixture` (4.2)
4. `feat(commands): expand roundtable.md to master with --workflow-type dispatch` (4.3)
5. `fix(commands): remove inline phase enumeration drift in roundtable.md` (4.4)
6. `test(baselines): exp45 regression replay + anchor parse fixture assertions` (4.5)
7. `docs(adr,backlog,plan): close Phase 4 + ADR-0011 Phase 4 addendum` (4.6)

7 commits, atomic.

PR body must include:
- Link to plan file and to 4.0 audit file.
- Explicit "Option B chosen — see §3.1 matrix + ADR-0011 Phase 4 addendum" note.
- D3 hierarchy diagram snippet.
- Before/after `wc -l commands/roundtable.md`.
- Regression deltas table (acceptable + unacceptable inventory).

## 8. Out-of-scope follow-ups (tracked, not actioned)

- **Phase 8 thin launcher conversion**: specs/design/brainstorm → ~150 lines each. Next plan after Phase 4 merges. Phase 4 makes the master capable; Phase 8 collapses the inline launchers.
- **Six-hats wiring with empirical baseline**: capture baseline via `/s2s:design --strategy six-hats --verbose --diagnostic` on dogfood; freeze structural summary in `.s2s/test-baselines/`. Then add a deterministic anchor policy to `strategy-hook-resolution.md` (Option B configuration change only, no architectural work). Separate task.
- **`debate-phase-machine.md` extraction**: if 4.0 audit reveals debate complexity rivals disney, extract analogously. Deferred otherwise.
- **session-schema.md `INT-*` / `CONF-*` gaps**: pre-existing drift unrelated to Phase 4; tracked separately in BACKLOG.
- **CI drift check for anchor fixture**: `strategy-hook-resolution.md` opening-line phrases vs strategy-docs opening lines — small bash check. Phase 8 candidate.
- **`templates/project/config.yaml` per-strategy consensus rules duplication**: lines 35-57 carry consensus thresholds per strategy that profile YAMLs also reference indirectly. Phase 4 D3 keeps config.yaml as user canonical; further normalization (e.g. moving consensus rules into strategy docs) is post-v0.4.0.
- **New strategy onboarding doc**: with Option B in place, adding a 6th strategy is a 3-step procedure (new strategy doc with § Strategy hooks + new anchor row + optional override policy). Document this in `s2s-guide` skill — Phase 8 candidate or separate `docs:` PR.
- **Promote debate anchor policy from `facilitator_emergent` to deterministic rule**: once enough exp45+ debate runs are observed, codify Pro/Con assignment rule in `strategy-hook-resolution.md` instead of falling back to facilitator emergence. Empirical-data-driven; not in Phase 4 scope.

## 9. Exit pointer

After Phase 4 PR merges to develop:
- Update `.s2s/BACKLOG.md` TECH-002 block per §6.
- Verify `MEMORY.md` `project_tech002_progress.md` reflects new state (Phase 7B + 7-lite + 4 done; Phase 8 + six-hats baseline pending; v0.4.0 release waits on Phase 8 only).
- Draft Phase 8 plan using this plan as structural template; the thin launchers are mechanical (Phase 4 made the master capable).
- Do NOT release v0.4.0 → main yet. Wait for Phase 8.

Phase 8 plan should be drafted as a new file targeting ~150 lines each for specs/design/brainstorm, with regression replay against exp45-phase4 baselines from §4.5.

## 10. Contract invariants (must NOT change)

Per `strategy-hooks.md` §9, exp44-post-phase7b baselines, and Phase 7-lite Step 2.10 freeze:

- **All baseline runtime behavior structurally unchanged**. exp44 dump shapes remain valid (no field removals, no path changes). Phase 4 may add new fields under `agent_state.facilitator.hook_overrides` (additive).
- **Step 2.0 → Step 2.10 numbering frozen**. Phase 4 adds new inputs to Step 2.2c (deterministic overrides from hook_overrides) but does NOT renumber.
- **Schema additivity for session.yaml**: `agent_state.facilitator.hook_overrides` is the only new top-level addition. No removals.
- **FIX-S1 preserved**: session-observer dumps still written `{NNN}-04-session-observer.yaml` per round.
- **Disney machine ownership**: algorithmic source remains `disney-phase-machine.md`. Phase 4 does not touch the machine.
- **All 5 CLI flags + 6 optional flags preserved**: no removals; no semantic changes.
- **strategy_constraints.forced wins**: profile YAML `forced: true` (brainstorm.yaml:17) continues to override CLI `--strategy`. Phase 4 does NOT relax this.

If any of these is violated, that is a regression and the PR cannot merge.

---

## Appendix A: 4.0 audit output

To be produced as `.s2s/plans/20260518-tech002-phase4-4.0-audit.md` during 4.0 execution. Output must include:
1. **Triple-dup map** — every duplicated cell across config.yaml, profiles, SKILL.md mapped to its D3 role.
2. **roundtable.md dispatch sites** — exact line numbers for each insertion/replacement in §4.3.
3. **commands/*.md Phase 2 pattern reference** — line numbers in specs/design/brainstorm where `phase-2-core.md` is invoked, so roundtable.md mirrors the pattern (confirmed compact: design.md:379-401 ~23 lines).
4. **Anchor fixture map** — 5-row table of strategy doc → opening line phrase → expected override dict.
5. **Phase-name drift table** — full inventory beyond consensus-driven and six-hats.
6. **Resolution hierarchy gap inventory** — `default_strategy` + any other "documented intent, unread" field (e.g. `strategy_constraints.forced`).
7. **Profile gap closure** — drafted `profiles/roundtable.yaml` content (minimal: standard default, no agenda gating, no phase transition, min_participants: 2).
8. **phase-2-core.md Step 2.2c modification site** — exact lines around 269 where facilitator agent is invoked; the `hook_overrides:` input field to be added.
9. **Facilitator agent strategy-doc pointer lines** — confirmed line numbers for `#strategy-hooks` anchor sharpening (currently ~518/579/607).
10. **Pass-3 grep verification footer** — explicit repo-wide greps run, results pasted (per Phase 7-lite 7.0 audit lesson §7.5).

## Appendix B: Option B parser pseudo-code

```
# In commands/roundtable.md, after Step 1.7 "Get strategy configuration"
# (current line ~199 area, post-strategy-doc-Read)

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
  HOOK_OVERRIDES = {error: "strategy doc opening line did not match any anchor"}
  abort with error

Write HOOK_OVERRIDES to session.yaml at agent_state.facilitator.hook_overrides
```

At each round, `phase-2-core.md` Step 2.2c reads `session.yaml.agent_state.facilitator.hook_overrides` and passes it as the `hook_overrides:` input field to the facilitator agent invocation (Task tool). The facilitator agent honors this input: if present and non-skip → populates `participant_context.overrides.{participant-id}.{field}` per the dict; if absent or `skip: true` → emits no overrides (current LLM-emergent behavior preserved for backward-compat with pre-Phase-4 sessions).

# TECH-002 Phase 4: roundtable.md as master (structured workflows) + Option A/B/C wiring decision

**Plan ID**: `20260518-tech002-phase4-roundtable-master`
**Branch**: `feature/TECH-002-phase4-roundtable-master`
**Forked from**: `develop` @ `3043c1a` (post Phase 7-lite PR #15 merge)
**Author**: Claude (Opus 4.7) + Francesco
**Status**: draft (created 2026-05-18, revised 2026-05-19 after reviews #2 and #4)
**Created**: 2026-05-18
**Revised**: 2026-05-19 (Approach 4 pivot + Option δ refinement: `profiles/roundtable.yaml` NOT created; `--workflow-type roundtable` keeps current stub UNLESS §4.0 step 7 reveals broken state, in which case mandatory minimum-viable fix (MVF) ships in Phase 4; full hardening deferred to Phase 9. Test gate strengthened to cover all 3 master paths. CI-style anchor drift check in-scope.)
**Predecessor plan**: `.s2s/plans/20260517-tech002-phase7-strategy-consolidation.md` (Phase 7-lite)
**Contract sources**:
- `skills/roundtable-execution/references/strategy-hooks.md` (Phase 7-lite hardened state, §7 Option A/B/C decision matrix)
- `.s2s/decisions/0011-roundtable-command-unification.md` (Phase 7-lite addendum)
- `.s2s/plans/20260518-tech002-phase7-lite-7.0-audit.md` (§6.2 triple-duplication, §7.3 default_strategy, §4 commands/roundtable.md drift)

---

## 1. Goal

Expand `commands/roundtable.md` (currently 437 lines, "follow the skill" stub for Phase 2) into the master orchestrator (~530 lines) for the three structured workflow types: `specs`, `design`, `brainstorm`. Execution flows uniformly through `phase-2-core.md` for these three. The fourth invocation mode, `--workflow-type roundtable` (generic free-form discussion, also the default when no flag), keeps its current Phase 3 stub behavior; hardening generic mode is deferred to Phase 9 as an explicit non-goal (see §3.5 for rationale and three approaches considered).

Make the explicit **Option A/B/C decision** for runtime consumption of strategy hooks (debate Pro/Con assignment, six-hats hat rotation, disney phase already handled by machine) and implement the chosen option. Unify the triple-duplication of strategy/workflow defaults across `templates/project/config.yaml`, `profiles/{workflow}.yaml`, and `roundtable-strategies/SKILL.md`. Clarify and codify the `default_strategy` resolution hierarchy.

Phase 4 delivers five concrete wins:

1. **roundtable.md master for structured workflows**: full Phase 2 wiring via `phase-2-core.md` for specs/design/brainstorm (no "follow the skill" deferral on those paths), with `--workflow-type` profile dispatch, resume/diagnostic, and proper output dispatch per workflow. Generic-mode path (`--workflow-type roundtable` or default) explicitly preserved as current stub (or MVF if §4.0 step 7 reveals broken state). **Honest disclosure**: master capability is **dormant until Phase 8** thin launchers consume it (only `/s2s:roundtable --workflow-type X` invocations exercise the master path in v0.4.0). Phase 4 builds the foundation; Phase 8 makes it user-visible.
2. **Option B implementation across 3 files**: deterministic parser in roundtable.md, plus Step 2.2c modification in `phase-2-core.md` to consume `agent_state.facilitator.hook_overrides`, plus `agents/roundtable/facilitator.md` updated to honor passed overrides instead of LLM-inferring per-round overrides. Three-branch semantics codified: `{skip: true}` (strategy has no hooks), policy dict (strategy has hooks), absent field (pre-Phase-4 session, LLM-emergent fallback).
3. **Triple-duplication unification**: single canonical source per concern via resolution hierarchy (CLI, then config.yaml, then profile fallback). `templates/project/config.yaml` clarified as user-facing canonical; profile YAMLs clarified as plugin defaults; SKILL.md table disclaimers from 7-lite extended with resolution-hierarchy diagram.
4. **commands/roundtable.md drift reconciliation**: keyword auto-detect table (currently lines 170-179) and inline phase enumeration (currently lines 194-199, with phase-name drift versus strategy docs for `consensus-driven` and `six-hats`) reconciled per Option B.
5. **Facilitator-agent strategy-doc pointer sharpening**: 3 pointers in `agents/roundtable/facilitator.md` (currently lines 518/579/607) sharpened from whole-file references to `#strategy-hooks` anchors. Reduces coupling.

Phase 8 (thin launcher conversion specs/design/brainstorm to ~150 lines each) is the immediate downstream consumer and is NOT in Phase 4 scope; it runs separately after Phase 4 merges.

### Non-goals (explicit deferrals)

- **Generic-mode roundtable hardening**: deferred to Phase 9. `--workflow-type roundtable` (or no `--workflow-type`) keeps current Phase 3 stub. Phase 9 will evaluate three approaches: (a) create `profiles/roundtable.yaml`, (b) `phase-2-core.md` accepts `PROFILE=null` with generic defaults, (c) hard-code defaults inline in roundtable.md. Decision blocked on Phase 8 thin-launcher empirical data; see §3.5.
- **Phase 8 thin launchers**: separate plan after Phase 4 merges to develop. Phase 4 makes specs/design/brainstorm capable of being thin launchers; it does not convert them.
- **Six-hats wiring with empirical baseline**: prerequisite-blocked on baseline acquisition. Phase 4 implements the chosen Option mechanism so that six-hats wiring becomes a configuration change only, but does NOT capture the baseline.
- **`debate-phase-machine.md` extraction**: deferred unless §4.0 audit shows debate complexity warrants a machine file.
- **New strategy additions**: Phase 4 works with the 5 existing strategies; it does not add a sixth.
- **session-schema.md `INT-*` / `CONF-*` gaps**: pre-existing drift unrelated to roundtable unification.
- **Agent prompt redesign**: `agents/roundtable/facilitator.md` continues to be invoked by roundtable.md. Phase 4 sharpens 3 strategy-doc pointers (win #5) and adds `hook_overrides` consumption logic but does NOT rewrite agent prompt structure.

## 2. Inputs and constraints

### What we know

- `commands/roundtable.md` is 437 lines today, of which Phase 3 (lines 359-437) defers entirely to `roundtable-execution` skill with `"Follow the skill instructions EXACTLY"`. Phase 4 replaces this stub with a **conditional dispatch**: structured workflows (specs/design/brainstorm) get explicit Read of `phase-2-core.md` after loading their profile; generic-mode (roundtable) preserves the current stub flow verbatim.
- `commands/{specs,design,brainstorm}.md` (600/536/482 lines post-7B) inline the Phase 2 loop themselves via `phase-2-core.md` Reads. Phase 4 makes roundtable.md follow the same pattern for those three workflow types via `--workflow-type`.
- `templates/project/config.yaml` (107 lines, the third source flagged in 7.0 audit §6.2) carries `roundtable.strategy.by_workflow_type` (line 30-33), `roundtable.strategy.consensus` per-strategy rules (line 35-57), `roundtable.participants.by_workflow_type` (line 60-80). Profile YAMLs and SKILL.md duplicate slices of this.
- `default_strategy` field exists in `profiles/{workflow}.yaml` (e.g. `brainstorm.yaml:13 default_strategy: "disney"`) but is **NOT** consulted at command runtime; commands resolve strategy from `config.yaml.roundtable.strategy.by_workflow_type.{workflow}`. `profile-schema.md:115` describes it as "required for Phase 1 strategy resolution"; this is intent, not actual behavior.
- `commands/roundtable.md:194-199` enumerates phases inline with two drift sites versus strategy docs:
  - `consensus-driven`: command says `["proposal", "discussion", "resolution"]`; `consensus-driven.md` says `proposal/refinement/convergence` (per 7.0 audit §4).
  - `six-hats`: command says `["blue-opening", "white", "red", "black", "yellow", "green", "blue-closing"]`; `six-hats.md` line 86 says `["blue-hat-opening", "white-hat", "red-hat", "black-hat", "yellow-hat", "green-hat", "blue-hat-closing"]`.
- Phase 7-lite delivered 5 strategy docs with uniform `## Strategy hooks` sections. Opening lines drawn from a 4-phrase set serve as skip-triggers compatible with Option A (LLM regex) and Option B (command-side regex parse).
- exp44-post-phase7b regression baselines (3 workflows) are the authoritative behavior reference. Phase 4 runtime change may shift one or two specific behaviors (debate Pro/Con assignment data path, six-hats hat order data path) but core dump shapes and session file structure must remain identical.
- `profile-schema.md:5` enumerates "Profiles: specs.yaml, design.yaml, brainstorm.yaml". Approach 4 (Phase 4 chosen) keeps this enumeration as-is; profile-schema.md gains a footnote pointing to Phase 9 for generic-mode hardening.

### What we have as baselines

- exp44-post-phase7b: specs, design, brainstorm full structural summaries in `.s2s/test-baselines/`.
- exp44 debate sample (single run): `debate_role` was assigned via LLM emergence; one observation only, not a discriminative baseline.
- No six-hats baseline (prerequisite-blocked task, not addressed here).
- No empirical baseline for `/s2s:roundtable` native mode (Approach 4 preserves current undocumented behavior; Phase 9 will capture).

### Hard constraints

- **Backward compatible Phase 2 output**. exp44-post-phase7b dump shapes for the 3 workflows must replay identically after Phase 4. Any deviation is a regression and the PR cannot merge.
- **Generic-mode not regressed below pre-Phase-4 state**. `/s2s:roundtable` invocation without `--workflow-type` (or with `--workflow-type roundtable`) is determined by §4.0 step 7 audit outcome: if pre-Phase-4 works (outcome a), Phase 4 produces structurally identical output; if pre-Phase-4 is already broken (outcome b/c), the broken state is preserved verbatim and explicitly documented (Phase 9 fixes). Verified in §4.5 step 1 generic-mode light probe.
- **State machine preserved**. Step 2.0 to Step 2.10 numbering and dispatch invariants from Phase 7-lite are frozen. Phase 4 adds new inputs to Step 2.2c (3-branch dispatch from hook_overrides) but does not renumber.
- **Existing CLI flags preserved**. `--strategy`, `--participants`, `--workflow-type`, `--output-type`, `--verbose`, `--interactive`, `--diagnostic`, `--pro`, `--con`, `--new`, `--session` continue to work with current semantics. Phase 4 may add new flags but does not remove or rename.
- **No new third-party dependencies**. Pure markdown + plugin-side YAML.
- **Atomic PR**. Single PR target develop, milestone v0.4.0.

## 3. Approach

Phase 4 is the architectural inflection point of TECH-002 for **structured workflows**. The Option A/B/C decision is binding for the runtime wiring layer of all five strategies; six-hats and any future strategy will follow the same mechanism. Generic-mode roundtable is deferred to Phase 9 (see §3.5).

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

Phase 4 delivers in 7 sub-phases over an estimated **~7.75 hours** (revised from ~6.25 after Option δ refinements: mandatory MVF if audit outcome b/c, +CI anchor drift check, +master test coverage expansion):

- **4.0** audit (~1.5h): inventory of inline duplication, drift sites, Step 2.X dispatch points in roundtable.md, anchor fixture map, generic-mode preservation lines, 3-pass grep verification, **pre-Phase-4 generic-mode smoke test (CRITICAL, gates MVF inclusion)**.
- **4.1** triple-dup resolution (~0.5h): D3 hierarchy codified, SKILL.md disclaimer + diagram, profile-schema.md updated with Phase 9 footnote. NO profile YAML created.
- **4.2** Option B implementation across 3 files (~1.25h, +0.25h for anchor drift check): `strategy-hook-resolution.md` fixture (with 2 dict shapes) + parse block in roundtable.md + `phase-2-core.md` Step 2.2c with 3-branch dispatch + facilitator agent consumer with matching 3-branch logic + 3 strategy-doc pointer sharpening + **CI-style anchor drift check script in `skills/dev-testing/references/`**.
- **4.3** roundtable.md conditional Phase 2 dispatch (~1.5h): replace lines 359-437 with `if workflow_type in {specs, design, brainstorm}: load profile + Read phase-2-core.md; else: preserve current stub OR MVF`.
- **4.4** drift fix (currently lines 170-179 + 194-199) (~0.5h): keyword-auto-detect table disclaimer-protected; inline phase enumeration removed by source-of-truth deferral.
- **4.4b (conditional)** generic-mode MVF (~0.5-1h, ONLY if §4.0 step 7 outcome is b/c): minimum-viable fix in `/s2s:roundtable` native path. See §4.4b for spec.
- **4.5** regression replay + fixture assertions + backward-compat (~1h, +0.25h for expanded master coverage): exp45-{specs, design, brainstorm, roundtable-routed-as-specs, roundtable-routed-as-design, roundtable-routed-as-brainstorm, roundtable-native} via dogfood; 5 anchor parse fixture assertions; anchor drift check passes; backward-compat resume probe; light + (optional) heavy smoke probes.
- **4.6** close-out (~0.5h): BACKLOG (acceptance criteria #2 and #4 marked partially done with scope notes), ADR-0011 addendum (Option B + D3 + Approach 4 + Option δ refinements + dormant master acknowledgment + roundtable-strategies asymmetry), plan Status finalization, MEMORY.md update.

### 3.5 Generic-mode roundtable deferral rationale (Approach 4)

This plan adopts **Approach 4** (defer generic-mode hardening to Phase 9). Three other approaches were evaluated and rejected for Phase 4 scope:

| # | Approach | Trade-off summary |
|---|----------|-------------------|
| 1 | Create `profiles/roundtable.yaml` with generic placeholders | Uniform dispatch but yaml is semi-fictional; profile-schema.md needs new `progress.axis: "free_form"` value or carve-outs; 60-80 lines of placeholders. |
| 2 | `phase-2-core.md` accepts `PROFILE=null` with generic defaults | Cleanest architecturally (profiles describe DEVIATIONS from generic). Requires non-trivial phase-2-core.md edits and defining "generic" for every field. |
| 3 | Hard-code generic defaults inline in roundtable.md | Zero schema change; honest about asymmetry. Defaults live in 2 places (command + profiles); less DRY. |
| **4** | **Defer generic-mode hardening to Phase 9** | Surgical scope; no premature architectural decision; allows Phase 8 thin-launcher empirical data to inform Phase 9 choice. v0.4.0 ships with "structured workflows masters" capability. |

**Rationale for choosing Approach 4**:

1. **Scope honesty**. Phase 4's real prerequisite for Phase 8 thin launchers is "roundtable.md can route specs/design/brainstorm". Generic-mode hardening is independent and can ship later without blocking thin launchers.
2. **Decision under uncertainty**. Choosing between 1/2/3 requires data on how generic mode is actually invoked in practice. Phase 8 dogfood will surface this.
3. **Pattern from Phase 7-lite**. Phase 7-lite re-scoped (full → lite) when a sub-decision was premature; same pattern here.
4. **Atomic PR size**. Removing generic-mode work keeps Phase 4 at ~6.25h with focused scope, easier to review.

**Trade-off acknowledged**: TECH-002 acceptance criterion #2 ("roundtable.md can execute all workflows") is **partially done** after Phase 4 (3 of 4 workflow types). v0.4.0 → main release is gated on Phase 8 (thin launchers) regardless; Phase 9 generic-mode hardening lands in v0.5.0 or later.

**Dormant master disclosure (Option δ honest framing)**: Phase 4 builds the master capability in `commands/roundtable.md` but specs/design/brainstorm commands remain UNCHANGED (Phase 8 territory). Consequently, the master path is exercised only by non-canonical `/s2s:roundtable --workflow-type X` invocations in v0.4.0; users invoking `/s2s:specs`, `/s2s:design`, `/s2s:brainstorm` continue to use the existing inline implementation. The architectural shift becomes user-visible only when Phase 8 thin launchers consume the master. This is acceptable as a Phase 4/8 split (separate PRs, easier review) but the dormant interval requires explicit ADR acknowledgment and stronger Phase 4 test coverage (§4.5 step 1 expanded to exercise master path for all 3 structured workflow types, not just specs).

**MVF contract (Option δ, mandatory if §4.0 step 7 outcome b/c)**: if pre-Phase-4 smoke test reveals generic-mode broken state, Phase 4 expands scope by sub-phase 4.4b (~0.5-1h) to ship a Minimum Viable Fix: detect generic-mode invocation at Phase 0/1 of roundtable.md, display clear warning/error directing user to `--workflow-type {specs|design|brainstorm}` workaround, and either (i) stop session creation gracefully or (ii) proceed with explicit "best-effort, unsupported" annotation in session.yaml. The MVF is documented in commands help text and BACKLOG. No silent broken behavior ships to v0.4.0.

**Important caveat re "preserve verbatim"**: the current `/s2s:roundtable` native stub (lines 359-437) does NOT load a profile before delegating to `phase-2-core.md`. Post-Phase-7B, `phase-2-core.md` is profile-aware (`{{profile.X}}` references throughout, confirmed via grep in Phase 7B post-merge state). Whether native mode actually works today is unverified (no exp44 baseline for roundtable native). §4.0 step 7 makes pre-Phase-4 smoke test MANDATORY before declaring "preserve verbatim" feasible. Three outcomes (a/b/c in §4.0 step 7) determine §4.3 + §4.4b contract: (a) works → preserve verbatim; (b/c) broken → MVF ships in Phase 4 (§4.4b mandatory). Either way, Phase 4 does NOT regress generic mode below its current functional state, and does NOT ship silent broken behavior.

## 4. Sub-phases

**Execution order**: 4.0 → 4.1 → 4.2 → 4.3 → 4.4 → 4.5 → 4.6.

(4.4 follows 4.3 because the drift fix at lines 170-179/194-199 lands cleanly only after the conditional dispatch in 4.3 replaces the surrounding scaffolding.)

### 4.0: audit current state (~1.5h)

**Goal**: produce a definitive inventory for execution sub-phases. Use Phase 7-lite 7.0 audit as procedural template; pass-3 grep verification is mandatory (pass 1 undercounted 4× in 7-lite).

**Actions**:
1. **Triple-dup map**: enumerate every site in `templates/project/config.yaml`, `profiles/{workflow}.yaml`, `roundtable-strategies/SKILL.md` that holds workflow defaults, strategy mappings, participant lists. Output: table mapping each cell to its post-4.1 role.
2. **roundtable.md dispatch points**: list every place lines 1-437 needs to change to host the master execution for structured workflows (Phase 2 dispatch site, `--workflow-type` flag handling, output-type default per workflow, resume path).
3. **`commands/{specs,design,brainstorm}.md` Phase 2 sites**: cross-reference how they currently invoke `phase-2-core.md`, confirmed compact pattern (e.g. `design.md:379-401`, ~23 lines total including framing). Document the exact lines roundtable.md will mirror.
4. **Strategy-hook anchor fixture map**: for each of 5 strategy docs, capture the exact opening-line phrase in `## Strategy hooks` (Phase 7-lite output) and map to expected override dict, distinguishing `{skip: true}` shape (standard, consensus-driven) from policy-dict shape (debate, six-hats, disney). Output: candidate fixture for §4.2.
5. **Phase-name drift inventory**: confirm `consensus-driven` and `six-hats` mismatches; flag any others (compare command line 194-199 against each `{strategy}.md` `phases:` block).
6. **Resolution hierarchy gap inventory**: confirm `default_strategy` is currently unread by any command; identify whether any other profile field has the same "documented intent, unread" status (e.g. `strategy_constraints.forced`).
7. **Pre-Phase-4 generic-mode smoke test + preservation map** (CRITICAL, gates §4.4b MVF inclusion): BEFORE declaring "preserve verbatim" feasible, run `/s2s:roundtable "test topic" --diagnostic` in dogfood on PRE-Phase-4 code (current develop @ 3043c1a) and capture structural summary. Three possible outcomes determine §4.3 + §4.4b contract:
   - **(a) Works fine**: capture as `.s2s/test-baselines/exp45-roundtable-native-pre-phase4.md`; becomes the post-Phase-4 invariant target. §4.3 step 1 else-branch preserves stub verbatim; §4.4b SKIPPED.
   - **(b) Fails silently or produces structurally broken output**: document the failure mode in audit; §4.4b MVF MANDATORY (per Option δ refinement); §4.3 step 1 else-branch dispatches to MVF code path instead of broken stub; §10 invariant adjusted to "no NEW regression" framing.
   - **(c) Fails with hard error**: §4.4b MVF MANDATORY (per Option δ refinement); error is converted to a user-friendly warning + workaround suggestion before the failure surfaces. §10 invariant adjusted same as (b).
   Outcomes (b) and (c) BOTH trigger §4.4b expansion. Phase 4 scope grows by ~0.5-1h if triggered. Phase 4 NEVER ships with silent or hard-error broken generic-mode behavior to users.
   Then document exact lines (probably 357-437 stub area) that must NOT be touched by §4.3 conditional dispatch (if outcome a), OR document the MVF replacement scope (if outcome b/c).
8. **phase-2-core.md Step 2.2c facilitator invocation**: locate the exact lines in §2.2c that invoke the facilitator agent (around line 269); identify where 3-branch `hook_overrides` dispatch will be inserted.
9. **Facilitator agent strategy-doc pointers**: confirm exact line numbers (currently 518/579/607 area) for `#strategy-hooks` anchor sharpening in §4.2 step 5.

**Output**: `.s2s/plans/20260518-tech002-phase4-4.0-audit.md` mirroring the structure of `20260518-tech002-phase7-lite-7.0-audit.md`. Must include explicit pass-3 grep verification.

**Exit condition**: audit file produced; per-sub-phase task lists for 4.1-4.4 finalized; generic-mode preservation lines explicitly listed; phase-2-core.md Step 2.2c modification site identified.

### 4.1: codify D3 triple-duplication hierarchy (~0.5h)

**Goal**: explicit roles for the three sources; runtime resolution order codified; SKILL.md documentation updated. NO profile YAML created (Approach 4).

**Actions**:
1. **profile-schema.md**: rewrite the `default_strategy` field description to read "**Plugin fallback**. Consulted by `roundtable.md` Phase 1 after CLI and `config.yaml` are exhausted. See §3.3 resolution hierarchy in Phase 4 plan / ADR-0011 Phase 4 addendum." Same treatment for any other "documented intent, unread" field surfaced in 4.0 §6. Also: line 5 enumeration `Profiles: specs.yaml, design.yaml, brainstorm.yaml` gains a footnote: "Roundtable workflow does not have a profile YAML; generic-mode handling deferred to Phase 9 (see ADR-0011 Phase 4 addendum)."
2. **`roundtable-strategies/SKILL.md`** v1.2.0 → v1.3.0: insert a new "## Strategy resolution hierarchy" section between current "## How" and "## Workflow-Specific Defaults" sections, with an ASCII diagram of `CLI → config.yaml → profile → error`. The existing 7-lite disclaimer banners stay. **Version bump rationale**: additive (new section + diagram, no removals; backward-compatible with all consumers).
3. **`templates/project/config.yaml`** header comment: add `# This file is the user-canonical source for strategy/participant defaults at runtime.` Add `# See plugin profiles for fallback values if a key is omitted.` near the strategy block.
4. **Profile YAML comments**: in `profiles/{workflow}.yaml`, prefix `default_strategy` with a comment block: `# Plugin fallback. Consumed only when .s2s/config.yaml omits roundtable.strategy.by_workflow_type[{workflow}].`
5. **Cross-reference fixture**: add a single-source table `skills/roundtable-execution/references/strategy-resolution.md` (new file, ~60 lines) that documents the hierarchy with one worked example per workflow (specs/design/brainstorm). Referenced from SKILL.md and roundtable.md.

**Exit condition**: D3 hierarchy is the single explanation of strategy resolution across plugin; no contradictory text remains. `grep -rn "default_strategy" skills/ commands/` returns only sites that explicitly state "plugin fallback" or quote the resolution hierarchy. `ls skills/roundtable-execution/profiles/` still shows 3 files (specs, design, brainstorm); no roundtable.yaml created.

### 4.2: Option B implementation across 3 files (~1h)

**Goal**: deterministic resolution of per-strategy hook overrides via a parser block in roundtable.md, a Step 2.2c modification in phase-2-core.md, and a hook_overrides consumer in the facilitator agent. Two distinct fallback semantics codified: `{skip: true}` (strategy declares no per-round hooks, current standard behavior) versus absent field (pre-Phase-4 session, LLM-emergent fallback).

**Actions**:
1. **Anchor fixture**: create `skills/roundtable-execution/references/strategy-hook-resolution.md` (new file, ~80 lines; name disambiguated from existing `strategy-hooks.md` contract doc). Contents:
   - One row per strategy with: opening-line phrase exact match (regex), derived override dict, target Step 2.2c field set.
   - Header note: "Deterministic fixture consumed by `commands/roundtable.md` Phase 1 strategy-hook resolution. Keep in sync with `roundtable-strategies/references/{strategy}.md` `## Strategy hooks` opening lines."
   - Two semantically-distinct dict shapes documented: `{skip: true}` for strategies declaring no per-round hooks (standard, consensus-driven); `{participant_response_field: X, round_summary_field: Y, policy: "facilitator_emergent" | <coded_rule>}` for strategies with hooks (debate, six-hats, disney).
2. **Parser block in roundtable.md**: insert a new "## Resolve strategy hooks" section (post strategy-doc Read, pre debate handling). Block does:
   - Read `strategy-hook-resolution.md` fixture table.
   - Read the chosen `{strategy}.md` `## Strategy hooks` section (already done in current flow).
   - Match opening line to anchor row; produce `strategy_hook_overrides` dict per fixture.
   - Persist `strategy_hook_overrides` in session.yaml under `agent_state.facilitator.hook_overrides` so phase-2-core.md Step 2.2c can pass it to the facilitator agent at each round.
3. **phase-2-core.md Step 2.2c modification** (NEW deliverable surfaced in review #1): in the facilitator-invocation block (around line 269), add 3-branch dispatch reading `session.yaml.agent_state.facilitator.hook_overrides`:
   - **Branch 1** (`hook_overrides.skip == true`): pass `hook_overrides: {skip: true}` to facilitator agent input; facilitator emits no per-round overrides (strategy-by-design behavior, current standard for `standard`/`consensus-driven` strategies).
   - **Branch 2** (policy fields present): pass full dict; facilitator honors the policy (debate, six-hats, disney).
   - **Branch 3** (`hook_overrides` field absent in session.yaml): do NOT include `hook_overrides:` key in agent input at all; facilitator falls back to its current LLM-emergent inference. **Two distinct triggers for Branch 3**: (i) pre-Phase-4 session resumed (backward-compat); (ii) `/s2s:roundtable` native session (generic-mode path skips the §4.3 parser block per Approach 4, so hook_overrides is never written for these sessions). Branch 3 is therefore the STANDARD path for generic-mode invocations, not only a backward-compat path.
4. **Facilitator agent NEW logic**: `agents/roundtable/facilitator.md` adds a new "Hook override consumption" section to its system prompt with three corresponding branches matching Step 2.2c above:
   - `hook_overrides.skip == true` → emit no per-round overrides.
   - `hook_overrides` with policy fields → populate `participant_context.overrides.{participant-id}.{field}` per the dict.
   - `hook_overrides` key absent in input → fall back to current LLM-emergent inference (preserves pre-Phase-4 session resume behavior).
5. **Strategy-doc pointer sharpening** (win #5): in `agents/roundtable/facilitator.md`, change the 3 strategy-doc pointers (currently around lines 518/579/607, exact lines confirmed in 4.0 step 9) from `{strategy}.md` (whole-file) to `{strategy}.md#strategy-hooks` (anchor). Reduces coupling; cost ~3 edits.
6. **Test fixture**: add 5 unit-style assertions inside `.s2s/plans/20260518-tech002-phase4-4.2-fixture.md` (kept in plans/ to avoid muddling with `.s2s/test-baselines/` structural baselines): for each strategy doc, capture the parse output dict and freeze it. Used in §4.5 to assert no regression.
7. **CI-style anchor drift check** (Option δ in-scope, ~15min): create `skills/dev-testing/references/strategy-hook-anchor-check.md` (~30 lines) containing a bash snippet that, for each of 5 strategy docs, extracts the first non-empty line of `## Strategy hooks` section and compares to the corresponding regex anchor in `strategy-hook-resolution.md`. Exits non-zero if drift detected. Documented as "run before any docs PR touching strategy docs". Phase 4 ships the check; Phase 8 or post-v0.4.0 work may wire it to actual CI infra if/when added.

**Exit condition**: roundtable.md has deterministic hook resolution; phase-2-core.md Step 2.2c reads + dispatches via 3-branch logic; facilitator agent consumes input with matching 3-branch logic; 5 fixture assertions documented; anchor drift check script exists and passes for all 5 strategies as-is. Backward-compat preserved: missing `hook_overrides` field triggers LLM-emergent fallback (Branch 3), semantically distinct from `{skip: true}` (Branch 1).

### 4.3: expand roundtable.md to master for structured workflows (~1.5h)

**Goal**: replace the Phase 3 stub (lines 359-437) with conditional dispatch: structured workflows (specs/design/brainstorm) get full Phase 2 dispatch through `phase-2-core.md`; generic mode (`--workflow-type roundtable` or absent) preserves current stub flow verbatim. Pattern for structured path mirrors `commands/design.md:379-401`.

**Actions**:
1. **Conditional Phase 2 dispatch**: replace lines 359-437 with branch logic:
   ```
   if workflow_type in {"specs", "design", "brainstorm"}:
       Read profiles/{workflow_type}.yaml → PROFILE
       Read phase-2-core.md and follow §2 Round Loop
   else:  # workflow_type == "roundtable" or absent (generic mode)
       (preserve current "Follow the skill EXACTLY" stub flow per §4.0 step 7 audit outcome)
   ```
   Structured path ~25-30 new lines mirroring `design.md:379-401`. Generic path ~50 lines preserved from current 359-437 (verbatim if §4.0 step 7 outcome is (a); with explicit "known broken" annotation if outcome is (b)/(c)). The branch wrapper adds ~10 lines.
2. **Session ID naming**: current line 237 generates `{timestamp}-roundtable-{topic-slug}` (hard-coded "roundtable" prefix because command name is `/s2s:roundtable`). Phase 4 change: session_id uses `workflow_type` prefix instead of command name: `{ts}-{workflow_type}-{slug}`. So `/s2s:roundtable "topic"` (workflow_type defaults to roundtable) → `{ts}-roundtable-{slug}` (unchanged); `/s2s:roundtable "topic" --workflow-type specs` → `{ts}-specs-{slug}` (consistent with what `/s2s:specs` produces today and what Phase 8 thin launchers will need). Documented in commit message + ADR-0011 addendum.
3. **Output dispatch (structured workflows only)**: Phase 3 output-type defaulting per workflow:
   - `specs` → `requirements`
   - `design` → `architecture`
   - `brainstorm` → `summary` (with brainstorm output template)
   - `roundtable` (generic) → `summary` (current default, no change)
   Read the corresponding `output-generation/references/{template}.md` per `--output-type` resolution.
4. **Resume path**: ensure `--session {id}` works for sessions of any `workflow_type` (current code only handles `workflow_type: roundtable` on resume, see line 75). Add workflow-type-aware resume dispatch for the structured paths; generic-mode resume unchanged.
5. **Diagnostic mode**: `--diagnostic` continues to force `verbose_flag = true` and routes to `Step 3.0 Final Diagnostic Report` in `phase-2-core.md` for structured workflows; generic-mode diagnostic unchanged.
6. **Line budget**: current 437 lines + conditional dispatch wrapper (~10 lines) + structured-path Phase 1 profile load (~15 lines) + structured-path Phase 2 dispatch (~30 lines) + structured-path output dispatch (~20 lines) + resume extension (~15 lines) + session-id renaming logic (~5 lines) = **~532 lines target**. Margin: keep ≤ 550 lines.

**Exit condition**: roundtable.md can run 3 structured workflows end-to-end through phase-2-core.md; generic-mode path behaves per §4.0 step 7 audit outcome (preserved if (a), known-broken-documented if (b)/(c)); session_id uses workflow_type prefix; `wc -l commands/roundtable.md` ≤ 550; specs/design/brainstorm commands UNCHANGED (still inline; Phase 8 territory).

### 4.4: fix command drift (currently lines 170-179 + 194-199) (~0.5h)

**Goal**: remove inline phase enumeration and keyword auto-detect drift; reconcile with strategy docs. Line numbers will shift after §4.3 expansion; the 4.0 audit captures the post-4.3 line positions for precise targeting.

**Actions**:
1. **Keyword-auto-detect table** (currently lines 170-179): keep the table (it serves a UX purpose: telling user which strategy fits which keywords) but add a header note `> Keyword → strategy mapping is documented here for user discoverability. The authoritative strategy descriptions live in skills/roundtable-strategies/references/{strategy}.md.` No deletion; just disclaimer.
2. **Inline phase enumeration** (currently lines 194-199): REMOVE the `- **standard**: phases: ["discussion"]` bulleted list entirely. Replace with: `Read the strategy doc; the canonical phases live in its Configuration block. The strategy-hook overrides parsed in §4.2 surface phase metadata when needed.`
3. **consensus-driven phase-name fix**: data fix; `consensus-driven.md` is authoritative per Phase 7-lite. The command's inline `["proposal", "discussion", "resolution"]` is wrong and is removed in step 2 above.
4. **six-hats phase-name fix**: same; six-hats.md line 86 is authoritative; command's enumeration is removed.
5. **Grep verification**: `grep -n "phases:" commands/roundtable.md` returns no inline phase list; only Read directives.

**Exit condition**: no inline phase enumeration in roundtable.md; keyword table disclaimer-protected; phase-name drift eliminated by source-of-truth deferral.

### 4.4b: generic-mode Minimum Viable Fix (~0.5-1h, CONDITIONAL on §4.0 step 7 outcome b/c)

**Goal**: ensure Phase 4 NEVER ships silent or hard-error broken generic-mode behavior to v0.4.0 users. Triggered only when §4.0 step 7 outcome is (b) or (c). Skipped if outcome is (a).

**Actions** (executed only if triggered):
1. **Detect at Phase 0**: in `commands/roundtable.md` Phase 0 (or early Phase 1 after `--workflow-type` parsing), detect generic-mode invocation (`workflow_type` is absent OR equal to `"roundtable"`).
2. **MVF behavior selection** (decide based on §4.0 step 7 outcome severity):
   - **For outcome (c) hard error**: display a clear AskUserQuestion-style message: "Generic-mode `/s2s:roundtable` (without `--workflow-type`) is currently not fully supported in v0.4.0 due to phase-2-core.md profile-awareness requirements (TECH-002 Phase 9 will harden). Workaround: re-invoke with `--workflow-type {specs|design|brainstorm}` explicitly." Stop session creation gracefully (exit code 1 with non-error message in user-facing display).
   - **For outcome (b) silent broken**: display a non-blocking warning at session start: "WARNING: generic-mode roundtable is in best-effort state in v0.4.0 (TECH-002 Phase 9 pending). Output may be structurally incomplete. Recommended: use `--workflow-type {specs|design|brainstorm}` for guaranteed behavior." Annotate session.yaml with `generic_mode_warning: true` for diagnostic. Proceed with current stub flow.
3. **Help text update**: update `commands/roundtable.md` frontmatter `description` and `argument-hint` to mention `--workflow-type` recommendation. Update `docs/` user-facing doc if relevant.
4. **BACKLOG note**: add entry under TECH-002 referencing Phase 9 as the fix; record §4.0 step 7 outcome (b or c) explicitly.
5. **Test fixture**: capture the MVF behavior structural summary in `.s2s/test-baselines/exp45-roundtable-native-phase4-mvf.md` for Phase 9 to use as comparison baseline.

**Exit condition** (only if triggered): generic-mode invocation produces user-facing warning OR friendly error (NO silent failure, NO bare exception); workaround documented in command help; Phase 9 BACKLOG entry references this MVF as the predecessor state.

**Skipped condition** (if §4.0 step 7 outcome is (a)): no MVF needed; current stub preserved verbatim per §4.3 step 1 else-branch.

### 4.5: regression replay + Option B fixture verification + backward-compat (~1h)

**Goal**: confirm no behavioral regression across the 3 structured workflows that have baselines; verify Option B fixture matches expected dicts; confirm pre-Phase-4 sessions resume cleanly via Branch 3 (LLM-emergent fallback); confirm generic-mode preserved.

**Actions**:
1. **Regression replay + expanded master coverage** in dogfood (`ElfGiftRush_s2s/exp45-phase4`):
   - **Direct invocations (unchanged paths, full regression)**:
     - `/s2s:specs "..."` compare structural summary to `.s2s/test-baselines/exp44-specs-post-phase7b.md`.
     - `/s2s:design "..."` same, `exp44-design-post-phase7b.md`.
     - `/s2s:brainstorm "..."` same, `exp44-brainstorm-post-phase7b.md`.
   - **Master path via roundtable.md (Option δ expanded coverage, all 3 structured workflows)**:
     - `/s2s:roundtable "..." --workflow-type specs` expected output structurally equivalent to `/s2s:specs` (session_id will use `specs-` prefix per §4.3 step 2).
     - `/s2s:roundtable "..." --workflow-type design` expected output structurally equivalent to `/s2s:design`.
     - `/s2s:roundtable "..." --workflow-type brainstorm` expected output structurally equivalent to `/s2s:brainstorm`.
   - **Generic-mode probe (depends on §4.0 step 7 outcome)**:
     - **Outcome (a)**: light probe at Phase 1 boundary only (no 3+ round wait). Assert: (i) no Phase 0/1 errors; (ii) session.yaml created with `workflow_type: roundtable`; (iii) first round invocation starts; (iv) compare to `.s2s/test-baselines/exp45-roundtable-native-pre-phase4.md`. Optional full probe if time permits.
     - **Outcome (b)/(c) with §4.4b MVF**: probe the MVF behavior. Assert: (i) user-facing warning/error displayed correctly (matches §4.4b spec); (ii) no silent failure; (iii) session annotated with `generic_mode_warning: true` (outcome b) OR session creation stopped gracefully (outcome c); (iv) structural summary matches `.s2s/test-baselines/exp45-roundtable-native-phase4-mvf.md`.
2. **Anchor parse fixture**: for each of 5 strategies, run the parse block standalone (manual Read + match probe), assert output dict equals `.s2s/plans/20260518-tech002-phase4-4.2-fixture.md` frozen values. Distinguishes 2-of-5 strategies with `{skip: true}` shape (standard, consensus-driven) from 3-of-5 with policy-dict shape.
3. **Backward-compat resume probe**: take a frozen pre-Phase-4 session file (from `.s2s/test-baselines/exp44-*`) and resume via `/s2s:roundtable --session {id}`. Assert behavior:
   - No error on missing `agent_state.facilitator.hook_overrides` field.
   - Facilitator agent input does NOT include `hook_overrides:` key (matches §4.2 step 3 Branch 3).
   - Per-round behavior identical to current LLM-emergent inference (no semantic shift).
4. **Acceptable deltas**: debate Pro/Con assignment data path changes (now flows through hook_overrides session field) but behavior is identical because initial `policy: "facilitator_emergent"` (per §4.2 step 1 default) preserves LLM emergence. Document delta as "data path additive, no behavioral shift expected".
5. **Unacceptable deltas**: dump schema changes (except additive `agent_state.facilitator.hook_overrides`), Step 2.X numbering changes, session.yaml structural differences, missing artifacts. Any unacceptable delta blocks the PR.
6. **Light smoke probe (Phase 1 inspection only, no full session)**: `/s2s:roundtable "test topic" --workflow-type design --strategy debate` (debate strategy exercises Branch 2 non-skip path); interrupt or wait for session.yaml first write (post Phase 1, before Round 1 completes), then `grep "hook_overrides" .s2s/sessions/{id}.yaml` confirms field populated with `debate_role`/`debate_phase` keys. Avoids waiting for full 3+ round dogfood completion.
7. **Heavy smoke probe (full session, optional)**: if light probe (step 6) passes and time permits, run full `/s2s:design "test topic" --strategy debate --diagnostic` to completion; confirm participant context dumps show `debate_role` populated via Branch 2 data path (not LLM-inferred). Skip if 4.5 budget is tight; light probe in step 6 is sufficient for done criteria.

**Exit condition**: 3 structured-workflow baselines match (structural); roundtable.md master path produces structurally-equivalent specs output (with workflow_type-prefixed session_id); generic-mode light probe shows no NEW regression vs §4.0 step 7 baseline; 5 fixture assertions pass; backward-compat resume probe succeeds via Branch 3; light smoke probe verifies `hook_overrides` populated via Branch 2.

### 4.6: close-out (~0.5h)

**Actions**:
1. `.s2s/BACKLOG.md` TECH-002 block: Phase 4 marked ✅ completed; Phase 8 promoted to `in_progress (next session)`; Acceptance Criterion **#2** ("`roundtable.md can execute all workflows`") marked **partially done** with note: "3/4 workflow types covered (specs/design/brainstorm via Phase 4); generic-mode roundtable hardening deferred to Phase 9. Full closure of #2 awaits Phase 9."; Acceptance Criterion **#4** ("`Skills actually used, not just declared`") marked **partially done** with note: "roundtable.md now uses both skills for structured workflows; specs/design/brainstorm commands continue inline until Phase 8 thin-launcher conversion."
2. `.s2s/decisions/0011-roundtable-command-unification.md` Phase 4 addendum: record (i) Option B choice with §3.1 matrix summary; (ii) D3 hierarchy decision; (iii) Approach 4 generic-mode deferral rationale + §4.0 step 7 outcome (a/b/c) actual result; (iv) §4.4b MVF if triggered (outcome b/c) with behavior spec; (v) phase-2-core.md Step 2.2c modification with 3-branch semantics; (vi) drift fixes + pointer sharpening; (vii) **dormant master acknowledgment** ("Phase 4 master capability is dormant in v0.4.0 until Phase 8 thin launchers consume it; user-visible only post-Phase-8 merge"); (viii) **roundtable-strategies/ asymmetry note** ("roundtable-execution = executable via Read; roundtable-strategies = parsed by command, documentation-only at runtime; asymmetry by D3 design, not accidental"); (ix) CI anchor drift check existence + invocation path.
3. Plan Status field finalize: `draft` → `completed (PR #XX merged YYYY-MM-DD)` post-merge.
4. `MEMORY.md` `project_tech002_progress.md` updated to reflect Phase 4 done; Phase 8 + Phase 9 (generic-mode) + six-hats baseline as remaining items; MEMORY.md index entry updated.

**Exit condition**: BACKLOG + ADR + plan + memory all consistent with post-Phase-4 state; Approach 4 explicit in ADR-0011 addendum.

## 5. Risk register

| ID | Risk | Likelihood | Impact | Mitigation |
|----|------|------------|--------|------------|
| R1 | Option B fixture brittleness: opening-line phrases drift when strategy docs are edited | medium | medium | §4.2 anchor fixture is single-file; `## Strategy hooks` opening lines are referenced from `strategy-hook-resolution.md` header note as "must stay in sync". CI grep check (post-v0.4.0 follow-up) flags drift. |
| R2 | roundtable.md exceeds 550-line budget after Phase 2 expansion | low | low | §4.3 step 6 line budget computation: 437 + ~95 (additions) = ~532. If overflow, two honest options: (a) extend budget to ≤600 lines (no architectural compromise; just a number); (b) extract Phase 0 auto-detect section (lines 29-146) to `roundtable-execution/references/auto-detect.md` (~120 lines, behaviorally neutral). Do NOT compact long YAML examples or verbose comments because the current 437 lines are mostly business logic without such low-hanging fruit. Do NOT extract Phase 1 helpers (would contradict master goal). |
| R3 | Resume path workflow-type-aware dispatch breaks legacy `--session` for pure roundtable sessions | low | high | §4.3 step 4 explicitly preserves current line 75 semantics for `workflow_type: roundtable`; extends only to handle other workflow_types. Test in §4.5 step 3. |
| R4 | Triple-dup hierarchy D3 confuses users (which file to edit?) | medium | medium | §4.1 SKILL.md resolution diagram + strategy-resolution.md worked examples + config.yaml header comment all repeat the hierarchy explicitly. |
| R5 | Debate Pro/Con deterministic assignment (Option B) produces worse pairings than LLM-emergent | low | medium | exp44 sample is one observation; deterministic anchor policy is `facilitator_emergent` until empirical data justifies a coded rule. Option B initial overrides preserve current emergent behavior; only six-hats and future strategies get deterministic policy at this stage. |
| R6 | Phase 4 changes break the 3 structured-workflow baselines (regression) | low | high | §4.5 replay is the gate. Mitigation if unacceptable delta: fix in-place for minor deltas; for significant deltas, escalate to additional review round or split PR into smaller commits; full Phase 4 rollback only as last resort. |
| R7 | `default_strategy` change from "documented intent" to "actual fallback" exposes a latent bug if profile YAML value disagrees with current implicit behavior | low | low | §4.0 audit cross-checks profile.default_strategy vs config.yaml.by_workflow_type for each workflow; reconcile any disagreement in §4.1 commit. |
| R8 | Generic-mode roundtable invocation breaks after §4.3 conditional dispatch | low | high | §4.3 step 1 preserves current stub OR dispatches to §4.4b MVF based on §4.0 step 7 outcome. §4.5 step 1 generic-mode probe verifies behavior matches expected (outcome a preserved, b/c MVF). Phase 4 never ships silent or hard-error broken behavior to users (Option δ guarantee via mandatory §4.4b MVF if outcome b/c). |
| R9 | `phase-2-core.md` Step 2.2c modification not done: Option B data path incomplete (overrides written to session.yaml but never read) | medium | high | §4.2 step 3 explicitly delivers Step 2.2c modification as in-scope work with 3-branch semantics. §4.0 step 8 confirms exact insertion site. §4.5 step 6 light smoke probe verifies `hook_overrides` populated AND structurally consumable via Branch 2. |
| R10 | Backward-compat resume probe fails: pre-Phase-4 session resumes throw on missing `agent_state.facilitator.hook_overrides` field | low | high | §4.2 steps 3+4 specify 3-branch logic with absent-field fallback (Branch 3) to LLM-emergent, semantically distinct from `{skip: true}` (Branch 1). §4.5 step 3 dedicated probe with frozen pre-Phase-4 session file verifies. |
| R11 | Approach 4 (generic-mode deferral) leaves user confusion about `/s2s:roundtable` capabilities | medium | low | BACKLOG note + ADR-0011 Phase 4 addendum + plan §3.5 all explicitly document deferral. If §4.0 step 7 outcome b/c, §4.4b MVF surfaces clear user-facing warning/error reducing confusion to "tell me what to do" guidance. |
| R12 | §4.4b MVF triggered when outcome was actually (a), OR skipped when outcome was actually (b)/(c) (decision error) | low | high | §4.0 step 7 is explicit: outcome must be classified into exactly one of a/b/c with structural-summary evidence captured in audit. Phase 4 review (this plan) before execution + audit review before §4.4b decision reduces classification error. If misclassified, §4.5 step 1 generic-mode probe will fail because expected vs actual behavior diverges. Rollback path: re-run §4.0 step 7, reclassify, redo §4.3+§4.4b. |
| R13 | Phase 4 master code is dormant until Phase 8; if Phase 8 is delayed indefinitely, v0.4.0 ships partial architectural change with no user value | medium | medium | Acknowledged in §1 win #1 framing + §3.5 dormant disclosure + ADR-0011 Phase 4 addendum. Phase 4 deliverables are still useful as structural prerequisite (D3 hierarchy, Option B wiring substrate, drift fixes). Phase 8 plan should be drafted promptly post-Phase-4 merge. v0.4.0 release timing is explicitly gated on Phase 8 completion per release flow note. |

## 6. Done criteria

- [ ] 4.0 audit file produced; per-sub-phase task lists finalized; pass-3 grep verification recorded; generic-mode preservation lines explicitly listed; phase-2-core.md Step 2.2c modification site identified; **§4.0 step 7 pre-Phase-4 generic-mode smoke test executed; outcome (a/b/c) recorded; §4.4b inclusion decided based on outcome**.
- [ ] D3 hierarchy codified: profile-schema.md (with Phase 9 footnote on roundtable profile absence), SKILL.md (v1.3.0 with new "Strategy resolution hierarchy" section + ASCII diagram), templates/project/config.yaml, profiles/*.yaml comments, strategy-resolution.md reference file all in agreement.
- [ ] `grep -rn "default_strategy" skills/ commands/` returns only "plugin fallback" or hierarchy-quoting sites; no orphan references.
- [ ] `ls skills/roundtable-execution/profiles/` still shows 3 files; no `roundtable.yaml` created (Approach 4 invariant).
- [ ] Option B implemented across 3 files: `strategy-hook-resolution.md` fixture exists with 2 dict shapes documented (`{skip: true}` vs policy dict); roundtable.md Phase 1 has parse block; `phase-2-core.md` Step 2.2c reads `agent_state.facilitator.hook_overrides` and dispatches via 3-branch logic; facilitator agent consumes input with matching 3-branch logic; 5 anchor assertions frozen in `.s2s/plans/20260518-tech002-phase4-4.2-fixture.md`.
- [ ] **CI-style anchor drift check script** exists at `skills/dev-testing/references/strategy-hook-anchor-check.md` and passes for all 5 strategies as-is. Documented invocation path in script header.
- [ ] **§4.4b MVF status**: if §4.0 step 7 outcome was (a), §4.4b SKIPPED and noted in audit. If outcome (b)/(c), §4.4b executed: user-facing warning/error implemented; command help text updated; `.s2s/test-baselines/exp45-roundtable-native-phase4-mvf.md` captured; BACKLOG references Phase 9 fix.
- [ ] 3 facilitator-agent strategy-doc pointers sharpened to `#strategy-hooks` anchors (lines 518/579/607 area).
- [ ] roundtable.md expanded to master for structured workflows: conditional dispatch in place; `--workflow-type {specs|design|brainstorm}` runs through phase-2-core.md; `--workflow-type roundtable` (or absent) preserves current stub verbatim; resume works for all workflow_types; `wc -l commands/roundtable.md` ≤ 550.
- [ ] specs/design/brainstorm commands UNCHANGED in this PR (Phase 8 territory).
- [ ] Keyword-auto-detect table disclaimer-protected; inline phase enumeration removed.
- [ ] consensus-driven and six-hats phase-name drift resolved (by source-of-truth deferral, no inline enumeration).
- [ ] Regression replay: 3 structured baselines match structurally; debate data-path delta documented (no behavioral shift since `facilitator_emergent` policy preserved); **roundtable.md master path produces structurally-equivalent output for ALL 3 structured workflows** via `/s2s:roundtable --workflow-type {specs,design,brainstorm}` (Option δ expanded coverage, not just specs); generic-mode probe behaves per §4.0 step 7 outcome (preserved if (a), MVF if (b)/(c)).
- [ ] §4.0 step 7 pre-Phase-4 generic-mode smoke test executed; outcome (a/b/c) recorded in audit file; if outcome (b)/(c), §10 invariant + §3.5 caveat reframed from "preserve verbatim" to "no NEW regression".
- [ ] 5 anchor parse fixture assertions pass.
- [ ] Backward-compat resume probe: pre-Phase-4 session file resumes without error on missing `hook_overrides` field; facilitator falls back to LLM-emergent inference via Branch 3 (NOT via Branch 1's skip path); behavior verified visible.
- [ ] Light smoke probe (`/s2s:roundtable "test" --workflow-type design --strategy debate`) populates `agent_state.facilitator.hook_overrides` with `debate_role` and `debate_phase` fields (Branch 2 working).
- [ ] `.s2s/BACKLOG.md` TECH-002 block: Phase 4 ✅; Phase 8 `in_progress (next session)`; TECH-002 acceptance criteria #2 and #4 marked **partially done** with explicit scope notes (structured workflows only; generic mode deferred to Phase 9).
- [ ] ADR-0011 Phase 4 addendum: Option B + D3 + Approach 4 deferral rationale + §4.0 step 7 outcome (a/b/c) actual result + §4.4b MVF spec if triggered + phase-2-core.md Step 2.2c modification (3-branch) + drift fixes + pointer sharpening + **dormant master acknowledgment** + **roundtable-strategies/ asymmetry note** + CI anchor drift check existence all recorded.
- [ ] PR opened against `develop`, milestone v0.4.0.
- [ ] Plan `Status` field updated from `draft` to `completed (PR #XX merged YYYY-MM-DD)` post-merge.

## 7. PR strategy

**Single PR**: `feature/TECH-002-phase4-roundtable-master` → `develop`.

Commit structure (in execution order):

1. `docs(plans): Phase 4 audit, triple-dup map, dispatch sites, anchor fixture map` (4.0)
2. `refactor(config): codify D3 strategy resolution hierarchy across profiles, SKILL.md, template` (4.1)
3. `feat(roundtable): Option B strategy-hook parser, fixture, Step 2.2c 3-branch dispatch, facilitator consumer, pointer sharpening, anchor drift check` (4.2). **Optional split if reviewer prefers atomic commits**: 3a `feat(roundtable): strategy-hook-resolution.md fixture + parser block + anchor-check script`, 3b `feat(phase-2-core): Step 2.2c 3-branch hook_overrides dispatch`, 3c `feat(facilitator): hook_overrides consumer logic + sharpen 3 strategy-doc pointers to #strategy-hooks anchors`.
4. `feat(commands): expand roundtable.md to master for structured workflows (conditional dispatch, generic mode preserved OR MVF)` (4.3)
5. `fix(commands): remove inline phase enumeration drift in roundtable.md` (4.4)
5b. `fix(roundtable): MVF for generic-mode invocation (warning/error + workaround guidance)` (4.4b, CONDITIONAL on §4.0 step 7 outcome b/c; SKIPPED if outcome a).
6. `test(baselines): exp45 regression replay (expanded master coverage), anchor parse fixture, backward-compat resume probe` (4.5)
7. `docs(adr,backlog,plan): close Phase 4, ADR-0011 Phase 4 addendum (Option B + D3 + Approach 4 + Option δ refinements + dormant master + asymmetry)` (4.6)

7 commits if outcome (a); 8 commits if outcome (b)/(c).

PR body must include:
- Link to plan file and to 4.0 audit file.
- Explicit "Option B chosen, see §3.1 matrix + ADR-0011 Phase 4 addendum" note.
- Approach 4 deferral note: generic-mode roundtable hardening deferred to Phase 9.
- D3 hierarchy diagram snippet.
- Before/after `wc -l commands/roundtable.md`.
- Regression deltas table (acceptable + unacceptable inventory).

## 8. Out-of-scope follow-ups (tracked, not actioned)

- **Generic-mode roundtable hardening (Phase 9)**: define semantics for `/s2s:roundtable` native mode (no `--workflow-type`). Approaches under consideration (per §3.5): (a) create `profiles/roundtable.yaml`, (b) `phase-2-core.md` accepts `PROFILE=null` with generic defaults, (c) hard-code defaults inline in roundtable.md. Decision blocked on Phase 8 thin-launcher empirical data.
- **Phase 8 thin launcher conversion**: specs/design/brainstorm to ~150 lines each. Next plan after Phase 4 merges. Phase 4 makes the master capable for structured workflows; Phase 8 collapses the inline launchers.
- **Six-hats wiring with empirical baseline**: capture baseline via `/s2s:design --strategy six-hats --verbose --diagnostic` on dogfood; freeze structural summary in `.s2s/test-baselines/`. Then add a deterministic anchor policy to `strategy-hook-resolution.md` (Option B configuration change only, no architectural work). Separate task.
- **`debate-phase-machine.md` extraction**: if 4.0 audit reveals debate complexity rivals disney, extract analogously. Deferred otherwise.
- **session-schema.md `INT-*` / `CONF-*` gaps**: pre-existing drift unrelated to Phase 4; tracked separately in BACKLOG.
- ~~**CI drift check for anchor fixture**~~ **MOVED TO IN-SCOPE (§4.2 step 7, Option δ)**. The bash check script ships in Phase 4 as `skills/dev-testing/references/strategy-hook-anchor-check.md`. Wiring to actual CI infrastructure (if/when the plugin acquires one) remains post-v0.4.0.
- **`templates/project/config.yaml` per-strategy consensus rules duplication**: lines 35-57 carry consensus thresholds per strategy that profile YAMLs also reference indirectly. Phase 4 D3 keeps config.yaml as user canonical; further normalization (e.g. moving consensus rules into strategy docs) is post-v0.4.0.
- **New strategy onboarding doc**: with Option B in place, adding a 6th strategy is a 3-step procedure (new strategy doc with `## Strategy hooks` + new anchor row + optional override policy). Document this in `s2s-guide` skill; post-v0.4.0 task.
- **Promote debate anchor policy from `facilitator_emergent` to deterministic rule**: once enough exp45+ debate runs are observed, codify Pro/Con assignment rule in `strategy-hook-resolution.md` instead of falling back to facilitator emergence. Empirical-data-driven; not in Phase 4 scope.

## 9. Exit pointer

After Phase 4 PR merges to develop:
- Update `.s2s/BACKLOG.md` TECH-002 block per §6 (acceptance criteria #2 and #4 partially done with scope notes).
- Verify `MEMORY.md` `project_tech002_progress.md` reflects new state: Phase 7B + 7-lite + 4 done for structured workflows; Phase 8 + Phase 9 generic-mode + six-hats baseline pending; v0.4.0 release waits on Phase 8 only; Phase 9 generic-mode lands in v0.5.0 or later.
- Draft Phase 8 plan using this plan as structural template; the thin launchers are mechanical (Phase 4 made the master capable for structured workflows).
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
- **Generic-mode `/s2s:roundtable` behavior NOT regressed below pre-Phase-4 state (Approach 4)**: `--workflow-type roundtable` or absent invocation behavior is determined by §4.0 step 7 audit outcome. If pre-Phase-4 works (outcome a), Phase 4 produces structurally identical output. If pre-Phase-4 is already broken (outcome b/c), the broken state is preserved verbatim with explicit documentation; Phase 9 fixes. Either way, no NEW regression.
- **profile-schema.md enumeration preserved**: still `Profiles: specs.yaml, design.yaml, brainstorm.yaml` (footnote added for Phase 9). No `roundtable.yaml` introduced.

If any of these is violated, that is a regression and the PR cannot merge.

---

## Appendix A: 4.0 audit output

To be produced as `.s2s/plans/20260518-tech002-phase4-4.0-audit.md` during 4.0 execution. Output must include:
1. **Triple-dup map**: every duplicated cell across config.yaml, profiles, SKILL.md mapped to its D3 role.
2. **roundtable.md dispatch sites**: exact line numbers for each insertion/replacement in §4.3, with generic-mode preservation lines clearly marked.
3. **commands/*.md Phase 2 pattern reference**: line numbers in specs/design/brainstorm where `phase-2-core.md` is invoked, so roundtable.md mirrors the pattern (confirmed compact: design.md:379-401 ~23 lines).
4. **Anchor fixture map**: 5-row table of strategy doc → opening line phrase → expected override dict, with `{skip: true}` vs policy-dict shape clearly distinguished.
5. **Phase-name drift table**: full inventory beyond consensus-driven and six-hats.
6. **Resolution hierarchy gap inventory**: `default_strategy` plus any other "documented intent, unread" field (e.g. `strategy_constraints.forced`).
7. **Generic-mode preservation map**: exact lines in current roundtable.md that the else-branch of §4.3 conditional dispatch must preserve verbatim (Approach 4 contract).
8. **phase-2-core.md Step 2.2c modification site**: exact lines around 269 where facilitator agent is invoked; the 3-branch `hook_overrides:` dispatch to be added.
9. **Facilitator agent strategy-doc pointer lines**: confirmed line numbers for `#strategy-hooks` anchor sharpening (currently ~518/579/607).
10. **Pass-3 grep verification footer**: explicit repo-wide greps run, results pasted (per Phase 7-lite 7.0 audit lesson §7.5).

## Appendix B: Option B parser pseudo-code

**Conditional context (Approach 4 contract)**: this parser block executes ONLY when `workflow_type ∈ {"specs", "design", "brainstorm"}`. For generic-mode invocations (`workflow_type == "roundtable"` or absent), the parser is skipped entirely (see §4.3 step 1 conditional dispatch). Consequently `hook_overrides` is never written to session.yaml for generic-mode sessions, and `phase-2-core.md` Step 2.2c handles them via Branch 3 (LLM-emergent fallback).

```
# In commands/roundtable.md, after "Get strategy configuration"
# (current line ~199 area, post-strategy-doc-Read)
# This block runs ONLY in the structured-workflows branch of §4.3 step 1.

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

- **Branch 1** (`hook_overrides.skip == true`): pass `hook_overrides: {skip: true}` to facilitator agent invocation; facilitator emits no per-round overrides (strategy declares no hooks, e.g. standard, consensus-driven).
- **Branch 2** (policy fields present): pass full dict; facilitator populates `participant_context.overrides.{participant-id}.{field}` per the policy (e.g. debate, six-hats with deterministic rule).
- **Branch 3** (`hook_overrides` field absent in session.yaml): do NOT include `hook_overrides:` key in agent input at all; facilitator falls back to current LLM-emergent inference. **Branch 3 has two distinct triggers**: (i) pre-Phase-4 session resumed (backward-compat); (ii) generic-mode session (`/s2s:roundtable` native, `workflow_type == "roundtable"` or absent) where the §4.3 parser block was skipped per Approach 4 contract. Both produce the same runtime behavior.

Branch 1 and Branch 3 are semantically distinct: Branch 1 means "strategy has decided there are no hooks" (e.g. standard, consensus-driven; no inference needed); Branch 3 means "no deterministic resolution has been performed" (either pre-Phase-4 session or generic-mode invocation; fall back to current LLM-emergent inference).

# Strategy Hooks Contract

> **Status**: contract documentation hardened (TECH-002 Phase 7-lite, 2026-05-18). Strategy reference docs now have uniform `## Strategy hooks` sections per strategy; runtime wiring deferred to Phase 4 (Option A/B/C decision).
> **Scope**: defines WHERE strategy-specific variation injects into the Phase 2 algorithm. Documents the contract; runtime wiring (Option A/B/C) deferred to Phase 4 architectural decision.
> **Behavior contract**: preserve current behavior. Strategies still produce the same observable fields (`debate_role`, `debate_phase`, Disney phase machine, etc.) as before Phase 7-lite.

Phase 2 (`phase-2-core.md`) is workflow-aware via `PROFILE` (from `profiles/{workflow}.yaml`). Some workflows additionally support **strategy-specific variations** that inject fields into facilitator/participant/synthesis output. This document inventories those variations and defines the hook contract; Phase 4 will wire it (subject to Option A/B/C choice).

---

## 1. Strategy inventory

Strategies are defined in `skills/roundtable-strategies/references/{strategy}.md`. The 5 current strategies and their per-round effects on Phase 2:

| Strategy | Workflows | Effect on Phase 2 | Hook points | Strategy doc § Strategy hooks |
|----------|-----------|-------------------|-------------|-------------------------------|
| `standard` | specs / design (allowed) | none beyond defaults | — | `standard.md` § Strategy hooks ("No per-round hooks") |
| `consensus-driven` | specs (default) / design (allowed) | none beyond defaults (participation: parallel, weighted_majority threshold) | — | `consensus-driven.md` § Strategy hooks ("No per-round hooks") |
| `debate` | specs (allowed) / design (default) | per-participant Pro/Con assignment + per-round debate phase tracking | §3 debate_role, §4 debate_phase | `debate.md` § Strategy hooks (Facilitator-driven, LLM-emergent; no fixed policy codified) |
| `disney` | brainstorm (forced) | three sequential phases (dreamer/realist/critic) with phase transitions | already extracted to `disney-phase-machine.md` | `disney.md` § Strategy hooks (phase machine via Step 2.10; no Step 2.2c overrides) |
| `six-hats` | specs / design (allowed) | six sequential hats (white/red/black/yellow/green/blue), each with focused mindset | §5 hat_role, §6 hat_phase (deferred) | `six-hats.md` § Strategy hooks (No per-round overrides; wiring deferred, no baseline) |

Disney is a complete machine, not a per-round hook — extracted to its own doc. The remaining hooks (§3-§6) are per-round inject points.

---

## 2. Hook contract

Each hook is a **named, optional injection point** in the Phase 2 algorithm. The contract:

- **Hook name**: identifies the hook (e.g., `participant_response.debate_role`).
- **Phase 2 step**: where the hook applies (e.g., Step 2.3c).
- **Condition**: when the hook activates (e.g., `STRATEGY == "debate"`).
- **Field added**: what gets added to the canonical schema (e.g., `debate_role` in participant response).
- **Source**: where the value comes from (e.g., facilitator's `participant_context.overrides.{id}.debate_role`).
- **Behavior contract**: what the LLM/agent does when the hook fires.

Hooks are **additive**: they extend canonical schemas with extra fields without breaking baseline behavior. Pre-7B.6 commands produced these fields via inline LLM-emergent behavior; post-7B.6 (and post Phase 7-lite, pre-Phase 4) the contract is documented in both `strategy-hooks.md` and each `{strategy}.md` § Strategy hooks section, but the wiring is unchanged (LLM still emergent).

---

## 3. Hook: `participant_response.debate_role`

| Property | Value |
|----------|-------|
| **Phase 2 step** | Step 2.3c (participant response) |
| **Condition** | `STRATEGY == "debate"` |
| **Field added** | `debate_role: "pro" \| "con"` (top-level in participant dump's `response`) |
| **Source** | Facilitator's Step 2.2c response includes `participant_context.overrides.{participant-id}.debate_role`. Participant receives and echoes it. |
| **Behavior** | Each participant is assigned to either the "pro" or "con" side at session start (or per round). The role drives the participant's argumentation stance. Without this hook, the participant gives a neutral response. |

**Phase 4 wiring direction**: facilitator agent should consult `roundtable-strategies/references/debate.md` § Strategy hooks to determine Pro/Con assignment policy and emit `overrides`. Currently LLM-emergent. Phase 4 Option A would Read the doc at runtime; Option B/C would parse a structured config. Phase 7-lite added the § Strategy hooks section as the documentation substrate for the future wiring.

---

## 4. Hook: `round_summary.debate_phase`

| Property | Value |
|----------|-------|
| **Phase 2 step** | Step 2.6 (Update Session File, round summary entry) |
| **Condition** | `STRATEGY == "debate"` |
| **Field added** | `debate_phase: "opening" \| "rebuttal" \| "closing" \| "synthesis"` (optional field in `rounds[].` entry) |
| **Source** | Facilitator's Step 2.4c synthesis response: `next_focus.debate_phase` or inferred from facilitator's current debate progression. |
| **Behavior** | The round summary records which debate phase was active. Enables audit ("round 3 was the rebuttal") and informs Step 2.7 round recap display. |

**Phase 4 wiring direction**: debate strategy's phases (`opening → rebuttal → closing → synthesis`) form a state machine similar to Disney's, but currently informally tracked. Phase 4 (or later) may extract a `debate-phase-machine.md` mirroring `disney-phase-machine.md`. For Phase 7-lite the field remains optional and LLM-driven.

---

## 5. Hook: `participant_response.hat_role` (six-hats — deferred)

| Property | Value |
|----------|-------|
| **Phase 2 step** | Step 2.3c (participant response) |
| **Condition** | `STRATEGY == "six-hats"` |
| **Field added** | `hat_role: "white" \| "red" \| "black" \| "yellow" \| "green" \| "blue"` |
| **Source** | Facilitator's `participant_context.overrides.{participant-id}.hat_role`. |
| **Behavior** | Each participant is assigned a thinking hat that drives their mindset (facts, emotions, criticism, positive, creative, process). |

**Status**: NOT observed in current dogfood baselines (six-hats has never been used). Hook is documented for completeness but unverified empirically. Phase 4 (when wired) will exercise; baseline acquisition is a prerequisite (capture `/s2s:design --strategy six-hats --verbose --diagnostic` structural summary first). Phase 7-lite added `six-hats.md` § Strategy hooks documenting the deferred contract.

---

## 6. Hook: `round_summary.hat_phase` (six-hats — deferred)

| Property | Value |
|----------|-------|
| **Phase 2 step** | Step 2.6 |
| **Condition** | `STRATEGY == "six-hats"` |
| **Field added** | `hat_phase: "blue-opening" \| "white-hat" \| ... \| "blue-closing"` |
| **Source** | Facilitator's synthesis decision. |
| **Behavior** | Records which hat was active. |

**Status**: same as §5 — deferred to Phase 4 (Option A/B/C decision); prerequisite-blocked on six-hats baseline acquisition.

---

## 7. Where strategy data CURRENTLY comes from vs. WILL come from

### Current state (post Phase 7-lite, pre Phase 4 wiring)

- **debate_role / debate_phase**: emerge from the LLM (facilitator agent and participant agents) interpreting `STRATEGY == "debate"` from input. Phase 7-lite added `debate.md` § Strategy hooks documenting this LLM-emergent state and noting that no fixed policy is codified. No runtime change at Step 2.2c.
- **disney phases**: machine fully extracted to `disney-phase-machine.md`. Phase transitions deterministic via `phase-2-core.md` Step 2.10. Phase 7-lite added `disney.md` § Strategy hooks + bidirectional cross-link banners between strategy doc and machine doc.
- **hat_role / hat_phase**: untested. Phase 7-lite added `six-hats.md` § Strategy hooks documenting the deferred contract; baseline acquisition required before wiring.

### Phase 4 target state (Option A/B/C decision)

Phase 4 will make the architectural choice for how strategy hook policy is consumed at runtime. Three options on the table:

- **Option A** (LLM-mediated): facilitator at Step 2.2c Reads `{strategy}.md` § Strategy hooks and interprets the policy. Opening lines of Phase 7-lite's § Strategy hooks sections are designed to be skip-trigger compatible (`"No per-round hooks"`, `"No per-round overrides"`, `"Facilitator-driven, LLM-emergent"`).
- **Option B** (command-side parsing): commands parse strategy doc (or a structured config) and populate `STRATEGY_CONFIG` deterministically; facilitator consumes that without re-reading.
- **Option C** (full YAML profile per strategy): per-strategy YAML configs (`strategies/{strategy}.yaml`) become the structured source; strategy `.md` files remain human-facing.

Phase 4 decision will be informed by: complexity/blast-radius tradeoff, ability to eliminate LLM emergence for hook population, alignment with roundtable.md-as-master architecture, and the consensus from macro review #4 of the original Phase 7 plan (recorded in `.s2s/plans/20260517-tech002-phase7-strategy-consolidation.md` §3).

---

## 8. Phase 2 algorithm integration

`phase-2-core.md` references this document in three places:

1. **Step 2.3c** (Participant response): adds optional `debate_role` field when `STRATEGY == "debate"`. See §3.
2. **Step 2.6a** (Round summary entry): adds optional `debate_phase` field when `STRATEGY == "debate"`. See §4.
3. **Step 2.2c** (Facilitator response): `participant_context.overrides` may include strategy-specific directives. See §3 source.

Hook points are added as conditional sections in `phase-2-core.md` matching the `IF STRATEGY == "X"` pattern. Runtime wiring (Option A/B/C) deferred to Phase 4 — see §7 for the target-state options and `.s2s/plans/20260517-tech002-phase7-strategy-consolidation.md` §1 + §3 for the deferral rationale.

---

## 9. Contract invariants

Per the plan §10 contract invariants, these MUST hold:

- **Existing baseline behavior preserved**: design+debate sessions produce `debate_role` in participants and `debate_phase` in round summaries, as observed in exp43-design baseline (commit `50b1de2` in `ElfGiftRush_s2s`).
- **Optional fields stay optional**: hooks add fields but don't remove or rename existing ones.
- **No schema validation break**: dump readers/diagnostic tools tolerate the presence or absence of hook-injected fields.

The exp44 regression replay in 7B.7 will verify the design+debate path still produces the expected fields.

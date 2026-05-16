# Strategy Hooks Contract

> **Status**: contract documentation (TECH-002 Phase 7B.6, 2026-05-16).
> **Scope**: defines WHERE strategy-specific variation injects into the Phase 2 algorithm. Does NOT yet implement strategy-driven wiring — that is Phase 7 territory (strategy skill consolidation).
> **Behavior contract**: preserve current behavior. Strategies still produce the same observable fields (`debate_role`, `debate_phase`, Disney phase machine, etc.) as before 7B.6.

Phase 2 (`phase-2-core.md`) is workflow-aware via `PROFILE` (from `profiles/{workflow}.yaml`). Some workflows additionally support **strategy-specific variations** that inject fields into facilitator/participant/synthesis output. This document inventories those variations and defines the hook contract that Phase 7 will wire.

---

## 1. Strategy inventory

Strategies are defined in `skills/roundtable-strategies/references/{strategy}.md`. The 5 current strategies and their per-round effects on Phase 2:

| Strategy | Workflows | Effect on Phase 2 | Hook points |
|----------|-----------|-------------------|-------------|
| `standard` | specs / design (allowed) | none beyond defaults | — |
| `consensus-driven` | specs (default) / design (allowed) | none beyond defaults (participation: parallel, weighted_majority threshold) | — |
| `debate` | specs (allowed) / design (default) | per-participant Pro/Con assignment + per-round debate phase tracking | §3 debate_role, §4 debate_phase |
| `disney` | brainstorm (forced) | three sequential phases (dreamer/realist/critic) with phase transitions | already extracted to `disney-phase-machine.md` |
| `six-hats` | specs / design (allowed) | six sequential hats (white/red/black/yellow/green/blue), each with focused mindset | §5 hat_role, §6 hat_phase (placeholder — see §7 deferred) |

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

Hooks are **additive**: they extend canonical schemas with extra fields without breaking baseline behavior. Pre-7B.6 commands produced these fields via inline LLM-emergent behavior; post-7B.6 (and pre-Phase 7) the contract is documented but the wiring is unchanged (LLM still emergent).

---

## 3. Hook: `participant_response.debate_role`

| Property | Value |
|----------|-------|
| **Phase 2 step** | Step 2.3c (participant response) |
| **Condition** | `STRATEGY == "debate"` |
| **Field added** | `debate_role: "pro" \| "con"` (top-level in participant dump's `response`) |
| **Source** | Facilitator's Step 2.2c response includes `participant_context.overrides.{participant-id}.debate_role`. Participant receives and echoes it. |
| **Behavior** | Each participant is assigned to either the "pro" or "con" side at session start (or per round). The role drives the participant's argumentation stance. Without this hook, the participant gives a neutral response. |

**Phase 7 wiring direction**: facilitator agent should consult `roundtable-strategies/references/debate.md` to determine Pro/Con assignment policy (alternating per round, fixed for session, etc.) and emit `overrides`. Currently this is LLM-emergent and consistent across rounds.

---

## 4. Hook: `round_summary.debate_phase`

| Property | Value |
|----------|-------|
| **Phase 2 step** | Step 2.6 (Update Session File, round summary entry) |
| **Condition** | `STRATEGY == "debate"` |
| **Field added** | `debate_phase: "opening" \| "rebuttal" \| "closing" \| "synthesis"` (optional field in `rounds[].` entry) |
| **Source** | Facilitator's Step 2.4c synthesis response: `next_focus.debate_phase` or inferred from facilitator's current debate progression. |
| **Behavior** | The round summary records which debate phase was active. Enables audit ("round 3 was the rebuttal") and informs Step 2.7 round recap display. |

**Phase 7 wiring direction**: debate strategy's phases (`opening → rebuttal → closing → synthesis`) form a state machine similar to Disney's, but currently informally tracked. Phase 7 may extract a `debate-phase-machine.md` mirroring `disney-phase-machine.md`. For 7B.6 the field is optional and LLM-driven.

---

## 5. Hook: `participant_response.hat_role` (six-hats — deferred)

| Property | Value |
|----------|-------|
| **Phase 2 step** | Step 2.3c (participant response) |
| **Condition** | `STRATEGY == "six-hats"` |
| **Field added** | `hat_role: "white" \| "red" \| "black" \| "yellow" \| "green" \| "blue"` |
| **Source** | Facilitator's `participant_context.overrides.{participant-id}.hat_role`. |
| **Behavior** | Each participant is assigned a thinking hat that drives their mindset (facts, emotions, criticism, positive, creative, process). |

**Status**: NOT observed in current dogfood baselines (six-hats has never been used). Hook is documented for completeness but unverified empirically. Phase 7 will wire and exercise.

---

## 6. Hook: `round_summary.hat_phase` (six-hats — deferred)

| Property | Value |
|----------|-------|
| **Phase 2 step** | Step 2.6 |
| **Condition** | `STRATEGY == "six-hats"` |
| **Field added** | `hat_phase: "blue-opening" \| "white-hat" \| ... \| "blue-closing"` |
| **Source** | Facilitator's synthesis decision. |
| **Behavior** | Records which hat was active. |

**Status**: same as §5 — deferred to Phase 7.

---

## 7. Where strategy data CURRENTLY comes from vs. WILL come from

### Current state (post-7B.6, pre-Phase 7)

- **debate_role / debate_phase**: emerge from the LLM (facilitator agent and participant agents) interpreting `STRATEGY == "debate"` from input. No formal source of truth for the assignment policy beyond `roundtable-strategies/references/debate.md`'s phase descriptions.
- **disney phases**: machine fully extracted to `disney-phase-machine.md`. Phase transitions deterministic.
- **hat_role / hat_phase**: untested.

### Phase 7 target state

- **Strategy skill consolidation**: each strategy's reference doc (`roundtable-strategies/references/{strategy}.md`) becomes the source of truth for hooks. Commands and `phase-2-core.md` Read the active strategy's doc and apply its hooks.
- **debate.md** should formalize: Pro/Con assignment policy, phase progression, when overrides fire.
- **six-hats.md** should formalize: hat assignment per round/per participant.
- **disney.md** already has phase machine — could integrate with `disney-phase-machine.md`.

---

## 8. Phase 2 algorithm integration

`phase-2-core.md` references this document in three places:

1. **Step 2.3c** (Participant response): adds optional `debate_role` field when `STRATEGY == "debate"`. See §3.
2. **Step 2.6a** (Round summary entry): adds optional `debate_phase` field when `STRATEGY == "debate"`. See §4.
3. **Step 2.2c** (Facilitator response): `participant_context.overrides` may include strategy-specific directives. See §3 source.

Hook points are added as conditional sections in `phase-2-core.md` matching the `IF STRATEGY == "X"` pattern from §11 Option III of the plan.

---

## 9. Contract invariants

Per the plan §10 contract invariants, these MUST hold:

- **Existing baseline behavior preserved**: design+debate sessions produce `debate_role` in participants and `debate_phase` in round summaries, as observed in exp43-design baseline (commit `50b1de2` in `ElfGiftRush_s2s`).
- **Optional fields stay optional**: hooks add fields but don't remove or rename existing ones.
- **No schema validation break**: dump readers/diagnostic tools tolerate the presence or absence of hook-injected fields.

The exp44 regression replay in 7B.7 will verify the design+debate path still produces the expected fields.

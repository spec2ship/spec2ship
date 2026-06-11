# Strategy Hooks Contract

> **Status**: contract documented (TECH-002 Phase 7-lite, 2026-05-18) and wired via **Option B** (TECH-002 Phase 4, 2026-05-21). See `strategy-hook-resolution.md` for the 3-branch dispatch and `strategy-resolution.md` for the D3 resolution hierarchy. ADR-0011 Phase 4 addendum records the architectural decision.
> **Scope**: defines WHERE strategy-specific variation injects into the Phase 2 algorithm. The contract is stable; runtime wiring uses Option B (command-side parsing in `commands/roundtable.md` PHASE 1, hook_overrides populated and passed via session.yaml and agent input).
> **Behavior contract**: preserve baseline behavior. Strategies still produce the same observable fields (`debate_role`, `debate_phase`, Disney phase machine, etc.); Option B makes the population path explicit instead of LLM-emergent.

Phase 2 (`phase-2-core.md`) is workflow-aware via `PROFILE` (from `profiles/{workflow}.yaml`). Some workflows additionally support **strategy-specific variations** that inject fields into facilitator/participant/synthesis output. This document inventories those variations and defines the hook contract; the wiring is implemented via Option B (per-session `hook_overrides` populated at PHASE 1 in `roundtable.md`).

---

## 1. Strategy inventory

Strategies are defined in `skills/roundtable-strategies/references/{strategy}.md`. The 5 current strategies and their per-round effects on Phase 2:

| Strategy | Workflows | Effect on Phase 2 | Hook points | Strategy doc § Strategy hooks |
|----------|-----------|-------------------|-------------|-------------------------------|
| `standard` | specs / design (allowed) | none beyond defaults | (none, `skip`) | `standard.md` § Strategy hooks ("No per-round hooks") |
| `consensus-driven` | specs (default) / design (allowed) | none beyond defaults (participation: parallel, weighted_majority threshold) | (none, `skip`) | `consensus-driven.md` § Strategy hooks ("No per-round hooks") |
| `debate` | specs (allowed) / design (default) | per-participant Pro/Con assignment + per-round debate phase tracking | §3 debate_role, §4 debate_phase | `debate.md` § Strategy hooks (facilitator_emergent policy, fields populated via hook_overrides) |
| `disney` | brainstorm (forced) | three sequential phases (dreamer/realist/critic) with phase transitions | already extracted to `disney-phase-machine.md` | `disney.md` § Strategy hooks (phase machine via Step 2.10; no Step 2.2c overrides) |
| `six-hats` | specs / design (allowed) | six sequential hats (white/red/black/yellow/green/blue), each with focused mindset | §5 hat_role, §6 hat_phase (untested baseline) | `six-hats.md` § Strategy hooks (No per-round overrides; baseline acquisition pending) |

Disney is a complete machine, not a per-round hook (extracted to its own doc). The remaining hooks (§3-§6) are per-round inject points.

---

## 2. Hook contract

Each hook is a **named, optional injection point** in the Phase 2 algorithm. The contract:

- **Hook name**: identifies the hook (e.g., `participant_response.debate_role`).
- **Phase 2 step**: where the hook applies (e.g., Step 2.3c).
- **Condition**: when the hook activates (e.g., `STRATEGY == "debate"`).
- **Field added**: what gets added to the canonical schema (e.g., `debate_role` in participant response).
- **Source**: where the value comes from (`hook_overrides` field in session.yaml, populated by `roundtable.md` PHASE 1 per strategy doc § Strategy hooks).
- **Behavior contract**: what the LLM/agent does when the hook fires.

Hooks are **additive**: they extend canonical schemas with extra fields without breaking baseline behavior. Population path: `roundtable.md` PHASE 1 reads `roundtable-strategies/references/{strategy}.md` § Strategy hooks, computes the `hook_overrides` dict, and writes it to `session.yaml`. Step 2.2c dispatches on the dict via the 3-branch logic in `strategy-hook-resolution.md` (skip / policy / absent).

---

## 3. Hook: `participant_response.debate_role`

| Property | Value |
|----------|-------|
| **Phase 2 step** | Step 2.3c (participant response) |
| **Condition** | `STRATEGY == "debate"` |
| **Field added** | `debate_role: "pro" \| "con"` (top-level in participant dump's `response`) |
| **Source** | `hook_overrides.participant_response.debate_role` from session.yaml; facilitator emits per-participant assignment in Step 2.2c via `participant_context.overrides.{participant-id}.debate_role`. |
| **Behavior** | The facilitator assigns each participant a "pro" or "con" role per round (TECH-011: no static session-start split). The role drives the participant's argumentation stance. Without this hook, the participant gives a neutral response. |

**Wiring**: Option B (Phase 4). `roundtable.md` PHASE 1 populates `hook_overrides.participant_response.debate_role.policy = "facilitator_emergent"` per `debate.md` § Strategy hooks. Facilitator agent consumes the policy at Step 2.2c via the dispatch in `strategy-hook-resolution.md`. Promote to a deterministic rule once empirical baseline justifies.

---

## 4. Hook: `round_summary.debate_phase`

| Property | Value |
|----------|-------|
| **Phase 2 step** | Step 2.6 (Update Session File, round summary entry) |
| **Condition** | `STRATEGY == "debate"` |
| **Field added** | `debate_phase: "opening" \| "rebuttal" \| "closing" \| "synthesis"` (optional field in `rounds[].` entry) |
| **Source** | Facilitator's Step 2.4c synthesis response: `next_focus.debate_phase` or inferred from facilitator's current debate progression. |
| **Behavior** | The round summary records which debate phase was active. Enables audit ("round 3 was the rebuttal") and informs Step 2.7 round recap display. |

**Wiring**: Option B (Phase 4) leaves debate phase progression as facilitator-emergent (still LLM-driven); the field remains optional. A future enhancement may extract a `debate-phase-machine.md` mirroring `disney-phase-machine.md`, but the Option B parser does not block that work.

---

## 5. Hook: `participant_response.hat_role` (six-hats, untested baseline)

| Property | Value |
|----------|-------|
| **Phase 2 step** | Step 2.3c (participant response) |
| **Condition** | `STRATEGY == "six-hats"` |
| **Field added** | `hat_role: "white" \| "red" \| "black" \| "yellow" \| "green" \| "blue"` |
| **Source** | `hook_overrides.participant_response.hat_role` per `six-hats.md` § Strategy hooks. |
| **Behavior** | Each participant is assigned a thinking hat that drives their mindset (facts, emotions, criticism, positive, creative, process). |

**Status**: NOT observed in current dogfood baselines (six-hats has never been used). Hook is documented for completeness but unverified empirically. Wiring via Option B is a configuration-only change once a baseline is captured (`/s2s:design --strategy six-hats --verbose --diagnostic` structural summary first).

---

## 6. Hook: `round_summary.hat_phase` (six-hats, untested baseline)

| Property | Value |
|----------|-------|
| **Phase 2 step** | Step 2.6 |
| **Condition** | `STRATEGY == "six-hats"` |
| **Field added** | `hat_phase: "blue-opening" \| "white-hat" \| ... \| "blue-closing"` |
| **Source** | Facilitator's synthesis decision. |
| **Behavior** | Records which hat was active. |

**Status**: same as §5. Baseline acquisition is the prerequisite; the Option B parser handles six-hats hook_overrides identically to debate.

---

## 7. Wiring history

### Current state (post Phase 4, 2026-05-21)

- **debate_role / debate_phase**: `roundtable.md` PHASE 1 populates `hook_overrides` per `debate.md` § Strategy hooks; facilitator and participant agents consume via the 3-branch dispatch in `strategy-hook-resolution.md`. Current policy is `facilitator_emergent` (LLM picks the role/phase values; field names provided via hook_overrides). Branch 3 (`hook_overrides` absent) is the backward-compat fallback for pre-Phase-4 resumed sessions.
- **disney phases**: machine fully extracted to `disney-phase-machine.md`. Phase transitions deterministic via `phase-2-core.md` Step 2.10. Bidirectional cross-link with `disney.md` § Strategy hooks.
- **hat_role / hat_phase**: contract documented; wiring path identical to debate. Empirical baseline required before regression coverage.

### Pre-Phase-4 history

Pre-7B.6 commands produced these fields via inline LLM-emergent behavior with no explicit contract. Phase 7B.6 introduced this document. Phase 7-lite added uniform `## Strategy hooks` sections in each `{strategy}.md`. Phase 4 added Option B parser + `strategy-hook-resolution.md` + ADR-0011 Phase 4 addendum.

**Option B vs. alternatives considered in Phase 4** (recorded in ADR-0011 Phase 4 addendum):

- **Option A** (LLM-mediated): facilitator Reads `{strategy}.md` at Step 2.2c. Rejected: doesn't eliminate LLM emergence; cache cost.
- **Option B** (command-side parsing): selected. Master parses `{strategy}.md` § Strategy hooks at PHASE 1 and emits `hook_overrides` deterministically.
- **Option C** (full YAML profile per strategy): not adopted now; an additive future migration if structured config becomes load-bearing.

---

## 8. Phase 2 algorithm integration

`phase-2-core.md` references this document in three places:

1. **Step 2.3c** (Participant response): adds optional `debate_role` field when `STRATEGY == "debate"`. See §3.
2. **Step 2.6a** (Round summary entry): adds optional `debate_phase` field when `STRATEGY == "debate"`. See §4.
3. **Step 2.2c** (Facilitator response): `participant_context.overrides` may include strategy-specific directives. See §3 source.

Hook points are conditional sections in `phase-2-core.md` matching the `IF STRATEGY == "X"` pattern. Runtime wiring (Option B) is documented in `strategy-hook-resolution.md` (3-branch dispatch: skip, policy dict, absent).

---

## 9. Contract invariants

Per the plan §10 contract invariants, these MUST hold:

- **Existing baseline behavior preserved**: design+debate sessions produce `debate_role` in participants and `debate_phase` in round summaries, as observed in exp43-design baseline and re-verified in exp44 (post-7B) and exp52 (post-Phase-4 master path with Branch 2 hook_overrides populated).
- **Optional fields stay optional**: hooks add fields but don't remove or rename existing ones.
- **No schema validation break**: dump readers/diagnostic tools tolerate the presence or absence of hook-injected fields.
- **Backward compatibility**: Branch 3 (absent `hook_overrides`) restores pre-Phase-4 LLM-emergent behavior for resumed sessions.

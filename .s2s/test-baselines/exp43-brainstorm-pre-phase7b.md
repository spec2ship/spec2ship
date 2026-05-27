# Pre-Phase 7B: /s2s:brainstorm structural baseline

**Captured**: 2026-05-13
**Source**: dogfood worktree (local, not in this repo)
**Plugin commit under test**: `0274b4a` (TECH-002 Phase 3 merged in develop)
**Dogfood commit (baseline)**: `ff712e8` on branch `exp43-brainstorm` (and tag `exp43-brainstorm`) in `ElfGiftRush_s2s`
**Compared against**: none — this is the **first brainstorm baseline** ever recorded
**Purpose**: capture pre-Phase 7B fingerprint so the upcoming `exp44-brainstorm` replay can prove no behavioral regression after the executable extraction.

---

## Run conditions

| Variable | Value |
|----------|-------|
| Command | `/s2s:brainstorm --verbose --diagnostic --topic "improvements for the ElfGiftRush game"` |
| Strategy | `disney` (forced — brainstorm always uses disney) |
| Participants | product-manager, software-architect, technical-lead, devops-engineer (default) |
| Mode | autonomous |
| Workflow_type | `brainstorm` |

## Schema invariants — recorded

| Invariant | Observed |
|-----------|----------|
| Session top-level keys | 13 → `id, topic, workflow_type, strategy, status, timing, agent_state, artifacts, current_phase, phases, rounds, metrics, validation` |
| Difference vs specs/design | replaces `agenda` with `current_phase` + `phases` (workflow profile §1, expected) |
| Status at session close | `closed` |
| Rounds completed | 3 (1 per Disney phase) |
| Disney phase progression | `dreamer → realist → critic`, all 3 marked `completed` |
| `next_action` per round | round 1: `phase`, round 2: `phase`, round 3: `conclude` (correct Disney machine flow) |
| Verbose dump filename pattern | matches `{NNN}-{PP}-{actor}.yaml` regex 18/18 |
| Dump files per round | 6 (1 facilitator-question + 4 participants + 1 facilitator-synthesis) |
| Total verbose dumps | 18 = 3 × 6 |
| Question dump top-keys | `action, actor, completed_at, disney_phase, input, phase, response, result, round, started_at, tokens` |
| Synthesis dump top-keys | same + `verification` (mandatory block present 3/3 ✓) |
| Synthesis `result.conflicts_resolved` | present 3/3 ✓ (Phase 3 FIX-3 preserved) |
| Participant dump top-keys | same as question (with `disney_phase`) |
| Participant `response` keys | canonical 8 fields + `ideas` (workflow-specific, dreamer phase) |
| `disney_phase` field in dumps | present in question/participant/synthesis 18/18 ✓ |
| Validation warnings | none |
| Outputs generated | `.s2s/sessions/{id}-summary.md`, `.s2s/ideas.md` updated |

## Metric snapshot

| Metric | Value |
|--------|-------|
| Artifacts total | 49 |
| IDEA-* (ideas) | 18 |
| RISK-* (risks) | 14 |
| MIT-* (mitigations) | 14 |
| OQ-* (open_questions) | 3 |
| CONF-* (conflicts) | 0 |
| Phases.dreamer | 1 round |
| Phases.realist | 1 round |
| Phases.critic | 1 round |
| Consensus rate | 1.0 |
| Tokens total | ~40,000 |

## Findings (workflow-specific observations)

| Finding | Observation |
|---------|-------------|
| **B1: `agent_id` field placement drift** | Brainstorm dumps do NOT have `agent_id` at top level (specs/design do). It is placed inside `result` for synthesis and inside `response` for participant. **Pre-existing drift** vs specs/design schema. Candidate for Phase 7B normalization OR mark as workflow-specific. To be reconciled in 7B.4 via profile schema decision. |
| **B2: CONF-* never created** | 0 conflicts in this run. `CONF-*` artifact type is documented but rarely instantiated in autonomous brainstorm runs (LLMs tend to agree across Disney phases). |
| **B3: Disney phase machine works correctly** | Phase transitions follow `dreamer → realist → critic` and conclude only at critic phase. Must be preserved by Phase 7B Disney machine extraction (§7B.5). |
| **B4: `verification` block always emitted** | All 3 synthesis dumps include the full canonical verification block. No emission instability for brainstorm path either. |
| **B5: `ideas` field in participant response (dreamer phase)** | Dreamer phase participants include `ideas` array in response. Workflow-specific extension to the canonical response schema. Must be preserved by 7B.4 (profile-aware response handling). |

## Pass criteria for exp44-brainstorm replay (post-7B)

- Schema invariants from the table above must be identical.
- `rounds_completed` must equal 3.
- Disney phase progression `dreamer → realist → critic` with `completed` status for all 3.
- `next_action` sequence must be `phase, phase, conclude`.
- `artifacts.total` within ±5 of 49 (Disney phases are looser; allow larger nondeterminism than specs/design).
- All 3 synthesis dumps must contain `verification` block with all 5 sub-keys.
- `disney_phase` field must appear in 18/18 dumps.
- 18 dump files, no missing entries.
- `result.conflicts_resolved` present in 3/3 synthesis dumps.
- `agent_id` placement: preserve current behavior unless explicitly normalized (B1).

## Reproducibility

To re-run from this baseline:
```bash
cd ~/Repositories/ElfGiftRush_s2s/exp43
git checkout 15484d4  # post-Phase 3 specs baseline
# install spec2ship plugin at develop@0274b4a
/s2s:brainstorm --verbose --diagnostic --topic "improvements for the ElfGiftRush game"
```

To inspect baseline contents:
```bash
cd ~/Repositories/ElfGiftRush_s2s/exp43
git checkout exp43-brainstorm   # branch or tag
ls .s2s/sessions/20260513-brainstorm-improvements-elfgiftrush/
```

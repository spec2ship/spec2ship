# Pre-Phase 7B: /s2s:design structural baseline

**Captured**: 2026-05-13
**Source**: dogfood worktree (local, not in this repo)
**Plugin commit under test**: `0274b4a` (TECH-002 Phase 3 merged in develop)
**Dogfood commit (baseline)**: `50b1de2` on branch `exp43-design` (and tag `exp43-design`) in `ElfGiftRush_s2s`
**Compared against**: none — this is the **first design baseline** ever recorded
**Purpose**: capture pre-Phase 7B fingerprint so the upcoming `exp44-design` replay can prove no behavioral regression after the executable extraction.

---

## Run conditions

| Variable | Value |
|----------|-------|
| Command | `/s2s:design --verbose --diagnostic` |
| Strategy | `debate` (workflow default) |
| Participants | software-architect, security-champion, technical-lead, devops-engineer |
| Topic | `Architecture design for ElfGiftRush` (auto-derived from CONTEXT.md) |
| Mode | autonomous (no user prompts) |
| Workflow_type | `design` |

## Schema invariants — recorded

| Invariant | Observed |
|-----------|----------|
| Session top-level keys | 12 → `id, topic, workflow_type, strategy, status, timing, agent_state, artifacts, agenda, rounds, metrics, validation` |
| Status at session close | `closed` |
| Rounds completed | 3 |
| Verbose dump filename pattern | matches `{NNN}-{PP}-{actor}.yaml` regex 18/18 |
| Dump files per round | 6 (1 facilitator-question + 4 participants + 1 facilitator-synthesis) |
| Total verbose dumps | 18 = 3 × 6 |
| Question dump top-keys | `action, actor, agent_id, completed_at, input, phase, response, result, round, started_at, tokens` |
| Synthesis dump top-keys | same + `verification` (mandatory block present 3/3 ✓) |
| Synthesis `result.conflicts_resolved` | present 3/3 ✓ (Phase 3 FIX-2 preserved) |
| Synthesis `verification` sub-keys | `expected_artifacts, round_summary, agenda_status, metrics_consistency, context_propagation` (all 5 present 3/3) |
| Participant dump top-keys | same as question + `debate_role` (debate strategy field) |
| Participant `response` keys | `participant, position, rationale, trade_offs, concerns, suggestions, confidence, references` (8 fields, canonical) |
| Validation warnings | none |
| Outputs generated | `.s2s/architecture.md` (present), `.s2s/decisions/ADR-*.md` (10 files) |

## Metric snapshot

| Metric | Value |
|--------|-------|
| Artifacts total | 30 |
| ARCH-* (architecture_decisions) | 10 |
| COMP-* (components) | 18 |
| INT-* (interfaces) | **0** |
| OQ-* (open_questions) | 2 |
| CONF-* (conflicts) | 0 |
| Agenda topics total | 5 |
| Agenda topics closed | 5 |
| Consensus rate | 1.0 |
| Tokens total | ~46,000 |

## Findings (workflow-specific observations)

| Finding | Observation |
|---------|-------------|
| **D1: INT-* never created** | Despite design profile defining `INT-*` artifact type, 0 interfaces were generated in this run. Predates Phase 7B (BACKLOG out-of-scope item). |
| **D2: `debate_role` field present** | Each participant dump has `debate_role` field (debate strategy specific). Confirms strategy hook works in current command. Must be preserved by Phase 7B strategy hooks (§7B.6). |
| **D3: `verification` block always emitted** | All 3 synthesis dumps include the full canonical verification block. No emission instability observed for design path. |
| **D4: session-observer per-round activation** | TBD — 7B.7 will compare against exp44 to detect regression vs this baseline. |

## Pass criteria for exp44-design replay (post-7B)

- Schema invariants from the table above must be identical.
- `rounds_completed` must equal 3.
- `artifacts.total` within ±2 of 30 (LLM nondeterminism allowance).
- All 3 synthesis dumps must contain `verification` block with all 5 sub-keys.
- `debate_role` field must still appear in each participant dump.
- 18 dump files, no missing entries.
- `result.conflicts_resolved` present in 3/3 synthesis dumps.

## Reproducibility

To re-run from this baseline:
```bash
cd ~/Repositories/ElfGiftRush_s2s/exp43
git checkout 15484d4  # post-Phase 3 specs baseline
# install spec2ship plugin at develop@0274b4a
/s2s:design --verbose --diagnostic
```

To inspect baseline contents:
```bash
cd ~/Repositories/ElfGiftRush_s2s/exp43
git checkout exp43-design   # branch or tag
ls .s2s/sessions/20260512-design-elfgiftrush/
```

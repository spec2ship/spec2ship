# Post-Phase 3: /s2s:specs structural verification

**Captured**: 2026-05-05
**Source**: dogfood worktree (local, not in this repo)
**Commit under test**: `9f160e5` (TECH-002 Phase 3 drift fixes)
**Compared against**: [`exp42-specs-pre-phase3.md`](exp42-specs-pre-phase3.md) (commit `516f040`)
**Purpose**: confirm Phase 3 drift fixes preserve schema invariants and surface side-effects on baseline findings F1/F2/F3.

---

## Run conditions

| Variable | Pre-Phase 3 (exp42) | Post-Phase 3 (exp43) |
|----------|---------------------|----------------------|
| Command | `/s2s:specs --verbose --diagnostic` | identical |
| Topic | none (CONTEXT.md fallback) | identical |
| User OQ answers | 3 OQs answered interactively | **none** (autonomous run) |
| Strategy | `consensus-driven` | identical |

The run-mode delta (no user OQ answers) is the **primary explanation** for the metric divergences below. It is not a Phase 3 regression.

## Schema invariants — all preserved ✅

| Invariant | Pre | Post |
|-----------|-----|------|
| Session top-level keys | 12 | 12 (identical set) |
| Verbose dump filename pattern (regex) | match | 24/24 match |
| Dump top-level keys | `round, phase, actor, action, started_at, completed_at, agent_id, input, response, result` (+ `tokens` for participants) | identical |
| Participant response sub-keys | `participant, position, rationale, trade_offs, concerns, suggestions, confidence, references` | identical |
| Synthesis `result.conflicts_resolved` | sometimes missing | **always present** (FIX-2/3 effect) |
| Validation warnings | empty | empty |
| `requirements.md` SRS sections | 10 | identical structure |

## Phase 3 fix verification ✅

| Fix | Verification path | Status |
|-----|-------------------|--------|
| FIX-1 verification schema canonical (design only — not exercised by specs) | template alignment | ✓ template canonical |
| FIX-2/3 `conflicts_resolved` in synthesis result | grep `result:` block in 4/4 synthesis dumps | ✓ present |
| FIX-4 brainstorm dump fields (not exercised by specs) | n/a | n/a |
| FIX-5/A `{Role}` header | dump header expansion (`Product Manager Response`, etc.) | ✓ |
| FIX-6 specs Step 2.9 `min_rounds (from config)` | session ran 4 rounds > min=3, conclude legitimate | ✓ |

## Findings F1/F2/F3 — re-evaluation

| Finding | Pre (exp42) | Post (exp43) | Delta |
|---------|-------------|--------------|-------|
| **F1** participant_context propagation in dumps | 3/18 (17%) | 4/24 (17%) | unchanged (Phase 3 did not target it) |
| **F2** session-observer Step 2.6c per-round | 0/3 + 1 end-session | **1/4** + 1 end-session | partial improvement; rounds 2-4 still skip |
| **F3** token `actual` measured per round | 1/3 | **3/4** | notable improvement (free benefit, likely Phase 6b interaction) |

## Explainable metric divergences (run-mode artifact)

| Metric | exp42 | exp43 | Cause |
|--------|-------|-------|-------|
| Rounds | 3 | 4 | autonomous run did one extra round; OQs deferred not resolved |
| REQ count | 14 | 14 | identical |
| BR count | 8 | 8 | identical |
| NFR count | 21 | 12 | exp42 user answered platform-OQ → derived more NFR; exp43 deferred |
| EX count | 15 | 3 | same root cause |
| OQ deferred | 0 | 4 | autonomous run cannot resolve OQs; deferred is correct behavior |

## Verdict

Phase 3 drift fixes verified. No schema regression. Pre-existing baseline findings F1/F2/F3:
- F1 unchanged (not targeted)
- F2 partially improved as side effect (Phase 7B candidate to fully fix)
- F3 substantially improved (Phase 6b alignment side effect)

The `verification:` block in synthesis dumps (already inconsistent in exp42 at 2/3) was emitted 0/4 in exp43 — pre-existing optionality issue in the template, not introduced by Phase 3. Candidate for Phase 7B (mark `verification` block as MANDATORY).

## Comparison protocol used

See [`exp42-specs-pre-phase3.md` § Comparison protocol](exp42-specs-pre-phase3.md). All 9 listed checks executed; pass criteria met for all schema invariants. Artifact-count divergences explained by run-mode delta (autonomous vs interactive).

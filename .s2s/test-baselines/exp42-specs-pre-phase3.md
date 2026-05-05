# Baseline: /s2s:specs (pre-Phase 3 of TECH-002)

**Captured**: 2026-05-05
**Source**: `ElfGiftRush_s2s/exp42` worktree, branch `exp42`
**Commit**: `516f040 baseline: /s2s:specs --verbose --diagnostic (no topic, CONTEXT.md fallback)`
**spec2ship branch under test**: `feature/TECH-002-roundtable-unification` (pre-Phase 3)
**Purpose**: Frozen reference to compare against `exp43` post-Phase 3 replay.

---

## Run conditions

| Variable | Value |
|----------|-------|
| Working dir | `ElfGiftRush_s2s/exp42` (git worktree) |
| Init baseline | commit `af9af48` (identical in exp42 and exp43) |
| Command | `/s2s:specs --verbose --diagnostic` |
| Topic argument | none (Smart Source Detection → CONTEXT.md fallback) |
| Strategy | `consensus-driven` (from config default) |
| Source detection | no brainstorm, no active ideas, no planned BACKLOG → CONTEXT.md only |
| User decisions | OQ-001 web/desktop+responsive, OQ-002 accept persona, OQ-003 WCAG 2.2 AA subset |

## Session metadata

| Field | Value |
|-------|-------|
| Session ID | `20260505-specs-elfgiftrush` |
| Workflow type | `specs` |
| Strategy | `consensus-driven` |
| Status | `closed` |
| Rounds completed | 3 |
| Participants | 4 (business-analyst, product-manager, qa-lead, ux-researcher) |

## Session YAML schema (top-level keys)

```
id, topic, workflow_type, strategy, status,
timing, agent_state, artifacts, agenda, rounds, metrics, validation
```

Section sizes (lines): `artifacts: 761`, `rounds: 208`, `agenda: 56`, `metrics: 39`, `agent_state: 20`, `timing: 6`, `validation: 4`. Total: 1103 lines.

## Artifacts produced

| Type | Count | IDs |
|------|-------|-----|
| Functional Requirements | 14 | REQ-001..014 |
| Business Rules | 8 | BR-001..008 |
| Non-Functional Requirements | 21 | NFR-{PERF×5, REL×4, COMPAT×5, A11Y×5, USA×2} |
| Exclusions | 15 | EX-001..015 |
| Open Questions (resolved) | 4 | OQ-001..004 |
| **Total** | **62** | |

`metrics.by_state`: approved=58, resolved=4, hybrid_resolved=1. `consensus_rate: 0.92`.

## Round structure (per round)

Each round produces 6 verbose dump files with stable naming:

```
{NNN}-01-facilitator-question.yaml      ← phase 1
{NNN}-02-business-analyst.yaml          ← phase 2 (participant)
{NNN}-02-product-manager.yaml           ← phase 2
{NNN}-02-qa-lead.yaml                   ← phase 2
{NNN}-02-ux-researcher.yaml             ← phase 2
{NNN}-03-facilitator-synthesis.yaml     ← phase 3
```

Total verbose dumps: **18** (3 rounds × 6 files).

Round in session YAML has these keys: `round, timestamp, topic_id, facilitator_question, synthesis_summary, participant_positions, key_decisions, artifacts_created, resolved_conflicts, resolved_questions, consensus_reached, next_action`.

## Verbose dump structure

**Common top-level keys** (all dumps): `round, phase, actor, action, started_at, completed_at, agent_id, input, response, result`. Participant dumps add: `tokens` (input_estimate, output_estimate).

**Participant `response` sub-keys**: `participant, position, rationale, trade_offs, concerns, suggestions, confidence, references`.

**File line counts** (representative): facilitator-question 49-85, participant 40-75, synthesis 105-167. Mean ~58 lines.

## Output document (`requirements.md`)

**Format**: IEEE 830 / SRS-aligned, 562 lines.

**Sections**:
1. Introduction (Purpose, Scope, Persona, Platform)
2. Functional Requirements (REQ-001..014)
3. Business Rules (BR-001..008)
4. Non-Functional Requirements (PERF, Reliability, Compatibility, A11Y, Usability)
5. Round State Machine
6. Resolved Open Questions (OQ-001..004)
7. Exclusions (Out of Scope)
8. Coverage Map
9. Working Assumptions
10. Source

## Token tracking

| Round | Estimate | Actual | Source |
|-------|----------|--------|--------|
| 1 | 24,569 | 46,553 | measured |
| 2 | 34,486 | null | estimated |
| 3 | 38,000 | null | estimated |

Round 3 notes captured by the LLM: *"Opus 1M context model in use — prior 200k SHOULD_STOP/SHOULD_WARN heuristics inappropriate; flagged in Task #9 for plugin update"*.

## Validation

`validation.warnings: []` (no warnings produced). `validation.last_check: null`.

---

## Findings flagged for Phase 3 (potential regressions to watch)

These are observations from the baseline that the post-Phase 3 replay should match (or, if they reveal a current bug, that Phase 3 may legitimately fix — to be decided in review):

### F1. `participant_context` present in only 3/18 verbose dumps

Files containing `participant_context`:
```
001-01-facilitator-question.yaml
001-03-facilitator-synthesis.yaml
002-01-facilitator-question.yaml
```

The 12 participant response dumps and the round-3 facilitator dumps don't contain it.

**Relevance**: BUG-003 / CTX-001..005 in `roundtable-tests.md` specifically check `participant_context` propagation. This baseline shows partial coverage. Phase 3 should at minimum preserve this (not lose where present); ideally, this is the kind of thing a unification would fix by uniformizing the propagation logic.

### F2. `--diagnostic` partially executed; Step 2.6c skipped 3/3 times

Investigated by reading the user's CC transcript at `~/.claude/projects/-Users-fvadicamo-Repositories-ElfGiftRush-s2s-exp42/fac05be1-baf2-41ed-b821-d20f2698379e.jsonl`.

**Two-part finding**:

**F2a — by design**: `session-observer` output is **displayed**, not persisted. Both `references/diagnostic.md` and `specs.md:1560,1614` instruct "Display observer result" / "Display final diagnostic report". The session YAML schema has no `diagnostic` field. So absence of diagnostic content in `session.yaml` is correct behavior, not a bug.

**F2b — real gap**: Per-round Step 2.6c **did not execute**. Transcript analysis:

```
"subagent_type":"s2s:validation:session-observer"  →  count: 1
```

Only **one** observer invocation in the whole session (the end-session Step 3.0). The expected behavior is **3 per-round invocations + 1 end-session = 4 total**. Step 2.6c was silently skipped after each of the 3 rounds.

The DIAGNOSTIC REPORT box was rendered once (Step 3.0 worked). The per-round `[DIAGNOSTIC] Round N: ...` lines never appeared.

Other agent invocations match expectations (18 verbose dumps = 6 facilitator + 12 participants), confirming Phase 2 itself executed normally. The skip is specific to Step 2.6c.

**Likely cause** (hypothesis, not verified): the instruction `**IF** diagnostic_flag == true:` at `specs.md:1540` may not be strong enough for the LLM to consistently honor inside the auto-continuation loop (TECH-002 Phase 6b explicitly added rules to prevent stopping mid-loop, which may have over-corrected and caused conditional steps to be elided too).

**Relevance for Phase 3**: this IS a candidate for Phase 3 to address. Step 2.6c is one of the per-round steps that Phase 3 will uniformize across specs/design/brainstorm. If the unified version uses a stronger activation pattern (e.g., explicit "YOU MUST execute" wording per Phase 6b token tracking), this gap closes as a side effect.

**Action**: track in the baseline; verify in exp43 post-Phase 3 whether Step 2.6c fires 3/3 times.

### F3. Token tracking precision regresses after R1

Only round 1 has `actual` measured tokens. R2 and R3 fall back to `estimate` only. The LLM noted that the Opus 1M context heuristics in the codebase are stale (200k thresholds).

**Relevance**: TECH-009 ("progressive precision") was supposed to address this. The note in R3 indicates a known gap. Not a Phase 3 target either, but worth tracking.

---

## Comparison protocol for exp43 post-Phase 3

When Phase 3 of TECH-002 is done, replay in exp43:

```bash
cd /Users/fvadicamo/Repositories/ElfGiftRush_s2s/exp43
/s2s:specs --verbose --diagnostic    # SAME flags, NO topic, same OQ answers
git add .s2s/ && git commit -m "post-phase3: /s2s:specs replay"
```

Then diff against this baseline:

| Check | Method | Pass criteria |
|-------|--------|---------------|
| Session schema | top-level keys | identical set |
| Round count | `grep -c "^  - round:"` | 3 (assuming same OQs answered same way) |
| Verbose dump count | `ls rounds/ \| wc -l` | 18 |
| Verbose dump filename pattern | regex `\d+-\d+-{actor}.yaml` | preserved |
| Verbose dump top-level keys | `grep -E "^[a-z_]+:"` per file | identical set |
| Participant `response` sub-keys | sub-key list | preserved |
| Artifacts by type counts | `metrics.by_type` | within ±2 per type (LLM variance) |
| `requirements.md` section structure | `grep -E "^#"` | section headings preserved |
| Validation warnings | `validation.warnings` | empty in both, OR matched set |

**NOT compared**: artifact text content, prompt wording, exact NFR/REQ count (LLM nondeterminism). Only schema and structural invariants.

## Files involved

- Baseline source: `/Users/fvadicamo/Repositories/ElfGiftRush_s2s/exp42/.s2s/`
- Comparison target (post-Phase 3): `/Users/fvadicamo/Repositories/ElfGiftRush_s2s/exp43/.s2s/`
- Spec2ship branch: `feature/TECH-002-roundtable-unification` @ commit before Phase 3 starts

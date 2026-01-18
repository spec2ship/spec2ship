# Unify Session Validation in Single Agent with Script-First Approach

## Status

accepted

## Context and Problem Statement

The `/s2s:session:validate` command had grown to include 4 validation phases with 20+ checks across different `--level` flags (structural, deep, strategy, diagnostic). Analysis revealed that many checks were:

1. **Ineffective for LLM** - Required cross-round memory or massive context
2. **Dependent on non-existent data** - Fields like `consent_phase`, `disney_phase` not tracked in session files
3. **Redundant** - Multiple checks verifying similar aspects
4. **Too subjective** - High false positive rates for qualitative assessments

How should we restructure validation to be reliable and maintainable?

## Decision Drivers

- Script-based checks are deterministic and reliable
- LLM-based checks require enormous context for cross-round analysis
- Multiple `--level` flags add complexity without proportional value
- Maintenance burden of 20+ checks across 4 phases
- Desire for single, unified validation flow

## Considered Options

- Keep current multi-level validation structure
- Unify all checks in session-qa agent with script-first approach
- Remove validation entirely (rely on command-level validation only)

## Decision Outcome

Chosen option: "Unify all checks in session-qa agent with script-first approach", because it provides deterministic validation with clear categories (STR-*, STRAT-*, DIAG-*) while eliminating ineffective LLM-based checks.

### Consequences

- Good, because validation is deterministic and repeatable
- Good, because single agent auto-determines which checks to run
- Good, because eliminates confusing `--level` flags
- Good, because reduces maintenance surface
- Bad, because some semantic checks are lost (participant coherence, context integrity)
- Neutral, because deferred checks can be reintroduced when conditions are met

## Pros and Cons of the Options

### Keep current multi-level validation structure

Maintain the 4-phase structure with --level flag selection.

- Good, because preserves all check types
- Bad, because LLM-based checks are unreliable
- Bad, because depends on non-tracked fields
- Bad, because high maintenance burden

### Unify all checks in session-qa agent with script-first approach

Single agent that auto-determines checks based on session metadata.

- Good, because script checks are reliable
- Good, because simpler mental model for users
- Good, because auto-detection removes user burden
- Neutral, because some checks deferred until infrastructure supports them

### Remove validation entirely

Only use command-level validation (Step 2.6b in specs/design).

- Good, because simplest
- Bad, because no way to validate completed sessions
- Bad, because no diagnostic capability for debugging

## Checks Retained

| New ID | Original Check | Type | Implementation |
|--------|----------------|------|----------------|
| STR-001 | 1.2 Required Fields | Script | `yq -e '.id' && yq -e '.workflow_type'` |
| STR-002 | 1.3 Artifact States | Script | Validate status values in `artifacts.*` |
| STR-003 | 1.5 References | Script | Cross-check `rounds[].artifacts_created` vs `artifacts.*` |
| STR-004 | 1.6 Round Sequence | Script | Verify sequential round numbers |
| STR-005 | 1.7 Metrics Consistency | Script | Count vs `metrics.artifacts.total` |
| STR-006 | 1.8 + 3.C2 | Script | Verify all configured participants contributed |
| STRAT-D1 | 3.D1 Debate Phases | Script | Check `debate_phase` progression (debate only) |
| STRAT-D2 | 3.D2 Pro/Con Assignment | Mixed | Check overrides in verbose dumps (debate only) |
| DIAG-001 | Verbose Completeness | Script | Verify dump files have required fields |
| DIAG-002 | Context Propagation | Script | Check participant_context.shared saved |
| DIAG-003 | Debate Phase Tracking | Mixed | Verify debate_phase in round summary |

## Checks Deferred

| Original Check | Reason | Reintroduction Condition |
|----------------|--------|--------------------------|
| 1.4 State Transitions | Session file has current state only, no history | Track `state_history[]` per artifact |
| 2.1 Participant Coherence | Requires cross-round memory | Vector store for session history |
| 2.2 Context Integrity | Massive cross-reference, error-prone | Track `context_hash` per round |
| 2.3 Quality Assessment | Too subjective, high false positives | Define quantitative criteria |
| 3.C1 Consent Phases | Field `consent_phase` not tracked | Add field to session schema |
| 3.C3 Blocking Addressed | Semantic parsing unreliable | Structured output for concerns |
| 3.Y1 Disney Phases | Field `disney_phase` not tracked | Add field to session schema |
| 3.Y2 Phase Tone | Too subjective | Likely not reintroducible |

## More Information

**Implementation steps:**
1. Expand `agents/validation/session-qa.md` with STR-* and STRAT-* checks (inline bash snippets)
2. Simplify `commands/session/validate.md` to only invoke session-qa agent
3. Remove `--level` flags (agent auto-determines checks)

**Related decisions:**
- QA-001: Self-contained agent architecture
- QA-002: Script-first with LLM fallback
- QA-003: Require yq dependency
- QA-004: Inline bash snippets in agent

**Date:** 2026-01-16
**Participants:** Developer + Claude Code

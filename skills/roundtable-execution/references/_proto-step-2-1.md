# PROTOTYPE — Step 2.1 (extracted, feasibility test only)

> **THIS IS A PROTOTYPE FILE — DO NOT REFERENCE FROM PRODUCTION CODE.**
> **Will be reverted via `git revert` after 7B.3.5 feasibility test (TECH-002 Phase 7B).**
> **See `.s2s/plans/20260506-tech002-phase7b-deep-extraction.md` Appendix C for context.**

This file is a single-step extraction of Step 2.1 (Display Round Start) from `commands/specs.md`, restructured as a workflow-profile-aware reference that a command can Read and follow. Used to validate the extraction contract before scaling to all 13 steps in 7B.4a.

---

## Pre-conditions (caller responsibility)

Before invoking this file, the command must have made the following available in conversation context:

- `PROFILE`: the loaded workflow profile YAML object (e.g., the parsed content of `profiles/specs.yaml`)
- `STRATEGY`: the resolved strategy name string (e.g., `"consensus-driven"`)
- `SESSION_ID`: the session ID string
- `ROUND_NUMBER`: integer, current round index (0 for fresh round 1, N-1 for round N on resume)

---

## Step 2.1 — Display Round Start

### 2.1a Display block

Choose display style based on the loaded profile:

**IF** `PROFILE.display_block_style == "minimal"`:

Display a single line summarizing the round start:

```
Round {ROUND_NUMBER + 1}: agenda status and artifact counts
```

(Concrete content: count of agenda topics closed vs total, plus current artifact counts by primary type from `session.yaml.metrics.artifacts.by_type`.)

**IF** `PROFILE.display_block_style == "rich"`:

Display the full Disney phase block (brainstorm). Read the live `session.current_phase` value from `session.yaml`:

```
═══════════════════════════════════════════════════════════════
{{PROFILE.workflow_type | uppercase}}: {session.topic}
Strategy: {STRATEGY} | Phase: {session.current_phase} | Round: {ROUND_NUMBER + 1}
═══════════════════════════════════════════════════════════════

{IF session.current_phase == "dreamer"}
DREAMER PHASE: Think BIG! No constraints, wild ideas welcome.
{/IF}
{IF session.current_phase == "realist"}
REALIST PHASE: Evaluate feasibility. How would we implement?
{/IF}
{IF session.current_phase == "critic"}
CRITIC PHASE: Identify risks. What could go wrong?
{/IF}

ARTIFACTS: {counts from session.yaml.metrics.artifacts.by_type}
```

### 2.1b Update state.json

**IF `.s2s/state.json` exists**: Read it first to get current `active_plan` value (to preserve it).

**IMMEDIATELY** use Write tool to write `.s2s/state.json`:

```json
{
  "active_session": {
    "id": "{SESSION_ID}",
    "workflow_type": "{PROFILE.workflow_type}",
    "strategy": "{STRATEGY}",
    "phase": "{PROFILE.state_phase}",
    "round": {ROUND_NUMBER + 1},
    "participants_count": {length of PROFILE.participants.default}
  },
  "active_plan": {existing active_plan value OR null if file didn't exist},
  "last_activity": {
    "timestamp": "{ISO timestamp}",
    "action": "round_started",
    "session_id": "{SESSION_ID}"
  }
}
```

**SPECIAL CASE**: when `PROFILE.state_phase == "{current_phase}"` (brainstorm), substitute the placeholder with the live `session.current_phase` value (one of `"dreamer"` / `"realist"` / `"critic"`), NOT the literal string `"{current_phase}"`.

---

## Post-conditions

After Step 2.1 completes:
- `.s2s/state.json` has been written with `active_session` populated.
- The round-start display has been shown to the user.
- Control returns to the caller, which proceeds to Step 2.2 (Facilitator Question).

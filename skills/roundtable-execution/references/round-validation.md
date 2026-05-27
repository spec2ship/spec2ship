# Round Validation Checks

Per-round validation after Step 2.6 (Update Session File). Non-blocking - display warnings but continue execution.

---

## Quick Checks (MANDATORY)

Execute these checks by reading the session file:

### 1. Round Entry Exists

```
rounds[{round_number}] exists with fields:
- timestamp
- topic_id (or disney_phase for brainstorm)
- synthesis_summary
- artifacts_created
```

### 2. Artifacts Embedded

For each ID in `rounds[{round_number}].artifacts_created`:
```
artifacts.{type}.{ID} exists with:
- state
- title
- created_round == {round_number}
```

### 3. Metrics Match

```
metrics.rounds_completed == length(rounds[])
metrics.artifacts.total == sum of all artifacts.{type} counts
```

### 4. Agenda/Phase Status

- For specs/design: `agenda[topic_id].status` updated per `agenda_update`
- For brainstorm: `phases[current_phase].status` is correct

---

## Verbose Dump Check (IF --verbose)

Check files exist in `rounds/` folder:
- `{NNN}-01-facilitator-question.yaml`
- `{NNN}-02-{participant}.yaml` (one per participant)
- `{NNN}-03-facilitator-synthesis.yaml`

---

## On Failure

Display warning (non-blocking):

```
⚠️ VALIDATION WARNING
Round {N} issues found:
- {list of issues}

Continuing execution...
```

Update session file:
```yaml
validation:
  warnings:
    - round: {N}
      check: "{check name}"
      message: "{issue description}"
```

**Continue to next step** - validation is non-blocking.

---

## Reference

For comprehensive validation, use `/s2s:session:validate` which runs full STR-*, STRAT-*, DIAG-* checks via session-qa agent.

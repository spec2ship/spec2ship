# Definition of Done Checklist

Validation checklist for each step of the roundtable execution loop.

## After Step 2.2 (Facilitator Question)

- [ ] roundtable-facilitator agent was invoked with `action: "question"` input
- [ ] Facilitator returned valid YAML with `action: "question"`
- [ ] Decision includes focus_type and topic_id
- [ ] Context files list is present
- [ ] Dump file written (if verbose)

## After Step 2.3 (Participant Responses)

- [ ] ALL participant agents launched in SINGLE message (parallel execution)
- [ ] ALL participants returned valid YAML with `participant: "{id}"`
- [ ] Each response has position, rationale, confidence, concerns, suggestions
- [ ] Dump files written (if verbose)

## After Step 2.4 (Facilitator Synthesis)

- [ ] roundtable-facilitator agent was invoked with `action: "synthesis"` input
- [ ] Synthesis includes proposed_artifacts and constraints_check
- [ ] next is one of: continue, conclude, escalate
- [ ] Dump file written (if verbose)

## After Step 2.5 (Process Artifacts)

- [ ] New artifact files written
- [ ] Session file updated with new IDs
- [ ] Resolved conflicts updated

## Critical Reminders

- **Parallel execution**: ALL participant Tasks must be in a SINGLE message
- **Single source of truth**: Session file is authoritative, not in-memory state
- **Write immediately**: Update session file after EACH round, not batch

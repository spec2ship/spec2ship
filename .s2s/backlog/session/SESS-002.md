# SESS-002: User Hand-Raise Intervention

**Status**: draft
**Priority**: medium
**Category**: Session
**Created**: 2026-01-11
**Updated**: 2026-01-11

## Context

During a roundtable session, users currently cannot intervene mid-execution. The facilitator and participants discuss, and the user only sees the output. The user wants to be able to "raise their hand" and insert input during a running roundtable.

This is valuable because:
- Users may have context that participants don't
- Discussions may go off-track and need correction
- Real-time feedback improves roundtable quality

## Technical Findings

**Claude Code does NOT support user input during subagent execution.** Task execution is blocking - user cannot type while an agent runs. However:

- `AskUserQuestion` can pause at round boundaries (already implemented with `--interactive`)
- Ctrl+C can cancel, Ctrl+B can background tasks
- Current `--interactive` flag already provides checkpoint-based pausing

**Conclusion**: True "mid-execution interrupt" is not feasible. The solution is **enhanced checkpoint-based interaction**.

## Proposal

### 1. Enhanced --interactive Mode

- More frequent checkpoints (not just end of round)
- After facilitator question: "Provide input or continue?"
- After participant responses: "Review and intervene?"
- After facilitator synthesis: "Approve or redirect?"

### 2. User Intervention Format

```yaml
user_intervention:
  round: 2
  after_step: "participant_responses"  # or "facilitator_question", "synthesis"
  type: "clarification" | "correction" | "direction" | "question"
  content: "The authentication must use OAuth 2.0, not basic auth"
  target: "all" | "facilitator" | "{participant-name}"
```

### 3. Facilitator Handling

- Facilitator receives user intervention in next prompt
- Must acknowledge and incorporate in framing
- Can adjust topic/direction based on user input

### 4. Session Recording

- All interventions logged in session file
- Traceable in round summary

### Files to Modify
- `commands/specs.md`, `design.md`, `brainstorm.md` (enhance --interactive)
- `agents/roundtable/facilitator.md` (handle interventions)
- Session file schema (add interventions)

## Acceptance Criteria

- [ ] Enhanced checkpoints in `--interactive` mode
- [ ] User can provide structured input at checkpoints
- [ ] Input passed to facilitator in next prompt
- [ ] Facilitator acknowledges user intervention
- [ ] Session file records all interventions with timestamps

## Related

- Related to: SESS-003 (Product Owner Observer)
- Related to: CTX-001 (Context Reduction) - interventions add context

## Open Questions

- How many checkpoints per round? (Too many = annoying, too few = limited control)
- Should checkpoint options be configurable? (`--interactive=full` vs `--interactive=light`)
- How to format user input prompt for best UX?

## Notes

This is an enhancement to the existing `--interactive` flag, not a new mechanism.

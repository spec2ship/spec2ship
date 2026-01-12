# SESS-003: Product Owner Observer Agent

**Status**: draft
**Priority**: low
**Category**: Session
**Created**: 2026-01-11
**Updated**: 2026-01-11

## Context

Related to SESS-002 (User Hand-Raise), the user proposed having a "Product Owner" agent that:
- Observes the roundtable silently
- Tracks discussion without contributing
- Only speaks when user decides to intervene

This is essentially a "user proxy" agent that:
- Maintains user's perspective
- Can be activated by user to inject their viewpoint
- Provides continuity if user steps away

## Proposal

### 1. Observer Agent

- New agent: `agents/roundtable/product-owner-observer.md`
- Mode: "silent" by default, "active" when user intervenes
- Receives all round context but doesn't contribute unless activated

### 2. Activation Mechanism

- User types input → Observer becomes active for next round
- Observer synthesizes user input with discussion context
- Speaks on behalf of user with their viewpoint

### 3. Tracking Output

- Maintains running summary of key points
- Flags potential concerns from user perspective
- Available for user review at any time

### Files to Create
- `agents/roundtable/product-owner-observer.md` (new)
- Modify command files to include observer in roundtable

## Acceptance Criteria

- [ ] Observer agent exists and is invoked in roundtables
- [ ] Silent by default (no output unless activated)
- [ ] Can be activated by user intervention
- [ ] Produces tracking summary on demand

## Related

- Depends on: SESS-002 (User Hand-Raise mechanism)
- Related to: Existing product-manager agent (different role)

## Open Questions

- Is this redundant with just letting user type directly?
- How does this differ from product-manager participant?
- Should observer have its own color in status line?
- Does silent agent still consume tokens/context?

## Notes

This may be over-engineering. Consider if SESS-002 (enhanced --interactive) is sufficient before implementing this.

# SESS-001: Intelligent Auto-Resume

**Status**: draft
**Priority**: high
**Category**: Session
**Created**: 2026-01-11
**Updated**: 2026-01-11

## Context

Currently, agent resume is implemented (facilitator and participants can be resumed between rounds), but session resume at a higher level is not automatic. If a user starts a roundtable, gets interrupted, and returns later, they need to manually find and resume the session.

## Proposal

### 1. Active Session Detection

- On any `/s2s:*` workflow command, check `.s2s/state.yaml` for active session
- If active session exists, prompt: "Active session found: {session-id}. Resume? [Y/n]"

### 2. Session List in State

- Maintain list of recent sessions in `state.yaml` (not just current)
- Allow quick access without running `session:list`

```yaml
# .s2s/state.yaml
sessions:
  current: "20260111-specs-myproject"
  recent:
    - id: "20260111-specs-myproject"
      status: "active"
      rounds: 3
      updated: "2026-01-11T10:30:00Z"
    - id: "20260110-design-myproject"
      status: "completed"
      rounds: 5
      updated: "2026-01-10T15:00:00Z"
```

### 3. Resume Command Enhancement

- `/s2s:session:resume {session-id}` to explicitly resume any session
- `/s2s:specs --resume` to resume most recent specs session

### 4. Graceful New Session

- If user declines resume, create new session
- Old session remains accessible via `session:list`

### Files to Modify
- `commands/specs.md`, `design.md`, `brainstorm.md`
- `commands/session/resume.md` (new or enhance)
- `.s2s/state.yaml` schema

## Acceptance Criteria

- [ ] Active session detection on workflow command start
- [ ] Prompt to resume with clear session info
- [ ] State.yaml contains recent sessions list
- [ ] `--resume` flag works on workflow commands
- [ ] Old sessions remain accessible after new one created

## Related

- Extends: P2-10 (Agent Resume Architecture) - completed
- Related to: SESS-002 (User Hand-Raise)

## Open Questions

- How many recent sessions to keep in state.yaml? (Suggest: 5-10)
- Should expired/completed sessions auto-archive?
- What information to show in resume prompt? (topic, round count, last update)

## Notes

This builds on the existing agent resume capability (P2-10) to provide session-level resume.

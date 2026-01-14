# Error Handling

Guidelines for handling errors during roundtable execution.

## Facilitator Task Failure

If Task(facilitator) fails or times out:

1. Log error to session file with timestamp
2. Use fallback question:
   ```yaml
   action: "question"
   question: "What are the key considerations for {topic}?"
   participants: "all"
   focus: "Core requirements"
   ```
3. Continue with participants using fallback

## Participant Task Failure

If ANY participant Task fails:

1. Continue with remaining participants
2. Note missing response in synthesis prompt to facilitator
3. Do not block round completion for single participant failure

## Session File Write Failure

If session file write fails:

1. **STOP immediately** - this is a critical failure
2. Report error to user with file path and error details
3. Do NOT continue without persistence
4. Suggest user check disk space and file permissions

## Recovery Patterns

### Partial Round Recovery

If round partially completes (some participants responded):
- Save available responses to session file
- Mark round as `partial` in metadata
- Allow resume from last complete checkpoint

### Session Corruption

If session file is corrupted or invalid YAML:
- Attempt to parse last valid round from file
- Report corruption error with line number if available
- Suggest using `/s2s:session:list` to check session state

---

*Part of roundtable-execution skill*

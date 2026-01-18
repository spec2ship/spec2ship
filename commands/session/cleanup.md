---
description: Remove old or abandoned sessions to free up space.
allowed-tools: Bash(pwd:*), Bash(ls:*), Bash(rm:*), Bash(date:*), Read, Glob, AskUserQuestion
argument-hint: [--older-than 7d|30d|90d] [--status closed] [--dry-run]
---

# Cleanup Sessions

## Context

- Current directory: !`pwd`
- Directory contents: !`ls -la`
- Current date: !`date -u +"%Y-%m-%dT%H:%M:%SZ"`

## Interpret Context

Based on the context output above, determine:

- **S2S initialized**: If `.s2s` directory appears → "yes", otherwise → "NOT_S2S"

If S2S is initialized:
- Use Glob to find all `.s2s/sessions/*.yaml` files

---

## Instructions

### Validate environment

If S2S initialized is "NOT_S2S":

    Error: Not an s2s project. Run /s2s:init first.

### Parse arguments

Extract from $ARGUMENTS:
- **--older-than**: Age threshold (7d|30d|90d). Default: 30d
- **--status**: Only cleanup sessions with this status. Default: closed
- **--dry-run**: Show what would be deleted without deleting

Parse age threshold:
- `7d` → 7 days
- `30d` → 30 days
- `90d` → 90 days

### Find sessions to cleanup

Use Glob tool to find all session files:
```
.s2s/sessions/*.yaml
```

For each session file:

1. **YOU MUST use Read tool** to read the session file
2. Extract:
   - `id`
   - `status`
   - `timing.started_at`
   - `timing.closed_at` (if exists)
   - `timing.updated_at`
3. Calculate age from `timing.updated_at` or `timing.closed_at`
4. Mark for deletion if:
   - Age > threshold AND
   - Status matches filter

### Protection rules

**NEVER delete**:
- Sessions with `status: "active"`
- Sessions younger than threshold

### Show cleanup preview

    Session Cleanup
    ═══════════════════════════════════════

    Filter:
    - Older than: {threshold}
    - Status: {status filter}
    - Dry run: {yes|no}

    Sessions to remove ({count}):
    ─────────────────────────────────────
    {for each session marked for deletion}
    {status_icon} {id}
      Status: {status}
      Age: {calculated age}
      Last activity: {timing.updated_at}
      Artifacts: {metrics.artifacts.total}
    {/for}

    Protected ({count}):
    ─────────────────────────────────────
    {for each protected session}
    🛡️ {id} - {reason: "current session" | "active" | "too recent"}
    {/for}

    Space to free: ~{estimated size}

### Confirm deletion

**IF** --dry-run:

    Dry run complete. No sessions deleted.
    Remove --dry-run to actually delete.

**ELSE IF** sessions to delete > 0:

Use AskUserQuestion:
- "Delete {count} sessions? This cannot be undone."
  - Options: "Delete" / "Cancel"

**IF** user confirms "Delete":

### Execute cleanup

For each session marked for deletion:

1. **Delete session file**: `.s2s/sessions/{id}.yaml`
2. **Delete verbose folder** (if exists): `.s2s/sessions/{id}/`

**YOU MUST use Bash tool NOW** for each deletion:
```bash
rm -f .s2s/sessions/{id}.yaml
rm -rf .s2s/sessions/{id}/
```

### Report results

    Cleanup Complete
    ═══════════════════════════════════════

    Deleted: {count} sessions
    Freed: ~{size}

    Remaining: {count} sessions
      - Active: {count}
      - Closed: {count}

**IF** user cancels:

    Cleanup cancelled. No sessions deleted.

---

## Examples

```bash
# Remove closed sessions older than 7 days
/s2s:session:cleanup --older-than 7d --status closed

# Preview what would be deleted (30 days, all non-active)
/s2s:session:cleanup --dry-run

# Remove all closed sessions older than 90 days
/s2s:session:cleanup --older-than 90d --status closed
```

---

## Status Icons

| Status | Icon |
|--------|------|
| active | → |
| closed | ✓ |
| protected | 🛡️ |

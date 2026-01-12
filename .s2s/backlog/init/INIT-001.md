# INIT-001: Optional Structure Creation

**Status**: draft
**Priority**: high
**Category**: Init
**Created**: 2026-01-11
**Updated**: 2026-01-11

## Context

Currently, `/s2s:init` creates a predefined folder structure (`docs/`, `docs/specifications/`, etc.) in the user's project. However, many users already have their own documentation structure or prefer not to have s2s create folders automatically.

This is a common scenario for:
- Existing projects with established structure
- Projects following different documentation conventions
- Users who want to use s2s only for roundtable facilitation without file generation

## Proposal

Modify `commands/init.md` to:

1. **Add `--no-structure` flag**: Skip folder creation entirely
2. **Add interactive prompt**: When no flag is provided, ask user:
   - "Create recommended folder structure? (docs/, .s2s/, etc.)"
   - Options: Yes (default) | No | Customize
3. **Detect existing structure**: If `docs/` or similar already exists, inform user and ask what to do

### Files to Modify
- `commands/init.md`

## Acceptance Criteria

- [ ] `--no-structure` flag skips folder creation
- [ ] Interactive prompt when flag not provided
- [ ] Existing structure detection works
- [ ] CONTEXT.md and config.yaml are always created (in .s2s/)
- [ ] State.yaml is always created (in .s2s/)

## Related

- Related to: INIT-002 (Intelligent Project Assessment)
- Supersedes: Part of old P2-6/P2-7

## Open Questions

- Should we still create `.s2s/` even with `--no-structure`? (Likely yes, it's internal to s2s)
- What about `docs/specifications/` specifically - is that optional too?

## Notes

User explicitly stated: "nel mio caso vorrei non crearla" (in my case I wouldn't want to create it).

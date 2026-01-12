# QUAL-002: Validate Default to Full

**Status**: draft
**Priority**: medium
**Category**: Quality
**Created**: 2026-01-11
**Updated**: 2026-01-11

## Context

Currently, `/s2s:session:validate` has different levels (structural, deep, strategy). The user suggests the default should be ALL checks.

## Proposal

### 1. Default to All Checks

- `validate` with no flags runs all checks
- Structural + Deep + Strategy

### 2. Skip/Exclude Flags

- `--skip structural` - skip structural checks
- `--skip deep` - skip LLM-based checks
- `--skip strategy` - skip strategy-specific checks

### 3. Or Keep Current with New Default

- `--level all` becomes default
- `--level structural` for quick check

### Files to Modify
- `commands/session/validate.md`

## Acceptance Criteria

- [ ] Default runs all checks
- [ ] Skip flags work
- [ ] Backward compatible

## Related

- Related to: TEST-002 (Validation in tests)

## Open Questions

- Performance impact of always running deep checks?
- Should there be a "quick" alias for structural-only?

## Notes

This is a quick fix that improves validation thoroughness by default.

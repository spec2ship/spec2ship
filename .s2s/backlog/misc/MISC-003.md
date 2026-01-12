# MISC-003: File Size Verification

**Status**: draft
**Priority**: low
**Category**: Misc
**Created**: 2026-01-11
**Updated**: 2026-01-11

## Context

The user notes the need to verify no excessively large files exist that waste tokens/context.

## Proposal

### 1. Audit

- List all files by size
- Identify files > 500 lines
- Analyze if size is justified

### 2. Mitigation

- Extract reference sections to separate files
- Use progressive loading where possible
- Document findings

## Acceptance Criteria

- [ ] Audit completed
- [ ] Large files identified
- [ ] Mitigation applied where beneficial

## Related

- Related to: CTX-001 (Context Reduction)

## Open Questions

- What's the threshold for "too large"?
- Which files are critical vs. can be split?

## Notes

Run audit command:
```bash
find . -name "*.md" -exec wc -l {} \; | sort -rn | head -20
```

Current known large files:
- commands/specs.md (~1500 lines)
- commands/design.md (~1400 lines)
- commands/brainstorm.md (~1400 lines)

These may be acceptable given their complexity, but should be reviewed.

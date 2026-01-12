# MISC-001: Release v0.2.5

**Status**: ready
**Priority**: high
**Category**: Misc
**Created**: 2026-01-11
**Updated**: 2026-01-11

## Context

develop branch is 1 commit ahead of main with README.md fixes.

## Proposal

1. Merge develop → main
2. Tag v0.2.5
3. Create release

### Commands

```bash
git checkout main
git merge develop
git tag v0.2.5
git push origin main --tags
```

## Acceptance Criteria

- [ ] Merged
- [ ] Tagged
- [ ] Released

## Related

None

## Open Questions

None

## Notes

Quick release to sync main with develop.

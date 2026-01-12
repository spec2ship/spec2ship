# TEST-002: Ad-Hoc Test Projects Suite

**Status**: draft
**Priority**: low
**Category**: Testing
**Created**: 2026-01-11
**Updated**: 2026-01-11

## Context

Beyond the test command (TEST-001), we need actual test projects with known issues that should trigger:
- Session validation warnings
- Facilitator hand-raise
- Participant concerns

## Proposal

### 1. Test Project Repository

```
test/projects/
├── valid-minimal/       # Minimal valid project
├── valid-complete/      # Full featured valid project
├── invalid-context/     # Malformed CONTEXT.md
├── conflicting-reqs/    # Requirements with conflicts
├── missing-nfrs/        # No non-functional requirements
└── stale-artifacts/     # Outdated artifact references
```

### 2. Expected Outcomes

- Each project has `expected.yaml` with:
  - Expected validation warnings
  - Expected hand-raises
  - Expected concerns from participants

### 3. Test Runner

- Iterates through test projects
- Runs session validate
- Compares actual vs expected
- Reports pass/fail

### 4. Exclusion from Plugin

- Test projects not in plugin manifest
- Or in separate test branch

### Files to Create
- `test/projects/*/` (multiple test projects)
- `test/projects/*/expected.yaml` (expected outcomes)
- Test runner script

## Acceptance Criteria

- [ ] At least 5 test projects with different scenarios
- [ ] Expected outcomes defined for each
- [ ] Test runner compares actual vs expected
- [ ] Tests not shipped with plugin

## Related

- Related to: TEST-001 (Test Framework)
- Related to: QUAL-002 (Validate)

## Open Questions

- How to maintain test projects as plugin evolves?
- Should tests be run in CI?
- How to handle non-deterministic LLM responses?

## Notes

Test projects should cover:
1. Valid scenarios (baseline)
2. Validation edge cases
3. Conflict detection
4. Context propagation issues
5. Strategy-specific behaviors

# TEST-001: Test Framework with s2s:test

**Status**: draft
**Priority**: high
**Category**: Testing
**Created**: 2026-01-11
**Updated**: 2026-01-11

## Context

Testing s2s commands requires:
- Creating test projects with specific contexts
- Running commands with diagnostic flags
- Verifying expected behavior

Currently, this is manual and cumbersome. A test command would set up everything needed.

## Proposal

### 1. Test Command Structure

- `/s2s:test specs` - test specs workflow
- `/s2s:test design` - test design workflow
- `/s2s:test roundtable` - test generic roundtable

### 2. Test Setup

- Creates temporary directory (or uses `test/output/`)
- Generates test CONTEXT.md with known content
- Generates test config.yaml
- Sets up state.yaml indicating test mode

### 3. Test Execution

- Automatically adds `--diagnostic --verbose`
- Runs the actual command
- Captures output for verification

### 4. Test Scenarios

- Store test scenarios in `test/scenarios/`
- Each scenario: input context, expected behavior
- Not shipped with plugin (excluded from manifest)

### 5. Local Test Files

- Use `.local` suffix for test-only files
- Or specify excluded folders in manifest

### Files to Create
- `commands/test/specs.md` (new)
- `commands/test/design.md` (new)
- `commands/test/roundtable.md` (new)
- `test/scenarios/*.yaml` (not shipped)

## Acceptance Criteria

- [ ] s2s:test command with subcommands
- [ ] Automatic test environment setup
- [ ] Diagnostic flags applied automatically
- [ ] Test scenarios can be defined
- [ ] Test files not shipped with plugin

## Related

- Related to: TEST-002 (Ad-hoc test projects)
- Related to: QUAL-001 (Code Review) - tests verify quality
- Related to: CTX-001 (--simulate) - simulate useful for testing

## Open Questions

- How to verify expected behavior automatically?
- Should tests run in isolated session or current?
- How to handle test cleanup?
- Integration with CI/CD?

## Notes

The test command should make it easy to:
1. Test s2s from within s2s development session
2. Debug issues live
3. Verify fixes before committing

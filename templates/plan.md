# Implementation Plan: {topic}

**ID**: {plan-id}
**Status**: active
**Branch**: {branch-name}
**Created**: {created-timestamp}
**Updated**: {updated-timestamp}

## Traceability

<!-- Source of this plan - what item triggered its creation -->
**Source**: {source-id}
**Source Type**: {source-type}
<!-- Source types: backlog (FEAT-*, BUG-*, TECH-*, DEBT-*), requirement (REQ-*, NFR-*), idea (IDEA-*), architecture (COMP-*, ARCH-*), topic (free text) -->

## References

### Requirements
<!-- Link to relevant functional requirements -->
<!-- Format: - REQ-XXX: description @.s2s/requirements.md -->
{requirements-list}

### Architecture
<!-- Link to relevant architecture sections -->
<!-- Format: - Component: role @.s2s/architecture.md -->
{architecture-list}

### Decisions
<!-- Link to relevant ADRs -->
<!-- Format: - ADR-NNN: summary @.s2s/decisions/ADR-NNN-topic.md -->
{decisions-list}

### Dependencies
<!-- Other plans that must complete first -->
{dependencies-list}

## Overview

{overview-description}

## Design Notes

<!--
Document component-specific technical decisions here.
This section captures design choices that don't warrant a full ADR
but are important for understanding the implementation.
-->

## Tasks

<!--
Break down the implementation into concrete tasks.
Each task should be:
- Specific and actionable
- Completable in a reasonable time
- Independently testable when possible
-->

- [ ] {task-1}
- [ ] {task-2}
- [ ] {task-3}

## State & Data Lifecycle

<!--
For each stateful element this plan introduces or touches (cache, table, file,
queue, in-memory registry): cover the FULL runtime lifecycle, not just the
startup/load path. A cache that is only ever loaded at boot is a design smell:
who writes it, who invalidates it, who deletes from it? (VKT-042)
Write "None - this plan introduces no stateful elements." when that is true.
-->

| State element | Created by | Updated by | Invalidated/Deleted by |
|---------------|-----------|------------|------------------------|
| {element} | {task/path} | {task/path} | {task/path} |

## Acceptance Criteria

- [ ] {criterion-1}
- [ ] {criterion-2}

## Testing Approach

{testing-description}

### Test Infrastructure

<!--
What the acceptance criteria need to actually run (VKT-032). A criterion that
cannot run without infrastructure that no task provides will be silently
skipped and reported as passed.
Write "None - tests run with no external infrastructure." when that is true.
-->

- **Required**: {fixtures | Docker services | seeded database | external API stub | none}
- **Provided by**: {task in this plan that sets it up, or plan-id that provides it}
- **False-pass guard**: {how a skipped/impossible test is reported as SKIPPED/BLOCKED, never as passed}

### NFR Verification

<!--
For each NFR this plan claims to satisfy: a runnable benchmark, not an
adjective (VKT-043). Delete the section only if the References list no NFR.
-->

| NFR | Dataset/Load | Tool | Environment | Pass criterion |
|-----|--------------|------|-------------|----------------|
| {NFR-XXX} | {what is measured against} | {how} | {where} | {measurable threshold from the NFR target/minimum} |

## Integration Notes

{integration-description}

## Notes

<!--
Progress notes, blockers, discoveries, or anything relevant
to the implementation that doesn't fit elsewhere.
-->

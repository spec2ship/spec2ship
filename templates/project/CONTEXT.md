# {Project Name} - S2S Context

<!--
This file is automatically maintained by Spec2Ship.
Import this in CLAUDE.md using @.s2s/CONTEXT.md
-->

## Project Structure

| Category | Path |
|----------|------|
| Architecture | `docs/architecture/` |
| Requirements | `docs/specifications/requirements.md` |
| API Specs | `docs/specifications/api/` |
| Decisions | `docs/decisions/` |
| Guides | `docs/guides/` |
| Plans | `.s2s/plans/` |

## S2S Commands

### Planning

| Command | Description |
|---------|-------------|
| `/s2s:plan:new "topic"` | Create implementation plan |
| `/s2s:plan:new "topic" --branch` | Create plan with git branch |
| `/s2s:plan:start "id"` | Start working on plan |
| `/s2s:plan:complete` | Mark current plan complete |
| `/s2s:plan:list` | List all plans |

### Decisions

| Command | Description |
|---------|-------------|
| `/s2s:decision:new "topic"` | Create ADR |
| `/s2s:decision:new "topic" --roundtable` | Create via discussion |
| `/s2s:decision:list` | List all decisions |

### Roundtable

| Command | Description |
|---------|-------------|
| `/s2s:roundtable:start "topic"` | Start discussion |
| `/s2s:roundtable:resume` | Resume last session |
| `/s2s:roundtable:converge` | Force consensus |

## Active Plans

<!--
This section shows current implementation plans.
See .s2s/plans/ for details.
-->

@.s2s/plans/

## Recent Decisions

<!--
Recent architecture decisions.
See docs/decisions/ for full list.
-->

@docs/decisions/

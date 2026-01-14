# {Workspace Name} - S2S Context

<!--
This file is automatically maintained by Spec2Ship.
Components import this using @{workspace-path}/.s2s/CONTEXT.md
-->

## Workspace Structure

| Category | Path |
|----------|------|
| Architecture | `docs/architecture/` |
| Requirements | `docs/specifications/requirements.md` |
| API Specs | `docs/specifications/api/` |
| Decisions | `docs/decisions/` |
| Guides | `docs/guides/` |
| Cross-component Plans | `.s2s/plans/` |
| Roundtable Sessions | `.s2s/sessions/` |

## Components

<!--
Component registry from components.yaml
-->

@.s2s/components.yaml

## S2S Commands

### Workspace Management

| Command | Description |
|---------|-------------|
| `/s2s:init:detect` | Show workspace status |
| `/s2s:workspace:add-component` | Add component to registry |
| `/s2s:workspace:sync` | Sync context across components |

### Planning

| Command | Description |
|---------|-------------|
| `/s2s:plan --new "topic"` | Create cross-component plan |
| `/s2s:plan --session "id"` | Start plan |
| `/s2s:plan:close` | Complete plan |

### Roundtable

| Command | Description |
|---------|-------------|
| `/s2s:roundtable "topic"` | Start workspace discussion |
| `/s2s:roundtable "topic" --components a,b` | Cross-component discussion |

## Active Plans

@.s2s/plans/

## Recent Decisions

@docs/decisions/

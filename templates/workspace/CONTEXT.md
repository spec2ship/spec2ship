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
| `/s2s:plan:create "topic"` | Create cross-component plan |
| `/s2s:plan:start "id"` | Start plan |
| `/s2s:plan:complete` | Complete plan |

### Git (Multi-Repo)

| Command | Description |
|---------|-------------|
| `/s2s:git:branch "name"` | Create branch across all components |
| `/s2s:git:sync` | Sync branch status |
| `/s2s:git:pr` | Create linked PRs |

### Decisions

| Command | Description |
|---------|-------------|
| `/s2s:decision:new "topic"` | Create system-level ADR |
| `/s2s:decision:new "topic" --roundtable` | Create via discussion |

### Roundtable

| Command | Description |
|---------|-------------|
| `/s2s:roundtable:start "topic"` | Start workspace discussion |
| `/s2s:roundtable:start "topic" --components a,b` | Cross-component discussion |

## Active Plans

@.s2s/plans/

## Recent Decisions

@docs/decisions/

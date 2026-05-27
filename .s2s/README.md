# Spec2Ship - S2S Project

This project uses [Spec2Ship](https://github.com/spec2ship/spec2ship) for specification-driven development.

> **Note**: This is the s2s plugin developing itself (dogfooding).

## Structure

| Path | Purpose | Content |
|------|---------|---------|
| `CONTEXT.md` | Project context | Business domain, objectives, constraints |
| `config.yaml` | Configuration | Roundtable settings, participants |
| `requirements.md` | Requirements | REQ-*, NFR-*, BR-* from specs sessions |
| `architecture.md` | Architecture | Components, interfaces, data flow |
| `BACKLOG.md` | Work items | Active tasks (planned, in_progress) |
| `ideas.md` | Ideas | Proposals and concepts for evaluation |
| `decisions/` | ADRs | Architecture Decision Records (MADR format) |
| `sessions/` | Sessions | Roundtable session artifacts |
| `plans/` | Plans | Implementation plans |

## Artifact flow

```
brainstorm → ideas.md (IDEA-*)
                 ↓ promote
specs ←──── BACKLOG.md (FEAT-*)
    ↓
requirements.md (REQ-*, NFR-*)
    ↓
design → architecture.md (COMP-*, INT-*)
       + decisions/ (ADR-*)
    ↓
plan → plans/
```

## Commands

| Command | Use Case |
|---------|----------|
| `/s2s:specs "topic"` | Define requirements |
| `/s2s:design "topic"` | Design architecture |
| `/s2s:brainstorm "topic"` | Creative exploration |
| `/s2s:plan "feature"` | Generate implementation plan |

### Session management

| Command | Description |
|---------|-------------|
| `/s2s:session:list` | List all sessions |
| `/s2s:session:status` | Current session status |
| `/s2s:session:close` | Close active session |

## More information

- [Spec2Ship Documentation](https://github.com/spec2ship/spec2ship)
- Project context: `CONTEXT.md`
- Development guidelines: `.claude/s2s-development.md`

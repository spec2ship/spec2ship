# Spec2Ship - S2S Project

This project uses [Spec2Ship](https://github.com/spec2ship/spec2ship) for specification-driven development.

> **Note**: This is the s2s plugin developing itself (dogfooding).

## Structure

| Path | Purpose |
|------|---------|
| `CONTEXT.md` | Project context (loaded by Claude via CLAUDE.md) |
| `config.yaml` | Project configuration |
| `decisions/` | Architecture Decision Records (MADR format) |
| `sessions/` | Roundtable session artifacts |
| `plans/` | Implementation plans |
| `BACKLOG.md` | Work items, ideas, technical debt |

## Project Tracking

**Backlog**: `BACKLOG.md` - Single source of truth for all planned work, ideas, and technical debt. Uses category-based IDs (ARCH-*, EXT-*, QUAL-*, etc.) with status tracking.

**Decisions**: `decisions/` - Architecture Decision Records (ADRs) in MADR format.

## Commands

| Command | Use Case |
|---------|----------|
| `/s2s:specs "topic"` | Define requirements |
| `/s2s:design "topic"` | Design architecture |
| `/s2s:brainstorm "topic"` | Creative exploration |
| `/s2s:plan "feature"` | Generate implementation plan |

### Session Management

| Command | Description |
|---------|-------------|
| `/s2s:session:list` | List all sessions |
| `/s2s:session:status` | Current session status |
| `/s2s:session:close` | Close active session |

## More Information

- [Spec2Ship Documentation](https://github.com/spec2ship/spec2ship)
- Project context: `CONTEXT.md`
- Development guidelines: `.claude/s2s-development.md`

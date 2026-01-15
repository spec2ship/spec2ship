# Architecture Decision Records (Internal)

This directory contains internal ADRs for Spec2Ship development.

## Index

| # | Decision | Status |
|---|----------|--------|
| [0001](0001-component-separation.md) | Component Separation: Commands vs Agents vs Skills | accepted |
| [0002](0002-inline-orchestration.md) | Inline Orchestration in Commands | accepted |
| [0003](0003-agent-model-tiers.md) | Agent Model Tiers | accepted |
| [0004](0004-participant-context-passing.md) | Participant Context Passing | accepted |
| [0005](0005-skills-progressive-disclosure.md) | Skills Progressive Disclosure | accepted |
| [0006](0006-session-embedded-artifacts.md) | Session Embedded Artifacts | accepted |

## Status Legend

- **accepted** — Currently in effect
- **proposed** — Under discussion
- **deprecated** — No longer applicable
- **superseded** — Replaced by another ADR
- **rejected** — Considered but not adopted

## Internal vs Public

These ADRs are **internal** (`.s2s/` is gitignored):
- Work-in-progress decisions
- Implementation details
- Exploratory discussions

Significant decisions may be promoted to **public** ADRs in `docs/architecture/decisions/` for contributors.

## Format

We use [MADR](https://adr.github.io/madr/) (Markdown Any Decision Records):
- Filename: `NNNN-slug.md` (4-digit padding)
- See `skills/madr-decisions/SKILL.md` for template

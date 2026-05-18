---
name: Roundtable Execution
description: "This skill provides instructions for executing multi-agent roundtable discussions.
  Use when a command needs to run discussion rounds with facilitator and participants.
  Referenced by: specs.md, design.md, brainstorm.md.
  Trigger: 'execute roundtable', 'run discussion rounds', 'multi-agent discussion'."
version: 3.0.0
---

# Roundtable Execution Skill

This skill provides the canonical, profile-aware reference for executing multi-agent roundtable discussions in spec2ship. After TECH-002 Phase 7B (2026-05), the Phase 2 Round Execution Loop is extracted to `references/phase-2-core.md` as a single executable source consumed by `/s2s:specs`, `/s2s:design`, and `/s2s:brainstorm`.

## When to Use This Skill

- Executing `/s2s:specs` requirements gathering
- Executing `/s2s:design` architecture design
- Executing `/s2s:brainstorm` ideation sessions

---

## Workflow Context

Each workflow has specific goals, participants, artifacts, and outputs. **Authoritative source**: the YAML profile in `profiles/{workflow}.yaml` — the tables below are a human-readable summary.

### specs Workflow

| Aspect | Value |
|--------|-------|
| **Goal** | Define WHAT to build — requirements, constraints, scope |
| **Default Participants** | product-manager, ux-researcher, business-analyst, qa-lead |
| **Default Strategy** | consensus-driven |
| **Primary Artifacts** | `REQ-*`, `BR-*`, `NFR-*` |
| **Secondary Artifacts** | `OQ-*`, `CONF-*`, `EX-*` |
| **Output** | `.s2s/requirements.md` |
| **Profile** | `profiles/specs.yaml` |
| **Agenda** | `references/agenda-specs.md` |

### design Workflow

| Aspect | Value |
|--------|-------|
| **Goal** | Define HOW to build — architecture, components, interfaces |
| **Default Participants** | software-architect, security-champion, technical-lead, devops-engineer |
| **Default Strategy** | debate |
| **Primary Artifacts** | `ARCH-*`, `COMP-*`, `INT-*` |
| **Secondary Artifacts** | `ADR-*`, `OQ-*`, `CONF-*` |
| **Output** | `.s2s/architecture.md` + `.s2s/decisions/` |
| **Profile** | `profiles/design.yaml` |
| **Agenda** | `references/agenda-design.md` |

### brainstorm Workflow

| Aspect | Value |
|--------|-------|
| **Goal** | Explore possibilities — ideas, risks, mitigations |
| **Default Participants** | product-manager, software-architect, technical-lead, devops-engineer (configurable via `--participants`) |
| **Default Strategy** | disney (FORCED — `--strategy` is ignored) |
| **Primary Artifacts** | `IDEA-*`, `RISK-*`, `MIT-*` |
| **Secondary Artifacts** | `OQ-*`, `CONF-*` |
| **Output** | `.s2s/sessions/{session-id}-summary.md` + updates to `.s2s/ideas.md` |
| **Profile** | `profiles/brainstorm.yaml` |
| **Agenda** | `references/agenda-brainstorm.md` (phase-based, Disney) |

### Workflow Differences Summary

| Aspect | specs | design | brainstorm |
|--------|-------|--------|------------|
| Focus | User needs, requirements | Technical architecture | Creative exploration |
| Tone | Collaborative agreement | Adversarial evaluation | No criticism (dreamer) → Full critique (critic) |
| Participants | Business + QA focus | Technical focus | Flexible (--participants) |
| Strategy | Consensus | Debate | Disney phases (forced) |
| Progress axis | Agenda topics | Agenda topics | Disney phase machine |

---

## Key Architecture

- **Session file**: `.s2s/sessions/{session-id}.yaml` — slim index with embedded artifacts (per ADR-0008/0010).
- **Session folder**: `.s2s/sessions/{session-id}/` — subfolder for `rounds/` dumps when `--verbose`.
- **Artifacts**: EMBEDDED in session.yaml under `artifacts.{session_key}`, NOT separate files.
- **Verbose dumps**: `rounds/{NNN}-{PP}-{actor}.yaml` per `verbose-dump-format.md`.

---

## Phase structure

Each `/s2s:{workflow}` command runs three phases. Phase 1 (init) and Phase 3 (close) remain inline in each command; Phase 2 (Round Execution Loop) is the canonical extracted algorithm in `phase-2-core.md`.

### Phase 1: Session Setup (inline in each command)

Steps 1.1–1.4 (or 1.5 for workspace projects):
1. **Generate session ID** — `{YYYYMMDD}-{workflow_type}-{project-slug}`.
2. **Create session folder structure** — `.s2s/sessions/{session-id}/[rounds/]`.
3. **Create snapshot files** — `context-snapshot.yaml`, `config-snapshot.yaml`, `agenda.yaml` (specs/design only).
4. **Create session index file** — `.s2s/sessions/{session-id}.yaml` with initial state, empty rounds, empty artifacts.

Phase 1 is inline because it's command-specific (different snapshots, different prerequisites). The thin-launcher conversion is deferred to Phase 8 in the TECH-002 roadmap.

### Phase 2: Round Execution Loop (canonical, profile-aware)

**Read** `references/phase-2-core.md` and follow its §2 (Round Loop algorithm). The algorithm loops Steps 2.0 → 2.9 internally until terminal dispatch.

Steps (per `phase-2-core.md`):

| Step | Purpose | Token checkpoint |
|------|---------|------------------|
| 2.0 | Context Capacity Check | — |
| 2.1 | Display Round Start + update state.json | — |
| 2.2 | Facilitator Question | T1 |
| 2.3 | Participant Responses (PARALLEL) | T2 |
| 2.4 | Facilitator Synthesis | T3 |
| 2.5 | Process Artifacts (uses `artifact-schemas/`) | — |
| 2.6 | Update Session File | — |
| 2.6b | Validate Round Output (`round-validation.md`) | — |
| 2.6c | Diagnostic Observation (`IF --diagnostic`) — MANDATORY | — |
| 2.10 | Phase Transition (brainstorm only, `disney-phase-machine.md`) | — |
| 2.7 | Display Round Recap | — |
| 2.8 | Handle Interactive Mode | — |
| 2.9 | Evaluate Next Action (min_rounds enforcement, dispatch) | — |

All step details are in `phase-2-core.md`. **Do not duplicate Phase 2 logic in commands** — commands invoke phase-2-core.md via the caller pattern documented there (§3).

### Phase 3: Completion (inline in each command)

Steps 3.0–3.5:
1. **3.0 — Final Diagnostic Report** (`IF --diagnostic`): invoke `session-observer` in `end-session` mode, display final report.
2. **3.1 — Update Session Status**: set `status: "closed"`, clear `state.json.active_session`. Execute "Session Complete" token tracking.
3. **3.2 — Read Session for Summary**: extract artifacts from session file.
4. **3.4 — User Review**: AskUserQuestion to approve / refine / add more.
5. **3.5+ — Generate Output**: invoke `output-generation` skill for `.s2s/requirements.md` (specs), `.s2s/architecture.md` + `.s2s/decisions/` (design), or `.s2s/ideas.md` + summary (brainstorm).

Phase 3 stays inline because output generation is workflow-specific (different documents). Deferred to Phase 8 for consolidation if useful.

---

## Reference Files

### Phase 2 canonical references (new in TECH-002 Phase 7B)

| File | Content |
|------|---------|
| `references/phase-2-core.md` | **Executable** Phase 2 Round Execution Loop — single source consumed by all 3 workflow commands |
| `references/profile-schema.md` | Workflow profile YAML schema + field-to-§1 mapping + how-to-add-a-workflow |
| `profiles/specs.yaml` | specs workflow profile (artifact types, participants, agenda axis, defaults) |
| `profiles/design.yaml` | design workflow profile |
| `profiles/brainstorm.yaml` | brainstorm workflow profile (with `forced: true` disney strategy and `has_phase_transition: true`) |
| `references/artifact-schemas/README.md` | Index of 12 per-type artifact schemas |
| `references/artifact-schemas/{type}.md` | Canonical schema per artifact type (req, br, nfr, ex, arch, comp, int, idea, risk, mit, oq, conf) |
| `references/disney-phase-machine.md` | Disney phase state machine (brainstorm Step 2.10) |
| `references/strategy-hooks.md` | Strategy-specific Phase 2 variation hooks (debate_role, debate_phase, future hat_role) — contract documented, Phase 4 wires (Option A/B/C decision) |

### Supporting references

| File | Content |
|------|---------|
| `references/session-schema.md` | Full session.yaml schema |
| `references/agenda-specs.md` | Specs workflow agenda with DoD criteria |
| `references/agenda-design.md` | Design workflow agenda with DoD criteria |
| `references/agenda-brainstorm.md` | Brainstorm workflow agenda (phase-based) |
| `references/verbose-dump-format.md` | Verbose dump file naming + canonical YAML schemas for facilitator/participant/synthesis/session-observer dumps |
| `references/token-tracking.md` | Token tracking script + checkpoints T1/T2/T3 + Session Complete |
| `references/round-validation.md` | Per-round validation checks (Step 2.6b) |
| `references/diagnostic.md` | Diagnostic mode notes |
| `references/definition-of-done.md` | Step validation checklist |
| `references/error-handling.md` | Error recovery patterns |
| `references/workspace-scope.md` | Workspace/component scope handling (Phase 1 Step 1.3b-1.4) |

---

## Migration history

- **v1.x–v2.x**: SKILL.md inlined Phase 1/2/3 algorithms (1000+ lines), duplicating logic also present in each workflow command. Drift between SKILL.md and commands led to BUG-013 and others.
- **v3.0 (2026-05, TECH-002 Phase 7B.5)**: SKILL.md restructured to thin overview pointing to `phase-2-core.md` (executable Phase 2 single-source) and per-type artifact schemas. Phase 1/3 stay inline in commands until Phase 8 (thin launchers).

---

*Referenced by: `commands/specs.md`, `commands/design.md`, `commands/brainstorm.md`, `commands/roundtable.md` (the latter still uses pre-7B inline pattern; Phase 4 will align it).*

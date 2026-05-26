---
name: Roundtable Execution
description: "This skill provides instructions for executing multi-agent roundtable discussions.
  Use when a command needs to run discussion rounds with facilitator and participants.
  Referenced by: roundtable.md (master orchestrator); specs.md, design.md, brainstorm.md (thin launchers that Read-and-follow roundtable.md).
  Trigger: 'execute roundtable', 'run discussion rounds', 'multi-agent discussion'."
version: 3.1.0
---

# Roundtable Execution Skill

This skill provides the canonical, profile-aware reference for executing multi-agent roundtable discussions in spec2ship. After TECH-002 Phase 7B (2026-05), the Phase 2 Round Execution Loop is extracted to `references/phase-2-core.md` as a single executable source. After TECH-002 Phase 8 (2026-05), `commands/roundtable.md` is the master orchestrator for all 4 workflow types (specs, design, brainstorm, roundtable); `specs.md`, `design.md`, `brainstorm.md` are thin launchers that Read-and-follow the master.

## When to Use This Skill

- Executing `/s2s:specs` requirements gathering (thin launcher delegates to master)
- Executing `/s2s:design` architecture design (thin launcher delegates to master)
- Executing `/s2s:brainstorm` ideation sessions (thin launcher delegates to master)
- Executing `/s2s:roundtable` (master, native or with `--workflow-type`)

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

All 4 workflows (`specs`, `design`, `brainstorm`, native `roundtable`) execute the same 4 phases inside `commands/roundtable.md` (the master). Thin launchers (`specs.md`, `design.md`, `brainstorm.md`) perform workflow-specific prep (prerequisite checks, smart source detection, argument parsing) and then Read-and-follow the master. The master is profile-driven via `profiles/{workflow}.yaml`.

| Phase | Where it runs | Source of truth |
|-------|---------------|-----------------|
| 0: Auto-detect / parse args | `roundtable.md` PHASE 0 | scoped to `workflow_type` |
| 1: Session setup (folder + 3 snapshots + skeleton) | `roundtable.md` PHASE 1 | `profiles/{workflow}.yaml` |
| 2: Round Execution Loop | `phase-2-core.md` via `roundtable.md` PHASE 3 caller | `phase-2-core.md` §2 + `PROFILE` |
| 3: Completion (close, summary, output) | `roundtable.md` PHASE 4 + `output-generation/references/{workflow}.md` | per-workflow output reference |

### Phase 1: Session Setup (master, profile-driven)

Driven by `PROFILE` loaded from `profiles/{workflow}.yaml` in `roundtable.md` PHASE 1:
1. **Generate session ID**: `{YYYYMMDD}-{workflow_type}-{topic-slug}`.
2. **Create session folder**: `.s2s/sessions/{session-id}/[rounds/]`.
3. **Create snapshot files**: `config-snapshot.yaml`, `context-snapshot.yaml`, and `agenda.yaml` if `PROFILE.progress.axis == agenda`.
4. **Create session index file**: `.s2s/sessions/{session-id}.yaml` with skeleton derived from `PROFILE` (`artifact_types` populate `artifacts.by_state`, `topics`, `validation`; `progress.axis` discriminates `agenda` vs `disney_phase`).

Topic resolution per `PROFILE.topic.source` (cli-arg vs synthesized from project context vs none).

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

### Phase 3: Completion (master, output workflow-specific)

`roundtable.md` PHASE 4 runs the common close-out then dispatches to the workflow-specific output reference:
1. **Final Diagnostic Report** (`IF --diagnostic`): invoke `session-observer` in `end-session` mode, display final report.
2. **Update Session Status**: set `status: "closed"`, clear `state.json.active_session`. Execute "Session Complete" token tracking.
3. **Read Session for Summary**: extract artifacts from session file.
4. **User Review**: AskUserQuestion to approve / refine / add more.
5. **Generate Output**: invoke `output-generation` skill with the workflow-specific reference (`references/specs-srs.md`, `references/design-arc42.md`, `references/brainstorm.md`, or `references/roundtable-summary.md`). Handoff variables (`OUTPUT_MERGE_MODE`, `OUTPUT_FORMAT`, `FOCUS_AREA`) wired by the master per launcher context.

Output stays workflow-specific (different documents), but Phase 3 orchestration is now centralized in the master rather than duplicated per command.

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
| `references/strategy-hooks.md` | Strategy-specific Phase 2 variation hooks (debate_role, debate_phase, future hat_role): contract documented and wired via Option B (Phase 4). See `references/strategy-hook-resolution.md` for the 3-branch dispatch and `references/strategy-resolution.md` for the D3 hierarchy |

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
- **v3.0 (2026-05, TECH-002 Phase 7B.5)**: SKILL.md restructured to thin overview pointing to `phase-2-core.md` (executable Phase 2 single-source) and per-type artifact schemas.
- **v3.1 (2026-05, TECH-002 Phase 8)**: Phase structure section rewritten. Phase 1 (session setup) and Phase 3 (close-out + output dispatch) moved out of each workflow command into the master orchestrator `commands/roundtable.md`. Thin launchers (`specs.md`, `design.md`, `brainstorm.md`) Read-and-follow the master.

---

*Referenced by: `commands/roundtable.md` (master orchestrator, runs PHASE 0+1+3+4 and delegates PHASE 2 to `phase-2-core.md`); `commands/specs.md`, `commands/design.md`, `commands/brainstorm.md` (thin launchers, Read-and-follow the master per Pattern 1, see ADR-0011 Phase 8 addendum).*

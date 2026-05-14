# Phase 2 Core Algorithm — Canonical Reference

> **Status**: descriptive reference (not executable). The three commands `/s2s:specs`, `/s2s:design`, `/s2s:brainstorm` each implement Phase 2 Round Execution Loop inline. This document captures the canonical algorithm they share, with the parameterized differences made explicit. It is the single source of truth for the Phase 2 contract and the target spec for the future Phase 7B "deep extraction" refactor (where commands become thin launchers that delegate to a single executable algorithm).
>
> **Maintenance rule**: when changing the Phase 2 loop in any command, update this doc in the same commit. Drift here is the indicator that uniformity has been lost again.

---

## 1. Workflow profiles

The same algorithm runs in three flavors, parameterized by `workflow_type`. Every workflow-specific value is captured in a **profile YAML** under `skills/roundtable-execution/profiles/`. The algorithm in §2 references profile values via `{{profile.X}}` paths (or, until 7B.4 lands, via narrative reference to "the loaded profile").

**Profiles**:
- `profiles/specs.yaml`
- `profiles/design.yaml`
- `profiles/brainstorm.yaml`

**Schema documentation**: `references/profile-schema.md` (canonical schema + field-to-§1 mapping + validation rules + how-to-add-a-workflow guide).

### Human-readable summary

For quick reference, the workflow differences captured by the profiles:

| Parameter | `specs` | `design` | `brainstorm` | Profile path |
|-----------|---------|----------|--------------|--------------|
| `workflow_type` literal | `"specs"` | `"design"` | `"brainstorm"` | `workflow_type` |
| `topic_pattern` | `"Requirements definition for {project_name}"` | `"Architecture design for {project_name}"` | `"{topic}"` (from `--topic`) | `topic.pattern` |
| `state.json.phase` | `"requirements"` | `"design"` | `"{current_phase}"` (variable) | `state_phase` |
| Participants (4) | PM, UX, BA, QA | Arch, Sec, TechLead, DevOps | PM, Arch, TechLead, DevOps | `participants.default` |
| Artifact types | REQ, BR, NFR, EX, OQ, CONF | ARCH, COMP, INT, OQ, CONF | IDEA, RISK, MIT, OQ, CONF | `artifact_types[].prefix` |
| Progress axis | `agenda` | `agenda` | `disney_phase` | `progress.axis` |
| Default agenda count | 6 | 5 | n/a | `progress.agenda_count` |
| `updates_since_last_round.*_changes` | `agenda_changes` | `agenda_changes` | `phase_changes` | `progress.changes_field` |
| Synthesis input progress fields | `full_agenda` + `focus_topic` | same | `phases_status` + `current_phase` + `artifacts_summary` | `progress.synthesis_input_fields` |
| Synthesis output progress field | `agenda_update` | `agenda_update` | `phase_recommendation` | `progress.synthesis_output_field` |
| Round summary tag | `topic_id` | `topic_id` (+ optional `debate_phase` for debate) | `disney_phase` | `round_summary.tag_field` |
| `next` values | `continue` / `conclude` / `escalate` | same | + **`phase`** | `next_values` |
| Step 2.6d Phase Transition | n/a | n/a | **present** | `has_phase_transition` |
| Step 2.1 display block | minimal | minimal | rich (Disney phase rules) | `display_block_style` |

The table is informational; the authoritative source is each profile YAML. When updating a workflow value, edit the profile YAML and update this table in the same commit.

> **Out-of-scope drifts** known but not yet fixed:
> - `session-schema.md:567` lists design artifact types as `ARCH-*, COMP-*, CONF-*, OQ-*` (no `INT-*`); design profile uses `INT-*`. Schema doc incomplete.
> - `session-schema.md:568` does not list `CONF-*` for brainstorm; brainstorm profile defines `CONF-*`. Same shape of issue.
>
> These are tracked as follow-ups; they affect schema docs, not the loop.

---

## 2. Round Loop algorithm (canonical)

Each round runs the steps below in order. References to "profile" mean values from §1 for the active `workflow_type`.

### Step 2.0 — Context Capacity Check

Identical across all three commands.

1. Read `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/token-tracking.md`
2. Always execute "Script Location" (verify script exists, store path as `TOKEN_SCRIPT`)
3. Execute "Context Capacity Check" (every round, computes `SHOULD_STOP` / `SHOULD_WARN`)

Token checkpoints fire later: T1 after 2.2, T2 after 2.3, T3 after 2.4.

### Step 2.1 — Display Round Start

- **specs / design**: minimal display ("agenda status and artifact counts").
- **brainstorm**: rich block showing current Disney phase + per-phase rules. *(Necessary; the phase machine drives the entire UX.)*

Then update `state.json` with the same shape across workflows; only `workflow_type`, `phase`, and `strategy` differ. Always preserve any pre-existing `active_plan` value.

### Step 2.2 — Facilitator Question

`IF agent_state.facilitator.agent_id` is set AND not first round of new session: **resume** facilitator agent. **ELSE**: fresh invocation.

Input YAML (canonical fields, parameterized values):
- `action: "question"`
- `round`, `topic` (from `topic_pattern`), `strategy`, `phase`, `workflow_type`
- `escalation_config` (from `config-snapshot.yaml`)
- `project_context` (from `context-snapshot.yaml`); design adds `requirements_summary`; brainstorm adds `brainstorm_topic`
- `session_state.artifacts` (typed by profile)
- Progress axis: `agenda[]` (specs/design) **or** `phases_status[]` + `disney_phase_rules` (brainstorm)
- `participants` (from profile)

On resume only, also: `updates_since_last_round` with `agenda_changes` (specs/design) or `phase_changes` (brainstorm).

On fresh only, also: `project_scope`, `workspace_scope`, `cross_cutting_decisions` (workspace-awareness fields).

Facilitator returns: `decision`, `question`, `exploration`, `participants`, `participant_context.{shared, overrides}`. For brainstorm, `decision.focus_type` is `"disney_phase"` (not `agenda`/`conflict`/`open_question`).

**IF `verbose_flag == true`**: write `rounds/{NNN}-01-facilitator-question.yaml` (see `verbose-dump-format.md` for canonical schema). Save FULL `participant_context.shared` content; never summarize.

Save `agent_state.facilitator.{agent_id, last_round, last_action: "question"}` to session.

→ **Token checkpoint T1**: `bash "<TOKEN_SCRIPT>" capture "{session-id}" T1`

### Step 2.3 — Participant Responses

**Critical context-passing rule**: participants have `tools: []`. They cannot read files. Copy `participant_context.shared` VERBATIM (never summarize/truncate). If incomplete, participants will hallucinate.

For each of the 4 participants from the profile, in a **single message** (parallel execution):
- `IF agent_state.participants.{id}.agent_id` is set AND continuation: **resume**. **ELSE**: fresh invocation.
- For brainstorm only, include `disney_phase_instructions` block (per-phase guidance for participants).
- Pass `context.{project_summary, relevant_artifacts, open_conflicts, open_questions, recent_rounds}` verbatim from facilitator response.

Each participant returns the canonical schema: `position`, `rationale`, `trade_offs`, `concerns`, `suggestions`, `confidence`, `references`. Brainstorm adds phase-specific `ideas`, `risks`, `mitigations`.

**IF `verbose_flag == true`**: write `rounds/{NNN}-02-{participant-id}.yaml`. Header comment is `# Round {N} - {Role} Response` (or `…Response ({disney_phase} phase)` for brainstorm). Capture ALL response fields including `rationale`, `concerns`, `suggestions` — these are returned in every workflow and must be preserved.

Save `agent_state.participants.{id}.{agent_id, last_round}` for each participant.

→ **Token checkpoint T2**

### Step 2.4 — Facilitator Synthesis

`IF agent_state.facilitator.agent_id` exists (same facilitator from 2.2): **resume** with `action: "synthesis"`. **ELSE**: fresh.

Input YAML:
- `action: "synthesis"`
- `round`, `topic`, `strategy`, `phase`
- `escalation_config`
- `question_asked` (from 2.2)
- `responses` (keyed by participant ids from profile, full content for decision-making)
- Progress fields:
  - specs/design: `full_agenda[]` + `focus_topic` (with `done_when` criteria)
  - brainstorm: `phases_status[]` + `current_phase` + `artifacts_summary`
- `open_conflicts`, `artifacts_count`

Facilitator returns:
- `synthesis` (2-4 sentences)
- `proposed_artifacts[]` (typed per profile)
- `resolved_conflicts[]`
- Progress update: `agenda_update` (specs/design) or `phase_recommendation` (brainstorm)
- `constraints_check` (`rounds_completed`, `min_rounds`, `can_conclude`, `reason`)
- `next` (`continue` / `conclude` / `escalate` for specs/design; **plus `phase`** for brainstorm)
- `next_focus`, `escalation_reason`

**IF `verbose_flag == true`**: write `rounds/{NNN}-03-facilitator-synthesis.yaml`. Canonical structure (per `verbose-dump-format.md:200-266`):

```yaml
result:
  artifacts_proposed: {count}
  conflicts_resolved: {count}      # MANDATORY in all workflows
  status: "closed"

verification:
  expected_artifacts:              # MANDATORY: list of {map, expected_keys}
    - map: "artifacts.{type}"
      expected_keys: [...]
  round_summary:                    # MANDATORY
    expected_round: {N}
    required_fields: [...]
  agenda_status:                    # specs/design
    topic_id: "..."
    expected_status: "..."
  # OR phases_status: for brainstorm
  metrics_consistency:              # MANDATORY
    rounds_completed: {N}
    artifacts_total: {sum}
  context_propagation:              # MANDATORY
    participant_context_keys: [...]
```

Update `agent_state.facilitator.{agent_id, last_action: "synthesis"}`.

→ **Token checkpoint T3**

### Step 2.5 — Process Artifacts

For each `proposed_artifact` from facilitator:
1. **Count existing**: count keys in `artifacts.{type}` in session file.
2. **Assign ID**: next available with the prefix from the profile.
3. **Edit session file**: add the artifact to `artifacts.{type}` with full content per the type-specific schema (see each command for the schemas).

Artifacts are EMBEDDED in the session file, not separate files (per ADR-0008/0010).

**For resolved conflicts**: edit the existing `CONF-*` entry in place (`state: resolved`, `resolution: ...`) and append a `rounds[].artifacts_transitioned` entry for audit.

### Step 2.6 — Update Session File

Single Edit operation appending to `rounds:` and updating top-level fields:

1. **`rounds[]` entry**: `round`, `timestamp`, `topic_id` (specs/design) or `disney_phase` (brainstorm), `facilitator_question`, `synthesis_summary`, `participant_positions{}`, `key_decisions[]`, `artifacts_created[]`, `resolved_conflicts[]`, `resolved_questions[]`, `consensus_reached`, `next_action`. Optional `debate_phase` for debate strategy in design.
2. **`timing.updated_at`** ISO timestamp.
3. **Progress update**: `agenda[topic].status` (specs/design) or `phases[name].status` (brainstorm).
4. **`metrics`**: `rounds_completed`, `artifacts.total`, `artifacts.by_type`, `artifacts.by_state`, axis-specific count (`topics.closed/total` or `phases.{dreamer,realist,critic}` round counts), `consensus_rate`, `tokens.total` + `tokens.by_round[]`.

### Step 2.6b — Validate Round Output

Identical across workflows: read `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/round-validation.md` and execute its checks. **Non-blocking**: display warnings, continue.

### Step 2.6c — Diagnostic Observation (`IF --diagnostic`)

Identical across workflows except `workflow_type` parameter:

```yaml
mode: "per-round"
session_path: ".s2s/sessions/{session-id}"
round: {round_number + 1}
workflow_type: "{specs|design|brainstorm}"
strategy: "{strategy_to_use}"
```

Use the `session-observer` agent. Display its result. If `recommendation == "Stop for investigation"`, ask user via `AskUserQuestion`: `Investigate now / Continue anyway / Abort session`.

> **Known issue (TECH-002 baseline F2)**: in current behavior, `session-observer` is invoked only at `end-session` (1 invocation per session) instead of expected 4 (3 per-round + 1 final). The activation pattern at this step is consistently skipped. Candidate for Phase 7B fix.

### Step 2.7 — Display Round Recap

Show synthesis, new artifacts, resolved conflicts, axis status (agenda or phase). Token recap section per `token-tracking.md`.

### Step 2.8 — Handle Interactive Mode

Identical text across workflows:
- `IF interactive_flag == true`: ask user to continue / skip / exit (brainstorm: skip phase).
- `IF interactive_flag == false`: proceed automatically (do NOT stop, do NOT ask). Stop conditions: `SHOULD_STOP` (context), `round_number >= max_rounds`, `next == "escalate"`, or `interactive_flag == true`.

### Step 2.6d — Phase Transition (BRAINSTORM ONLY)

Brainstorm-only. When facilitator returns `next: "phase"`: advance `current_phase` (`dreamer → realist → critic`), mark previous phase `completed`, mark new phase `active`. When in `critic` phase and facilitator returns `next: "conclude"`: exit loop.

### Step 2.9 — Evaluate Next Action (CRITICAL)

**MANDATORY `min_rounds` enforcement** (uniform across workflows after TECH-002 Phase 3):

```
IF round_number < min_rounds (from config) AND next == "conclude":
  OVERRIDE next to "continue"
  Display: "⚠️ min_rounds not reached ({round_number}/{min_rounds}), continuing..."
```

Then dispatch on `next`:
- `continue`: loop back to Step 2.1
- `phase` (brainstorm only): advance Disney phase via 2.6d
- `conclude`: proceed to Phase 3 (only valid in `critic` phase for brainstorm)
- `escalate`: ask user with `AskUserQuestion`, then continue or conclude

→ **Session Complete token checkpoint** fires at Phase 3 Step 3.1.

---

## 3. Cross-reference: command line numbers

For maintainers checking parity. Updated at TECH-002 Phase 3 (2026-05-05).

| Step | `commands/specs.md` | `commands/design.md` | `commands/brainstorm.md` |
|------|---------------------|----------------------|--------------------------|
| 2.0 Context Capacity | 476-491 | 374-389 | 350-365 |
| 2.1 Display + state.json | 493-519 | 391-417 | 367-410 |
| 2.2 Facilitator Question | 521-782 | 419-670 | 412-655 |
| 2.3 Participant Responses | 784-1011 | 672-899 | 657-891 |
| 2.4 Facilitator Synthesis | 1013-1300 | 901-1167 | 893-1166 |
| 2.5 Process Artifacts | 1302-1439 | 1169-1297 | 1168-1286 |
| 2.6 Update Session File | 1441-1530 | 1299-1388 | 1288-1383 |
| 2.6b Validate | 1532-1536 | 1390-1394 | 1385-1389 |
| 2.6c Diagnostic | 1538-1575 | 1396-1433 | 1391-1428 |
| 2.6d Phase Transition | n/a | n/a | 1430-1442 |
| 2.7 Round Recap | 1577-1579 | 1435-1437 | 1444-1447 |
| 2.8 Interactive | 1581-1588 | 1439-1446 | 1449-1456 |
| 2.9 Evaluate Next | 1590-1593 | 1448-1462 | 1458-1473 |

> Line numbers will drift after edits. Treat this as a snapshot; re-anchor by section heading when navigating.

---

## 4. Phase 7B handoff notes

To make this document executable (Phase 7B), the following would need to be addressed:

1. **Profile loading**: define a YAML schema for the `workflow_type` profile (§1 table), store under `skills/roundtable-execution/profiles/{specs,design,brainstorm}.yaml`. Each command becomes a thin launcher that selects the profile and invokes the unified algorithm.
2. **Artifact schemas**: extract the per-type artifact schemas (currently inlined in each command's Step 2.5) into `references/artifact-schemas/{type}.md` with one canonical schema per artifact type.
3. **Disney phase machine**: factor out brainstorm's Step 2.6d into a state machine doc that `next: "phase"` consumes. Currently inline in `commands/brainstorm.md`.
4. **Session-observer activation**: the 2.6c invocation pattern is consistently skipped by the runtime (baseline finding F2). Investigate cause before extraction; the abstraction won't fix a runtime activation bug.
5. **Strategy hooks**: support per-strategy variations (e.g., `debate_phase` field in design's round summary, six-hats overrides) without re-introducing per-command divergence.
6. **Re-evaluate Claude Code platform features**: by the time Phase 7B starts, newer Claude Code patterns (richer agent-invocation primitives, deferred tools, scheduled wakeups) may simplify several flows. Re-baseline before designing the unified executor.

Until Phase 7B lands, this doc is the contract. Keep the three commands aligned to it.

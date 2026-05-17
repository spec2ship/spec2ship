# Workflow Profile Schema

> **Status**: canonical schema (TECH-002 Phase 7B)
> **Consumers**: `phase-2-core.md` reads profile values via `{{profile.X}}` references; Phase 1 init in commands may consult some fields.
> **Profiles**: `profiles/specs.yaml`, `profiles/design.yaml`, `profiles/brainstorm.yaml`.

Each workflow profile YAML captures every workflow-specific value referenced by the canonical Phase 2 Round Loop algorithm. The schema is a tight 1-to-1 mapping from `phase-2-core.md` §1 (workflow profiles table) plus the minimum data needed to execute Phase 2 correctly.

## Schema

```yaml
# Top-level: workflow identification
workflow_type: <string>            # one of: "specs" | "design" | "brainstorm"

# Topic generation for session.yaml.topic + state.json
topic:
  pattern: <string>                # literal with {placeholder} substitutions
                                   # e.g., "Requirements definition for {project_name}"
                                   # e.g., "{topic}" (free-form from --topic arg)
  source: <string>                 # where the placeholder value comes from
                                   # values: "context-snapshot.project_name" | "cli-arg.topic"

# state.json.active_session.phase field (written by Step 2.1 every round)
state_phase: <string>              # literal value to write
                                   # e.g., "requirements" | "design"
                                   # OR "{current_phase}" (variable, substituted with dreamer/realist/critic)

# Strategy defaults and constraints
default_strategy: <string>         # e.g., "consensus-driven" | "debate" | "disney"
strategy_constraints:
  allowed: [<string>, ...]         # strategies OFFICIALLY SUPPORTED for this workflow
                                   # (per roundtable-strategies/SKILL.md compatibility table).
                                   # If user passes --strategy not in this list, command warns
                                   # but does not block (when forced: false).
                                   # NOTE: command frontmatter argument-hint may show a shorter
                                   # list for UX brevity; this profile field is authoritative.
  forced: <bool>                   # if true, --strategy CLI value is IGNORED regardless of
                                   # what user passes; default_strategy is always used.
                                   # Only brainstorm has forced: true (disney).

# Default participants (4 fixed for specs/design; configurable for brainstorm)
participants:
  default: [<participant-id>, ...] # ordered list of default participant agent ids
  configurable: <bool>             # if true, --participants flag overrides default

# Artifact types this workflow creates
artifact_types:
  - prefix: <string>               # uppercase prefix, e.g., "REQ"
    session_key: <string>          # snake_case key in session.yaml.artifacts
                                   # e.g., "requirements", "architecture_decisions"
    is_primary: <bool>             # primary artifacts (main output) vs secondary

# Progress tracking axis
progress:
  axis: <string>                   # "agenda" | "disney_phase"
  
  # ONLY if axis == "agenda"
  agenda_count: <int>              # number of default topics
  agenda_reference: <string>       # path relative to skill root, e.g., "references/agenda-specs.md"
  
  # Field name in updates_since_last_round.X_changes
  changes_field: <string>          # "agenda_changes" | "phase_changes"
  
  # Fields the synthesis INPUT contains (sent to facilitator at Step 2.4)
  synthesis_input_fields: [<string>, ...]
                                   # specs/design: ["full_agenda", "focus_topic"]
                                   # brainstorm: ["phases_status", "current_phase", "artifacts_summary"]
  
  # Field the synthesis OUTPUT contains (returned by facilitator at Step 2.4)
  synthesis_output_field: <string>
                                   # specs/design: "agenda_update"
                                   # brainstorm: "phase_recommendation"

# Round summary tag (in rounds[].* entry written at Step 2.6)
round_summary:
  tag_field: <string>              # "topic_id" | "disney_phase"

# Phase 2 control flow (Step 2.9 dispatch)
next_values: [<string>, ...]       # allowed values returned by facilitator at Step 2.4
                                   # specs/design: ["continue", "conclude", "escalate"]
                                   # brainstorm: ["continue", "phase", "conclude", "escalate"]

# Step 2.6d Phase Transition gating
has_phase_transition: <bool>       # true only for brainstorm

# Step 2.1 Display Round Start style
display_block_style: <string>      # "minimal" | "rich"
                                   # minimal: 1-line agenda + artifact counts (specs/design)
                                   # rich: full Disney phase rules block (brainstorm)
```

## Field-to-§1 mapping

Every cell in `phase-2-core.md` §1 maps to exactly one profile field:

| §1 table parameter | Profile path |
|--------------------|--------------|
| `workflow_type` literal | `workflow_type` |
| `topic_pattern` | `topic.pattern` + `topic.source` |
| `state.json.phase` | `state_phase` |
| Participants (4) | `participants.default` |
| Artifact types | `artifact_types[].prefix` |
| Progress axis | `progress.axis` |
| Default agenda count | `progress.agenda_count` |
| `updates_since_last_round.*_changes` | `progress.changes_field` |
| Synthesis input progress field | `progress.synthesis_input_fields` |
| Synthesis output progress field | `progress.synthesis_output_field` |
| Round summary tag | `round_summary.tag_field` |
| `next` values | `next_values` |
| Step 2.6d Phase Transition | `has_phase_transition` |
| Step 2.1 display block | `display_block_style` |

Additional fields not in §1 but required for execution:
- `topic.source`: tells Step 2.2 where to fetch the topic placeholder value
- `default_strategy` + `strategy_constraints`: required for Phase 1 strategy resolution
- `participants.configurable`: required for Phase 1 CLI flag handling
- `artifact_types[].session_key`: required for Step 2.5/2.6 to write artifacts to the correct map
- `artifact_types[].is_primary`: required for Phase 3 output generation prioritization
- `progress.agenda_reference`: required for Phase 1 agenda.yaml population

## How profiles are loaded

Pattern (implemented in Phase 7B.4b):

```
1. Command parses CLI args, determines workflow_type ("specs" | "design" | "brainstorm").
2. Command Reads `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/profiles/{workflow_type}.yaml`.
3. Command Reads `${CLAUDE_PLUGIN_ROOT}/skills/roundtable-execution/references/phase-2-core.md`.
4. Command executes phase-2-core.md instructions, substituting {{profile.X}} references with loaded profile values.
```

## Adding a new workflow

To support a new workflow (e.g., `retrospective`):
1. Create `profiles/retrospective.yaml` matching this schema.
2. Create `commands/retrospective.md` that loads the profile and Reads phase-2-core.md.
3. Add an entry to §1 table of `phase-2-core.md` documenting the new workflow's parameter values.

No changes to `phase-2-core.md` execution logic are needed — it's profile-agnostic.

## Schema validation

A profile is valid IFF:
- All required top-level keys present (workflow_type, topic, state_phase, default_strategy, strategy_constraints, participants, artifact_types, progress, round_summary, next_values, has_phase_transition, display_block_style).
- `workflow_type` ∈ {"specs", "design", "brainstorm"}.
- `progress.axis` ∈ {"agenda", "disney_phase"}.
- If `progress.axis == "agenda"`: `agenda_count`, `agenda_reference`, `changes_field`, `synthesis_input_fields`, `synthesis_output_field` all present.
- If `progress.axis == "disney_phase"`: `has_phase_transition` must be `true`; `next_values` must include `"phase"`.
- Every `artifact_types[]` entry has both `prefix` and `session_key`.
- `display_block_style` ∈ {"minimal", "rich"}.

Manual validation is sufficient for now. Phase 8 (or later) may add a validation script.

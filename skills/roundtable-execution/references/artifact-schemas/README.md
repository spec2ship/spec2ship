# Artifact Schemas

Canonical per-type artifact schemas. Used by `phase-2-core.md` Step 2.5 when processing facilitator-proposed artifacts.

| Type | File | Workflows | Profile session_key |
|------|------|-----------|--------------------|
| `REQ-*` | `req.md` | specs | `requirements` |
| `BR-*` | `br.md` | specs | `business_rules` |
| `NFR-*` | `nfr.md` | specs | `nfr` |
| `EX-*` | `ex.md` | specs | `exclusions` |
| `ARCH-*` | `arch.md` | design | `architecture_decisions` |
| `COMP-*` | `comp.md` | design | `components` |
| `INT-*` | `int.md` | design | `interfaces` |
| `IDEA-*` | `idea.md` | brainstorm | `ideas` |
| `RISK-*` | `risk.md` | brainstorm | `risks` |
| `MIT-*` | `mit.md` | brainstorm | `mitigations` |
| `OQ-*` | `oq.md` | all (specs/design use `topic_id`; brainstorm uses `disney_phase`) | `open_questions` |
| `CONF-*` | `conf.md` | all (same workflow tag pattern as OQ) | `conflicts` |

## Common conventions

All artifact schemas share these conventions:

- **`state` field** (ADR-0010): single state field, lifecycle managed via state transitions audited in `rounds[].artifacts_transitioned`. Allowed values vary per type — see each schema.
- **`created_round` field**: integer, the round number when the artifact was first proposed.
- **Workflow context tag**: `topic_id` (specs/design, refers to agenda topic) OR `disney_phase` (brainstorm, refers to active Disney phase).
- **`proposed_by`** + **`supported_by`**: provenance fields. `proposed_by` is usually `"facilitator"` (artifacts come from synthesis); `supported_by` lists participant ids that endorsed the artifact.
- **`related_to`**: optional array of artifact IDs from any type, indicating relationships.
- **Embedding rule**: all artifacts live inside `session.yaml.artifacts.{session_key}` map, NOT separate files (per ADR-0008/0010).

## How Step 2.5 uses these

For each `proposed_artifact` returned by Step 2.4 facilitator synthesis:

1. Look up the matching `PROFILE.artifact_types[]` entry by `prefix` to find the `session_key`.
2. Count existing entries in `session.yaml.artifacts.{session_key}` to determine next ID (e.g., `REQ-015` if 14 exist).
3. Read this directory's schema file for the artifact type and produce a YAML object matching it.
4. Edit `session.yaml` to add the new artifact under `artifacts.{session_key}.{new_id}`.

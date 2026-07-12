---
name: Output Generation
description: "This skill generates output documents from roundtable session artifacts. Supports specs (SRS), design (arc42 + ADR), brainstorm (summary + ideas), and roundtable (generic summary). Use after roundtable completion.
  Trigger: 'generate output', 'create requirements document', 'generate architecture', 'save brainstorm', 'generate roundtable summary'."
version: 1.2.0
---

# Output Generation

Generates output documents from session artifacts. Common logic is here; format-specific pseudo-code is in references.

## When to Use

Called by workflow commands at PHASE 3 completion:
- `/s2s:specs` - generates requirements.md
- `/s2s:design` - generates architecture.md + ADRs
- `/s2s:brainstorm` - generates summary + updates ideas.md
- `/s2s:roundtable` (native) - generates generic discussion summary

## Input Required

From calling command:
- `workflow_type`: specs | design | brainstorm | roundtable
- `session_id`: current session ID
- `session_folder`: path to session folder
- `mode`: merge | override (determined earlier by command)

## Step 1: Determine Format

| Workflow | Default Format | Output Files |
|----------|---------------|--------------|
| specs | srs | `.s2s/requirements.md` |
| design | arc42 | `.s2s/architecture.md` + `.s2s/decisions/ADR-*.md` |
| brainstorm | summary | `.s2s/sessions/{id}-summary.md` + `.s2s/ideas.md` |
| roundtable | summary | `.s2s/sessions/{id}-summary.md` (no persistent project-file update) |

Future formats (not yet implemented):
- specs: srs-lite, user-stories
- design: c4, simple

## Step 2: Handle Merge vs Override

**IF mode == "merge"**:
1. Read existing output file
2. Find highest existing artifact IDs (REQ-*, COMP-*, etc.)
3. Renumber new artifacts starting from next available
4. Append new sections to existing document
5. Update metadata (date, session reference)

**IF mode == "override"**:
1. Create new file from scratch using format template

## Step 3: Read Session Data

**YOU MUST Read** from session file `.s2s/sessions/{session-id}.yaml`:
- `artifacts.*` - all artifact collections
- `metrics.*` - counts and statistics
- `topic` - session topic

**YOU MUST Read** from `{session-folder}/context-snapshot.yaml`:
- `project_name`
- `description`
- `scope`
- `constraints`

## Step 4: Generate Output

Based on workflow_type, read the corresponding reference and follow its pseudo-code:

| Workflow | Reference |
|----------|-----------|
| specs | `references/specs-srs.md` |
| design | `references/design-arc42.md` |
| brainstorm | `references/brainstorm.md` |
| roundtable | `references/roundtable-summary.md` |

## Step 5: Fidelity Check (no silent loss)

After writing the output file(s), verify that no approved artifact was silently dropped
during rendering (VKT-063):

1. Collect from the session file every artifact ID whose state is `approved` / `accepted`
   (all collections under `artifacts.*`).
2. For each ID, check that the ID string appears verbatim in at least one generated
   output file (use Grep on the file(s) written in Step 4).
3. **IF any ID is missing**: go back to the output file and add the artifact to its
   proper section (see the format reference for the section mapping), then re-check.
4. Report the result in the output summary: `Fidelity check: all {N} artifact IDs
   rendered` or `MISSING: {list}` (only if step 3 could not place one — this should
   not happen).

This check is MANDATORY for specs and design (persistent project documents). For
brainstorm and roundtable summaries it is recommended but non-blocking.

## Step 6: Update CONTEXT.md

After document generation, update `.s2s/CONTEXT.md`:
- Update phase to workflow_type (specs | design)
- Add reference to generated document
- Update "Last updated" date

**Note**: brainstorm + roundtable do NOT update CONTEXT.md phase (both are exploratory/discussion workflows, not phase-transition markers).

## Step 7: Display Output Summary

Format depends on workflow - see reference file for specific summary format.

Common elements:
- Document path(s) created
- Mode used (merge | override)
- Artifact counts
- Next steps suggestions

---

## Reference Files

| File | Workflow | Content |
|------|----------|---------|
| `references/specs-srs.md` | specs | SRS template pseudo-code |
| `references/design-arc42.md` | design | Architecture + ADR pseudo-code |
| `references/brainstorm.md` | brainstorm | Summary + ideas.md pseudo-code |
| `references/roundtable-summary.md` | roundtable | Generic discussion summary pseudo-code (added TECH-002 Phase 4) |

---
*Used by: specs.md, design.md, brainstorm.md, roundtable.md (Phase 4+), roundtable-execution*

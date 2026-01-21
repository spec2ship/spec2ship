---
name: Output Generation
description: "This skill generates output documents from roundtable session artifacts. Supports specs (SRS), design (arc42 + ADR), and brainstorm (summary + ideas). Use after roundtable completion.
  Trigger: 'generate output', 'create requirements document', 'generate architecture', 'save brainstorm'."
version: 1.0.0
---

# Output Generation

Generates output documents from session artifacts. Common logic is here; format-specific pseudo-code is in references.

## When to Use

Called by workflow commands at PHASE 3 completion:
- `/s2s:specs` - generates requirements.md
- `/s2s:design` - generates architecture.md + ADRs
- `/s2s:brainstorm` - generates summary + updates ideas.md

## Input Required

From calling command:
- `workflow_type`: specs | design | brainstorm
- `session_id`: current session ID
- `session_folder`: path to session folder
- `mode`: merge | override (determined earlier by command)

## Step 1: Determine Format

| Workflow | Default Format | Output Files |
|----------|---------------|--------------|
| specs | srs | `.s2s/requirements.md` |
| design | arc42 | `.s2s/architecture.md` + `.s2s/decisions/ADR-*.md` |
| brainstorm | summary | `.s2s/sessions/{id}-summary.md` + `.s2s/ideas.md` |

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

## Step 5: Update CONTEXT.md

After document generation, update `.s2s/CONTEXT.md`:
- Update phase to workflow_type (specs | design)
- Add reference to generated document
- Update "Last updated" date

**Note**: brainstorm does NOT update CONTEXT.md phase.

## Step 6: Display Output Summary

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

---
*Used by: specs.md, design.md, brainstorm.md, roundtable-execution*

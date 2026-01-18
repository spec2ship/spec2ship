# QA Framework

Documentation for the Spec2Ship QA validation system.

## Overview

The QA framework validates roundtable sessions run with `--diagnostic` flag. It detects issues in session execution and helps identify bugs in commands, agents, and skills.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│ /s2s:session:validate {session-id}                              │
│                                                                 │
│  1. Command reads session file for context                      │
│  2. Command invokes session-qa agent with context               │
│  3. Agent executes applicable checks                            │
│  4. Agent writes evidence to .s2s/qa/evidence/                  │
│  5. Agent returns summary                                       │
└─────────────────────────────────────────────────────────────────┘
```

## Components

| Component | Path | Purpose |
|-----------|------|---------|
| **session-qa agent** | `agents/validation/session-qa.md` | Executes checks, produces evidence |
| **validate command** | `commands/session/validate.md` | Invokes agent, displays results |
| **evidence files** | `.s2s/qa/evidence/{session-id}.yaml` | Stores validation results |

## Check Catalog

### DIAG-001: Verbose Dump Completeness

- **When**: diagnostic_mode = true
- **What**: Verifies participant dump files have all required fields
- **Detects**: Missing `started_at`, `input`, `tokens` in resume mode

### DIAG-002: Participant Context Propagation

- **When**: diagnostic_mode = true
- **What**: Verifies facilitator's participant_context.shared is saved
- **Detects**: Missing context that participants need

### DIAG-003: Debate Phase Tracking

- **When**: strategy = debate AND diagnostic_mode = true
- **What**: Verifies debate phases are tracked in round summary
- **Detects**: Missing or incorrect phase progression

## Dependencies

### yq (required)

The QA framework uses `yq` for reliable YAML parsing.

**Installation:**
```bash
# macOS
brew install yq

# Linux (snap)
snap install yq

# Linux (binary)
wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq
chmod +x /usr/local/bin/yq
```

**Verify:**
```bash
yq --version
# yq (https://github.com/mikefarah/yq/) version v4.x.x
```

## Evidence Schema

Evidence files are stored in `.s2s/qa/evidence/{session-id}.yaml`:

```yaml
session_id: "20260116-specs-spec2ship"
validated_at: "2026-01-16T10:30:00Z"

context:
  workflow_type: specs
  strategy: consensus-driven
  diagnostic_mode: true
  rounds_completed: 2

results:
  - check: DIAG-001
    status: partial
    files_checked: [...]
    results: [...]

  - check: DIAG-002
    status: fail
    files_checked: [...]
    results: [...]

summary:
  total: 3
  passed: 0
  failed: 1
  partial: 1
  skipped: 1

critical_findings:
  - "DIAG-001: Dump files missing fields in resumed rounds"
  - "DIAG-002: participant_context.shared not saved to dump"
```

## Design Decisions

### QA-001: Self-Contained Agent

All check definitions are inline in the agent markdown. No external scripts or separate check files.

**Rationale:**
- Skills don't support attached files (only `.md` with frontmatter)
- Agent can't access plugin installation path
- Agent copies bash snippets directly to Bash tool

### QA-002: Script-First with LLM Fallback

| Task Type | Approach |
|-----------|----------|
| Field exists? | `yq -e '.field'` |
| Count files | `find \| wc -l` |
| Compare values | `[ "$a" = "$b" ]` |
| "Is progression logical?" | LLM judgment |
| "Are positions distinct?" | LLM semantic analysis |

**Rule:** Objective/deterministic → Script. Interpretation/judgment → LLM.

### QA-003: yq Dependency

Using `yq` (not `grep`) for YAML parsing ensures reliable field extraction even with complex nested structures.

### QA-004: Inline Bash Snippets

Each check contains copy-paste ready bash snippets. The agent copies these to the Bash tool for execution.

## Adding New Checks

To add a new check:

1. **Define in agent** (`agents/validation/session-qa.md`):
   - Add check definition with properties table
   - Add verification steps with bash snippets
   - Add evidence schema
   - Add to selection logic table

2. **Update documentation** (this file):
   - Add to Check Catalog
   - Document when/what/detects

3. **Test**:
   - Run a diagnostic session that should trigger the check
   - Run `/s2s:session:validate {session-id}`
   - Verify evidence file contains correct results

## Usage

```bash
# Run diagnostic session
/s2s:specs --new --diagnostic

# Validate session with diagnostic checks
/s2s:session:validate --level diagnostic 20260116-specs-myproject

# View evidence
cat .s2s/qa/evidence/20260116-specs-myproject.yaml
```

## References

- [session-qa agent](../../agents/validation/session-qa.md)
- [validate command](../../commands/session/validate.md)
- [yq documentation](https://mikefarah.gitbook.io/yq/)

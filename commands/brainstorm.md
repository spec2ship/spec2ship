---
description: Creative brainstorming session using the Disney strategy (Dreamer → Realist → Critic). Use for ideation and exploring new ideas without constraints.
allowed-tools: Bash(pwd:*), Bash(ls:*), Bash(mkdir:*), Bash(date:*), Read, Write, Edit, Glob, Task, AskUserQuestion
argument-hint: "topic" [--participants <list>] [--verbose] [--interactive]
skills: roundtable-execution, roundtable-strategies
---

# Brainstorm Session

Launches a creative brainstorming roundtable using the **Disney strategy** (Dreamer → Realist → Critic).

This strategy separates creative thinking from critical evaluation:
1. **Dreamer phase**: Think big, no constraints, what would be ideal?
2. **Realist phase**: What's feasible? How would we implement this?
3. **Critic phase**: What could go wrong? What risks should we address?

## Context

- Current directory: !`pwd`
- Directory contents: !`ls -la`
- Timestamp: !`date +"%Y%m%d-%H%M%S"`

---

## Interpret Context

Based on the Directory contents output, determine:

- **S2S initialized**: If `.s2s` directory appears → "yes", otherwise → "no"
- **Directory name**: Extract the last segment from pwd

---

## Instructions

### Parse Arguments

Extract from $ARGUMENTS:
- **topic**: Required. The subject for brainstorming (first quoted argument)
- **--participants**: Optional. Comma-separated list to override defaults

**Boolean flags**: `--verbose` and `--interactive` → parse as `true` if present, `false` if absent.

If topic is missing, ask using AskUserQuestion:
- "What would you like to brainstorm?"

### Validate Environment

If S2S initialized is "no":
- Display: "Warning: Not an s2s project. Results displayed but not saved."
- Continue anyway (brainstorm can work without full s2s setup)

### Determine Participants

Default participants for brainstorming:
- product-manager (user needs, business value)
- software-architect (structure, patterns)
- technical-lead (implementation, feasibility)
- devops-engineer (operations, deployment)

If --participants specified, use that list instead.

### Display Introduction

    Brainstorm Session Starting
    ═══════════════════════════

    Topic: {topic}
    Strategy: Disney (Dreamer → Realist → Critic)
    Participants: {list}

    Phase 1 (Dreamer): Think BIG, no constraints!
    Phase 2 (Realist): What's feasible? How to implement?
    Phase 3 (Critic): What could go wrong? What risks?

    Starting discussion...

### Launch Roundtable

**IMPORTANT: Follow the `roundtable-execution` skill instructions EXACTLY.**
**DO NOT use SlashCommand. Execute the roundtable inline using Task().**

#### Roundtable Configuration

Configure the roundtable with these parameters:
- **topic**: {parsed topic}
- **workflow_type**: "brainstorm"
- **strategy**: "disney"
- **output_type**: "summary"
- **participants**: {--participants or defaults: product-manager, software-architect, technical-lead, devops-engineer}
- **verbose**: {verbose_flag}
- **interactive**: {interactive_flag}

#### Execute Roundtable

**YOU MUST** execute these steps from `roundtable-execution` skill with workflow-specific values:

| Parameter | Value |
|-----------|-------|
| session_id | `{timestamp}-brainstorm-{topic-slug}` |
| workflow_type | `brainstorm` |
| strategy | `disney` |
| participants | `[product-manager, software-architect, technical-lead, devops-engineer]` |
| agenda | **None** (free-form creativity) |

**PHASE 2 - Session Setup:**

1. Create sessions directory: `mkdir -p .s2s/sessions`
2. Generate session ID: `{timestamp}-brainstorm-{topic-slug}`
3. **NOW use Write tool** to create `.s2s/sessions/{session-id}.yaml`:
```yaml
id: "{session-id}"
topic: "{topic}"
workflow_type: "brainstorm"
strategy: "disney"
status: "active"
started: "{ISO timestamp}"
participants:
  - id: product-manager
  - id: software-architect
  - id: technical-lead
  - id: devops-engineer
config:
  min_rounds: 3
  max_rounds: 20
  verbose: {verbose_flag}
  interactive: {interactive_flag}
  escalation:
    max_rounds_per_conflict: 3
    confidence_below: 0.5
    critical_keywords: ["security", "must-have", "blocking", "legal"]
current_phase: "dreamer"
rounds: []
```
4. **NOW use Edit tool** to update `.s2s/state.yaml` with `current_session: "{session-id}"`

**PHASE 3 - Round Execution Loop** (cycle through Disney phases: dreamer → realist → critic):

1. **Step 3.0.5**: Display current phase to terminal (Dreamer/Realist/Critic)
2. **Step 3.1**: **YOU MUST use Task tool NOW** to call facilitator for question
   - Include current Disney phase in prompt
   - Include escalation config section in prompt:
   ```
   === ESCALATION CONFIG ===
   max_rounds_per_conflict: 3
   confidence_below: 0.5
   min_rounds: 3
   critical_keywords: [security, must-have, blocking, legal]
   ```
3. **Step 3.2**: **YOU MUST launch ALL participant Tasks in SINGLE message**
   - This ensures blind voting (parallel execution)
   - **Store responses in `participant_responses` array:**
   ```
   participant_responses = [
     { id, role, position, rationale, concerns, confidence }
   ]
   ```
4. **Step 3.3**: **YOU MUST use Task tool** for facilitator synthesis
5. **Step 3.4**: **NOW use Edit tool** to append round to session file:
   - Append to `rounds:` array with: number, phase, question, synthesis, consensus, conflicts
   - **IF verbose_flag == true**: Include `responses:` with full participant_responses array
6. **Step 3.5**: Display round recap to terminal
7. **Step 3.6**: Evaluate next_action:
   - **min_rounds CHECK**: If round < 3 AND "conclude" → OVERRIDE to "continue"
   - **Phase progression**: dreamer (1+ rounds) → realist (1+ rounds) → critic (1+ rounds)
   - **Interactive mode**: Only ask user if `interactive_flag == true`

**PHASE 4 - Completion:**

1. **Update session status**: Edit session file, set `status: "completed"` and `completed_at: "{ISO timestamp}"`

2. **CRITICAL - Read session file for summary**:
   - **YOU MUST use Read tool** to read the completed session file
   - Extract consensus from each Disney phase (dreamer, realist, critic)
   - Extract unresolved conflicts (those without resolution)
   - This ensures summary matches persisted data (Single Source of Truth)

3. **Generate output**: Based on output_type ("summary"), create brainstorm summary

**Summary MUST be derived from session file, NOT from facilitator memory.**

### Process Results

After reading session file, extract from each phase:

1. **Dreamer phase ideas**: Big thinking, no constraints
2. **Realist assessment**: Feasibility evaluation
   - Immediately feasible
   - Requires more work
   - Long-term/aspirational
3. **Critic risks**: Identified risks with mitigations
4. **Consensus recommendations**: Agreed next steps

### Save Results (if S2S initialized)

If S2S is initialized:

1. Session YAML already created by roundtable:start

2. Generate summary markdown `.s2s/sessions/{session-id}-summary.md`:

```markdown
# Brainstorm: {Topic}

**Session**: {session-id}
**Date**: {date}
**Strategy**: Disney (Dreamer → Realist → Critic)
**Participants**: {list}

## Dreamer Phase Ideas

{Ideas from phase 1}

## Realist Assessment

### Immediately Feasible
{list}

### Requires More Work
{list}

### Long-term Vision
{list}

## Critic Risks

| Risk | Mitigation |
|------|------------|
| {risk} | {mitigation} |

## Recommended Next Steps

1. {step}
2. {step}

## Unresolved Questions

- {question}

---
*Generated by Spec2Ship /s2s:brainstorm*
```

### Output Summary

Display brainstorm results:

    Brainstorm Complete!
    ════════════════════

    Topic: {topic}
    Strategy: Disney (Dreamer → Realist → Critic)
    Participants: {count}

    Top Ideas:
    ──────────
    1. {idea 1}
    2. {idea 2}
    3. {idea 3}

    Feasibility:
    ────────────
    Ready now: {count} items
    Needs work: {count} items
    Long-term: {count} items

    Key Risks:
    ──────────
    - {risk 1}
    - {risk 2}

    {If S2S initialized}
    Session saved: .s2s/sessions/{session-id}.yaml
    Summary: .s2s/sessions/{session-id}-summary.md
    {/If}

    Next steps:
    ───────────
    To define requirements from these ideas:
      /s2s:specs

    To design architecture:
      /s2s:design

    To create a plan for top idea:
      /s2s:plan:create "{top idea}"

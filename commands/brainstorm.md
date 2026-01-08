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
- Display: "Warning: Not an s2s project. Results displayed but not saved to project structure."
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

---

## Phase 1: Session Setup

### Step 1.1: Generate Session ID

```
{YYYYMMDD}-brainstorm-{topic-slug}
Example: 20260107-brainstorm-mobile-app-idea
```

### Step 1.2: Create Session Folder Structure

**YOU MUST use Bash tool NOW**:
```bash
mkdir -p .s2s/sessions/{session-id}
```

If verbose_flag is true:
```bash
mkdir -p .s2s/sessions/{session-id}/rounds
```

### Step 1.3: Create Snapshot Files

**YOU MUST use Write tool NOW** to create `context-snapshot.yaml`:

If S2S initialized, read `.s2s/CONTEXT.md`. Otherwise, create minimal context:
```yaml
# Captured: {ISO timestamp}
source: "{.s2s/CONTEXT.md or 'user-provided'}"

project_name: "{from CONTEXT.md or directory name}"
description: "{from CONTEXT.md or topic}"
brainstorm_topic: "{topic}"
```

**YOU MUST use Write tool NOW** to create `config-snapshot.yaml`:
```yaml
# Captured: {ISO timestamp}
source: ".s2s/config.yaml"

verbose: {verbose_flag}
interactive: {interactive_flag}
strategy: "disney"
limits:
  min_rounds: 3
  max_rounds: 20
escalation:
  max_rounds_per_conflict: 3
  confidence_below: 0.5
  critical_keywords: ["security", "must-have", "blocking", "legal"]
participants:
  - "product-manager"
  - "software-architect"
  - "technical-lead"
  - "devops-engineer"
```

**Note**: Brainstorm uses Disney strategy with phases, no formal agenda.

### Step 1.4: Create Session Index File

**YOU MUST use Write tool NOW** to create `.s2s/sessions/{session-id}.yaml`:

```yaml
id: "{session-id}"
topic: "{topic}"
workflow_type: "brainstorm"
strategy: "disney"
status: "active"

timing:
  started: "{ISO timestamp}"
  completed: null
  duration_ms: null

artifacts:
  ideas: []
  risks: []
  mitigations: []
  conflicts: []
  open_questions: []

# Disney phases (no formal agenda)
current_phase: "dreamer"
phases:
  - name: "dreamer"
    status: "active"
    rounds: []
  - name: "realist"
    status: "pending"
    rounds: []
  - name: "critic"
    status: "pending"
    rounds: []

rounds: []

metrics:
  rounds: 0
  tasks: 0
  tokens: 0
```

### Step 1.5: Update State File

If S2S initialized:
**YOU MUST use Edit tool NOW** to update `.s2s/state.yaml`:
```yaml
current_session: "{session-id}"
```

---

## Phase 2: Round Execution Loop (Disney Strategy)

**Follow the `roundtable-execution` skill instructions with Disney strategy phases.**

Initialize:
- `round_number = 0`
- `current_phase = "dreamer"`
- `session_folder = ".s2s/sessions/{session-id}/"`

### Round Loop (cycle through Disney phases)

#### Step 2.1: Display Phase Status

```
═══════════════════════════════════════════════════════════════
BRAINSTORM: {topic}
Strategy: Disney | Phase: {current_phase} | Round: {round_number + 1}
═══════════════════════════════════════════════════════════════

{if current_phase == "dreamer"}
DREAMER PHASE: Think BIG! No constraints, wild ideas welcome.
{/if}
{if current_phase == "realist"}
REALIST PHASE: Evaluate feasibility. How would we implement?
{/if}
{if current_phase == "critic"}
CRITIC PHASE: Identify risks. What could go wrong?
{/if}

ARTIFACTS: {count} ideas, {count} risks, {count} mitigations
```

#### Step 2.2: Facilitator Question

**YOU MUST use Task tool NOW** to call facilitator:

```yaml
subagent_type: "general-purpose"
prompt: |
  You are the Roundtable Facilitator.
  Read your agent definition from: agents/roundtable/facilitator.md

  === WORKFLOW ===
  Type: brainstorm (creative ideation)
  Strategy: disney (Dreamer → Realist → Critic)
  Current Phase: {current_phase}
  Participants: product-manager, software-architect, technical-lead, devops-engineer

  === DISNEY PHASE RULES ===
  {if current_phase == "dreamer"}
  DREAMER: Generate creative ideas without constraints.
  - NO criticism allowed in this phase
  - Encourage wild, ambitious thinking
  - Quantity over quality
  {/if}
  {if current_phase == "realist"}
  REALIST: Evaluate feasibility of ideas.
  - Focus on "how to" thinking
  - Convert ideas to actionable items
  - Practical implementation paths
  {/if}
  {if current_phase == "critic"}
  CRITIC: Identify risks and issues.
  - What could go wrong?
  - Propose mitigations
  - Challenge assumptions
  {/if}

  === CURRENT STATE (Round {round_number + 1}) ===
  Session folder: {session_folder}

  Artifacts created:
  - Ideas: {list IDs or "none yet"}
  - Risks: {list IDs or "none"}
  - Mitigations: {list IDs or "none"}
  - Conflicts: {list IDs or "none"}

  Previous round synthesis:
  {synthesis from last round or "First round - no previous context"}

  === CONSTRAINTS ===
  min_rounds: 3
  max_rounds: 20
  max_rounds_per_conflict: 3
  confidence_below: 0.5

  === YOUR AUTONOMOUS DECISION ===
  Within the {current_phase} phase rules above:

  1. YOU DECIDE how to explore this phase:
     - What aspect to focus on?
     - How many questions to ask?
     - Whether to go deeper or broader?

  2. YOU DECIDE the question format:
     - Open-ended exploration?
     - Specific prompts?
     - Building on previous ideas?

  3. SELECT which context files participants should read

  4. GENERATE your question(s) and exploration prompt

  You have full autonomy within the phase constraints.
  Focus on creativity over consensus.
  Include constraints_check in your synthesis output (MANDATORY).
```

**IF verbose_flag == true**: Write dump to `rounds/{NNN}-01-facilitator-question.yaml`:
```yaml
# Round {N} - Facilitator Question ({phase} phase)
round: {N}
phase: 1
actor: "facilitator"
action: "question"
disney_phase: "{dreamer|realist|critic}"
started: "{ISO timestamp}"
completed: "{ISO timestamp}"

prompt:
  session_state: "{summary}"
  disney_phase_goal: "{phase instructions}"
  artifact_summary: "{counts}"

response:
  question: "{question}"
  exploration: "{exploration}"
  context_files: [...]

result:
  status: "completed"

tokens:
  input_estimate: {N}
  output_estimate: {N}
```

#### Step 2.3: Participant Responses

**YOU MUST launch ALL participant Tasks in SINGLE message**:

```yaml
subagent_type: "general-purpose"
prompt: |
  You are the {Role} in a brainstorming session.
  Read your agent definition from: agents/roundtable/{participant-id}.md

  === DISNEY PHASE: {current_phase} ===
  {if current_phase == "dreamer"}
  Think BIG! No constraints. What would be IDEAL?
  NO criticism of ideas in this phase.
  {/if}
  {if current_phase == "realist"}
  Evaluate feasibility. How would we BUILD this?
  Be practical but constructive.
  {/if}
  {if current_phase == "critic"}
  Identify risks. What could go WRONG?
  Propose mitigations for each risk.
  {/if}

  === CONTEXT FILES ===
  Read these files (DO NOT read other session files):
  {for each file in facilitator's context_files}
  - {session_folder}/{file}
  {/for}

  === QUESTION ===
  {facilitator's question}

  === EXPLORATION ===
  {facilitator's exploration prompt}

  === YOUR RESPONSE FORMAT ===
  Return YAML:
  position: "{your contribution}"
  rationale:
    - "{reason 1}"
  confidence: 0.85
  {if current_phase == "dreamer"}
  ideas:
    - "{new idea}"
  {/if}
  {if current_phase == "critic"}
  risks:
    - "{identified risk}"
  mitigations:
    - risk: "{risk}"
      mitigation: "{how to address}"
  {/if}
```

**IF verbose_flag == true**: Write dump for each participant to `rounds/{NNN}-02-{participant-id}.yaml`:
```yaml
# Round {N} - {Role} Response ({disney_phase} phase)
round: {N}
phase: 2
actor: "{participant-id}"
action: "response"
disney_phase: "{dreamer|realist|critic}"
started: "{ISO timestamp}"
completed: "{ISO timestamp}"

prompt:
  question: "{question}"
  disney_phase_instructions: "{phase-specific instructions}"

response:
  position: "{full response}"
  confidence: {0.0-1.0}
  ideas: [...]      # dreamer phase
  risks: [...]      # critic phase
  mitigations: [...] # critic phase

result:
  artifacts_proposed: {count}
  status: "completed"

tokens:
  input_estimate: {N}
  output_estimate: {N}
```

#### Step 2.4: Facilitator Synthesis

**YOU MUST use Task tool NOW** for synthesis.

Include phase-specific artifact extraction:
- **Dreamer**: Extract ideas as IDEA-* artifacts
- **Realist**: Assess feasibility, categorize ideas
- **Critic**: Extract risks as RISK-*, mitigations as MIT-*

**IF verbose_flag == true**: Write dump to `rounds/{NNN}-03-facilitator-synthesis.yaml`:
```yaml
# Round {N} - Facilitator Synthesis ({disney_phase} phase)
round: {N}
phase: 3
actor: "facilitator"
action: "synthesis"
disney_phase: "{dreamer|realist|critic}"
started: "{ISO timestamp}"
completed: "{ISO timestamp}"

prompt:
  participant_responses: "{summary}"

response:
  synthesis: "{summary}"
  proposed_artifacts: [...]
  phase_recommendation: "{stay|advance|conclude}"
  constraints_check: {rounds_completed, min_rounds, can_conclude, reason}
  next: "{continue|phase|conclude}"

result:
  artifacts_proposed: {count}
  status: "completed"

tokens:
  input_estimate: {N}
  output_estimate: {N}
```

#### Step 2.5: Process Artifacts

For each `proposed_artifact`:
- Ideas: `IDEA-{NNN}.yaml`
- Risks: `RISK-{NNN}.yaml`
- Mitigations: `MIT-{NNN}.yaml`
- Conflicts: `CONF-{NNN}.yaml`
- Open questions: `OQ-{NNN}.yaml`

#### Step 2.6: Phase Transition

Disney strategy phase progression:
- **dreamer**: 1+ rounds until facilitator recommends phase transition
- **realist**: 1+ rounds
- **critic**: 1+ rounds, then conclude

When facilitator returns `next: "phase"`:
- Advance `current_phase` (dreamer → realist → critic)
- Update phase status in session file

When in `critic` phase and facilitator returns `next: "conclude"`:
- Exit loop, proceed to completion

#### Step 2.7: Display Round Recap

Show synthesis, new artifacts, phase progress.

#### Step 2.8: Handle Interactive Mode

**IF interactive_flag == true**: Ask user to continue, skip phase, or pause.
**IF interactive_flag == false**: Proceed automatically.

#### Step 2.9: Evaluate Next Action (CRITICAL)

**MANDATORY min_rounds enforcement:**

```
IF round_number < min_rounds (default: 3) AND next == "conclude":
  OVERRIDE next to "continue"
  Display: "⚠️ min_rounds not reached ({round_number}/{min_rounds}), continuing..."
```

Then evaluate based on `next`:
- **continue**: Loop back to Step 2.1 (same phase)
- **phase**: Advance to next Disney phase (dreamer → realist → critic)
- **conclude**: Only valid in critic phase AND round_number >= min_rounds
- **escalate**: Ask user with AskUserQuestion

---

## Phase 3: Completion

### Step 3.1: Update Session Status

**YOU MUST use Edit tool NOW** to update session file.

### Step 3.2: Clear State

If S2S initialized:
**YOU MUST use Edit tool NOW** to clear current_session.

### Step 3.3: Read Session for Summary

**YOU MUST use Read tool** to read session file and artifact files.

Extract from each Disney phase:
- **Dreamer phase**: All IDEA-* artifacts
- **Realist phase**: Feasibility assessments
- **Critic phase**: All RISK-* and MIT-* artifacts

### Step 3.4: Process Results

Categorize ideas by feasibility:
- **Immediately feasible**: Ready to implement
- **Requires more work**: Needs further analysis
- **Long-term/aspirational**: Future consideration

Pair risks with mitigations.

### Step 3.5: Save Summary

**YOU MUST use Write tool NOW** to create `.s2s/sessions/{session-id}-summary.md`:

```markdown
# Brainstorm: {Topic}

**Session**: {session-id}
**Date**: {date}
**Strategy**: Disney (Dreamer → Realist → Critic)
**Participants**: {list}

## Dreamer Phase Ideas

{for each IDEA-* artifact}
### {ID}: {title}
{description}
{/for}

## Realist Assessment

### Immediately Feasible
{list ideas marked feasible}

### Requires More Work
{list ideas needing analysis}

### Long-term Vision
{list aspirational ideas}

## Critic Risks

| Risk | Mitigation |
|------|------------|
{for each RISK-* artifact}
| {title} | {matching MIT-* or "TBD"} |
{/for}

## Recommended Next Steps

1. {step based on top feasible ideas}
2. {step}
3. {step}

## Unresolved Questions

{for each OQ-* artifact}
- {question}
{/for}

---
*Generated by Spec2Ship /s2s:brainstorm*
*Session: {session-id}*
```

### Step 3.6: Output Summary

    Brainstorm Complete!
    ════════════════════

    Topic: {topic}
    Strategy: Disney (Dreamer → Realist → Critic)
    Participants: {count}
    Rounds: {count per phase}

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

    Session folder: .s2s/sessions/{session-id}/
    Summary: .s2s/sessions/{session-id}-summary.md

    Next steps:
    ───────────
    To define requirements from these ideas:
      /s2s:specs

    To design architecture:
      /s2s:design

    To create a plan for top idea:
      /s2s:plan:create "{top idea}"

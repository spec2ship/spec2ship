---
name: Roundtable Execution
description: "This skill provides instructions for executing multi-agent roundtable discussions.
  Use when a command needs to run discussion rounds with facilitator and participants.
  Referenced by: specs.md, design.md, brainstorm.md, roundtable:start.md.
  Trigger: 'execute roundtable', 'run discussion rounds', 'multi-agent discussion'."
version: 1.0.0
---

# Roundtable Execution Instructions

This skill provides step-by-step instructions for executing a multi-agent roundtable discussion. Commands that need to run discussions (specs, design, brainstorm, roundtable:start) reference this skill to avoid duplicating orchestration logic.

## When to Use This Skill

- Executing `/s2s:roundtable:start` command
- Running roundtable phase in `/s2s:specs`
- Running roundtable phase in `/s2s:design`
- Running roundtable phase in `/s2s:brainstorm`

## Prerequisites

Before executing these instructions, ensure:
- `.s2s` directory exists (project initialized)
- `.s2s/config.yaml` exists with roundtable settings
- Topic and workflow_type are defined

---

## PHASE 1: Configuration Loading

### Step 1.1: Read Config Defaults

Read `.s2s/config.yaml` and extract `roundtable.*` section:

```yaml
roundtable:
  verbose: false
  interactive: false
  strategy: "standard"
  limits:
    min_rounds: 3     # Minimum rounds before conclusion allowed
    max_rounds: 20    # Force conclude after this many rounds
  escalation:
    max_rounds_per_conflict: 3
    confidence_below: 0.5
    critical_keywords: ["security", "must-have", "blocking", "legal"]
  participants:
    specs: ["product-manager", "software-architect", "qa-lead"]
    design: ["software-architect", "technical-lead", "devops-engineer"]
    brainstorm: ["product-manager", "software-architect", "technical-lead"]
```

### Step 1.2: Apply Argument Overrides

Parse command arguments and override config defaults:

| Argument | Overrides | Example |
|----------|-----------|---------|
| `--verbose` | roundtable.verbose | `--verbose` → true |
| `--interactive` | roundtable.interactive | `--interactive` → true |
| `--strategy X` | roundtable.strategy | `--strategy debate` |
| `--participants X,Y,Z` | roundtable.participants.{workflow_type} | Custom list |

**Priority**: arguments > config.yaml > hardcoded defaults

### Step 1.3: Load Strategy Configuration

Read strategy details from `skills/roundtable-strategies/references/{strategy}.md`.

Extract:
- **phases**: Array of phase definitions (e.g., disney: dreamer→realist→critic)
- **participation**: "parallel" or "sequential"
- **consensus**: Policy and threshold

### Step 1.4: Load Workflow Agenda

Based on `workflow_type`, load required topics from:
- `skills/roundtable-execution/references/agenda-{workflow_type}.md`

**If file exists**: Parse REQUIRED_TOPICS list
**If file doesn't exist**: No agenda enforcement (e.g., brainstorm)

---

## Workflow Agendas

See workflow-specific agenda files for detailed topic definitions:
- `references/agenda-specs.md` - Requirements topics for specs workflow
- `references/agenda-design.md` - Architecture topics for design workflow
- Brainstorm: No agenda (free-form creativity)

Pass agenda to facilitator in prompts using `=== AGENDA ===` section.

---

## PHASE 2: Session Setup

### Step 2.1: Generate Session ID

Create session ID: `{YYYYMMDD-HHMMSS}-{topic-slug}` (slug: lowercase, hyphens, max 30 chars)

### Step 2.2: Create Session File

**YOU MUST** create `.s2s/sessions/{session-id}.yaml` following schema in `references/session-schema.md`.

Include: id, topic, workflow_type, strategy, status="active", timestamps, participants, current_phase, rounds=[], escalations=[], outcome=null.

### Step 2.3: Update State File

Set `current_session: "{session-id}"` in `.s2s/state.yaml`.

---

## PHASE 3: Round Execution Loop

**CRITICAL**: Execute rounds EXACTLY as specified. DO NOT improvise.

### Loop Variables

Initialize:
- `round_number = 0`
- `current_phase = first phase from strategy`
- `rounds_in_phase = 0`

### Step 3.0.5: Display Agenda Status

**At the START of each round**, display agenda status to terminal.

Show: Round number, agenda topics with status icons (✓ covered, ◐ partial, ○ pending).
Update status based on `agenda_coverage` from previous synthesis.
For brainstorm workflow, display "Free-form discussion" instead.

### Step 3.1: Facilitator Question

**YOU MUST use the Task tool NOW** with these parameters:

- **subagent_type**: "general-purpose"
- **prompt**: Include ALL of the following:

```
You are the Roundtable Facilitator.

Read your agent definition from: agents/roundtable/facilitator.md

=== SESSION STATE ===
Topic: {topic}
Strategy: {strategy}
Current Phase: {current_phase}
Round: {round_number + 1}
Rounds in this phase: {rounds_in_phase}

=== HISTORY ===
Previous synthesis: {last round's synthesis or 'First round'}
Current consensus: {accumulated consensus or 'None yet'}
Open conflicts: {unresolved conflicts or 'None'}

=== ESCALATION CONFIG ===
max_rounds_per_conflict: {from config}
confidence_below: {from config}
min_rounds: {from config, usually 3}

=== PROJECT CONTEXT (from CONTEXT.md) ===
Project: {project name}
Objectives: {key objectives from CONTEXT.md}
Scope: {in-scope / out-of-scope from CONTEXT.md}
Constraints: {constraints from CONTEXT.md}

=== AGENDA ===
Required topics: {REQUIRED_TOPICS list or "None"}
Current coverage: {from previous synthesis or "Not started"}

=== TASK ===
Generate the next question for participants.
If agenda has pending critical topics, prioritize those.
Include a context_summary for participants to review and potentially challenge.

Return YAML:
```yaml
action: "question"
question: "{specific question to ask}"
context_summary: |
  Project: {name}
  Objectives: {list}
  Scope: {in/out}
  Constraints: {list}
participants: "all"
focus: "{focus area}"
```
```

**IMPORTANT: Do NOT proceed to Step 3.2 until you have the facilitator's response.**

**If facilitator returns invalid YAML**, use fallback:
```yaml
action: "question"
question: "What are the key considerations for {topic}?"
participants: "all"
focus: "Core requirements"
```

### Step 3.2: Participant Responses (PARALLEL)

**YOU MUST launch ALL participant Tasks in a SINGLE message.**

This ensures blind voting - participants do NOT see each other's responses.

For EACH participant in participant_list, use Task tool:

- **subagent_type**: "general-purpose"
- **prompt**:

```
You are the {Participant Role} in a roundtable discussion.

Read your agent definition from: agents/roundtable/{participant-id}.md

=== DISCUSSION ===
Topic: {topic}
Question: {facilitator's question}
Focus: {facilitator's focus}

=== PROJECT CONTEXT (from facilitator) ===
{context_summary from facilitator's question output}

=== DISCUSSION CONTEXT ===
Strategy: {strategy}
Phase: {current_phase}
Previous synthesis: {last synthesis or 'First round'}

=== YOUR TASK ===
Provide your perspective on the question.

**CRITICAL**: If you identify issues with the PROJECT CONTEXT:
- Missing information
- Questionable assumptions
- Better alternatives

FLAG them explicitly using the `context_challenge` field.

Return YAML:
```yaml
position: "{your position statement}"
rationale:
  - "{reason 1}"
  - "{reason 2}"
confidence: 0.8  # 0.0 to 1.0
concerns:
  - "{any concerns}"
context_challenge: "{optional: your concern about the stated context}"
```
```

**IMPORTANT: WAIT for ALL participant responses before proceeding to Step 3.3.**

**Store responses for later use (CRITICAL for verbose mode):**

After ALL participant Tasks complete, you MUST create a `participant_responses` array:

```
participant_responses = []
for each participant_task_result:
    parsed = parse_yaml(result)
    participant_responses.append({
        "id": participant_id,
        "role": participant_display_name,
        "position": parsed.position,
        "rationale": parsed.rationale,
        "concerns": parsed.concerns,
        "confidence": parsed.confidence,
        "context_challenge": parsed.context_challenge or null
    })
```

This array is used in:
- Step 3.3: Pass to facilitator for synthesis
- Step 3.4: Include in session file (if verbose=true)

**DO NOT discard responses after synthesis. Keep them for session file writing.**

### Step 3.3: Facilitator Synthesis

**YOU MUST use the Task tool NOW** for synthesis:

- **subagent_type**: "general-purpose"
- **prompt**:

```
You are the Roundtable Facilitator.

Read agents/roundtable/facilitator.md

=== ROUND {round_number + 1} RESPONSES ===

{For each participant}
**{Participant Role}** (confidence: {confidence}):
Position: {position}
Rationale: {rationale}
Concerns: {concerns}
{End for each}

=== SESSION STATE ===
Topic: {topic}
Strategy: {strategy}
Phase: {current_phase}
Phase goal: {from strategy}

=== CURRENT STATE ===
Consensus so far: {accumulated consensus}
Open conflicts: {with round counts}

=== ESCALATION CONFIG ===
max_rounds_per_conflict: {from config}
confidence_below: {from config}
min_rounds: {from config, usually 3}

=== AGENDA ===
Required topics: {REQUIRED_TOPICS list or "None"}
Current coverage: {from previous synthesis or "Not started"}

=== TASK ===
Synthesize responses. Identify consensus and conflicts.
Update agenda_coverage for each topic.
Check min_rounds and agenda before allowing conclusion.
Determine next action.

Return YAML:
```yaml
action: "synthesis"
synthesis: "{summary of this round - 2-4 sentences}"
consensus:
  - "{new agreed point}"
conflicts:
  - id: "{slug-id}"
    description: "{what the conflict is about}"
    positions:
      participant-id: "{their position}"
resolved:
  - conflict_id: "{previously open conflict now resolved}"
    resolution: "{how it was resolved}"
    resolution_type: "consensus"
next_action: "continue"  # continue|phase|conclude|escalate
next_focus: "{if continue, what to focus on}"
escalation_reason: null  # if escalate
recommendation: null  # if conclude
output_type: null  # if conclude: adr|requirements|architecture|summary
```
```

**IMPORTANT: Do NOT proceed until you have the synthesis response.**

### Step 3.4: Update Session File (IMMEDIATE WRITE)

**CRITICAL: This step MUST execute IMMEDIATELY after Step 3.3 synthesis.**
**DO NOT defer to end of session. DO NOT batch multiple rounds.**

**YOU MUST** use the Write or Edit tool NOW:

1. Read current session file
2. Append new round to `rounds:` array (see `references/session-schema.md` for structure)
3. If verbose=true, include `participant_responses` from Step 3.2
4. Update `total_rounds`
5. Write file IMMEDIATELY

**If write fails, STOP and report error.**

### Step 3.4.5: Display Round Recap (ALWAYS)

**YOU MUST** display round summary to terminal after EVERY round (not conditional on --interactive).

Display: Phase, Focus, Synthesis, Consensus items (✓), Open conflicts (⚠), Resolved items, Agenda coverage, Next focus.

This provides user visibility into discussion progress.

### Step 3.5: Handle --interactive Mode (EVERY ROUND)

**This step executes AFTER Step 3.4.5 (recap display).**

Check `interactive_flag`:

**IF interactive_flag == true:**
1. Use AskUserQuestion tool with options:
   - "Continue to next round"
   - "Skip to conclusion"
   - "Pause session"

2. Handle user response:
   - "Continue": proceed to Step 3.6
   - "Skip": set `force_conclude = true`, proceed to Step 3.6
   - "Pause": set `status: "paused"` and `paused_at: {timestamp}`, EXIT loop

**IF interactive_flag == false:**
- Skip directly to Step 3.6

**NOTE**: This is NOT conditional on conflicts. Ask EVERY round when interactive=true.

### Step 3.6: Evaluate Next Action

**IMPORTANT: min_rounds Override**

Before accepting `next_action: "conclude"`:
1. Check: `round_number >= min_rounds` (from config, usually 3)
2. If NOT met: override `next_action` to `"continue"`
3. Log: "Minimum rounds not reached ({round_number}/{min_rounds}), continuing"

Based on facilitator's `next_action` (after override check):

| Action | Behavior |
|--------|----------|
| **continue** | Increment round_number, rounds_in_phase. REPEAT from Step 3.1 |
| **phase** | Advance to next phase, reset rounds_in_phase. REPEAT from Step 3.1 |
| **conclude** | EXIT loop. Proceed to PHASE 4 |
| **escalate** | Handle escalation (see below) |

### Step 3.7: Handle Escalation

If `next_action == "escalate"`:

1. Record escalation in session file
2. Display to user:
   ```
   Escalation Required
   Reason: {escalation_reason}
   Positions: {summary of positions}
   Recommendation: {facilitator's recommendation}
   ```
3. Use AskUserQuestion:
   - "Accept facilitator recommendation"
   - "Provide your own decision"
   - "Continue discussion for N more rounds"

4. Record user decision in escalations[]
5. If user provides decision, treat as resolved conflict
6. Continue loop or conclude based on user choice

### Step 3.8: Safety Limits

**HARD LIMIT**: If `round_number >= max_rounds`:
- Force `next_action: "conclude"`
- Note in session: "Reached maximum rounds limit"
- EXIT loop

---

## PHASE 4: Completion

### Step 4.1: Update Session Status

Set in session file:
- `status: "completed"`
- `completed_at: "{ISO timestamp}"`

### Step 4.2: Generate Output

Based on `output_type` from facilitator (or --output-type argument):

| Type | Path | Content |
|------|------|---------|
| **adr** | `docs/decisions/{timestamp}-{slug}.md` | ADR format (see madr-decisions skill) |
| **requirements** | `docs/specifications/requirements.md` | SRS format (append or create) |
| **architecture** | `docs/architecture/{slug}.md` | arc42 format |
| **summary** | `.s2s/sessions/{session-id}-summary.md` | Summary only |

### Step 4.3: Clear State

Set `current_session: null` in `.s2s/state.yaml`.

### Step 4.4: Display Completion

```
Roundtable Complete!

Session: {session-id}
Topic: {topic}
Strategy: {strategy}
Total Rounds: {total_rounds}

Consensus Reached:
{for each consensus item}
  {item}

{if unresolved conflicts}
Unresolved (noted for follow-up):
{for each conflict}
  {description}

Output: {output file path}

Next steps:
  /s2s:roundtable:list   - View all sessions
  /s2s:plan              - Generate implementation plans
```

---

## Definition of Done Checklist

**Before proceeding to each step, verify ALL previous checkboxes:**

### After Step 3.1 (Facilitator Question):
- [ ] Task tool was used (not simulated)
- [ ] Facilitator returned valid YAML with `action: "question"`
- [ ] Question is specific (not "What do you think?")

### After Step 3.2 (Participant Responses):
- [ ] ALL participants were launched in SINGLE message
- [ ] ALL participants returned valid YAML
- [ ] Each response has position, rationale, confidence

### After Step 3.3 (Facilitator Synthesis):
- [ ] Task tool was used for synthesis
- [ ] Synthesis identifies consensus AND conflicts
- [ ] next_action is one of: continue, phase, conclude, escalate

### After Step 3.4 (Update Session):
- [ ] Session file was written (not just planned)
- [ ] Round data includes question, synthesis, consensus, conflicts

---

## STOP Conditions

**YOU MUST check these conditions and STOP if any applies:**

1. **Max rounds reached**: rounds >= max_rounds → force conclude
2. **User requested pause**: status → "paused", EXIT
3. **Escalation unresolved**: user must decide
4. **Invalid session file**: STOP, report error

---

## Error Handling

See `references/error-handling.md` for detailed error handling patterns.

**Critical rule**: If session file write fails, STOP immediately and report error.

---

## Quick Reference

See `references/task-parameters.md` for full Task() parameter templates.

All roundtable tasks use `subagent_type: "general-purpose"`.

---

*Referenced by: specs.md, design.md, brainstorm.md, roundtable:start.md*
*For strategy details, see: skills/roundtable-strategies/*

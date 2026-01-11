# Mitigations for LLM Multi-Agent Limitations

This document describes how Roundtable addresses known issues in LLM multi-agent systems.

## Known Issues

Research has identified several problems with LLM multi-agent discussions:

| Issue | Prevalence | Description |
|-------|------------|-------------|
| Sycophancy | 58% of cases | Agents copy instead of critique |
| Echo Chambers | Common | Polarizing topics amplify bias |
| Bias Amplification | 78.5% persistence | Initial biases strengthen |
| Context Contamination | Sequential pipelines | Early responses influence later ones |

## Mitigation Strategies

### 1. Blind Voting (Parallel Execution)

**Problem**: When agents see others' responses, they tend to agree rather than provide independent perspectives.

**Solution**: Launch participant Tasks in parallel. Agents respond simultaneously and cannot see each other's answers.

**Implementation**:
```markdown
# In the command, execute Tasks in a SINGLE message:
Task(prompt="You are Software Architect..."),
Task(prompt="You are Technical Lead..."),
Task(prompt="You are QA Lead...")
# All execute simultaneously - true blind voting
```

**Evidence**: Simple majority voting accounts for most gains in multi-agent debate; the benefit comes from aggregation, not from agents reading each other.

### 2. Context Isolation

**Problem**: If agents read from shared files, they can be influenced by content they shouldn't see.

**Solution**: Pass all context in the prompt. Agents don't read from session files.

**Implementation**:
```python
# Command builds prompt with only relevant context
prompt = f"""
You are {role}.

=== TOPIC ===
{topic}

=== SYNTHESIS OF PREVIOUS ROUNDS ===
{only_synthesis_not_full_responses}

=== YOUR EXPERTISE ===
{agent_expertise}
"""
```

**Key Points**:
- Agents receive curated context, not raw file access
- Previous round synthesis provided, not full responses
- Agent's own previous positions included for consistency

### 3. Batch Write

**Problem**: If session file is updated during a round, agents reading it could see partial results.

**Solution**: Write to session file only at the end of each round.

**Implementation**:
```markdown
# Round execution:
1. Facilitator generates question
2. Collect ALL participant responses (parallel)
3. Facilitator synthesizes
4. THEN batch write everything to session file
```

**Guarantee**: Even if an agent somehow read the session file mid-round, current round responses wouldn't be there.

### 4. Facilitator Agent Separation

**Problem**: Hardcoded facilitation logic is inflexible and hard to tune.

**Solution**: Facilitator is a separate agent with strategy-specific behavior loaded from skills.

**Benefits**:
- Facilitation logic in prompt, not code
- Customizable strategies (Disney, Debate, Six Hats, etc.)
- Facilitator can adapt based on discussion progress

### 5. Escalation Triggers

**Problem**: Agents may reach false consensus or deadlock indefinitely.

**Solution**: Configure triggers that pause for human input:
- Conflict persists after N attempts
- Confidence drops below threshold
- Critical keywords detected (security, legal, blocking)

**Implementation**:
```yaml
escalation:
  enabled: true
  triggers:
    max_rounds_per_conflict: 3
    confidence_below: 0.5
    critical_keywords: [security, must-have, blocking, legal]
```

### 6. Heterogeneous Perspectives

**Problem**: Homogeneous agents produce homogeneous output.

**Solution**: Distinct agent roles with different expertise:
- Product Manager: user needs, business value
- Software Architect: structure, patterns
- Technical Lead: implementation, tech stack
- QA Lead: quality, testing, edge cases
- DevOps Engineer: deployment, operations

**Evidence**: Heterogeneous agents show +47% improvement on AIME-2024 vs homogeneous.

### 7. Strategy-Based Phase Separation

**Problem**: Creative and critical thinking interfere when mixed.

**Solution**: Strategies like Disney explicitly separate phases:
- Dreamer: No criticism allowed
- Realist: Practical grounding
- Critic: Risk identification

**Implementation**: Sequential phases with different prompt suffixes enforcing the thinking mode.

## Effectiveness

| Mitigation | Addresses | Confidence |
|------------|-----------|------------|
| Blind Voting | Sycophancy | High |
| Context Isolation | Contamination | High |
| Batch Write | Partial visibility | High |
| Facilitator Separation | Flexibility | Medium |
| Escalation Triggers | False consensus | Medium |
| Heterogeneous Agents | Echo chambers | Medium |
| Phase Separation | Mixed thinking | Medium |

## Trade-offs

| Mitigation | Cost |
|------------|------|
| Blind Voting | No iterative building on ideas (use sequential when needed) |
| Context Isolation | Larger prompts (more tokens) |
| Batch Write | Must complete round before seeing results |
| Phase Separation | Longer discussions (Disney = 3 phases) |

## Remaining Limitations

Even with mitigations, some issues persist:

1. **LLM Base Biases**: Model training biases affect all agents
2. **Prompt Sensitivity**: Agent behavior varies with prompt wording
3. **Confidence Calibration**: LLM confidence may not reflect accuracy
4. **Emergent Behavior**: Complex agent interactions are hard to predict

## Research References

- "Simple majority voting accounts for most of the observed gains in multi-agent debate"
- PTFA framework (2024): Heterogeneous thinking styles +47%
- Studies showing 58% sycophancy rates in multi-agent setups
- 78.5% bias persistence in sequential pipelines

---
*Part of Spec2Ship Roundtable documentation*

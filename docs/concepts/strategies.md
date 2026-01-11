# Strategies

Strategies define how roundtable discussions are facilitated. Each strategy has a different approach to reaching conclusions.

## Available Strategies

| Strategy | Best For | Phases | Default In |
|----------|----------|--------|------------|
| **standard** | General discussions | 1 | - |
| **disney** | Creative ideation | 3 | brainstorm |
| **debate** | Evaluating options | 4 | design |
| **consensus-driven** | Building agreement | 3 | specs |
| **six-hats** | Comprehensive analysis | 7 | - |

## Strategy Details

### Standard

Simple round-robin discussion without specialized phases.

**How it works**:
- All participants discuss simultaneously
- Facilitator synthesizes after each round
- Continues until topics are covered

**Use when**: General discussions, simple decisions.

### Disney (Creative Strategy)

Based on Walt Disney's creative process: separate thinking modes.

**Phases**:
1. **Dreamer**: Blue-sky thinking, no constraints, wild ideas welcome
2. **Realist**: Practical evaluation, how would we build this?
3. **Critic**: Risk identification, what could go wrong?

**How it works**:
- Each phase has different instructions for participants
- No criticism allowed in Dreamer phase
- Artifacts flow: IDEAS → REFINED_IDEAS → RISKS/MITIGATIONS

**Use when**: Exploring new features, creative problem-solving.

### Debate

Pro vs Con structured argumentation.

**Phases**:
1. **Opening**: Each side presents initial position
2. **Rebuttal**: Respond to opposing arguments
3. **Closing**: Final statements
4. **Synthesis**: Facilitator summarizes and decides

**How it works**:
- Participants assigned Pro or Con roles
- Explicit adversarial structure
- Forces consideration of both sides

**Use when**: Evaluating architectural trade-offs, technology choices.

### Consensus-Driven

Fast convergence through consent-based decision making.

**Phases**:
1. **Proposal**: Initial proposals presented
2. **Refinement**: Amendments and improvements
3. **Convergence**: Final agreement

**Consent model**:
- **Support**: Actively agree
- **Stand-aside**: Don't block, but have reservations
- **Block**: Cannot proceed (requires resolution)

**Use when**: Defining requirements, building team alignment.

### Six Thinking Hats

De Bono's comprehensive analysis method.

**Hats (phases)**:
1. **Blue**: Process control (facilitator only)
2. **White**: Facts and data
3. **Red**: Emotions and intuition
4. **Black**: Risks and problems
5. **Yellow**: Benefits and value
6. **Green**: Creativity and alternatives
7. **Blue**: Summary and decisions

**How it works**:
- All participants wear same "hat" each phase
- Separates different thinking modes
- Very thorough but time-intensive

**Use when**: Complex decisions requiring comprehensive analysis.

## Specifying a Strategy

```bash
# Use specific strategy
/s2s:specs --strategy debate

# Override default for design
/s2s:design --strategy consensus-driven
```

## Strategy-Workflow Compatibility

| Strategy | specs | design | brainstorm |
|----------|-------|--------|------------|
| standard | ✓ | ✓ | ✓ |
| disney | ✓ | ✓ | ✓ (default) |
| debate | ✓ | ✓ (default) | - |
| consensus-driven | ✓ (default) | ✓ | - |
| six-hats | ✓ | ✓ | ✓ |

---

*See also: [Roundtable](./roundtable.md) | [Extending: New Strategy](../extending/new-strategy.md)*

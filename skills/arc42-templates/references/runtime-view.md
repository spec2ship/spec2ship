# Runtime View - Detailed Patterns

## Purpose

The runtime view describes system behavior through scenarios, showing how components collaborate to fulfill key use cases.

## Scenario Selection Criteria

Focus on scenarios that are:

| Criteria | Why Important |
|----------|---------------|
| **Core business flows** | Most frequently executed paths |
| **Performance-critical** | Paths with strict timing requirements |
| **Complex interactions** | Multiple component coordination |
| **Error handling** | How failures are managed |
| **Edge cases** | Boundary conditions and limits |

## Scenario Documentation Template

```markdown
### {Scenario Name}

**Priority**: {Critical | Important | Nice-to-have}
**Frequency**: {requests/sec | daily | on-demand}

**Description**:
{Brief narrative of what happens}

**Actors**:
- {Actor 1}: {role in scenario}
- {Actor 2}: {role in scenario}

**Preconditions**:
- {State that must be true before scenario starts}

**Flow**:
1. {Step 1}
2. {Step 2}
3. {Step 3}

**Postconditions**:
- {State after successful completion}

**Error Paths**:
- {Error condition}: {How it's handled}
```

## Sequence Diagram Patterns

### Basic Request-Response

```
┌──────┐          ┌──────┐          ┌──────┐          ┌──────┐
│Client│          │ API  │          │Service│         │  DB  │
└──┬───┘          └──┬───┘          └──┬───┘          └──┬───┘
   │    Request      │                 │                 │
   │────────────────▶│                 │                 │
   │                 │   Validate      │                 │
   │                 │────────────────▶│                 │
   │                 │                 │     Query       │
   │                 │                 │────────────────▶│
   │                 │                 │     Result      │
   │                 │                 │◀────────────────│
   │                 │   Response      │                 │
   │                 │◀────────────────│                 │
   │    Response     │                 │                 │
   │◀────────────────│                 │                 │
```

### Async Processing

```
┌──────┐          ┌──────┐          ┌──────┐          ┌──────┐
│Client│          │ API  │          │ Queue │         │Worker│
└──┬───┘          └──┬───┘          └──┬───┘          └──┬───┘
   │    Request      │                 │                 │
   │────────────────▶│                 │                 │
   │                 │   Enqueue       │                 │
   │                 │────────────────▶│                 │
   │   Accepted      │                 │                 │
   │◀────────────────│                 │                 │
   │                 │                 │    Dequeue      │
   │                 │                 │────────────────▶│
   │                 │                 │                 │ Process
   │                 │                 │                 │───┐
   │                 │                 │                 │◀──┘
   │                 │                 │    Ack          │
   │                 │                 │◀────────────────│
```

### Event-Driven

```
┌──────┐          ┌──────┐          ┌──────┐          ┌──────┐
│Source│          │ Bus  │          │ Sub A │         │ Sub B│
└──┬───┘          └──┬───┘          └──┬───┘          └──┬───┘
   │   Publish       │                 │                 │
   │────────────────▶│                 │                 │
   │                 │    Notify       │                 │
   │                 │────────────────▶│                 │
   │                 │    Notify       │                 │
   │                 │─────────────────────────────────▶│
   │                 │                 │  Process        │
   │                 │                 │───┐             │
   │                 │                 │◀──┘             │
   │                 │                 │                 │ Process
   │                 │                 │                 │───┐
   │                 │                 │                 │◀──┘
```

## Performance-Critical Paths

Document timing requirements for critical scenarios:

```markdown
### User Login Flow

**SLA**: p95 < 200ms, p99 < 500ms

**Timing Breakdown**:
| Step | Target | Actual | Notes |
|------|--------|--------|-------|
| Request parsing | 5ms | 3ms | |
| Rate limit check | 10ms | 8ms | Redis lookup |
| Password verify | 100ms | 95ms | bcrypt cost=12 |
| Token generation | 20ms | 15ms | JWT signing |
| Session storage | 30ms | 25ms | Redis write |
| Response | 5ms | 3ms | |
| **Total** | **170ms** | **149ms** | Buffer for spikes |

**Bottlenecks**:
- Password verification (fixed cost, security requirement)
- Database queries under high load

**Mitigations**:
- Connection pooling
- Query result caching where safe
```

## Error Handling Scenarios

Document how errors propagate and are handled:

```markdown
### Database Failure Scenario

**Trigger**: Primary database becomes unreachable

**Detection**:
- Connection timeout after 5s
- Health check fails

**Response**:
1. Circuit breaker opens
2. Requests fail fast with 503
3. Alert triggered to ops team

**Recovery**:
1. Automatic reconnection attempts (exponential backoff)
2. Circuit breaker half-open after 30s
3. Test connection on next request
4. Resume normal operation if successful

**User Impact**:
- Requests fail for 30-60s during failover
- No data loss (writes rejected, reads fail)
```

## Best Practices

1. **Prioritize**: Document critical paths first, nice-to-haves later
2. **Keep it current**: Update scenarios when behavior changes
3. **Include timing**: Performance requirements belong here
4. **Show errors**: Happy path alone is insufficient
5. **Link to tests**: Reference integration/E2E tests that verify scenarios

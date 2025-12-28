# Building Blocks View - Detailed Patterns

## Decomposition Levels

arc42 uses hierarchical decomposition to describe system structure at increasing levels of detail.

### Level 0: System Context

The highest level showing your system as a black box within its environment.

```
┌─────────────────────────────────────────────────────────┐
│                    System Context                        │
│                                                         │
│    ┌─────────┐         ┌─────────────┐         ┌─────┐ │
│    │  User   │────────▶│ Your System │◀───────▶│ API │ │
│    └─────────┘         └─────────────┘         └─────┘ │
│                              │                          │
│                              ▼                          │
│                        ┌──────────┐                     │
│                        │ Database │                     │
│                        └──────────┘                     │
└─────────────────────────────────────────────────────────┘
```

**Document**:
- External actors (users, systems)
- System boundaries
- High-level interfaces

### Level 1: Container View

Decompose your system into deployable units (containers).

```
┌─────────────────────────────────────────────────────────┐
│                      Your System                         │
│                                                         │
│  ┌──────────────┐    ┌──────────────┐    ┌───────────┐ │
│  │ Web Frontend │───▶│  API Server  │───▶│  Database │ │
│  │   (React)    │    │   (Node.js)  │    │ (Postgres)│ │
│  └──────────────┘    └──────────────┘    └───────────┘ │
│                             │                           │
│                             ▼                           │
│                      ┌──────────────┐                   │
│                      │ Message Queue│                   │
│                      │   (Redis)    │                   │
│                      └──────────────┘                   │
└─────────────────────────────────────────────────────────┘
```

**Document**:
- Technology choices per container
- Communication protocols
- Data storage locations

### Level 2: Component View

Detail the internal structure of each container.

```
┌─────────────────────────────────────────────────────────┐
│                      API Server                          │
│                                                         │
│  ┌──────────────┐    ┌──────────────┐    ┌───────────┐ │
│  │  Controllers │───▶│   Services   │───▶│   Repos   │ │
│  └──────────────┘    └──────────────┘    └───────────┘ │
│         │                   │                   │       │
│         ▼                   ▼                   ▼       │
│  ┌──────────────┐    ┌──────────────┐    ┌───────────┐ │
│  │  Middleware  │    │    Domain    │    │  Entities │ │
│  └──────────────┘    └──────────────┘    └───────────┘ │
└─────────────────────────────────────────────────────────┘
```

## C4 Model Mapping

arc42 building blocks align with the C4 model:

| C4 Level | arc42 Level | Description |
|----------|-------------|-------------|
| Context | Level 0 | System in environment |
| Container | Level 1 | Deployable units |
| Component | Level 2 | Internal modules |
| Code | (optional) | Class-level detail |

## Black Box vs White Box

### Black Box View

Shows only external interfaces without revealing internal structure.

```markdown
### Authentication Service

**Purpose**: Handles user authentication and session management

**Interfaces**:
| Interface | Type | Description |
|-----------|------|-------------|
| `/auth/login` | REST | User login endpoint |
| `/auth/logout` | REST | Session termination |
| `auth.validated` | Event | Emitted on successful auth |

**Quality Requirements**:
- Response time < 100ms
- 99.9% availability
```

### White Box View

Reveals internal structure and relationships.

```markdown
### Authentication Service (White Box)

**Internal Components**:

1. **AuthController**
   - Handles HTTP requests
   - Input validation
   - Response formatting

2. **AuthService**
   - Business logic
   - Password verification
   - Session creation

3. **TokenManager**
   - JWT generation
   - Token validation
   - Refresh handling

4. **UserRepository**
   - Database access
   - User lookup
   - Credential storage
```

## Interface Documentation Pattern

```markdown
### {Interface Name}

**Type**: {REST | gRPC | Event | Message | File}
**Protocol**: {HTTP/HTTPS | TCP | AMQP | Kafka}
**Format**: {JSON | Protobuf | XML | Binary}

**Operations**:

#### {Operation Name}
- **Method**: {GET | POST | PUT | DELETE | PUBLISH | SUBSCRIBE}
- **Path/Topic**: {/api/v1/resource | topic.name}
- **Input**: {Schema or type reference}
- **Output**: {Schema or type reference}
- **Errors**: {Error codes and meanings}

**Example**:
```json
{
  "request": { ... },
  "response": { ... }
}
```
```

## Best Practices

1. **Start broad, go deep as needed**: Not every component needs Level 2 detail
2. **Focus on boundaries**: Interface documentation matters more than internals
3. **Keep diagrams simple**: 5-7 elements per diagram is ideal
4. **Use consistent notation**: Same shapes and colors throughout
5. **Document decisions**: Link to ADRs for technology choices

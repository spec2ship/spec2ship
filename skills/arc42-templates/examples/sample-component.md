# Sample Component Documentation

This example demonstrates complete arc42 documentation for an Authentication Service component.

---

## Authentication Service

### Overview (Black Box)

**Purpose**: Handles user authentication, authorization, and session management for the platform.

**Technology**: Node.js 20, Express, JWT, Redis

**Responsibilities**:
- User login/logout
- Session management
- Token generation and validation
- Password reset flow
- OAuth2 provider integration

### Interfaces

| Interface | Type | Description |
|-----------|------|-------------|
| `POST /auth/login` | REST | User login with credentials |
| `POST /auth/logout` | REST | Terminate session |
| `POST /auth/refresh` | REST | Refresh access token |
| `POST /auth/forgot-password` | REST | Initiate password reset |
| `auth.user.authenticated` | Event | Published on successful login |
| `auth.session.expired` | Event | Published when session times out |

### Quality Requirements

| Requirement | Target | Measurement |
|-------------|--------|-------------|
| Response Time | p95 < 100ms | Prometheus metrics |
| Availability | 99.95% | Uptime monitoring |
| Security | OWASP ASVS L2 | Annual audit |

---

## Internal Structure (White Box)

### Component Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                   Authentication Service                     │
│                                                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │   Routes     │───▶│ Controllers  │───▶│  Services    │  │
│  │              │    │              │    │              │  │
│  │ - /login     │    │ - AuthCtrl   │    │ - AuthSvc    │  │
│  │ - /logout    │    │ - UserCtrl   │    │ - TokenSvc   │  │
│  │ - /refresh   │    │              │    │ - SessionSvc │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
│                                                │             │
│                      ┌─────────────────────────┤             │
│                      ▼                         ▼             │
│              ┌──────────────┐         ┌──────────────┐      │
│              │ Repositories │         │  Providers   │      │
│              │              │         │              │      │
│              │ - UserRepo   │         │ - OAuth2     │      │
│              │ - SessionRepo│         │ - Email      │      │
│              └──────────────┘         └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

### Internal Components

#### AuthController

**Purpose**: HTTP request handling for authentication endpoints

**Responsibilities**:
- Request validation
- Error response formatting
- Rate limit enforcement

**Dependencies**:
- AuthService
- RateLimiter middleware

#### AuthService

**Purpose**: Core authentication business logic

**Responsibilities**:
- Credential verification
- Session creation/destruction
- Password policy enforcement

**Dependencies**:
- UserRepository
- TokenService
- SessionService

#### TokenService

**Purpose**: JWT token management

**Responsibilities**:
- Access token generation (15min expiry)
- Refresh token generation (7 day expiry)
- Token validation and decoding

**Configuration**:
- `JWT_SECRET`: Signing key (from secrets manager)
- `JWT_ISSUER`: Token issuer claim
- `ACCESS_TOKEN_TTL`: 900 seconds
- `REFRESH_TOKEN_TTL`: 604800 seconds

#### SessionService

**Purpose**: User session management

**Responsibilities**:
- Session creation in Redis
- Session validation
- Session termination
- Concurrent session limits

**Dependencies**:
- Redis client
- SessionRepository

---

## Runtime Scenarios

### Login Flow

```
┌──────┐     ┌──────────┐     ┌──────────┐     ┌────────┐     ┌───────┐
│Client│     │AuthCtrl  │     │AuthSvc   │     │UserRepo│     │TokenSv│
└──┬───┘     └────┬─────┘     └────┬─────┘     └───┬────┘     └───┬───┘
   │ POST /login  │                │               │              │
   │─────────────▶│                │               │              │
   │              │ authenticate() │               │              │
   │              │───────────────▶│               │              │
   │              │                │ findByEmail() │              │
   │              │                │──────────────▶│              │
   │              │                │    user       │              │
   │              │                │◀──────────────│              │
   │              │                │ verifyPassword│              │
   │              │                │───┐           │              │
   │              │                │◀──┘           │              │
   │              │                │ generateTokens│              │
   │              │                │──────────────────────────────▶
   │              │                │ {access, refresh}            │
   │              │                │◀──────────────────────────────
   │              │  {tokens, user}│               │              │
   │              │◀───────────────│               │              │
   │ 200 + tokens │                │               │              │
   │◀─────────────│                │               │              │
```

**Timing**: Target p95 < 100ms

| Step | Budget |
|------|--------|
| Request parsing | 5ms |
| User lookup | 15ms |
| Password verify (bcrypt) | 60ms |
| Token generation | 10ms |
| Session creation | 10ms |

### Token Refresh Flow

```
Client ──▶ POST /auth/refresh {refreshToken}
       ◀── 200 {accessToken, refreshToken}

       OR

       ◀── 401 {error: "Token expired"}
```

---

## Deployment

### Container Specification

```yaml
name: auth-service
image: registry.example.com/auth-service:v1.2.3
replicas: 3

resources:
  requests:
    cpu: 100m
    memory: 256Mi
  limits:
    cpu: 500m
    memory: 512Mi

env:
  - name: NODE_ENV
    value: production
  - name: REDIS_URL
    valueFrom:
      secretKeyRef:
        name: auth-secrets
        key: redis-url
  - name: JWT_SECRET
    valueFrom:
      secretKeyRef:
        name: auth-secrets
        key: jwt-secret

probes:
  liveness:
    path: /health
    port: 8080
  readiness:
    path: /ready
    port: 8080
```

### Dependencies

| Dependency | Type | Purpose |
|------------|------|---------|
| PostgreSQL | Database | User data storage |
| Redis | Cache | Session storage, rate limiting |
| Email Service | External | Password reset emails |
| OAuth Providers | External | Google, GitHub login |

---

## Related Decisions

<!-- Example references - replace with actual ADR paths in your project -->
- ADR-001: JWT vs Session-based Authentication
- ADR-007: Password Hashing Algorithm
- ADR-012: Session Storage Strategy

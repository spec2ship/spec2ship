# Deployment View - Detailed Patterns

## Purpose

The deployment view describes how software components map to infrastructure, including servers, containers, cloud services, and network topology.

## Infrastructure Diagram Template

```
┌─────────────────────────────────────────────────────────────────┐
│                         Production Environment                   │
│                                                                  │
│  ┌─────────────────────┐      ┌─────────────────────────────┐  │
│  │    Load Balancer    │      │      CDN (CloudFront)       │  │
│  │    (AWS ALB)        │      │                             │  │
│  └──────────┬──────────┘      └─────────────────────────────┘  │
│             │                                                    │
│  ┌──────────┴──────────────────────────────────────────────┐   │
│  │                   Kubernetes Cluster                      │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │   │
│  │  │ API Pod x3  │  │ Worker x2   │  │ Scheduler   │      │   │
│  │  │             │  │             │  │             │      │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘      │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐  │
│  │ PostgreSQL (RDS) │  │  Redis Cluster   │  │  S3 Bucket   │  │
│  │  Primary + Read  │  │  (ElastiCache)   │  │  (Assets)    │  │
│  └──────────────────┘  └──────────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Node Documentation Template

```markdown
### {Node Name}

**Type**: {Physical | VM | Container | Serverless | Managed Service}
**Provider**: {AWS | GCP | Azure | On-premise | Hybrid}
**Region**: {us-east-1 | eu-west-1 | etc.}

**Specifications**:
| Attribute | Value |
|-----------|-------|
| Instance Type | {t3.medium | n1-standard-2 | etc.} |
| vCPU | {2} |
| Memory | {4 GB} |
| Storage | {100 GB SSD} |
| Network | {Up to 5 Gbps} |

**Deployed Components**:
- {Component 1}: {version}
- {Component 2}: {version}

**Scaling**:
- Min instances: {2}
- Max instances: {10}
- Scaling trigger: {CPU > 70% for 5min}

**Dependencies**:
- Requires: {database, cache, queue}
- Network access: {VPC subnets, security groups}
```

## Environment Comparison

```markdown
## Environments Overview

| Aspect | Development | Staging | Production |
|--------|-------------|---------|------------|
| **Purpose** | Local dev | Pre-prod testing | Live traffic |
| **Scale** | 1 instance | 2 instances | 3+ instances |
| **Database** | Local Postgres | RDS (small) | RDS (multi-AZ) |
| **Cache** | Local Redis | ElastiCache (1 node) | ElastiCache (cluster) |
| **Monitoring** | Logs only | Full stack | Full + alerting |
| **Data** | Synthetic | Anonymized prod copy | Real |
| **Access** | All developers | Restricted | Ops only |
```

## Network Topology

```markdown
### Network Configuration

**VPC Layout**:
```
10.0.0.0/16 - Production VPC
├── 10.0.1.0/24 - Public Subnet A (ALB, NAT Gateway)
├── 10.0.2.0/24 - Public Subnet B (ALB, NAT Gateway)
├── 10.0.10.0/24 - Private Subnet A (App servers)
├── 10.0.11.0/24 - Private Subnet B (App servers)
├── 10.0.20.0/24 - Data Subnet A (Database, Cache)
└── 10.0.21.0/24 - Data Subnet B (Database, Cache)
```

**Security Groups**:
| Group | Inbound | Outbound | Attached To |
|-------|---------|----------|-------------|
| alb-sg | 443 from 0.0.0.0/0 | All to app-sg | Load Balancer |
| app-sg | 8080 from alb-sg | 5432 to data-sg, 6379 to data-sg | App servers |
| data-sg | 5432, 6379 from app-sg | None | Database, Cache |
```

## Deployment Pipeline

```markdown
### CI/CD Pipeline

**Stages**:

1. **Build** (GitHub Actions)
   - Checkout code
   - Run tests
   - Build Docker image
   - Push to ECR

2. **Deploy to Staging**
   - Update Kubernetes manifests
   - Apply to staging cluster
   - Run smoke tests
   - Wait for approval

3. **Deploy to Production**
   - Rolling update (25% at a time)
   - Health check validation
   - Automatic rollback on failure

**Rollback Procedure**:
1. Automated: Failed health checks trigger rollback
2. Manual: `kubectl rollout undo deployment/api`
```

## Configuration Management

```markdown
### Environment Configuration

**Secrets** (AWS Secrets Manager):
- `prod/database/credentials`
- `prod/api/jwt-secret`
- `prod/external/api-keys`

**Config** (ConfigMaps / SSM Parameter Store):
- Feature flags
- Service URLs
- Rate limits
- Timeouts

**Environment Variables**:
| Variable | Source | Example |
|----------|--------|---------|
| DATABASE_URL | Secret | postgres://... |
| REDIS_URL | ConfigMap | redis://cache:6379 |
| LOG_LEVEL | ConfigMap | info |
| FEATURE_X | ConfigMap | true |
```

## Disaster Recovery

```markdown
### DR Strategy

**RPO (Recovery Point Objective)**: 1 hour
**RTO (Recovery Time Objective)**: 4 hours

**Backup Schedule**:
- Database: Daily snapshots, 7-day retention
- S3: Cross-region replication enabled
- Config: GitOps - all config in version control

**Failover Procedure**:
1. Detect failure (automated monitoring)
2. Promote read replica to primary
3. Update DNS (Route53 health checks)
4. Verify application connectivity
5. Notify stakeholders

**Testing**:
- Quarterly DR drills
- Chaos engineering (monthly)
```

## Best Practices

1. **Infrastructure as Code**: All resources defined in Terraform/CloudFormation
2. **Immutable deployments**: Never modify running instances
3. **Environment parity**: Keep dev/staging/prod as similar as possible
4. **Document dependencies**: Network, data, external services
5. **Plan for failure**: Document what happens when each component fails

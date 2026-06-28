# Architecture Notes

## Network Topology

```
                         ┌─────────────────────────────────┐
                         │           VPC 10.0.0.0/16        │
                         │                                   │
  Internet ──► IGW ──► [Public Subnets]                     │
                         │  10.0.1.0/24  AZ-a  (ALB)       │
                         │  10.0.2.0/24  AZ-b  (ALB)       │
                         │         │                         │
                         │    [NAT Gateway] ◄── EIP          │
                         │         │                         │
                         │  [Private App Subnets]            │
                         │  10.0.10.0/24 AZ-a  (EC2)       │
                         │  10.0.11.0/24 AZ-b  (EC2)       │
                         │         │                         │
                         │  [Private DB Subnets]             │
                         │  10.0.20.0/24 AZ-a  (RDS)       │
                         │  10.0.21.0/24 AZ-b  (RDS)       │
                         └─────────────────────────────────┘
```

## Security Group Chain

```
Internet → ALB SG (80, 443 open) → App SG (3000 from ALB SG only) → DB SG (3306 from App SG only)
```

## Auto Scaling

- Min: 2 instances (one per AZ for HA)
- Max: 6 instances
- Scale out: CPU > 70% for 4 minutes
- Scale in: CPU < 20% for 4 minutes
- Health check: ELB (ALB health checks → /health endpoint)

## Data Protection

| Layer | Method |
|-------|--------|
| RDS | Encrypted at rest (AES-256), Multi-AZ |
| S3 (state) | AES-256 SSE, versioning, public access blocked |
| App Secrets | AWS SSM Parameter Store (not env vars) |
| In-transit | HTTPS via ACM + ALB TLS 1.3 |
| IAM | Least-privilege, IMDSv2 enforced on EC2 |

## Terraform State Architecture

Remote state in S3 prevents state file corruption across team members:
- S3 bucket: versioned, encrypted, no public access
- DynamoDB: provides atomic locking to prevent concurrent `terraform apply`

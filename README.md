# 3-Tier Web Application on AWS
**Full-Stack Infrastructure & Deployment using Terraform IaC**

> **Author:** Bikash Kushwaha  
> **GitHub:** [github.com/bikash9cmd](https://github.com/bikash9cmd)  
> **Stack:** AWS · Terraform · Node.js · MySQL (RDS) · Docker  

---

## Architecture Overview

```
Internet
    │
    ▼
[Route 53] ──► [ACM Certificate]
    │
    ▼
[Application Load Balancer]  ← Public Subnets (AZ-a, AZ-b)
    │
    ▼
[Auto Scaling Group: EC2]    ← Private App Subnets (AZ-a, AZ-b)
    │
    ▼
[RDS MySQL (Multi-AZ)]       ← Private DB Subnets (AZ-a, AZ-b)
```

### Three Tiers
| Tier | Component | Subnet |
|------|-----------|--------|
| **Presentation** | ALB + Route 53 + ACM | Public |
| **Application** | EC2 Auto Scaling Group | Private (App) |
| **Data** | RDS MySQL Multi-AZ | Private (DB) |

---

## Infrastructure Components

| Service | Purpose |
|---------|---------|
| VPC | Isolated network with public/private subnets across 2 AZs |
| ALB | HTTPS load balancer with health checks |
| EC2 Auto Scaling | App servers with min=2, max=6 scaling policy |
| RDS MySQL | Multi-AZ managed database with encrypted storage |
| NAT Gateway | Outbound internet for private subnets |
| Route 53 | DNS routing to ALB |
| ACM | SSL/TLS certificate for HTTPS |
| S3 + DynamoDB | Terraform remote state & locking |
| IAM | Least-privilege roles for EC2 and deployment |
| CloudWatch | Metrics, alarms, and Auto Scaling triggers |

---

## Repository Structure

```
3-tier-aws-app/
├── terraform/
│   ├── environments/
│   │   └── prod/
│   │       ├── main.tf          # Root module composition
│   │       ├── variables.tf     # Environment variables
│   │       ├── outputs.tf       # Output values
│   │       ├── terraform.tfvars # Actual values (gitignored)
│   │       └── backend.tf       # S3 remote state config
│   └── modules/
│       ├── vpc/                 # VPC, subnets, IGW, NAT, route tables
│       ├── alb/                 # ALB, target group, listeners, ACM
│       ├── ec2/                 # Launch template, ASG, CloudWatch alarms
│       ├── rds/                 # RDS MySQL, subnet group, parameter group
│       ├── iam/                 # IAM roles, policies, instance profile
│       └── s3/                  # S3 buckets (state, app assets)
├── app/
│   ├── src/
│   │   └── server.js            # Node.js Express app
│   ├── public/
│   │   └── index.html           # Frontend
│   ├── package.json
│   └── Dockerfile
├── scripts/
│   ├── bootstrap-state.sh       # Create S3 + DynamoDB for remote state
│   ├── deploy.sh                # Full deployment script
│   ├── destroy.sh               # Teardown script
│   └── userdata.sh              # EC2 user data (installs app)
├── .github/
│   └── workflows/
│       └── deploy.yml           # GitHub Actions CI/CD
├── docs/
│   ├── architecture.md          # Detailed architecture notes
│   └── cost-estimate.md         # Cost breakdown
├── .gitignore
└── README.md
```

---

## Prerequisites

- AWS CLI configured (`aws configure`)
- Terraform >= 1.5.0
- Node.js >= 18 (for local dev)
- An AWS account with admin or sufficient IAM permissions
- A registered domain in Route 53 (or skip DNS/ACM for basic deploy)

---

## Quick Start

### Step 1 – Bootstrap Remote State

```bash
chmod +x scripts/bootstrap-state.sh
./scripts/bootstrap-state.sh
```

This creates:
- S3 bucket: `bikash-terraform-state-<account-id>`
- DynamoDB table: `terraform-state-lock`

### Step 2 – Configure Variables

```bash
cp terraform/environments/prod/terraform.tfvars.example \
   terraform/environments/prod/terraform.tfvars
# Edit terraform.tfvars with your values
```

### Step 3 – Deploy

```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

Or manually:
```bash
cd terraform/environments/prod
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### Step 4 – Destroy (when done)

```bash
./scripts/destroy.sh
```

---

## Security Best Practices Applied

- ✅ RDS encrypted at rest (storage_encrypted = true)
- ✅ Least-privilege IAM roles (no wildcard `*` actions)
- ✅ Security groups: ALB→EC2→RDS layered rules only
- ✅ HTTPS enforced via ACM + ALB listener redirect
- ✅ Private subnets for EC2 and RDS (no direct internet access)
- ✅ Terraform state encrypted in S3 with DynamoDB lock
- ✅ Secrets via AWS SSM Parameter Store (not hardcoded)

---

## Cost Estimate (us-east-1)

| Resource | Monthly (~) |
|----------|------------|
| ALB | ~$20 |
| 2x EC2 t3.micro | ~$17 |
| RDS db.t3.micro Multi-AZ | ~$30 |
| NAT Gateway | ~$32 |
| Route 53 | ~$1 |
| **Total** | **~$100/mo** |

> Stop/terminate resources after testing to avoid charges.

---

## Author

**Bikash Kushwaha**  
BSc Computer Science with AI – Birmingham City University  
AWS Academy Graduate – Cloud Architecting  
📧 kushwahabikash9580@gmail.com

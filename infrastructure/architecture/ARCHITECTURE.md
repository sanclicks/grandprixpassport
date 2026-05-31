# 🏗️ GrandPrixPassport — Architecture (Single Account, Multi-VPC)

## Decision: Single AWS Account + Separate VPCs

| Approach | Decision | Why |
|---|---|---|
| Multiple AWS Accounts | ❌ Skip | Overkill for solo operator |
| Single Account + VPCs | ✅ Chosen | Simple, isolated, one bill |
| Control Tower | ❌ Skip | Not needed for one account |

---

## VPC Network Design

```
AWS Account: grandprixpassport (single account)
Region: us-east-1

├── VPC: gpp-dev     (10.0.0.0/16)
│   ├── Public:   10.0.1.0/24, 10.0.2.0/24
│   ├── Private:  10.0.3.0/24, 10.0.4.0/24
│   └── Database: 10.0.5.0/24, 10.0.6.0/24

├── VPC: gpp-staging (10.1.0.0/16)
│   ├── Public:   10.1.1.0/24, 10.1.2.0/24
│   ├── Private:  10.1.3.0/24, 10.1.4.0/24
│   └── Database: 10.1.5.0/24, 10.1.6.0/24

└── VPC: gpp-prod    (10.2.0.0/16)
    ├── Public:   10.2.1.0/24, 10.2.2.0/24
    ├── Private:  10.2.3.0/24, 10.2.4.0/24
    └── Database: 10.2.5.0/24, 10.2.6.0/24

NO VPC Peering between environments
NO shared databases between environments
Each VPC completely isolated
```

## Per-Environment Sizing

| Resource | Dev | Staging | Prod |
|---|---|---|---|
| Lambda Memory | 256 MB | 512 MB | 1024 MB |
| Lambda Timeout | 10s | 20s | 30s |
| NAT Gateways | 1 | 1 | 2 (HA) |
| Aurora Min/Max ACU | 0.5/1 | 0.5/2 | 1/8 |
| WAF | Off | On | On |
| Multi-AZ | No | No | Yes |

## Deploy Commands

```bash
# Dev
cd infrastructure/terraform/environments/dev
terraform init && terraform apply -var-file="terraform.tfvars"

# Staging (Sandeep approval)
cd infrastructure/terraform/environments/staging
terraform init && terraform apply -var-file="terraform.tfvars"

# Prod (ONLY after staging validated)
cd infrastructure/terraform/environments/prod
terraform init && terraform plan -var-file="terraform.tfvars"
# Review carefully, then:
terraform apply -var-file="terraform.tfvars"
```

*Last updated: May 2026 — Single account + VPC isolation*

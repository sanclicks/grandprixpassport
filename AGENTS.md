# GrandPrixPassport — Agent & Cloud Development Guide

## Repository status

This is a **pre-MVP planning repository**. MVP Phase 1 has not started. There is no `frontend/`, `backend/`, `package.json`, test suite, or linter configuration yet. Runnable application services do not exist in this repo today.

What **does** exist:

- Product and business documentation (`docs/`, `marketing/`, `legal/`, `data/`)
- Partial Terraform infrastructure (`infrastructure/terraform/`)
- AI agent role definitions (`agents/AGENTS.md`)

## Cursor Cloud specific instructions

### Installed prerequisites

The cloud VM image includes:

| Tool | Version | Purpose |
|---|---|---|
| Node.js | 22.x | Future Next.js / Lambda development |
| npm | 10.x | Package management (when apps are scaffolded) |
| Terraform | ≥ 1.6 | Infrastructure as code |
| AWS CLI | v2 | AWS account interaction |

### What you can run today

**Terraform — VPC module (validates cleanly):**

```bash
cd infrastructure/terraform/modules/vpc
terraform init -backend=false
terraform validate
```

**Terraform — security module (currently blocked):**

`infrastructure/terraform/modules/security/main.tf` has a syntax error on the WAF `default_action` block (line 115: `default_action { allow {} }` must use multi-line nested blocks). Until that is fixed, `terraform fmt -check -recursive` and `terraform init` on the dev root module will fail when parsing the security module.

**Terraform — dev root module (not runnable yet):**

`infrastructure/terraform/environments/dev/main.tf` references modules that are not in the repo (`auth`, `storage`, `database`, `lambda`, `api-gateway`, `cdn`, `monitoring`) and configures a remote S3 backend. Full `terraform plan` / `apply` requires:

1. AWS credentials (`aws configure` or `AWS_PROFILE`)
2. An S3 state bucket and DynamoDB lock table
3. The missing Terraform modules
4. A `*.tfvars` file (gitignored; see `example.tfvars` pattern in `.gitignore`)

**Frontend / backend (documented, not present):**

Per `docs/TECH_STACK.md`, future setup will be:

```bash
cd frontend && npm install && npm run dev   # → http://localhost:3000
cd backend && npm install                  # Lambda functions
```

These directories do not exist yet. Do not expect `npm run dev`, lint, or test commands to work until Phase 1 scaffolding lands.

### Lint and tests

There are **no** configured linters (ESLint, Prettier, markdownlint) or automated tests (Jest, Playwright) in this repository. The closest equivalent health check today is Terraform validation on individual modules.

### AWS credentials

No AWS credentials are pre-configured in the cloud VM. To exercise `terraform plan` or `aws` commands against a real account, add secrets via the environment (for example `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION=us-east-1`) or configure an AWS SSO profile locally.

### Starting services (future)

When MVP code is added, expected local services will be:

| Service | Command | Port |
|---|---|---|
| Next.js frontend | `cd frontend && npm run dev` | 3000 |
| Lambda backend | Deployed to AWS; local testing via SAM or similar | — |

Until then, infrastructure validation is the primary development workflow for this repo.

### Gotchas discovered during setup

- `terraform fmt -check -recursive` fails repo-wide because of the security module syntax error, even though the VPC module is valid.
- The dev root `main.tf` does not declare its own `variable` blocks; variables live in `shared/variables.tf` but are not wired into the dev environment entrypoint yet.
- `.gitignore` excludes `*.tfvars`; create local tfvars from documentation comments in `shared/variables.tf` when ready to plan.

## AI agent team

For the 12-agent roster and governance rules, see [`agents/AGENTS.md`](agents/AGENTS.md).

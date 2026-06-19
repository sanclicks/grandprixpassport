# AGENTS.md

## Cursor Cloud specific instructions

### What this repository is
This is a planning/documentation + early-stage **Terraform IaC** repository for
GrandPrixPassport.com. Despite the `README.md` project tree, there is currently
**no application code** — there are no `frontend/`, `backend/`, `mobile/`, or
`design/` directories, and no `package.json`/`requirements.txt`. Node.js and
Python are present on the VM but nothing in the repo uses them yet.

The only executable/checkable code lives under `infrastructure/terraform/`.

### Toolchain
- **Terraform** is the toolchain. It is installed in the base environment (via the
  HashiCorp apt repo). Verify with `terraform version`.

### Terraform dev loop (run from `infrastructure/terraform/`)
- **Lint/format check:** `terraform fmt -check -recursive` (use `terraform fmt -recursive` to auto-format).
- **Init a module without remote state:** `terraform init -backend=false` inside a module dir
  (downloads the `hashicorp/aws` provider; needs network access).
- **Validate:** `terraform validate` inside an initialized module dir.
- `terraform init`/`.terraform.lock.hcl` artifacts are created in the module dir.
  `.terraform/` is git-ignored, but `.terraform.lock.hcl` is **not** — remove it
  after ad-hoc validation if you don't intend to commit it.

### Known pre-existing issues (do NOT "fix" as part of setup)
- `modules/security/main.tf` has an HCL syntax error: single-line
  `default_action { allow {} }` (a single-line block cannot contain a nested
  block). This breaks `terraform fmt`/`validate` for that module.
- `environments/dev/main.tf` references modules that do not exist yet
  (`auth`, `storage`, `database`, `lambda`, `api-gateway`, `cdn`, `monitoring`)
  and its `backend "s3"` block uses `${var.account_id}` interpolation, which
  Terraform does not allow in backend configuration. So `terraform init`/`plan`
  in `environments/dev` will fail until those modules and a static backend config
  are added.
- `modules/vpc` validates cleanly and is the best module to use when demonstrating
  the working Terraform toolchain.

### Limitations
- `terraform plan`/`apply` require **real AWS credentials** (e.g. the
  `data "aws_availability_zones"` lookup runs at plan time). Without credentials,
  `terraform validate` is the meaningful local verification checkpoint.

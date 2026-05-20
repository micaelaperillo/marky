## Steps to Initialize Terraform Infrastructure

### 0. Bootstrap State Backend (first time only)

Create the S3 bucket for remote state (uses native S3 locking via `use_lockfile`):

```bash
cd terraform/bootstrap
terraform init
terraform apply
```

Then return to the main config and migrate:

```bash
cd terraform/
terraform init -migrate-state
```

Answer "yes" when prompted. See `bootstrap/README.md` for teardown order.

### 1. Get AWS Academy Credentials

Log into AWS Academy Learner Lab → "AWS Details" → copy the credentials block:

```
[default]
aws_access_key_id=...
aws_secret_access_key=...
aws_session_token=...
```

Run `./scripts/aws-creds.sh` and paste the whole block, and copy and paste the export commands, OR run the following command:

```sh
source <(xclip -selection clipboard -o | ./scripts/aws-creds.sh)
```

### 2. Create your tfvars file

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` — set your `suffix` (unique per team member, ≤13 chars).

### 3. Build Lambda functions (optional)

If the `lambdas/` directory exists (after merging the Lambda code branch):

```bash
cd lambdas && pnpm install && pnpm -r build
```

Or use the Makefile from the repo root: `make build`. If skipped, Terraform deploys stub handlers.

### 4. Deploy with Makefile

From the repo root:

```bash
make plan      # builds lambdas + terraform plan
make deploy    # builds lambdas + terraform apply
```

Or manually from `terraform/`:

```bash
terraform init
terraform validate
terraform plan
terraform apply    # ~15-20 min (RDS instance + proxy is slowest)
```

### Post-Apply

1. Set the Gemini API key:

```bash
aws secretsmanager put-secret-value \
  --secret-id marky-gemini-api-key-<suffix> \
  --secret-string '{"api_key":"your-key-here"}'
```

2. Deploy the frontend (if `frontend/` directory exists):

```bash
make deploy-frontend
```

This extracts Cognito IDs from Terraform outputs, builds the SvelteKit frontend, and uploads to S3.

Or do everything at once: `make deploy-all` (infra + frontend).

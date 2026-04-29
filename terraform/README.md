## Steps to Initialize Terraform Infrastructure

### 1. Get AWS Academy Credentials

Log into AWS Academy Learner Lab → "AWS Details" → copy the credentials block:

```bash
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_SESSION_TOKEN=...
```

Paste into terminal. These expire every ~4 hours.

### 2. Create your tfvars file

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` — set your `suffix` (unique per team member, ≤13 chars).

### 3. Initialize Terraform

```bash
terraform init
```

Downloads AWS provider, creates `.terraform/` directory.

### 4. Validate configuration

```bash
terraform validate
```

Catches syntax/reference errors without touching AWS.

### 5. Plan

```bash
terraform plan
```

Shows what will be created. Review the resource list — should be ~30 resources (VPC, subnets, SGs, fck-nat, ALB, ASGs, S3, DynamoDB).

### 6. Apply

```bash
terraform apply
```

Type `yes` when prompted. Takes ~3-5 minutes. fck-nat instance boot is the slowest part.

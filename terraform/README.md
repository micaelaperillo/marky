## Steps to Initialize Terraform Infrastructure

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

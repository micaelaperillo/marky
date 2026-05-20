## Steps to Initialize Terraform Infrastructure

### 0. Bootstrap State Backend (first time only)

Create the S3 bucket and DynamoDB table for remote state:

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

Shows what will be created. Review the resource list — expect ~80 resources (VPC, subnets, VPC endpoints, security groups, RDS + Proxy, API Gateway, 8 Lambdas, 5 SQS FIFO queues + 5 DLQs, SNS FIFO topic, EventBridge schedule group, S3 buckets, DynamoDB, Cognito, Secrets Manager, CloudWatch log groups).

### 6. Apply

```bash
terraform apply
```

Type `yes` when prompted. Takes ~15-20 minutes (RDS instance + proxy creation is the slowest part).

### Post-Apply

Set the Gemini API key manually:

```bash
aws secretsmanager put-secret-value \
  --secret-id marky-gemini-api-key-<suffix> \
  --secret-string '{"api_key":"your-key-here"}'
```

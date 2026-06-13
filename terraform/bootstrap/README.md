# Terraform State Bootstrap

Creates the private S3 bucket (`marky-tfstate`) that the **GitHub Actions
workflows** use to persist Terraform state between runs. The deploy/destroy
workflows pull `terraform.tfstate` from this bucket before running and push it
back after (`aws s3 cp`) — there is **no Terraform S3 backend and no state
locking**. Local runs use local state and don't need this bucket.

## Prerequisites

- Terraform >= 1.10
- AWS credentials configured

## Usage

Run once, before the first deploy workflow:

```bash
cd terraform/bootstrap
terraform init
terraform apply
```

The bucket is private (no public access, versioned, AES256-encrypted). The
workflows reach it with the same AWS Academy lab account credentials (LabRole)
via same-account IAM — no bucket policy is needed.

## Teardown

The main infrastructure's state lives in this bucket (written by the
workflows), so destroy that **first** with the GitHub Actions
**"Terraform Destroy"** workflow — it pulls the state from here. Then delete
this bucket:

```bash
cd terraform/bootstrap
terraform init
terraform destroy
```

`force_destroy = true` lets the versioned bucket delete even with state objects
present.

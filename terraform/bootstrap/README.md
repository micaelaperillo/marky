# Terraform State Bootstrap

Creates the S3 bucket and DynamoDB table used for remote state locking.

## Usage

```bash
cd terraform/bootstrap
terraform init
terraform apply
```

Then migrate the main project state:

```bash
cd terraform/
terraform init -migrate-state
```

Answer "yes" when prompted to copy existing state to S3.

## Teardown

Destroy infrastructure first, then the state backend:

```bash
cd terraform/
terraform init
terraform destroy

cd bootstrap/
terraform init
terraform destroy
```

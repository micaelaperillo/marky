<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | n/a |
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.migrator](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_db_instance.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) | resource |
| [aws_db_parameter_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_parameter_group) | resource |
| [aws_db_proxy.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_proxy) | resource |
| [aws_db_proxy_default_target_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_proxy_default_target_group) | resource |
| [aws_db_proxy_target.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_proxy_target) | resource |
| [aws_db_subnet_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_dynamodb_table.reports](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [aws_lambda_function.migrator](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_invocation.migrate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_invocation) | resource |
| [aws_secretsmanager_secret.rds_credentials](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.rds_credentials](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [random_password.rds_master](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [archive_file.migrator](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_db_instance_class"></a> [db\_instance\_class](#input\_db\_instance\_class) | RDS instance class. | `string` | `"db.t4g.micro"` | no |
| <a name="input_db_name"></a> [db\_name](#input\_db\_name) | Name of the PostgreSQL database to create. | `string` | `"marky"` | no |
| <a name="input_db_username"></a> [db\_username](#input\_db\_username) | Master username for the RDS instance. | `string` | `"marky_admin"` | no |
| <a name="input_lab_role_arn"></a> [lab\_role\_arn](#input\_lab\_role\_arn) | ARN of the LabRole IAM role used by all resources. | `string` | n/a | yes |
| <a name="input_lambda_dist_base"></a> [lambda\_dist\_base](#input\_lambda\_dist\_base) | Absolute path to the lambdas/apps directory for bundled handler zips. | `string` | n/a | yes |
| <a name="input_lambda_sg_id"></a> [lambda\_sg\_id](#input\_lambda\_sg\_id) | Security group ID for Lambda VPC configuration. | `string` | n/a | yes |
| <a name="input_lambda_subnet_ids"></a> [lambda\_subnet\_ids](#input\_lambda\_subnet\_ids) | Subnet IDs for Lambda VPC configuration. | `list(string)` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | Project name prefix for all resource names and tags. | `string` | n/a | yes |
| <a name="input_rds_sg_id"></a> [rds\_sg\_id](#input\_rds\_sg\_id) | Security group ID for the RDS instance and RDS Proxy. | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | List of subnet IDs for the DB subnet group and RDS Proxy. | `list(string)` | n/a | yes |
| <a name="input_suffix"></a> [suffix](#input\_suffix) | Auto-generated suffix for globally-scoped resources (secrets, etc.). | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_db_name"></a> [db\_name](#output\_db\_name) | Name of the PostgreSQL database. |
| <a name="output_dynamodb_reports_table_name"></a> [dynamodb\_reports\_table\_name](#output\_dynamodb\_reports\_table\_name) | Name of the DynamoDB reports table. |
| <a name="output_rds_proxy_endpoint"></a> [rds\_proxy\_endpoint](#output\_rds\_proxy\_endpoint) | RDS Proxy endpoint for database connections. |
| <a name="output_rds_secret_name"></a> [rds\_secret\_name](#output\_rds\_secret\_name) | Name of the Secrets Manager secret containing RDS credentials. |
<!-- END_TF_DOCS -->
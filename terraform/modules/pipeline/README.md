<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | n/a |
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.fetcher](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.orchestrator](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.report_generator](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.report_writer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_group.s3_saver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_lambda_event_source_mapping.fetcher](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping) | resource |
| [aws_lambda_event_source_mapping.orchestrator](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping) | resource |
| [aws_lambda_event_source_mapping.report_generator](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping) | resource |
| [aws_lambda_event_source_mapping.report_writer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping) | resource |
| [aws_lambda_event_source_mapping.s3_saver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping) | resource |
| [aws_lambda_function.fetcher](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_function.orchestrator](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_function.report_generator](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_function.report_writer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_lambda_function.s3_saver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [aws_scheduler_schedule_group.campaigns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/scheduler_schedule_group) | resource |
| [aws_secretsmanager_secret.gemini_api_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.gemini_api_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_sns_topic.campaign_posts](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_subscription.posts_to_analyze](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_sns_topic_subscription.posts_to_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |
| [aws_sqs_queue.campaign_events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue.campaign_events_dlq](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue.campaign_topics](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue.campaign_topics_dlq](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue.posts_to_analyze](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue.posts_to_analyze_dlq](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue.posts_to_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue.posts_to_s3_dlq](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue.reports](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue.reports_dlq](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue_policy.posts_to_analyze](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue_policy) | resource |
| [aws_sqs_queue_policy.posts_to_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue_policy) | resource |
| [aws_sqs_queue_redrive_allow_policy.campaign_events_dlq](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue_redrive_allow_policy) | resource |
| [aws_sqs_queue_redrive_allow_policy.campaign_topics_dlq](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue_redrive_allow_policy) | resource |
| [aws_sqs_queue_redrive_allow_policy.posts_to_analyze_dlq](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue_redrive_allow_policy) | resource |
| [aws_sqs_queue_redrive_allow_policy.posts_to_s3_dlq](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue_redrive_allow_policy) | resource |
| [aws_sqs_queue_redrive_allow_policy.reports_dlq](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue_redrive_allow_policy) | resource |
| [archive_file.fetcher](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [archive_file.orchestrator](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [archive_file.report_generator](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [archive_file.report_writer](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |
| [archive_file.s3_saver](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bluesky_app_password"></a> [bluesky\_app\_password](#input\_bluesky\_app\_password) | Bluesky app password for the fetcher Lambda. | `string` | `null` | no |
| <a name="input_bluesky_identifier"></a> [bluesky\_identifier](#input\_bluesky\_identifier) | Bluesky account identifier for the fetcher Lambda. | `string` | `null` | no |
| <a name="input_dynamodb_reports_table_name"></a> [dynamodb\_reports\_table\_name](#input\_dynamodb\_reports\_table\_name) | Name of the DynamoDB table for storing analysis reports. | `string` | n/a | yes |
| <a name="input_fetcher_max_concurrency"></a> [fetcher\_max\_concurrency](#input\_fetcher\_max\_concurrency) | Maximum concurrent Lambda invocations for the fetcher ESM. | `number` | `5` | no |
| <a name="input_gemini_api_key"></a> [gemini\_api\_key](#input\_gemini\_api\_key) | Google Gemini API key for report generation. | `string` | n/a | yes |
| <a name="input_lab_role_arn"></a> [lab\_role\_arn](#input\_lab\_role\_arn) | ARN of the LabRole IAM role used by all resources. | `string` | n/a | yes |
| <a name="input_lambda_dist_base"></a> [lambda\_dist\_base](#input\_lambda\_dist\_base) | Base path to the Lambda workspace apps directory. Null = use stubs. | `string` | `null` | no |
| <a name="input_orchestrator_max_concurrency"></a> [orchestrator\_max\_concurrency](#input\_orchestrator\_max\_concurrency) | Maximum concurrent Lambda invocations for the orchestrator ESM. | `number` | `5` | no |
| <a name="input_posts_bucket_name"></a> [posts\_bucket\_name](#input\_posts\_bucket\_name) | Name of the S3 bucket for storing Bluesky post data. | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | Project name prefix for all resource names and tags. | `string` | n/a | yes |
| <a name="input_report_generator_max_concurrency"></a> [report\_generator\_max\_concurrency](#input\_report\_generator\_max\_concurrency) | Maximum concurrent Lambda invocations for the report generator ESM. | `number` | `2` | no |
| <a name="input_report_writer_max_concurrency"></a> [report\_writer\_max\_concurrency](#input\_report\_writer\_max\_concurrency) | Maximum concurrent Lambda invocations for the report writer ESM. | `number` | `5` | no |
| <a name="input_s3_saver_max_concurrency"></a> [s3\_saver\_max\_concurrency](#input\_s3\_saver\_max\_concurrency) | Maximum concurrent Lambda invocations for the S3 saver ESM. | `number` | `10` | no |
| <a name="input_suffix"></a> [suffix](#input\_suffix) | Auto-generated suffix for globally-scoped resources (secrets, etc.). | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_campaign_events_queue_arn"></a> [campaign\_events\_queue\_arn](#output\_campaign\_events\_queue\_arn) | ARN of the campaign events FIFO SQS queue. |
| <a name="output_campaign_events_queue_url"></a> [campaign\_events\_queue\_url](#output\_campaign\_events\_queue\_url) | URL of the campaign events FIFO SQS queue. |
| <a name="output_campaign_topics_queue_url"></a> [campaign\_topics\_queue\_url](#output\_campaign\_topics\_queue\_url) | URL of the campaign topics FIFO SQS queue. |
| <a name="output_fetcher_function_name"></a> [fetcher\_function\_name](#output\_fetcher\_function\_name) | Name of the fetcher Lambda function. |
| <a name="output_gemini_secret_arn"></a> [gemini\_secret\_arn](#output\_gemini\_secret\_arn) | ARN of the Secrets Manager secret for the Gemini API key. |
| <a name="output_orchestrator_function_name"></a> [orchestrator\_function\_name](#output\_orchestrator\_function\_name) | Name of the orchestrator Lambda function. |
| <a name="output_report_generator_function_name"></a> [report\_generator\_function\_name](#output\_report\_generator\_function\_name) | Name of the report generator Lambda function. |
| <a name="output_report_writer_function_name"></a> [report\_writer\_function\_name](#output\_report\_writer\_function\_name) | Name of the report writer Lambda function. |
| <a name="output_reports_queue_url"></a> [reports\_queue\_url](#output\_reports\_queue\_url) | URL of the reports FIFO SQS queue. |
| <a name="output_s3_saver_function_name"></a> [s3\_saver\_function\_name](#output\_s3\_saver\_function\_name) | Name of the S3 saver Lambda function. |
| <a name="output_schedule_group_name"></a> [schedule\_group\_name](#output\_schedule\_group\_name) | Name of the EventBridge Scheduler group for per-campaign schedules. |
| <a name="output_sns_campaign_posts_arn"></a> [sns\_campaign\_posts\_arn](#output\_sns\_campaign\_posts\_arn) | ARN of the campaign posts SNS FIFO topic. |
<!-- END_TF_DOCS -->
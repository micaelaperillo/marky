################################################################################
# Section 1: DLQ Queues
################################################################################

resource "aws_sqs_queue" "campaign_events_dlq" {
  name                        = "${var.project}-campaign-events-dlq.fifo"
  fifo_queue                  = true
  content_based_deduplication = false
  message_retention_seconds   = 1209600
  sqs_managed_sse_enabled     = true
  tags                        = { Name = "${var.project}-campaign-events-dlq" }
}

resource "aws_sqs_queue" "campaign_topics_dlq" {
  name                        = "${var.project}-campaign-topics-dlq.fifo"
  fifo_queue                  = true
  content_based_deduplication = false
  message_retention_seconds   = 1209600
  sqs_managed_sse_enabled     = true
  tags                        = { Name = "${var.project}-campaign-topics-dlq" }
}

resource "aws_sqs_queue" "posts_to_s3_dlq" {
  name                        = "${var.project}-posts-to-s3-dlq.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  message_retention_seconds   = 1209600
  sqs_managed_sse_enabled     = true
  tags                        = { Name = "${var.project}-posts-to-s3-dlq" }
}

resource "aws_sqs_queue" "posts_to_analyze_dlq" {
  name                        = "${var.project}-posts-to-analyze-dlq.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  message_retention_seconds   = 1209600
  sqs_managed_sse_enabled     = true
  tags                        = { Name = "${var.project}-posts-to-analyze-dlq" }
}

resource "aws_sqs_queue" "reports_dlq" {
  name                        = "${var.project}-reports-dlq.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  message_retention_seconds   = 1209600
  sqs_managed_sse_enabled     = true
  tags                        = { Name = "${var.project}-reports-dlq" }
}

################################################################################
# Section 1b: DLQ Redrive Allow Policies
################################################################################

resource "aws_sqs_queue_redrive_allow_policy" "campaign_events_dlq" {
  queue_url = aws_sqs_queue.campaign_events_dlq.url
  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.campaign_events.arn]
  })
}

resource "aws_sqs_queue_redrive_allow_policy" "campaign_topics_dlq" {
  queue_url = aws_sqs_queue.campaign_topics_dlq.url
  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.campaign_topics.arn]
  })
}

resource "aws_sqs_queue_redrive_allow_policy" "posts_to_s3_dlq" {
  queue_url = aws_sqs_queue.posts_to_s3_dlq.url
  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.posts_to_s3.arn]
  })
}

resource "aws_sqs_queue_redrive_allow_policy" "posts_to_analyze_dlq" {
  queue_url = aws_sqs_queue.posts_to_analyze_dlq.url
  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.posts_to_analyze.arn]
  })
}

resource "aws_sqs_queue_redrive_allow_policy" "reports_dlq" {
  queue_url = aws_sqs_queue.reports_dlq.url
  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.reports.arn]
  })
}

################################################################################
# Section 2: Main Queues
################################################################################

resource "aws_sqs_queue" "campaign_events" {
  name                        = "${var.project}-campaign-events.fifo"
  fifo_queue                  = true
  content_based_deduplication = false
  deduplication_scope         = "messageGroup"
  fifo_throughput_limit       = "perMessageGroupId"
  visibility_timeout_seconds  = 360
  message_retention_seconds   = 1209600
  sqs_managed_sse_enabled     = true
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.campaign_events_dlq.arn
    maxReceiveCount     = 3
  })
  tags = { Name = "${var.project}-campaign-events" }
}

resource "aws_sqs_queue" "campaign_topics" {
  name                        = "${var.project}-campaign-topics.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  deduplication_scope         = "messageGroup"
  fifo_throughput_limit       = "perMessageGroupId"
  visibility_timeout_seconds  = 720
  message_retention_seconds   = 1209600
  sqs_managed_sse_enabled     = true
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.campaign_topics_dlq.arn
    maxReceiveCount     = 3
  })
  tags = { Name = "${var.project}-campaign-topics" }
}

resource "aws_sqs_queue" "posts_to_s3" {
  name                        = "${var.project}-posts-to-s3.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  visibility_timeout_seconds  = 360
  message_retention_seconds   = 1209600
  sqs_managed_sse_enabled     = true
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.posts_to_s3_dlq.arn
    maxReceiveCount     = 3
  })
  tags = { Name = "${var.project}-posts-to-s3" }
}

resource "aws_sqs_queue" "posts_to_analyze" {
  name                        = "${var.project}-posts-to-analyze.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  visibility_timeout_seconds  = 1800
  message_retention_seconds   = 1209600
  sqs_managed_sse_enabled     = true
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.posts_to_analyze_dlq.arn
    maxReceiveCount     = 3
  })
  tags = { Name = "${var.project}-posts-to-analyze" }
}

resource "aws_sqs_queue" "reports" {
  name                        = "${var.project}-reports.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
  visibility_timeout_seconds  = 360
  message_retention_seconds   = 1209600
  sqs_managed_sse_enabled     = true
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.reports_dlq.arn
    maxReceiveCount     = 3
  })
  tags = { Name = "${var.project}-reports" }
}

################################################################################
# Section 3: SNS FIFO Topic + Subscriptions + Queue Policies
################################################################################

resource "aws_sns_topic" "campaign_posts" {
  name                        = "${var.project}-campaign-posts.fifo"
  fifo_topic                  = true
  content_based_deduplication = true
  tags                        = { Name = "${var.project}-campaign-posts" }
}

resource "aws_sns_topic_subscription" "posts_to_s3" {
  topic_arn            = aws_sns_topic.campaign_posts.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.posts_to_s3.arn
  raw_message_delivery = false
}

resource "aws_sns_topic_subscription" "posts_to_analyze" {
  topic_arn            = aws_sns_topic.campaign_posts.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.posts_to_analyze.arn
  raw_message_delivery = false
}

resource "aws_sqs_queue_policy" "posts_to_s3" {
  queue_url = aws_sqs_queue.posts_to_s3.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "sns.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.posts_to_s3.arn
      Condition = { ArnEquals = { "aws:SourceArn" = aws_sns_topic.campaign_posts.arn } }
    }]
  })
}

resource "aws_sqs_queue_policy" "posts_to_analyze" {
  queue_url = aws_sqs_queue.posts_to_analyze.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "sns.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.posts_to_analyze.arn
      Condition = { ArnEquals = { "aws:SourceArn" = aws_sns_topic.campaign_posts.arn } }
    }]
  })
}

################################################################################
# Section 4: EventBridge Schedule Group + Gemini Secret
################################################################################

resource "aws_scheduler_schedule_group" "campaigns" {
  name = "${var.project}-campaigns"
  tags = { Name = "${var.project}-campaigns-schedule-group" }
}

resource "aws_secretsmanager_secret" "gemini_api_key" {
  name                    = "${var.project}-gemini-api-key-${var.suffix}"
  recovery_window_in_days = 0
  tags                    = { Name = "${var.project}-gemini-api-key" }
}

resource "aws_secretsmanager_secret_version" "gemini_api_key" {
  secret_id     = aws_secretsmanager_secret.gemini_api_key.id
  secret_string = var.gemini_api_key
}

################################################################################
# Section 5: Lambda Functions
################################################################################

locals {
  stub_handler = "export const handler = async (event) => ({ statusCode: 200, body: JSON.stringify({ message: 'stub' }) });"
  pkg_json_esm = "{\"type\":\"module\"}"

  pipeline_apps = {
    orchestrator     = "orchestrator"
    fetcher          = "bluesky-ingest"
    s3_saver         = "bluesky-store"
    report_generator = "report-creator"
    report_writer    = "report-writer"
  }
}

# --- Orchestrator ---

data "archive_file" "orchestrator" {
  type        = "zip"
  output_path = "${path.module}/dist/orchestrator.zip"

  source {
    content = try(
      var.lambda_dist_base != null ? file("${var.lambda_dist_base}/${local.pipeline_apps["orchestrator"]}/dist/handler.js") : local.stub_handler,
      local.stub_handler
    )
    filename = "handler.js"
  }
  source {
    content  = local.pkg_json_esm
    filename = "package.json"
  }
}

resource "aws_lambda_function" "orchestrator" {
  function_name    = "${var.project}-orchestrator"
  role             = var.lab_role_arn
  runtime          = "nodejs22.x"
  handler          = "handler.handler"
  filename         = data.archive_file.orchestrator.output_path
  source_code_hash = data.archive_file.orchestrator.output_base64sha256
  timeout          = 60
  memory_size      = 256

  environment {
    variables = {
      NODE_ENV                  = "production"
      CAMPAIGN_TOPICS_QUEUE_URL = aws_sqs_queue.campaign_topics.url
      SCHEDULE_GROUP_NAME       = aws_scheduler_schedule_group.campaigns.name
      SCHEDULER_ROLE_ARN        = var.lab_role_arn
      SCHEDULER_LAMBDA_ARN      = aws_lambda_function.fetcher.arn
    }
  }

  tags = { Name = "${var.project}-orchestrator" }
}

# --- Fetcher ---

data "archive_file" "fetcher" {
  type        = "zip"
  output_path = "${path.module}/dist/fetcher.zip"

  source {
    content = try(
      var.lambda_dist_base != null ? file("${var.lambda_dist_base}/${local.pipeline_apps["fetcher"]}/dist/handler.js") : local.stub_handler,
      local.stub_handler
    )
    filename = "handler.js"
  }
  source {
    content  = local.pkg_json_esm
    filename = "package.json"
  }
}

resource "aws_lambda_function" "fetcher" {
  function_name    = "${var.project}-fetcher"
  role             = var.lab_role_arn
  runtime          = "nodejs22.x"
  handler          = "handler.handler"
  filename         = data.archive_file.fetcher.output_path
  source_code_hash = data.archive_file.fetcher.output_base64sha256
  timeout          = 120
  memory_size      = 256

  environment {
    variables = merge(
      {
        NODE_ENV      = "production"
        SNS_TOPIC_ARN = aws_sns_topic.campaign_posts.arn
      },
      var.bluesky_identifier != null ? { BLUESKY_IDENTIFIER = var.bluesky_identifier } : {},
      var.bluesky_app_password != null ? { BLUESKY_APP_PASSWORD = var.bluesky_app_password } : {}
    )
  }

  tags = { Name = "${var.project}-fetcher" }
}

# --- S3 Saver ---

data "archive_file" "s3_saver" {
  type        = "zip"
  output_path = "${path.module}/dist/s3_saver.zip"

  source {
    content = try(
      var.lambda_dist_base != null ? file("${var.lambda_dist_base}/${local.pipeline_apps["s3_saver"]}/dist/handler.js") : local.stub_handler,
      local.stub_handler
    )
    filename = "handler.js"
  }
  source {
    content  = local.pkg_json_esm
    filename = "package.json"
  }
}

resource "aws_lambda_function" "s3_saver" {
  function_name    = "${var.project}-s3-saver"
  role             = var.lab_role_arn
  runtime          = "nodejs22.x"
  handler          = "handler.handler"
  filename         = data.archive_file.s3_saver.output_path
  source_code_hash = data.archive_file.s3_saver.output_base64sha256
  timeout          = 60
  memory_size      = 256

  environment {
    variables = {
      NODE_ENV       = "production"
      S3_BUCKET_NAME = var.posts_bucket_name
    }
  }

  tags = { Name = "${var.project}-s3-saver" }
}

# --- Report Generator ---

data "archive_file" "report_generator" {
  type        = "zip"
  output_path = "${path.module}/dist/report_generator.zip"

  source {
    content = try(
      var.lambda_dist_base != null ? file("${var.lambda_dist_base}/${local.pipeline_apps["report_generator"]}/dist/handler.js") : local.stub_handler,
      local.stub_handler
    )
    filename = "handler.js"
  }
  source {
    content  = local.pkg_json_esm
    filename = "package.json"
  }
}

resource "aws_lambda_function" "report_generator" {
  function_name    = "${var.project}-report-generator"
  role             = var.lab_role_arn
  runtime          = "nodejs22.x"
  handler          = "handler.handler"
  filename         = data.archive_file.report_generator.output_path
  source_code_hash = data.archive_file.report_generator.output_base64sha256
  timeout          = 300
  memory_size      = 512

  environment {
    variables = {
      NODE_ENV                    = "production"
      SM_GEMINI_API_KEY_SECRET_ID = aws_secretsmanager_secret.gemini_api_key.name
      SQS_OUTPUT_REPORTS_URL      = aws_sqs_queue.reports.url
    }
  }

  tags = { Name = "${var.project}-report-generator" }
}

# --- Report Writer ---

data "archive_file" "report_writer" {
  type        = "zip"
  output_path = "${path.module}/dist/report_writer.zip"

  source {
    content = try(
      var.lambda_dist_base != null ? file("${var.lambda_dist_base}/${local.pipeline_apps["report_writer"]}/dist/handler.js") : local.stub_handler,
      local.stub_handler
    )
    filename = "handler.js"
  }
  source {
    content  = local.pkg_json_esm
    filename = "package.json"
  }
}

resource "aws_lambda_function" "report_writer" {
  function_name    = "${var.project}-report-writer"
  role             = var.lab_role_arn
  runtime          = "nodejs22.x"
  handler          = "handler.handler"
  filename         = data.archive_file.report_writer.output_path
  source_code_hash = data.archive_file.report_writer.output_base64sha256
  timeout          = 60
  memory_size      = 256

  environment {
    variables = {
      NODE_ENV       = "production"
      DYNAMODB_TABLE = var.dynamodb_reports_table_name
    }
  }

  tags = { Name = "${var.project}-report-writer" }
}

################################################################################
# Section 6: CloudWatch Log Groups
################################################################################

resource "aws_cloudwatch_log_group" "orchestrator" {
  name              = "/aws/lambda/${var.project}-orchestrator"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "fetcher" {
  name              = "/aws/lambda/${var.project}-fetcher"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "s3_saver" {
  name              = "/aws/lambda/${var.project}-s3-saver"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "report_generator" {
  name              = "/aws/lambda/${var.project}-report-generator"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "report_writer" {
  name              = "/aws/lambda/${var.project}-report-writer"
  retention_in_days = 14
}

################################################################################
# Section 7: Event Source Mappings
################################################################################

resource "aws_lambda_event_source_mapping" "orchestrator" {
  event_source_arn        = aws_sqs_queue.campaign_events.arn
  function_name           = aws_lambda_function.orchestrator.arn
  batch_size              = 1
  enabled                 = true
  function_response_types = ["ReportBatchItemFailures"]

  scaling_config {
    maximum_concurrency = var.orchestrator_max_concurrency
  }
}

resource "aws_lambda_event_source_mapping" "fetcher" {
  event_source_arn        = aws_sqs_queue.campaign_topics.arn
  function_name           = aws_lambda_function.fetcher.arn
  batch_size              = 1
  enabled                 = true
  function_response_types = ["ReportBatchItemFailures"]

  scaling_config {
    maximum_concurrency = var.fetcher_max_concurrency
  }
}

resource "aws_lambda_event_source_mapping" "s3_saver" {
  event_source_arn        = aws_sqs_queue.posts_to_s3.arn
  function_name           = aws_lambda_function.s3_saver.arn
  batch_size              = 10
  enabled                 = true
  function_response_types = ["ReportBatchItemFailures"]

  scaling_config {
    maximum_concurrency = var.s3_saver_max_concurrency
  }
}

resource "aws_lambda_event_source_mapping" "report_generator" {
  event_source_arn        = aws_sqs_queue.posts_to_analyze.arn
  function_name           = aws_lambda_function.report_generator.arn
  batch_size              = 5
  enabled                 = true
  function_response_types = ["ReportBatchItemFailures"]

  scaling_config {
    maximum_concurrency = var.report_generator_max_concurrency
  }
}

resource "aws_lambda_event_source_mapping" "report_writer" {
  event_source_arn        = aws_sqs_queue.reports.arn
  function_name           = aws_lambda_function.report_writer.arn
  batch_size              = 1
  enabled                 = true
  function_response_types = ["ReportBatchItemFailures"]

  scaling_config {
    maximum_concurrency = var.report_writer_max_concurrency
  }
}

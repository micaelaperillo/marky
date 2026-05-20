data "aws_caller_identity" "current" {}

locals {
  lab_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
}

# ============================================================
# SQS Queue — receives campaign messages from the Go lambda
# ============================================================

resource "aws_sqs_queue" "campaigns" {
  name                       = "${var.project}-campaigns"
  visibility_timeout_seconds = 60

  tags = { Name = "${var.project}-campaigns-queue" }
}

# ============================================================
# SNS Topic — bluesky-ingest publishes one message per topic result
# ============================================================

resource "aws_sns_topic" "bluesky_results" {
  name = "${var.project}-bluesky-results"

  tags = { Name = "${var.project}-bluesky-results" }
}

# ============================================================
# Lambda Function
# ============================================================

data "archive_file" "bluesky_ingest" {
  type        = "zip"
  source_dir  = "${path.module}/../../../lambdas/apps/bluesky-ingest/dist"
  output_path = "${path.module}/dist/bluesky-ingest.zip"
}

resource "aws_lambda_function" "bluesky_ingest" {
  function_name    = "${var.project}-bluesky-ingest"
  role             = local.lab_role_arn
  handler          = "handler.handler"
  runtime          = "nodejs20.x"
  filename         = data.archive_file.bluesky_ingest.output_path
  source_code_hash = data.archive_file.bluesky_ingest.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      BLUESKY_IDENTIFIER   = var.bluesky_identifier
      BLUESKY_APP_PASSWORD = var.bluesky_app_password
      SNS_TOPIC_ARN        = aws_sns_topic.bluesky_results.arn
      AWS_REGION           = var.region
    }
  }

  vpc_config {
    subnet_ids         = var.lambda_subnet_ids
    security_group_ids = [var.lambda_sg_id]
  }

  tags = { Name = "${var.project}-bluesky-ingest" }
}

# ============================================================
# Event Source Mapping — SQS triggers the Lambda
# ============================================================

resource "aws_lambda_event_source_mapping" "sqs" {
  event_source_arn        = aws_sqs_queue.campaigns.arn
  function_name           = aws_lambda_function.bluesky_ingest.arn
  batch_size              = 10
  function_response_types = ["ReportBatchItemFailures"]
}

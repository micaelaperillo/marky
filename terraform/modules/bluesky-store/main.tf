data "aws_caller_identity" "current" {}

locals {
  lab_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
}

# ============================================================
# S3 Bucket — stores raw BlueSky results
# ============================================================

resource "aws_s3_bucket" "bluesky_raw" {
  bucket = "${var.project}-bluesky-raw-${var.suffix}"

  tags = { Name = "${var.project}-bluesky-raw-${var.suffix}" }
}

resource "aws_s3_bucket_versioning" "bluesky_raw" {
  bucket = aws_s3_bucket.bluesky_raw.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bluesky_raw" {
  bucket = aws_s3_bucket.bluesky_raw.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "bluesky_raw" {
  bucket = aws_s3_bucket.bluesky_raw.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "bluesky_raw" {
  bucket = aws_s3_bucket.bluesky_raw.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# ============================================================
# SQS Queue — receives BlueSky result notifications from SNS
# ============================================================

resource "aws_sqs_queue" "bluesky_raw" {
  name                       = "${var.project}-bluesky-raw"
  visibility_timeout_seconds = 60

  tags = { Name = "${var.project}-bluesky-raw-queue" }
}

resource "aws_sqs_queue_policy" "bluesky_raw" {
  queue_url = aws_sqs_queue.bluesky_raw.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "sns.amazonaws.com" }
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.bluesky_raw.arn
        Condition = {
          ArnEquals = { "aws:SourceArn" = var.sns_topic_arn }
        }
      }
    ]
  })
}

# ============================================================
# SNS Subscription — SNS delivers to the SQS queue
# ============================================================

resource "aws_sns_topic_subscription" "bluesky_raw" {
  topic_arn = var.sns_topic_arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.bluesky_raw.arn
}

# ============================================================
# Lambda Function
# ============================================================

data "archive_file" "bluesky_store" {
  type        = "zip"
  source_dir  = "${path.module}/../../../lambdas/apps/bluesky-store/dist"
  output_path = "${path.module}/dist/bluesky-store.zip"
}

resource "aws_lambda_function" "bluesky_store" {
  function_name    = "${var.project}-bluesky-store"
  role             = local.lab_role_arn
  handler          = "handler.handler"
  runtime          = "nodejs20.x"
  filename         = data.archive_file.bluesky_store.output_path
  source_code_hash = data.archive_file.bluesky_store.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      S3_BUCKET_NAME = aws_s3_bucket.bluesky_raw.bucket
      AWS_REGION     = var.region
    }
  }

  vpc_config {
    subnet_ids         = var.lambda_subnet_ids
    security_group_ids = [var.lambda_sg_id]
  }

  tags = { Name = "${var.project}-bluesky-store" }
}

# ============================================================
# Event Source Mapping — SQS triggers the Lambda
# ============================================================

resource "aws_lambda_event_source_mapping" "bluesky_raw" {
  event_source_arn        = aws_sqs_queue.bluesky_raw.arn
  function_name           = aws_lambda_function.bluesky_store.arn
  batch_size              = 10
  function_response_types = ["ReportBatchItemFailures"]
}

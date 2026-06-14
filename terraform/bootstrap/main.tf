variable "user" {
  description = "The user running the action"
  type    = string
}

resource "aws_s3_bucket" "tfstate" {
  bucket        = "marky-tfstate-${var.user}"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Keep the state bucket fully private. The GitHub Actions workflows reach it
# with the same AWS Academy lab account credentials (LabRole), so same-account
# IAM access is enough — no bucket policy is needed, and a public one would
# expose the secrets stored in Terraform state.
resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

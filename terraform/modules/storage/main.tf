# --- Frontend S3 Bucket (static HTML/JS/CSS, served via API Gateway) ---

resource "aws_s3_bucket" "frontend" {
  bucket        = "${var.project}-frontend-${var.suffix}"
  force_destroy = true

  tags = { Name = "${var.project}-frontend-${var.suffix}" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    id     = "expire-stale-build-assets"
    status = "Enabled"

    filter {
      prefix = "_app/immutable/"
    }

    expiration {
      days = 7
    }
  }
}

# --- Posts S3 Bucket ---

resource "aws_s3_bucket" "posts" {
  bucket        = "${var.project}-posts-${var.suffix}"
  force_destroy = true

  tags = { Name = "${var.project}-posts-${var.suffix}" }
}

resource "aws_s3_bucket_versioning" "posts" {
  bucket = aws_s3_bucket.posts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "posts" {
  bucket = aws_s3_bucket.posts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "posts" {
  bucket = aws_s3_bucket.posts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "posts" {
  bucket = aws_s3_bucket.posts.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "posts" {
  bucket = aws_s3_bucket.posts.id

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

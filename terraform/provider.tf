provider "aws" {
  region      = var.region
  max_retries = 30

  default_tags {
    tags = {
      Project = var.project
    }
  }
}

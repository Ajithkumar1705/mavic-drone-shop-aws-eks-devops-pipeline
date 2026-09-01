# bootstrap/main.tf
#
# This config has NO remote backend — it uses local state on purpose.
# It exists solely to create the S3 bucket + DynamoDB table that the
# REST of the project's Terraform (in terraform/) uses as its
# remote backend. Run this once, by hand, before anything else.
#
# Usage:
#   cd terraform/bootstrap
#   terraform init
#   terraform apply
#
# After this succeeds, you will have a local terraform.tfstate file
# right here in bootstrap/ — that's expected and fine. Do not delete it,
# but it does not need to be shared/remote since this config rarely changes.

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# S3 bucket to hold Terraform state files for the main project
resource "aws_s3_bucket" "tf_state" {
  bucket = var.state_bucket_name

  # Prevents accidental deletion of this bucket via `terraform destroy`
  # while you still have real infra state stored in it.
  lifecycle {
    prevent_destroy = true
  }
}

# Versioning lets you recover a previous state file if something
# corrupts or overwrites the current one.
resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Encrypt state at rest — state files can contain sensitive values
# (e.g. DB passwords passed as Terraform variables).
resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block all public access — state files should never be public.
resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB table for state LOCKING.
# Without this, two `terraform apply` runs at the same time could
# corrupt your state file. Terraform automatically uses a row in this
# table as a lock while an apply is in progress.
resource "aws_dynamodb_table" "tf_lock" {
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST" # no cost when idle — good for a portfolio project
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

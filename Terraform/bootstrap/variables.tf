variable "aws_region" {
  description = "AWS region to create the state bucket and lock table in"
  type        = string
  default     = "ap-south-1"
}

variable "state_bucket_name" {
  description = "Globally unique S3 bucket name for Terraform remote state. S3 bucket names are unique across ALL of AWS, not just your account — pick something specific to you."
  type        = string
  default     = "mavic-drone-shop-tfstate-ajithkumar1705"
}

variable "lock_table_name" {
  description = "DynamoDB table name used for Terraform state locking"
  type        = string
  default     = "mavic-drone-shop-tf-lock"
}

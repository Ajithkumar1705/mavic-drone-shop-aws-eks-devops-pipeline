output "state_bucket_name" {
  description = "Copy this into terraform/backend.tf"
  value       = aws_s3_bucket.tf_state.id
}

output "lock_table_name" {
  description = "Copy this into terraform/backend.tf"
  value       = aws_dynamodb_table.tf_lock.name
}

output "aws_region" {
  description = "Copy this into terraform/backend.tf"
  value       = var.aws_region
}

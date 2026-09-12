output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.eks.cluster_endpoint
}

output "update_kubeconfig_command" {
  description = "Run this to configure kubectl against the new cluster"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}"
}

output "github_actions_role_arn" {
  description = "Copy this into GitHub secrets as AWS_DEPLOY_ROLE_ARN"
  value       = aws_iam_role.github_actions_deploy.arn
}

output "ecr_repository_urls" {
  description = "ECR repository URLs, one per service"
  value       = { for k, v in aws_ecr_repository.service : k => v.repository_url }
}

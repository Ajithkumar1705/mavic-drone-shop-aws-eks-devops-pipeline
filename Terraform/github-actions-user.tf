# GitHub Actions authentication using an IAM user and access keys.
#
# The access key and secret access key are NOT stored in Terraform.
# Create the access key manually in IAM and store it as GitHub Actions
# repository secrets:
#   AWS_ACCESS_KEY_ID
#   AWS_SECRET_ACCESS_KEY
#
# This is the fallback authentication approach for this portfolio
# project. GitHub OIDC is intentionally not used here.

resource "aws_iam_user" "github_actions" {
  name = var.github_actions_user_name
}

# ECR permissions required by CI to authenticate, push, and pull images.
resource "aws_iam_user_policy" "github_actions_ecr" {
  name = "ecr-push-pull"
  user = aws_iam_user.github_actions.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = [for repo in aws_ecr_repository.service : repo.arn]
      }
    ]
  })
}

# Required by CD for `aws eks update-kubeconfig`.
resource "aws_iam_user_policy" "github_actions_eks_describe" {
  name = "eks-describe"
  user = aws_iam_user.github_actions.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "eks:DescribeCluster"
        Resource = module.eks.cluster_arn
      }
    ]
  })
}

# Allow this IAM user to authenticate to Kubernetes through the EKS
# access-entry API. This replaces the old GitHub OIDC role as the
# Kubernetes identity used by the deployment workflow.
resource "aws_eks_access_entry" "github_actions" {
  cluster_name      = module.eks.cluster_name
  principal_arn     = aws_iam_user.github_actions.arn
  kubernetes_groups = ["github-actions-deploy"]
}

resource "aws_eks_access_policy_association" "github_actions" {
  cluster_name  = module.eks.cluster_name
  principal_arn = aws_iam_user.github_actions.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"

  access_scope {
    type       = "namespace"
    namespaces = ["mavic-drone-shop"]
  }

  depends_on = [kubernetes_namespace.app]
}

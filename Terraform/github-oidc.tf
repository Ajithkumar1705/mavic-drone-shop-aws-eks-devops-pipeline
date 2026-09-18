# This is the file that eliminates the need to store AWS access keys as
# GitHub secrets. GitHub issues short-lived OIDC tokens to workflow runs;
# AWS trusts tokens from this specific provider AND only for this specific
# repo, via the condition block below.

# Dynamically fetches GitHub's actual current certificate and computes its
# thumbprint at plan-time, rather than trusting a hardcoded value that can
# go stale or get mistyped.
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}

# The role GitHub Actions assumes — scoped tightly to this repo (still NOT
# a wildcard trust: a workflow run from a fork, or from any other repo,
# cannot assume this role) but not locked to a single branch, since cd.yml
# is workflow_dispatch and the branch is picked manually on every run.
resource "aws_iam_role" "github_actions_deploy" {
  name = "${var.cluster_name}-github-actions-deploy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:Ajithkumar1705/mavic-drone-shop-aws-eks-devops-pipeline:*"
          }
        }
      }
    ]
  })
}

# Least-privilege ECR access — push/pull only, not full ECR admin
resource "aws_iam_role_policy" "ecr_push" {
  name = "ecr-push"
  role = aws_iam_role.github_actions_deploy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*" # this specific action does not support resource-level restriction
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

# Just enough EKS permission to run 'aws eks update-kubeconfig'
resource "aws_iam_role_policy" "eks_describe" {
  name = "eks-describe"
  role = aws_iam_role.github_actions_deploy.id

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

# Authenticating to AWS is not the same as having Kubernetes RBAC permissions
# inside the cluster — this grants the role actual permission to deploy via
# kubectl/Helm once it's authenticated. Scoped to a namespace-admin-equivalent
# policy rather than full cluster-admin.
resource "aws_eks_access_entry" "github_actions" {
  cluster_name  = module.eks.cluster_name
  principal_arn = aws_iam_role.github_actions_deploy.arn
  kubernetes_groups = ["github-actions-deploy"]
}

resource "aws_eks_access_policy_association" "github_actions" {
  cluster_name  = module.eks.cluster_name
  principal_arn = aws_iam_role.github_actions_deploy.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"

  access_scope {
    type       = "namespace"
    namespaces = ["mavic-drone-shop"]
  }

  depends_on = [kubernetes_namespace.app]
}
  
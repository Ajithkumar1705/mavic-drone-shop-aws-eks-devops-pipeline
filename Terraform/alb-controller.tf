# alb-controller.tf
#
# Installs the AWS Load Balancer Controller into the cluster and grants it
# the AWS permissions it needs (via IRSA) to actually create/manage a real
# ALB when EKS/helm/ingress.yaml is applied. Without this file, ingress.yaml
# sits inert — nothing in the cluster acts on Ingress resources by default.
#
# NOTE: all provider configuration (required_providers, the kubernetes/helm
# provider blocks, and the aws_eks_cluster_auth data source) lives in
# providers.tf, not here — Terraform only allows ONE required_providers
# block per module, so it can't be split across files.

# ---------------------------------------------------------------------------
# IAM policy — fetched live from AWS's official published source rather than
# hardcoded, since this is a long (~20-statement) document and a static copy
# can silently go stale or contain a transcription error.
#
# NOTE: pinned to a specific released version below. Check
# https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases
# for a newer tag if you want to update this later — don't blindly point at
# an unpinned "main" branch URL, which could change underneath you.
# ---------------------------------------------------------------------------
data "http" "alb_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.2/docs/install/iam_policy.json"
}

resource "aws_iam_policy" "alb_controller" {
  name   = "${var.cluster_name}-alb-controller"
  policy = data.http.alb_iam_policy.response_body
}

# ---------------------------------------------------------------------------
# IRSA — same pattern as github-oidc.tf, but the "identity" here is a
# Kubernetes ServiceAccount (via the cluster's own OIDC provider, which
# eks.tf already enabled with enable_irsa = true), not GitHub Actions.
# ---------------------------------------------------------------------------
resource "aws_iam_role" "alb_controller" {
  name = "${var.cluster_name}-alb-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${module.eks.oidc_provider}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
            "${module.eks.oidc_provider}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}

# ---------------------------------------------------------------------------
# The Kubernetes ServiceAccount the controller pod actually runs as,
# annotated with the IAM role above so EKS's IRSA mechanism grants it
# AWS credentials automatically — no static keys anywhere.
# ---------------------------------------------------------------------------
resource "kubernetes_service_account" "alb_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"

    labels = {
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
      "app.kubernetes.io/component" = "controller"
    }

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller.arn
    }
  }
}

# ---------------------------------------------------------------------------
# The controller itself, installed via its official Helm chart.
# Check https://github.com/aws/eks-charts for a newer chart version later.
# ---------------------------------------------------------------------------
resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.8.1"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "vpcId"
    value = module.vpc.vpc_id
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.alb_controller.metadata[0].name
  }

  depends_on = [kubernetes_service_account.alb_controller]
}

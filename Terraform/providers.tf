terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "mavic-drone-shop"
      ManagedBy   = "terraform"
      Environment = var.environment
    }
  }
}

# Authenticates the kubernetes/helm providers against the EKS cluster this
# same config creates.
# NOTE: on a completely fresh `terraform apply` (cluster doesn't exist yet),
# this can fail on the very first run since the cluster isn't up yet when
# providers are configured. If that happens, just run `terraform apply`
# a second time — the cluster will exist by then and this resolves cleanly.
# This is a known Terraform limitation when EKS creation and Helm/Kubernetes
# resources live in the same root module, not a mistake in this config.
data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

# Uses the community terraform-aws-modules/eks/aws module — provisions the
# control plane, a managed node group, and the OIDC provider for IRSA
# (pod-level AWS auth) all from one module block.
# Check registry.terraform.io/modules/terraform-aws-modules/eks/aws
# for the current version before applying.

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # API_AND_CONFIG_MAP supports the newer EKS access-entry API (used in
  # github-oidc.tf to grant the CI/CD role cluster access) alongside the
  # classic aws-auth ConfigMap approach, for flexibility.
  authentication_mode = "API_AND_CONFIG_MAP"

#to reach from my laptop - should not be in production
  cluster_endpoint_public_access = true

  enable_irsa = true

  eks_managed_node_groups = {
    default = {
      instance_types = [var.node_instance_type]
      desired_size   = var.node_desired_size
      min_size       = var.node_min_size
      max_size       = var.node_max_size
    }
  }
}

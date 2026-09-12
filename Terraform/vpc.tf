# Uses the community terraform-aws-modules/vpc/aws module rather than
# hand-writing subnets/route tables/NAT gateway resources individually.
# Check registry.terraform.io/modules/terraform-aws-modules/vpc/aws
# for the current version before applying.

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs = var.availability_zones

  # /24 subnets carved out of the /16 VPC CIDR — adjust math if you change vpc_cidr
  private_subnets = [for i, az in var.availability_zones : cidrsubnet(var.vpc_cidr, 8, i)]
  public_subnets  = [for i, az in var.availability_zones : cidrsubnet(var.vpc_cidr, 8, i + 10)]

  enable_nat_gateway = true
  single_nat_gateway = true # one shared NAT gateway, not one per AZ — keeps cost down for a dev/portfolio setup

  enable_dns_hostnames = true
  enable_dns_support   = true

  # Required tags for EKS to auto-discover subnets for load balancers
  public_subnet_tags = {
    "kubernetes.io/role/elb"                     = "1"
    "kubernetes.io/cluster/${var.cluster_name}"  = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"            = "1"
    "kubernetes.io/cluster/${var.cluster_name}"  = "shared"
  }
}

#######
# VPC #
#######

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "vpc-eks"
  cidr = "10.0.0.0/16"

  azs             = ["eu-south-2a", "eu-south-2b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.101.0/24"]

  # Internet Gateway
  enable_nat_gateway = true # vpc to internet
  single_nat_gateway = true
  enable_vpn_gateway = false

  # DNS
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Tags nécessaires pour l'auto-découverte par le Load Balancer Kubernetes
  public_subnet_tags = {
    "kubernetes.io/cluster/main" = "shared"
    "kubernetes.io/role/elb"     = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/main"      = "shared"
    "kubernetes.io/role/internal-elb" = "1"
  }
}


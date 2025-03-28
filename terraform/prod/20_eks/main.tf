#######
# EKS #
#######

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = local.cluster_name
  cluster_version = "1.31"

  # Optional
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  cluster_compute_config = {
    enabled    = true
    node_pools = ["general-purpose"]
  }

  vpc_id     = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnets

  cluster_enabled_log_types = [
    "audit",
    "api",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  # Add-ons Configuration
  cluster_addons = {
    amazon-cloudwatch-observability = {
      most_recent              = true
      addon_version            = "v2.6.0-eksbuild.1"
      service_account_role_arn = module.cloudwatch_irsa_role.iam_role_arn
    }
  }

  # Gestion des logs
  create_cloudwatch_log_group            = false
  depends_on                             = [aws_cloudwatch_log_group.containerinsights, aws_cloudwatch_log_group.eks]
}

##############
# Cloudwatch #
##############

resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${local.cluster_name}/cluster"
  retention_in_days = local.retention_in_days
}

resource "aws_cloudwatch_log_group" "containerinsights" {
  for_each          = toset(local.cw_log_groups)
  name              = "/aws/containerinsights/${local.cluster_name}/${each.key}"
  retention_in_days = local.retention_in_days
}

#######################
# IAM ROLE IRSA ADDONS#
#######################

module "cloudwatch_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${local.cluster_name}-cw-eks"

  attach_cloudwatch_observability_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["amazon-cloudwatch:cloudwatch-agent"] # namespace:service_account
    }
  }
}

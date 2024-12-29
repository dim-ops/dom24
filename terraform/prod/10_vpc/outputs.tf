output "vpc_id" {
  description = "L'ID du VPC"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "Liste des IDs des subnets privés"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "Liste des IDs des subnets publics"
  value       = module.vpc.public_subnets
}

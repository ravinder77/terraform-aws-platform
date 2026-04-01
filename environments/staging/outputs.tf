output "vpc_id" {
  description = "VPC ID for the environment."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "Private subnet IDs."
  value       = module.vpc.private_subnets
}

output "eks_cluster_name" {
  description = "EKS cluster name when enabled."
  value       = try(module.eks[0].cluster_id, null)
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint when enabled."
  value       = try(module.eks[0].cluster_endpoint, null)
}

output "eks_node_security_group_id" {
  description = "EKS node security group ID when enabled."
  value       = try(module.eks[0].node_security_group_id, null)
}

output "eks_oidc_provider_arn" {
  description = "IAM OIDC provider ARN for the EKS cluster when enabled."
  value       = try(module.eks[0].oidc_provider_arn, null)
}

output "rds_instance_id" {
  description = "Primary RDS instance ID when enabled."
  value       = try(module.rds[0].db_instance_id, null)
}

output "rds_secret_arn" {
  description = "Secrets Manager ARN for the RDS master secret when enabled."
  value       = try(module.rds[0].secret_arn, null)
}

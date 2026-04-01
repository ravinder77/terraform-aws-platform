output "cluster_id" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.this.id
}

output "cluster_arn" {
  description = "EKS cluster ARN."
  value       = aws_eks_cluster.this.arn
}

output "cluster_endpoint" {
  description = "Kubernetes API server endpoint."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_version" {
  description = "Kubernetes version running on the cluster."
  value       = aws_eks_cluster.this.version
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate authority data required by kubectl clients."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_primary_security_group_id" {
  description = "Primary EKS-managed cluster security group ID."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "cluster_security_group_id" {
  description = "Additional security group attached to the EKS control plane."
  value       = aws_security_group.cluster.id
}

output "node_security_group_id" {
  description = "Security group attached to EKS worker nodes."
  value       = aws_security_group.node.id
}

output "node_group_arn" {
  description = "Managed node group ARN."
  value       = aws_eks_node_group.default.arn
}

output "node_group_status" {
  description = "Managed node group status."
  value       = aws_eks_node_group.default.status
}

output "cluster_role_arn" {
  description = "IAM role ARN used by the EKS control plane."
  value       = aws_iam_role.cluster.arn
}

output "node_role_arn" {
  description = "IAM role ARN used by the managed node group."
  value       = aws_iam_role.node.arn
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for the cluster."
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "oidc_provider_arn" {
  description = "IAM OIDC provider ARN when enabled."
  value       = try(aws_iam_openid_connect_provider.this[0].arn, null)
}

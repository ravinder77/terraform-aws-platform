output "aws_account_id" {
  description = "AWS account ID."
  value       = data.aws_caller_identity.current.account_id
}

output "aws_partition" {
  description = "AWS partition for the current account."
  value       = data.aws_partition.current.partition
}

output "custom_policy_names" {
  description = "Customer-managed IAM policy names keyed by logical policy name."
  value = {
    for name, policy in aws_iam_policy.custom : name => policy.name
  }
}

output "custom_policy_arns" {
  description = "Customer-managed IAM policy ARNs keyed by logical policy name."
  value = {
    for name, policy in aws_iam_policy.custom : name => policy.arn
  }
}

output "role_names" {
  description = "IAM role names keyed by logical role name."
  value = {
    for name, role in aws_iam_role.this : name => role.name
  }
}

output "role_arns" {
  description = "IAM role ARNs keyed by logical role name."
  value = {
    for name, role in aws_iam_role.this : name => role.arn
  }
}

output "instance_profile_names" {
  description = "IAM instance profile names keyed by logical role name."
  value = {
    for name, profile in aws_iam_instance_profile.this : name => profile.name
  }
}

output "instance_profile_arns" {
  description = "IAM instance profile ARNs keyed by logical role name."
  value = {
    for name, profile in aws_iam_instance_profile.this : name => profile.arn
  }
}

output "oidc_provider_arns" {
  description = "OIDC provider ARNs keyed by logical provider name."
  value = {
    for name, provider in aws_iam_openid_connect_provider.this : name => provider.arn
  }
}

output "aws_account_id" {
  description = "AWS account ID."
  value       = data.aws_caller_identity.current.account_id
}

output "group_names" {
  description = "IAM group names keyed by logical group name."
  value = {
    for name, group in aws_iam_group.this : name => group.name
  }
}

output "group_arns" {
  description = "IAM group ARNs keyed by logical group name."
  value = {
    for name, group in aws_iam_group.this : name => group.arn
  }
}

output "user_names" {
  description = "IAM user names keyed by logical user name."
  value = {
    for name, user in aws_iam_user.this : name => user.name
  }
}

output "user_arns" {
  description = "IAM user ARNs keyed by logical user name."
  value = {
    for name, user in aws_iam_user.this : name => user.arn
  }
}

output "password_policy_expire_passwords" {
  description = "Whether the managed account password policy expires passwords."
  value       = try(aws_iam_account_password_policy.this[0].expire_passwords, null)
}

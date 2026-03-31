locals {
  name_prefix = "${var.prefix}-${var.environment}"

  common_tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  invalid_role_custom_policy_references = distinct(flatten([
    for role_name, role in var.roles : [
      for policy_name in role.custom_policy_names : "${role_name}:${policy_name}"
      if !contains(keys(var.custom_policies), policy_name)
    ]
  ]))

  role_managed_policy_attachments = merge([
    for role_name, role in var.roles : {
      for policy_arn in role.managed_policy_arns :
      "${role_name}-${md5(policy_arn)}" => {
        role_name  = role_name
        policy_arn = policy_arn
      }
    }
  ]...)

  role_custom_policy_attachments = merge([
    for role_name, role in var.roles : {
      for policy_name in role.custom_policy_names :
      "${role_name}-${policy_name}" => {
        role_name   = role_name
        policy_name = policy_name
      }
    }
  ]...)

  role_inline_policies = merge([
    for role_name, role in var.roles : {
      for policy_name, policy_json in role.inline_policies :
      "${role_name}-${policy_name}" => {
        role_name   = role_name
        policy_name = policy_name
        policy_json = policy_json
      }
    }
  ]...)
}

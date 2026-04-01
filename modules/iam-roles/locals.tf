locals {
  name_prefix     = "${var.prefix}-${var.environment}"
  roles           = var.roles
  custom_policies = var.custom_policies
  oidc_providers  = var.oidc_providers

  common_tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  invalid_role_custom_policy_references = distinct(flatten([
    for role_name, role in local.roles : [
      for policy_name in role.custom_policy_names : "${role_name}:${policy_name}"
      if !contains(keys(local.custom_policies), policy_name)
    ]
  ]))

  role_managed_policy_attachments = {
    for attachment in flatten([
      for role_name, role in local.roles : [
        for policy_arn in toset(role.managed_policy_arns) : {
          key        = "${role_name}-${md5(policy_arn)}"
          role_name  = role_name
          policy_arn = policy_arn
        }
      ]
    ]) : attachment.key => attachment
  }

  role_custom_policy_attachments = {
    for attachment in flatten([
      for role_name, role in local.roles : [
        for policy_name in toset(role.custom_policy_names) : {
          key         = "${role_name}-${policy_name}"
          role_name   = role_name
          policy_name = policy_name
        }
      ]
    ]) : attachment.key => attachment
  }

  role_inline_policies = {
    for policy in flatten([
      for role_name, role in local.roles : [
        for policy_name, policy_json in role.inline_policies : {
          key         = "${role_name}-${policy_name}"
          role_name   = role_name
          policy_name = policy_name
          policy_json = policy_json
        }
      ]
    ]) : policy.key => policy
  }

  instance_profiles = {
    for role_name, role in local.roles :
    role_name => role
    if role.create_instance_profile
  }
}

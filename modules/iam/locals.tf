locals {
  name_prefix = "${var.prefix}-${var.environment}"

  common_tags = merge(var.tags, {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  user_names = {
    for user_name, user in var.users :
    user_name => coalesce(try(user.name_override, null), "${local.name_prefix}-${user_name}")
  }

  invalid_user_group_references = distinct(flatten([
    for user_name, user in var.users : [
      for group_name in user.groups : "${user_name}:${group_name}"
      if !contains(keys(var.groups), group_name)
    ]
  ]))

  invalid_role_custom_policy_references = distinct(flatten([
    for role_name, role in var.roles : [
      for policy_name in role.custom_policy_names : "${role_name}:${policy_name}"
      if !contains(keys(var.custom_policies), policy_name)
    ]
  ]))

  group_policy_attachments = merge([
    for group_name, group in var.groups : {
      for policy_arn in group.managed_policy_arns :
      "${group_name}-${md5(policy_arn)}" => {
        group_name = group_name
        policy_arn = policy_arn
      }
    }
  ]...)

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

  user_group_memberships = {
    for user_name, user in var.users :
    user_name => user.groups
    if length(user.groups) > 0
  }

  users_with_access_keys = {
    for user_name, user in var.users :
    user_name => user
    if user.create_access_key
  }
}

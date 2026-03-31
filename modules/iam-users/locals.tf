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

  group_policy_attachments = merge([
    for group_name, group in var.groups : {
      for policy_arn in group.managed_policy_arns :
      "${group_name}-${md5(policy_arn)}" => {
        group_name = group_name
        policy_arn = policy_arn
      }
    }
  ]...)

  user_group_memberships = {
    for user_name, user in var.users :
    user_name => user.groups
    if length(user.groups) > 0
  }
}

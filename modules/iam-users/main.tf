data "aws_caller_identity" "current" {}

check "user_groups_exist" {
  assert {
    condition     = length(local.invalid_user_group_references) == 0
    error_message = "users[*].groups must reference keys that exist in var.groups."
  }
}

resource "aws_iam_group" "this" {
  for_each = var.groups

  name = "${local.name_prefix}-${each.key}"
  path = each.value.path
}

resource "aws_iam_group_policy_attachment" "this" {
  for_each = {
    for attachment in flatten([
      for group_name, group in var.groups : [
        for policy_arn in toset(try(group.managed_policy_arns, [])) : {
          key        = "${group_name}-${md5(policy_arn)}"
          group_name = group_name
          policy_arn = policy_arn
        }
      ]
    ]) : attachment.key => attachment
  }

  group      = aws_iam_group.this[each.value.group_name].name
  policy_arn = each.value.policy_arn
}
resource "aws_iam_user" "this" {
  for_each = var.users

  name                 = local.user_names[each.key]
  path                 = each.value.path
  force_destroy        = each.value.force_destroy
  permissions_boundary = try(each.value.permissions_boundary, null)

  tags = merge(local.common_tags, each.value.tags)
}

resource "aws_iam_user_group_membership" "managed" {
  for_each = local.user_group_memberships

  user = aws_iam_user.this[each.key].name
  groups = [
    for group_name in each.value : aws_iam_group.this[group_name].name
  ]
}

resource "aws_iam_account_password_policy" "this" {
  count = var.manage_password_policy ? 1 : 0

  minimum_password_length        = var.password_policy.minimum_length
  require_lowercase_characters   = var.password_policy.require_lowercase
  require_uppercase_characters   = var.password_policy.require_uppercase
  require_numbers                = var.password_policy.require_numbers
  require_symbols                = var.password_policy.require_symbols
  allow_users_to_change_password = var.password_policy.allow_users_to_change
  hard_expiry                    = var.password_policy.hard_expiry
  max_password_age               = var.password_policy.max_age_days
  password_reuse_prevention      = var.password_policy.reuse_prevention_count
}

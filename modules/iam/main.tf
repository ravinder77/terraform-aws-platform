data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

check "user_groups_exist" {
  assert {
    condition     = length(local.invalid_user_group_references) == 0
    error_message = "users[*].groups must reference keys that exist in var.groups."
  }
}

check "role_custom_policies_exist" {
  assert {
    condition     = length(local.invalid_role_custom_policy_references) == 0
    error_message = "roles[*].custom_policy_names must reference keys that exist in var.custom_policies."
  }
}

resource "aws_iam_group" "this" {
  for_each = var.groups

  name = "${local.name_prefix}-${each.key}"
  path = each.value.path
}

resource "aws_iam_group_policy_attachment" "this" {
  for_each = local.group_policy_attachments

  group      = aws_iam_group.this[each.value.group_name].name
  policy_arn = each.value.policy_arn
}

resource "aws_iam_policy" "custom" {
  for_each = var.custom_policies

  name        = "${local.name_prefix}-${each.key}"
  path        = each.value.path
  description = try(each.value.description, null)
  policy      = coalesce(try(each.value.policy_json, null), data.aws_iam_policy_document.custom[each.key].json)

  tags = merge(local.common_tags, each.value.tags)
}

resource "aws_iam_role" "this" {
  for_each = var.roles

  name                  = "${local.name_prefix}-${each.key}"
  path                  = each.value.path
  description           = try(each.value.description, null)
  assume_role_policy    = coalesce(try(each.value.assume_role_policy, null), data.aws_iam_policy_document.assume_role[each.key].json)
  max_session_duration  = each.value.max_session_duration
  force_detach_policies = each.value.force_detach_policies
  permissions_boundary  = try(each.value.permissions_boundary, null)

  tags = merge(local.common_tags, each.value.tags)
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = local.role_managed_policy_attachments

  role       = aws_iam_role.this[each.value.role_name].name
  policy_arn = each.value.policy_arn
}

resource "aws_iam_role_policy_attachment" "custom" {
  for_each = local.role_custom_policy_attachments

  role       = aws_iam_role.this[each.value.role_name].name
  policy_arn = aws_iam_policy.custom[each.value.policy_name].arn
}

resource "aws_iam_role_policy" "inline" {
  for_each = local.role_inline_policies

  name   = each.value.policy_name
  role   = aws_iam_role.this[each.value.role_name].id
  policy = each.value.policy_json
}

resource "aws_iam_instance_profile" "this" {
  for_each = {
    for role_name, role in var.roles :
    role_name => role
    if role.create_instance_profile
  }

  name = "${local.name_prefix}-${each.key}"
  path = each.value.path
  role = aws_iam_role.this[each.key].name

  tags = merge(local.common_tags, each.value.tags)
}

resource "aws_iam_openid_connect_provider" "this" {
  for_each = var.oidc_providers

  url             = each.value.url
  client_id_list  = each.value.client_id_list
  thumbprint_list = each.value.thumbprint_list

  tags = merge(local.common_tags, each.value.tags)
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

resource "aws_iam_access_key" "this" {
  for_each = local.users_with_access_keys

  user    = aws_iam_user.this[each.key].name
  pgp_key = try(each.value.pgp_key, null)
  status  = each.value.access_key_status

  lifecycle {
    create_before_destroy = true
  }

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

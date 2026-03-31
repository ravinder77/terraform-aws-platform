check "role_custom_policies_exist" {
  assert {
    condition     = length(local.invalid_role_custom_policy_references) == 0
    error_message = "roles[*].custom_policy_names must reference keys that exist in var.custom_policies."
  }
}

resource "aws_iam_policy" "custom" {
  for_each = var.custom_policies

  name        = "${local.name_prefix}-${each.key}"
  path        = each.value.path
  description = try(each.value.description, null)
  policy      = each.value.policy_json

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

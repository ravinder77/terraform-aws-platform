data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_iam_policy_document" "assume_role" {
  for_each = {
    for name, role in var.roles :
    name => role
    if try(role.assume_role_policy, null) == null
  }

  dynamic "statement" {
    for_each = each.value.assume_role_statements

    content {
      sid    = try(statement.value.sid, null)
      effect = statement.value.effect

      actions       = length(statement.value.actions) > 0 ? statement.value.actions : null
      not_actions   = length(statement.value.not_actions) > 0 ? statement.value.not_actions : null
      resources     = length(statement.value.resources) > 0 ? statement.value.resources : null
      not_resources = length(statement.value.not_resources) > 0 ? statement.value.not_resources : null

      dynamic "principals" {
        for_each = statement.value.principals

        content {
          type        = principals.value.type
          identifiers = principals.value.identifiers
        }
      }

      dynamic "not_principals" {
        for_each = statement.value.not_principals

        content {
          type        = not_principals.value.type
          identifiers = not_principals.value.identifiers
        }
      }

      dynamic "condition" {
        for_each = statement.value.conditions

        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}

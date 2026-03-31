variable "prefix" {
  description = "Prefix prepended to IAM resource names for namespacing."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.prefix))
    error_message = "prefix must be lowercase alphanumeric with hyphens only."
  }
}

variable "project" {
  description = "Project name used for tagging."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string

  validation {
    condition     = contains(["prod", "dev", "staging"], var.environment)
    error_message = "environment must be one of: prod, dev, staging."
  }
}

variable "tags" {
  description = "Common tags applied to all IAM resources."
  type        = map(string)
  default     = {}
}

variable "groups" {
  description = <<-EOT
    Map of IAM groups to create.
    Keys are logical names; values support:
      path                optional(string) - default "/"
      managed_policy_arns optional(list(string)) - managed policy ARNs to attach
  EOT
  type = map(object({
    path                = optional(string, "/")
    managed_policy_arns = optional(list(string), [])
  }))
  default = {}
}

variable "custom_policies" {
  description = <<-EOT
    Map of customer-managed IAM policies.
    Keys are logical names; values support:
      policy_json       optional(string) - JSON policy document
      policy_statements optional(list(object)) - structured policy statements
      description optional(string)
      path        optional(string) - default "/"
      tags        optional(map(string))
  EOT
  type = map(object({
    policy_json = optional(string)
    policy_statements = optional(list(object({
      sid           = optional(string)
      effect        = optional(string, "Allow")
      actions       = optional(list(string), [])
      not_actions   = optional(list(string), [])
      resources     = optional(list(string), [])
      not_resources = optional(list(string), [])
      principals = optional(list(object({
        type        = string
        identifiers = list(string)
      })), [])
      not_principals = optional(list(object({
        type        = string
        identifiers = list(string)
      })), [])
      conditions = optional(list(object({
        test     = string
        variable = string
        values   = list(string)
      })), [])
    })), [])
    description = optional(string)
    path        = optional(string, "/")
    tags        = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for policy in values(var.custom_policies) :
      (try(policy.policy_json, null) != null && can(jsondecode(policy.policy_json))) ||
      length(try(policy.policy_statements, [])) > 0
    ])
    error_message = "Each custom_policies[*] must set either valid policy_json or non-empty policy_statements."
  }
}

variable "roles" {
  description = <<-EOT
    Map of IAM roles to create.
    Keys are logical names; values support:
      assume_role_policy      optional(string) - JSON trust policy
      assume_role_statements  optional(list(object)) - structured trust policy statements
      description             optional(string)
      path                    optional(string) - default "/"
      max_session_duration    optional(number) - 3600 to 43200
      force_detach_policies   optional(bool)
      managed_policy_arns     optional(list(string))
      custom_policy_names     optional(list(string)) - keys from var.custom_policies
      inline_policies         optional(map(string)) - name => JSON policy document
      create_instance_profile optional(bool)
      permissions_boundary    optional(string)
      tags                    optional(map(string))
  EOT
  type = map(object({
    assume_role_policy = optional(string)
    assume_role_statements = optional(list(object({
      sid           = optional(string)
      effect        = optional(string, "Allow")
      actions       = optional(list(string), [])
      not_actions   = optional(list(string), [])
      resources     = optional(list(string), [])
      not_resources = optional(list(string), [])
      principals = optional(list(object({
        type        = string
        identifiers = list(string)
      })), [])
      not_principals = optional(list(object({
        type        = string
        identifiers = list(string)
      })), [])
      conditions = optional(list(object({
        test     = string
        variable = string
        values   = list(string)
      })), [])
    })), [])
    description             = optional(string)
    path                    = optional(string, "/")
    max_session_duration    = optional(number, 3600)
    force_detach_policies   = optional(bool, false)
    managed_policy_arns     = optional(list(string), [])
    custom_policy_names     = optional(list(string), [])
    inline_policies         = optional(map(string), {})
    create_instance_profile = optional(bool, false)
    permissions_boundary    = optional(string)
    tags                    = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for role in values(var.roles) :
      (try(role.assume_role_policy, null) != null && can(jsondecode(role.assume_role_policy))) ||
      length(try(role.assume_role_statements, [])) > 0
    ])
    error_message = "Each roles[*] must set either valid assume_role_policy or non-empty assume_role_statements."
  }

  validation {
    condition = alltrue([
      for role in values(var.roles) : role.max_session_duration >= 3600 && role.max_session_duration <= 43200
    ])
    error_message = "Each roles[*].max_session_duration must be between 3600 and 43200 seconds."
  }

  validation {
    condition = alltrue(flatten([
      for role in values(var.roles) : [
        for policy_json in values(role.inline_policies) : can(jsondecode(policy_json))
      ]
    ]))
    error_message = "Each roles[*].inline_policies value must be valid JSON."
  }
}

variable "oidc_providers" {
  description = <<-EOT
    Map of OIDC identity providers to register.
    Keys are logical names; values support:
      url             string - issuer URL
      client_id_list  list(string)
      thumbprint_list list(string)
      tags            optional(map(string))
  EOT
  type = map(object({
    url             = string
    client_id_list  = list(string)
    thumbprint_list = list(string)
    tags            = optional(map(string), {})
  }))
  default = {}
}

variable "users" {
  description = <<-EOT
    Map of IAM users to create.
    Keys are logical names; values support:
      name_override         optional(string) - override the generated name
      path                  optional(string) - default "/"
      groups                optional(list(string)) - keys from var.groups
      create_access_key     optional(bool)
      pgp_key               optional(string)
      access_key_status     optional(string) - Active or Inactive
      force_destroy         optional(bool)
      permissions_boundary  optional(string)
      tags                  optional(map(string))
  EOT
  type = map(object({
    name_override        = optional(string)
    path                 = optional(string, "/")
    groups               = optional(list(string), [])
    create_access_key    = optional(bool, false)
    pgp_key              = optional(string)
    access_key_status    = optional(string, "Active")
    force_destroy        = optional(bool, false)
    permissions_boundary = optional(string)
    tags                 = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for user in values(var.users) : contains(["Active", "Inactive"], user.access_key_status)
    ])
    error_message = "Each users[*].access_key_status must be Active or Inactive."
  }

  validation {
    condition = alltrue([
      for user in values(var.users) : !user.create_access_key || try(user.pgp_key, null) != null
    ])
    error_message = "Each users[*] with create_access_key = true must also set pgp_key so secrets are not stored unencrypted in state."
  }
}

variable "manage_password_policy" {
  description = "Whether to manage the account-level IAM password policy."
  type        = bool
  default     = false
}

variable "password_policy" {
  description = "Configuration for the IAM account password policy."
  type = object({
    minimum_length         = number
    require_lowercase      = bool
    require_uppercase      = bool
    require_numbers        = bool
    require_symbols        = bool
    allow_users_to_change  = bool
    hard_expiry            = bool
    max_age_days           = number
    reuse_prevention_count = number
  })
  default = {
    minimum_length         = 14
    require_lowercase      = true
    require_uppercase      = true
    require_numbers        = true
    require_symbols        = true
    allow_users_to_change  = true
    hard_expiry            = false
    max_age_days           = 90
    reuse_prevention_count = 24
  }

  validation {
    condition     = var.password_policy.minimum_length >= 14
    error_message = "password_policy.minimum_length must be at least 14 for production use."
  }
}

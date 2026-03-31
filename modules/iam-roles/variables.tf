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
  description = "Common tags applied to IAM resources."
  type        = map(string)
  default     = {}
}

variable "custom_policies" {
  description = <<-EOT
    Map of customer-managed IAM policies.
    Keys are logical names; values support:
      policy_json  string - JSON policy document
      description  optional(string)
      path         optional(string) - default "/"
      tags         optional(map(string))
  EOT
  type = map(object({
    policy_json = string
    description = optional(string)
    path        = optional(string, "/")
    tags        = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for policy in values(var.custom_policies) : can(jsondecode(policy.policy_json))
    ])
    error_message = "Each custom_policies[*].policy_json value must be valid JSON."
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

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
  description = "Common tags applied to IAM resources that support tags."
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

variable "users" {
  description = <<-EOT
    Map of IAM users to create.
    Keys are logical names; values support:
      name_override         optional(string) - override the generated name
      path                  optional(string) - default "/"
      groups                optional(list(string)) - keys from var.groups
      force_destroy         optional(bool)
      permissions_boundary  optional(string)
      tags                  optional(map(string))
  EOT
  type = map(object({
    name_override        = optional(string)
    path                 = optional(string, "/")
    groups               = optional(list(string), [])
    force_destroy        = optional(bool, false)
    permissions_boundary = optional(string)
    tags                 = optional(map(string), {})
  }))
  default = {}
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

# ============================================================
# — IAM Module
# ============================================================

variable "prefix" {
  description = "Prefix prepended to all resources for namespacing"
  type        = string

  validation {
    condition = can(regex("^[a-z0-9-]+$", var.prefix))
    error_message = "Prefix must be lowercase alphanumeric with hyphens only."
  }
}

variable "environment" {
  description =  "Deployment environment (prod, staging, dev)."
  type = string

  validation {
    condition = contains(["prod", "dev", "staging"], var.environment)
    error_message = "Environment must be one of: prod, dev, staging"
  }
}

variable "tags" {
  description = "Common tags applies to all resources"
  type = map(string)
  default = {}
}

# ─────────────────────────────────────────────
# GROUPS
# ─────────────────────────────────────────────

variable "groups" {
  description = <<-EOT
    Map of IAM groups to create.
    Keys are logical names; values support:
      path                (string)       - default "/"
      managed_policy_arns (list(string)) - AWS-managed or customer-managed ARNs
      members             (list(string)) - IAM usernames to add
  EOT
  type = map(any)
  default = {}
}


# ─────────────────────────────────────────────
# CUSTOM POLICIES
# ─────────────────────────────────────────────

variable "custom_policies" {
  description = <<-EOT
    Map of customer-managed IAM policies.
    Keys are policy logical names; values support:
      policy_json  (string, required) - JSON policy document
      description  (string)
      path         (string)
      tags         (map(string))
  EOT
  type = map(object({
    policy_json = string
    description = string
    path  = string
    tags = map(string)
  }))
  default = {}
}

# ─────────────────────────────────────────────
# ROLES
# ─────────────────────────────────────────────

variable "roles" {
  description = <<-EOT
    Map of IAM roles to create.
    Keys are logical names; values support:
      assume_role_policy       (string, required) - JSON trust policy
      description              (string)
      path                     (string)
      max_session_duration     (number)           - seconds, 3600–43200
      force_detach_policies    (bool)
      managed_policy_arns      (list(string))
      custom_policy_names      (list(string))     - keys from var.custom_policies
      inline_policies          (map(string))      - name => JSON
      create_instance_profile  (bool)
      tags                     (map(string))
  EOT
  type = map(object({
    assume_role_policy = string
    description = string
    path = string
    max_session_duration = number
    force_detach_policies = bool
    managed_policy_arns = list(string)
    custom_policy_names = list(string)
    inline_policies = map(string)
    create_instance_profile = bool
    tags = map(string)
  }))
  default = {}
}

# ─────────────────────────────────────────────
# OIDC PROVIDERS
# ─────────────────────────────────────────────

variable "oidc_providers" {
  description = <<-EOT
    Map of OIDC identity providers to register.
    Keys are logical names; values support:
      url              (string, required) - e.g. https://token.actions.githubusercontent.com
      client_id_list   (list(string), required)
      thumbprint_list  (list(string), required)
      tags             (map(string))
  EOT
  type        = map(any)
  default     = {}
}

# ─────────────────────────────────────────────
# USERS
# ─────────────────────────────────────────────

variable "users" {
  description = <<-EOT
    Map of IAM users (service accounts).
    Prefer roles + OIDC over long-lived users where possible.
    Keys are logical names; values support:
      name_override      (string)           - override the generated name
      path               (string)
      groups             (list(string))     - keys from var.groups
      create_access_key  (bool)
      pgp_key            (string)           - base64 PGP key to encrypt secret key
      access_key_status  (string)           - Active | Inactive
      force_destroy      (bool)
      tags               (map(string))
  EOT
  type = map(object({
    name_override = string
    path = string
    groups = list(string)
    create_access_key = bool
    pgp_key = string
    access_key_status = string
    force_destroy = bool
    tags = map(string)
  }))
  default = {}
}


# ─────────────────────────────────────────────
# PASSWORD POLICY
# ─────────────────────────────────────────────

variable "manage_password_policy" {
  description = "Set true to enforce an account-level IAM password-policy"
  type = bool
  default = false
}

variable "password_policy" {
  description = "Configuration for the IAM account password "
  type = object({
    minimum_length = number
    require_lowercase       = bool
    require_uppercase       = bool
    require_numbers         = bool
    require_symbols         = bool
    allow_users_to_change   = bool
    hard_expiry             = bool
    max_age_days            = number
    reuse_prevention_count  = number
  })
  default = {
    minimum_length         = 16
    require_lowercase      = true
    require_uppercase      = true
    require_numbers        = true
    require_symbols        = true
    allow_users_to_change  = true
    hard_expiry            = false
    max_age_days           = 90
    reuse_prevention_count = 24
  }
}
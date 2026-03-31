variable "aws_region" {
  description = "AWS region for this environment."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "project_name" {
  description = "Logical project name used in tags and naming."
  type        = string
}

variable "owner" {
  description = "Owning team or service."
  type        = string
}

variable "tags" {
  description = "Additional tags merged into the standard tag set."
  type        = map(string)
  default     = {}
}

variable "create_iam" {
  description = "Whether to deploy the IAM module in this environment."
  type        = bool
  default     = false
}

variable "iam_groups" {
  description = "IAM groups to create in this environment."
  type = map(object({
    path                = optional(string, "/")
    managed_policy_arns = optional(list(string), [])
  }))
  default = {}
}

variable "vpc_cidr" {
  description = "VPC CIDR block."
  type        = string
}

variable "azs" {
  description = "Availability zones used by this environment."
  type        = list(string)
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks."
  type        = list(string)
}

variable "private_subnets" {
  description = "Private subnet CIDR blocks."
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Whether private subnets get outbound internet via NAT."
  type        = bool
  default     = true
}

variable "create_rds" {
  description = "Whether to deploy the RDS module in this environment."
  type        = bool
  default     = false
}

variable "rds_identifier" {
  description = "Suffix used in the RDS identifier."
  type        = string
  default     = "db"
}

variable "rds_engine" {
  description = "Database engine for RDS."
  type        = string
  default     = "postgres"
}

variable "rds_engine_version" {
  description = "Database engine version."
  type        = string
  default     = "17"
}

variable "rds_parameter_group_family" {
  description = "Optional override for the parameter group family."
  type        = string
  default     = null
}

variable "rds_instance_class" {
  description = "RDS instance size."
  type        = string
  default     = "db.t3.medium"
}

variable "rds_allocated_storage" {
  description = "Initial RDS storage size in GB."
  type        = number
  default     = 20
}

variable "rds_max_allocated_storage" {
  description = "Maximum storage autoscaling limit in GB."
  type        = number
  default     = 100
}

variable "rds_db_name" {
  description = "Database name."
  type        = string
  default     = "app"
}

variable "rds_username" {
  description = "Master username for RDS."
  type        = string
  sensitive   = true
  default     = "platform_admin"
}

variable "rds_allowed_security_group_ids" {
  description = "Security groups allowed to connect to the RDS instance."
  type        = list(string)
  default     = []
}

variable "rds_multi_az" {
  description = "Whether to enable Multi-AZ."
  type        = bool
  default     = true
}

variable "rds_backup_retention_period" {
  description = "Retention window for automated backups."
  type        = number
  default     = 7
}

variable "rds_deletion_protection" {
  description = "Whether to protect the database from deletion."
  type        = bool
  default     = true
}

variable "rds_skip_final_snapshot" {
  description = "Whether to skip the final snapshot on destroy."
  type        = bool
  default     = false
}

variable "rds_create_read_replica" {
  description = "Whether to create a single read replica."
  type        = bool
  default     = false
}

variable "rds_parameters" {
  description = "Custom DB parameter group entries."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "identifier" {
  description = "Unique identifier for the RDS instance."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,62}$", var.identifier))
    error_message = "identifier must start with a letter and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "engine" {
  description = "Database engine."
  type        = string
  default     = "postgres"

  validation {
    condition     = contains(["postgres", "mysql", "mariadb"], var.engine)
    error_message = "engine must be one of: postgres, mysql, mariadb."
  }
}

variable "engine_version" {
  description = "Database engine version."
  type        = string
  default     = "15.7"
}

variable "instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.medium"
}

variable "parameter_group_family" {
  description = "Optional override for the DB parameter group family."
  type        = string
  default     = null
}

variable "license_model" {
  description = "Optional license model for the DB engine."
  type        = string
  default     = null
}

variable "allocated_storage" {
  description = "Initial storage allocation in GiB."
  type        = number
  default     = 20

  validation {
    condition     = var.allocated_storage >= 20
    error_message = "allocated_storage must be at least 20 GiB."
  }
}

variable "max_allocated_storage" {
  description = "Maximum autoscaled storage in GiB. Set to 0 to disable autoscaling."
  type        = number
  default     = 100

  validation {
    condition     = var.max_allocated_storage == 0 || var.max_allocated_storage >= var.allocated_storage
    error_message = "max_allocated_storage must be 0 or greater than or equal to allocated_storage."
  }
}

variable "storage_type" {
  description = "Storage type for the primary instance."
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1"], var.storage_type)
    error_message = "storage_type must be one of: gp2, gp3, io1."
  }
}

variable "db_name" {
  description = "Initial database name."
  type        = string
}

variable "username" {
  description = "Master database username."
  type        = string
  sensitive   = true
}

variable "vpc_id" {
  description = "VPC ID used by the RDS security group."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs used for the DB subnet group."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "subnet_ids must contain at least two subnets."
  }
}

variable "publicly_accessible" {
  description = "Whether the DB is publicly accessible."
  type        = bool
  default     = false
}

variable "multi_az" {
  description = "Whether to enable Multi-AZ deployment."
  type        = bool
  default     = true
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to connect to the database."
  type        = list(string)
  default     = []
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to connect to the database."
  type        = list(string)
  default     = []
}

variable "additional_security_group_ids" {
  description = "Additional security groups to attach to the RDS instance."
  type        = list(string)
  default     = []
}

variable "parameters" {
  description = "Custom DB parameter group parameters."
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string)
  }))
  default = []
}

variable "backup_retention_period" {
  description = "Number of days to retain backups."
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_period >= 0 && var.backup_retention_period <= 35
    error_message = "backup_retention_period must be between 0 and 35."
  }
}

variable "backup_window" {
  description = "Preferred daily backup window in UTC."
  type        = string
  default     = "03:00-04:00"
}

variable "copy_tags_to_snapshot" {
  description = "Whether instance tags are copied to snapshots."
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Whether to skip a final snapshot on destroy."
  type        = bool
  default     = false
}

variable "maintenance_window" {
  description = "Weekly maintenance window."
  type        = string
  default     = "Mon:05:00-Mon:06:00"
}

variable "auto_minor_version_upgrade" {
  description = "Whether to enable automatic minor version upgrades."
  type        = bool
  default     = true
}

variable "allow_major_version_upgrade" {
  description = "Whether to allow major version upgrades."
  type        = bool
  default     = false
}

variable "apply_immediately" {
  description = "Whether to apply changes immediately."
  type        = bool
  default     = false
}

variable "monitoring_interval" {
  description = "Enhanced monitoring interval in seconds. Set to 0 to disable."
  type        = number
  default     = 0

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "monitoring_interval must be one of: 0, 1, 5, 10, 15, 30, 60."
  }
}

variable "monitoring_role_arn" {
  description = "IAM role ARN used for enhanced monitoring. Required when monitoring_interval > 0."
  type        = string
  default     = null

  validation {
    condition     = var.monitoring_interval == 0 || var.monitoring_role_arn != null
    error_message = "monitoring_role_arn must be set when monitoring_interval is greater than 0."
  }
}

variable "enabled_cloudwatch_logs_exports" {
  description = "Optional override for CloudWatch log exports."
  type        = list(string)
  default     = null
}

variable "performance_insights_enabled" {
  description = "Whether to enable Performance Insights."
  type        = bool
  default     = true
}

variable "performance_insights_retention_period" {
  description = "Performance Insights data retention in days."
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Whether to enable deletion protection."
  type        = bool
  default     = true
}

variable "create_read_replica" {
  description = "Whether to create a single read replica."
  type        = bool
  default     = false
}

variable "enable_cloudwatch_alarms" {
  description = "Whether to create CloudWatch alarms for the primary instance."
  type        = bool
  default     = false
}

variable "alarm_actions" {
  description = "SNS topic ARNs triggered by CloudWatch alarms."
  type        = list(string)
  default     = []
}

variable "cpu_utilization_alarm_threshold" {
  description = "CPU utilization threshold for the CloudWatch alarm."
  type        = number
  default     = 80
}

variable "free_storage_space_alarm_threshold" {
  description = "Free storage space threshold in bytes for the CloudWatch alarm."
  type        = number
  default     = 10737418240
}

variable "freeable_memory_alarm_threshold" {
  description = "Freeable memory threshold in bytes for the CloudWatch alarm."
  type        = number
  default     = 268435456
}

variable "secret_recovery_window_in_days" {
  description = "Secrets Manager recovery window for the generated secret."
  type        = number
  default     = 7
}

variable "kms_key_deletion_window_in_days" {
  description = "Deletion window in days for the module-managed KMS key."
  type        = number
  default     = 10
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}

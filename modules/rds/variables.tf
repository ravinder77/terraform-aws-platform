
variable "identifier" {
  description = "Unique identifier for the RDS instance"
  type = string
}

variable "engine" {
  description = "Database Engine"
  type = string
  default = "postgres"
  validation {
    condition = contains(["postgres", "mysql, mariadb"], var.engine)
    error_message = "Engine must be postgres, mysql, or mariadb."
  }
}

variable "engine_version" {
  description = "Engine Version"
  type = string
  default = "17.2"
}

variable "instance_class" {
  description = "RDS instance class"
  type = string
  default = "db.t3.medium"
}

variable "allocated_storage" {
  description = "Initial storage in GB"
  type = number
  default = 20
}

variable "max_allocated_storage" {
  description = "Max storage for autoscaling (0 = disabled)"
  type        = number
  default     = 100
}

variable "db_name" {
  description = "Name of the database"
  type = string
}

variable "username" {
  description = "Master Username"
  type = string
  sensitive = true
}

variable "subnet_ids" {
  description = "List of private subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID for security group"
  type        = string
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to connect to RDS"
  type        = list(string)
  default     = []
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = true
}

variable "backup_retention_period" {
  description = "Backup retention in days"
  type        = number
  default     = 7
}

variable "deletion_protection" {
  description = "Prevent accidental deletion"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on destroy"
  type        = bool
  default     = false
}

variable "create_read_replica" {
  description = "Create a read replica"
  type        = bool
  default     = false
}

variable "enable_cloudwatch_alarms" {
  description = "Create CloudWatch alarms"
  type        = bool
  default     = true
}

variable "alarm_actions" {
  description = "SNS topic ARNs for alarm actions"
  type        = list(string)
  default     = []
}

variable "parameters" {
  description = "Custom parameter group parameters"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}


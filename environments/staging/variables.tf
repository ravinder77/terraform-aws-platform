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

variable "create_eks" {
  description = "Whether to deploy the EKS module in this environment."
  type        = bool
  default     = false
}

variable "eks_cluster_name" {
  description = "Suffix used in the EKS cluster name."
  type        = string
  default     = "eks"
}

variable "eks_kubernetes_version" {
  description = "Optional Kubernetes version for the EKS cluster."
  type        = string
  default     = null
}

variable "eks_endpoint_private_access" {
  description = "Whether the EKS API endpoint is reachable from within the VPC."
  type        = bool
  default     = true
}

variable "eks_endpoint_public_access" {
  description = "Whether the EKS API endpoint is publicly reachable."
  type        = bool
  default     = true
}

variable "eks_public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public EKS API endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "eks_cluster_log_retention_in_days" {
  description = "Retention period in days for EKS control plane logs."
  type        = number
  default     = 30
}

variable "eks_cluster_addons" {
  description = "Managed addons installed on the EKS cluster."
  type        = list(string)
  default     = ["coredns", "kube-proxy", "vpc-cni"]
}

variable "eks_node_group_name" {
  description = "Suffix used in the EKS managed node group name."
  type        = string
  default     = "default"
}

variable "eks_node_instance_types" {
  description = "EC2 instance types used by the EKS managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_node_ami_type" {
  description = "AMI type used by the EKS managed node group."
  type        = string
  default     = "AL2_x86_64"
}

variable "eks_node_capacity_type" {
  description = "Capacity type for the EKS managed node group."
  type        = string
  default     = "ON_DEMAND"
}

variable "eks_node_disk_size" {
  description = "Disk size in GiB for EKS worker nodes."
  type        = number
  default     = 20
}

variable "eks_node_desired_size" {
  description = "Desired number of EKS worker nodes."
  type        = number
  default     = 2
}

variable "eks_node_min_size" {
  description = "Minimum number of EKS worker nodes."
  type        = number
  default     = 1
}

variable "eks_node_max_size" {
  description = "Maximum number of EKS worker nodes."
  type        = number
  default     = 3
}

variable "eks_node_subnet_ids" {
  description = "Optional subnet IDs for EKS worker nodes. Defaults to the VPC private subnets."
  type        = list(string)
  default     = null
}

variable "eks_node_max_unavailable" {
  description = "Maximum number of EKS nodes unavailable during updates."
  type        = number
  default     = 1
}

variable "eks_ssh_key_name" {
  description = "Optional EC2 key pair name for SSH access to EKS nodes."
  type        = string
  default     = null
}

variable "eks_remote_access_source_security_group_ids" {
  description = "Security groups allowed to SSH to EKS nodes when eks_ssh_key_name is set."
  type        = list(string)
  default     = []
}

variable "eks_create_oidc_provider" {
  description = "Whether to create an IAM OIDC provider for the EKS cluster."
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
  default     = "15.7"
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

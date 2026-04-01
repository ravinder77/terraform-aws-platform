variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-_]{0,99}$", var.cluster_name))
    error_message = "cluster_name must be 1-100 characters and contain only letters, numbers, hyphens, or underscores."
  }
}

variable "kubernetes_version" {
  description = "Optional Kubernetes version for the cluster."
  type        = string
  default     = null
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster will be created."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs used by the EKS control plane."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "subnet_ids must contain at least two subnets."
  }
}

variable "node_subnet_ids" {
  description = "Optional subnet IDs for the managed node group. Defaults to subnet_ids."
  type        = list(string)
  default     = null
}

variable "endpoint_private_access" {
  description = "Whether the EKS API server is reachable from within the VPC."
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Whether the EKS API server is publicly reachable."
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public EKS API endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enabled_cluster_log_types" {
  description = "Control plane log types sent to CloudWatch Logs."
  type        = list(string)
  default     = ["api", "audit", "authenticator"]
}

variable "cluster_log_retention_in_days" {
  description = "Retention period in days for the EKS control plane log group."
  type        = number
  default     = 30
}

variable "cluster_addons" {
  description = "EKS managed addons to install after the node group is ready."
  type        = list(string)
  default     = ["coredns", "kube-proxy", "vpc-cni"]
}

variable "node_group_name" {
  description = "Suffix used for the managed node group name."
  type        = string
  default     = "default"
}

variable "node_instance_types" {
  description = "EC2 instance types used by the managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_ami_type" {
  description = "AMI type used by the managed node group."
  type        = string
  default     = "AL2_x86_64"
}

variable "node_capacity_type" {
  description = "Capacity type for the managed node group."
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.node_capacity_type)
    error_message = "node_capacity_type must be either ON_DEMAND or SPOT."
  }
}

variable "node_disk_size" {
  description = "Disk size in GiB for worker nodes."
  type        = number
  default     = 20
}

variable "node_desired_size" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 3

  validation {
    condition     = var.node_max_size >= var.node_desired_size && var.node_desired_size >= var.node_min_size
    error_message = "node_max_size must be greater than or equal to node_desired_size, and node_desired_size must be greater than or equal to node_min_size."
  }
}

variable "node_max_unavailable" {
  description = "Maximum number of nodes unavailable during managed node group updates."
  type        = number
  default     = 1
}

variable "ssh_key_name" {
  description = "Optional EC2 key pair name for SSH access to worker nodes."
  type        = string
  default     = null
}

variable "remote_access_source_security_group_ids" {
  description = "Security groups allowed to SSH to nodes when ssh_key_name is set."
  type        = list(string)
  default     = []
}

variable "create_oidc_provider" {
  description = "Whether to create an IAM OIDC provider for IRSA."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags applied to all resources."
  type        = map(string)
  default     = {}
}

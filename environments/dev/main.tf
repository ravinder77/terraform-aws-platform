locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = merge(
    {
      Environment = var.environment
      ManagedBy   = "terraform"
      Project     = var.project_name
      Owner       = var.owner
    },
    var.tags
  )
}

module "iam_users" {
  count  = var.create_iam ? 1 : 0
  source = "../../modules/iam-users"

  prefix      = var.project_name
  project     = var.project_name
  environment = var.environment
  tags        = local.common_tags
  groups      = var.iam_groups
}

module "vpc" {
  source = "../../modules/vpc"

  vpc_name           = "${local.name_prefix}-vpc"
  vpc_cidr           = var.vpc_cidr
  azs                = var.azs
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
  enable_nat_gateway = var.enable_nat_gateway
  tags               = local.common_tags
}

module "eks" {
  count  = var.create_eks ? 1 : 0
  source = "../../modules/eks"

  cluster_name                            = "${local.name_prefix}-${var.eks_cluster_name}"
  kubernetes_version                      = var.eks_kubernetes_version
  vpc_id                                  = module.vpc.vpc_id
  subnet_ids                              = module.vpc.private_subnets
  node_subnet_ids                         = var.eks_node_subnet_ids
  endpoint_private_access                 = var.eks_endpoint_private_access
  endpoint_public_access                  = var.eks_endpoint_public_access
  public_access_cidrs                     = var.eks_public_access_cidrs
  cluster_log_retention_in_days           = var.eks_cluster_log_retention_in_days
  cluster_addons                          = var.eks_cluster_addons
  node_group_name                         = var.eks_node_group_name
  node_instance_types                     = var.eks_node_instance_types
  node_ami_type                           = var.eks_node_ami_type
  node_capacity_type                      = var.eks_node_capacity_type
  node_disk_size                          = var.eks_node_disk_size
  node_desired_size                       = var.eks_node_desired_size
  node_min_size                           = var.eks_node_min_size
  node_max_size                           = var.eks_node_max_size
  node_max_unavailable                    = var.eks_node_max_unavailable
  ssh_key_name                            = var.eks_ssh_key_name
  remote_access_source_security_group_ids = var.eks_remote_access_source_security_group_ids
  create_oidc_provider                    = var.eks_create_oidc_provider
  tags                                    = local.common_tags
}

module "rds" {
  count  = var.create_rds ? 1 : 0
  source = "../../modules/rds"

  identifier                 = "${local.name_prefix}-${var.rds_identifier}"
  engine                     = var.rds_engine
  engine_version             = var.rds_engine_version
  parameter_group_family     = var.rds_parameter_group_family
  instance_class             = var.rds_instance_class
  allocated_storage          = var.rds_allocated_storage
  max_allocated_storage      = var.rds_max_allocated_storage
  db_name                    = var.rds_db_name
  username                   = var.rds_username
  subnet_ids                 = module.vpc.private_subnets
  vpc_id                     = module.vpc.vpc_id
  allowed_security_group_ids = var.rds_allowed_security_group_ids
  multi_az                   = var.rds_multi_az
  backup_retention_period    = var.rds_backup_retention_period
  deletion_protection        = var.rds_deletion_protection
  skip_final_snapshot        = var.rds_skip_final_snapshot
  create_read_replica        = var.rds_create_read_replica
  parameters                 = var.rds_parameters
  tags                       = local.common_tags
}

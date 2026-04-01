# --- Random Password --------
resource "random_password" "master" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_id" "final_snapshot_suffix" {
  count = var.skip_final_snapshot ? 0 : 1

  byte_length = 4
}

# ----- Secret Manager ---------
resource "aws_secretsmanager_secret" "rds" {
  name                    = "${var.identifier}/rds/master"
  recovery_window_in_days = var.secret_recovery_window_in_days
  tags                    = local.common_tags
}

resource "aws_secretsmanager_secret_version" "rds" {
  secret_id = aws_secretsmanager_secret.rds.id
  secret_string = jsonencode({
    username = var.username
    password = random_password.master.result
    host     = aws_db_instance.main.address
    port     = local.port
    db_name  = var.db_name
  })
}

# ----- KMS Key for encryption at rest ------
resource "aws_kms_key" "rds" {
  description             = "KMS key for ${var.identifier} RDS"
  deletion_window_in_days = var.kms_key_deletion_window_in_days
  enable_key_rotation     = true
  tags                    = local.common_tags
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.identifier}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

# ─── DB Subnet group ─────────────────
resource "aws_db_subnet_group" "main" {
  name       = var.identifier
  subnet_ids = var.subnet_ids
  tags       = local.common_tags
}

# ─── DB Parameter group ───────────
resource "aws_db_parameter_group" "main" {
  name_prefix = "${var.identifier}-"
  family      = local.family

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = try(parameter.value.apply_method, null)
    }
  }

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

# ----Security Group -------
resource "aws_security_group" "rds_sg" {
  name        = "${var.identifier}-sg"
  description = "RDS security group for ${var.identifier}"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.allowed_cidr_blocks
    content {
      from_port   = local.port
      to_port     = local.port
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  dynamic "ingress" {
    for_each = var.allowed_security_group_ids
    content {
      from_port       = local.port
      to_port         = local.port
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.identifier}-sg"
  })
}

#----- RDS Instance ------
resource "aws_db_instance" "main" {
  identifier = var.identifier

  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class
  license_model  = var.license_model

  db_name  = var.db_name
  username = var.username
  password = random_password.master.result

  port = local.port

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.rds.arn

  multi_az               = var.multi_az
  db_subnet_group_name   = aws_db_subnet_group.main.name
  parameter_group_name   = aws_db_parameter_group.main.name
  vpc_security_group_ids = concat([aws_security_group.rds_sg.id], var.additional_security_group_ids)
  publicly_accessible    = var.publicly_accessible

  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window

  auto_minor_version_upgrade  = var.auto_minor_version_upgrade
  allow_major_version_upgrade = var.allow_major_version_upgrade
  apply_immediately           = var.apply_immediately
  deletion_protection         = var.deletion_protection
  skip_final_snapshot         = var.skip_final_snapshot
  final_snapshot_identifier   = var.skip_final_snapshot ? null : "${var.identifier}-final-${random_id.final_snapshot_suffix[0].hex}"
  copy_tags_to_snapshot       = var.copy_tags_to_snapshot

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
  monitoring_interval                   = var.monitoring_interval
  monitoring_role_arn                   = var.monitoring_interval > 0 ? var.monitoring_role_arn : null

  enabled_cloudwatch_logs_exports = local.log_exports

  tags = local.common_tags

  lifecycle {
    ignore_changes = [password]
  }

}

# ─── Read replica (optional) ─────────────────────────────────────────────────
resource "aws_db_instance" "replica" {
  count = var.create_read_replica ? 1 : 0

  identifier             = "${var.identifier}-replica"
  replicate_source_db    = aws_db_instance.main.identifier
  instance_class         = var.instance_class
  vpc_security_group_ids = concat([aws_security_group.rds_sg.id], var.additional_security_group_ids)
  parameter_group_name   = aws_db_parameter_group.main.name
  publicly_accessible    = var.publicly_accessible
  skip_final_snapshot    = true
  storage_encrypted      = true
  kms_key_id             = aws_kms_key.rds.arn

  auto_minor_version_upgrade   = var.auto_minor_version_upgrade
  performance_insights_enabled = var.performance_insights_enabled
  monitoring_interval          = var.monitoring_interval
  monitoring_role_arn          = var.monitoring_interval > 0 ? var.monitoring_role_arn : null

  tags = merge(local.common_tags, { Role = "replica" })
}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  count = var.enable_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${var.identifier}-high-cpu"
  alarm_description   = "High CPU utilization for ${var.identifier}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_utilization_alarm_threshold
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "free_storage_space" {
  count = var.enable_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${var.identifier}-low-storage"
  alarm_description   = "Low free storage space for ${var.identifier}"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.free_storage_space_alarm_threshold
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "freeable_memory" {
  count = var.enable_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${var.identifier}-low-memory"
  alarm_description   = "Low freeable memory for ${var.identifier}"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.freeable_memory_alarm_threshold
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.id
  }

  tags = local.common_tags
}

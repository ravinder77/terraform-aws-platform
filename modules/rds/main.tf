
# --- Random Password --------
resource "random_password" "master" {
  length = 24
  special = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# ----- Secret Manager ---------
resource "aws_secretsmanager_secret" "rds" {
  name =  "${var.identifier}/rds/master"
  recovery_window_in_days = 7
  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "rds" {
  secret_id = aws_secretsmanager_secret.rds.id
  secret_string = jsonencode({
    username = var.username
    password = random_password.master.result
    host = aws_db_instance.main.address
    port = local.port
    db_name = var.db_name
  })
}

# ----- KMS Key for encryption at rest ------
resource "aws_kms_key" "rds" {
  description = "KMS key for ${var.identifier} RDS"
  deletion_window_in_days = 10
  enable_key_rotation = true
  tags = local.common_tags
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.identifier}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

# ─── Subnet group ─────────────────
resource "aws_db_subnet_group" "main" {
  name       = var.identifier
  subnet_ids = var.subnet_ids
  tags       = local.common_tags
}

# ─── Parameter group ───────────
resource "aws_db_parameter_group" "main" {
  name   = var.identifier
  family = local.family

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

# ----Security Group -------
resource "aws_security_group" "rds_sg" {
  name = "${var.db_name}-subnet-group"
  description = "RDS security group for ${var.identifier}"
  vpc_id = var.vpc_id

  dynamic "ingress" {
    for_each = var.allowed_security_group_ids
    content {
      from_port = local.port
      to_port = local.port
      protocol = "tcp"
      source_security_group_id = ingress.value
    }
  }
}

#----- RDS Instance ------
resource "aws_db_instance" "main" {
  identifier = var.identifier

  engine = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_name = var.db_name
  username = var.username
  password = random_password.master.result

  port = local.port

  allocated_storage = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type = "gp3"
  storage_encrypted = true
  kms_key_id = aws_kms_key.rds.arn

  multi_az = var.multi_az
  db_subnet_group_name = aws_db_subnet_group.main.name
  parameter_group_name = aws_db_parameter_group.main.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible = false

  backup_retention_period = var.backup_retention_period
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"


  auto_minor_version_upgrade = true
  deletion_protection        = var.deletion_protection
  skip_final_snapshot        = var.skip_final_snapshot
  final_snapshot_identifier  = "${var.identifier}-final"

  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  enabled_cloudwatch_logs_exports = var.engine == "postgres" ? ["postgresql"] : ["general", "error", "slowquery"]

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
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  parameter_group_name   = aws_db_parameter_group.main.name
  publicly_accessible    = false
  skip_final_snapshot    = true
  storage_encrypted      = true
  kms_key_id             = aws_kms_key.rds.arn

  performance_insights_enabled = true
  auto_minor_version_upgrade   = true

  tags = merge(local.common_tags, { Role = "replica" })
}
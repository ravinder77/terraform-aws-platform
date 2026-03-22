output "db_instance_id" {
  description = "RDS Instance ID"
  value       = aws_db_instance.main.id
}

output "db_instance_address" {
  description = "RDS endpoint address"
  value = aws_db_instance.main.address
}

output "db_instance_port" {
  description = "RDS port"
  value = aws_db_instance.main.port
}

output "db_instance_arn" {
  description = "RDS instance ARN"
  value = aws_db_instance.main.arn
}

output "security_group_id" {
  description = "RDS security group ID"
  value = aws_security_group.rds_sg.id
}

output "secret_arn" {
  description = "Secrets Manager ARN for master credentials"
  value = aws_secretsmanager_secret.rds.arn
}

output "kms_key_arn" {
  description = "KMS key ARN used for encryption"
  value = aws_kms_key.rds.arn
}

output "replica_address" {
  description = "Read replica address (if created)"
  value = try(aws_db_instance.replica[0].address, null)
}

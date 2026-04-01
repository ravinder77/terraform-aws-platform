locals {
  port = var.engine == "postgres" ? 5432 : 3306

  engine_version_parts = split(".", var.engine_version)

  default_log_exports = {
    postgres = ["postgresql"]
    mysql    = ["error", "general", "slowquery"]
    mariadb  = ["error", "general", "slowquery"]
  }

  inferred_family = {
    postgres = "postgres${local.engine_version_parts[0]}"
    mysql    = "mysql${join(".", slice(local.engine_version_parts, 0, min(length(local.engine_version_parts), 2)))}"
    mariadb  = "mariadb${join(".", slice(local.engine_version_parts, 0, min(length(local.engine_version_parts), 2)))}"
  }[var.engine]

  family      = coalesce(var.parameter_group_family, local.inferred_family)
  log_exports = coalesce(var.enabled_cloudwatch_logs_exports, local.default_log_exports[var.engine])

  common_tags = merge(var.tags, {
    ManagedBy = "terraform"
    Module    = "rds"
  })
}

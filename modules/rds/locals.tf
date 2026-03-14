
locals {
  port = var.engine == "postgres" ? 5432 : 3306

  family = {
    postgres = "postgres15"
    mysql    = "mysql8.0"
    mariadb  = "mariadb10.6"
  }[var.engine]

  common_tags = merge(var.tags, {
    ManagedBy = "terraform"
    Module    = "rds"
  })
}
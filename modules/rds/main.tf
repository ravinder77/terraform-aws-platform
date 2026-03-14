
resource "aws_db_subnet_group" "rds_subnet_group" {
  name = "${var.db_name}-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.db_name}-subnet-group"
  }
}

resource "aws_security_group" "rds_sg" {
  name = "${var.db_name}-subnet-group"
  vpc_id = var.vpc_id
}
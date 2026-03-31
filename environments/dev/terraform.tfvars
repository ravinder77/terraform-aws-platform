aws_region   = "ap-south-1"
environment  = "dev"
project_name = "platform"
owner        = "platform-team"

create_iam = true

iam_groups = {
  developers = {
    managed_policy_arns = [
      "arn:aws:iam::aws:policy/ReadOnlyAccess"
    ]
  }
}

vpc_cidr        = "31.10.0.0/16"
azs             = ["ap-south-1a", "ap-south-1b"]
public_subnets  = ["31.10.1.0/24", "31.10.2.0/24"]
private_subnets = ["31.10.11.0/24", "31.10.12.0/24"]

enable_nat_gateway = true
create_rds         = false

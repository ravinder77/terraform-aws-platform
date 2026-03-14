
module "vpc" {
  source   = "./modules/vpc"
  vpc_cidr = "31.0.0.0/16"
  vpc_name = "my-vpc"
  azs = [
    "ap-south-1a",
    "ap-south-1b"
  ]
  public_subnets = [
    "31.0.1.0/24",
    "31.0.2.0/24"
  ]
  private_subnets = [
    "31.0.11.0/24",
    "31.0.12.0/24"
  ]
}

module "rds" {
  source = "./modules/rds"
}
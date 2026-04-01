locals {


  # Normalize NAT mode
  nat_mode = var.enable_nat_gateway ? coalesce(var.nat_gateway_mode, "single") : "none"

  # Subnet maps (AZ → config)
  public_subnet_map = {
    for index, az in var.azs : az => {
      cidr = var.public_subnets[index]
      name = "${var.vpc_name}-public-${az}"
    }
  }

  private_subnet_map = {
    for index, az in var.azs : az => {
      cidr = var.private_subnets[index]
      name = "${var.vpc_name}-private-${az}"
    }
  }


  # NAT placement AZs
  nat_gateway_azs = (
    local.nat_mode == "one_per_az" ? var.azs :
    local.nat_mode == "single" ? slice(var.azs, 0, 1) :
    []
  )

  # Private route table keys
  private_route_table_azs = local.nat_mode == "one_per_az" ? var.azs : ["shared"]
}

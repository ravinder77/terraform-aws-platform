data "aws_caller_identity" "current" {}

check "public_subnet_length_match" {
  assert {
    condition     = length(var.azs) == length(var.public_subnets)
    error_message = "public_subnets must match number of AZs"
  }
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(var.tags, {
    Name = var.vpc_name
  })
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  count  = length(var.public_subnets) > 0 ? 1 : 0
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-igw"
  })
}

# Public Subnet
resource "aws_subnet" "public_subnet" {
  for_each = local.public_subnet_map

  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value.cidr
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = merge(var.tags, var.public_subnet_tags, {
    Name = each.value.name
    Tier = "public"
  })
}

# Private Subnet
resource "aws_subnet" "private_subnet" {
  for_each = local.private_subnet_map

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.key

  tags = merge(var.tags, var.private_subnet_tags, {
    Name = each.value.name
    Tier = "private"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-public-rt"
  })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw[0].id
}

resource "aws_route_table" "private" {
  for_each = toset(local.private_route_table_azs)

  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = each.key == "shared" ? "${var.vpc_name}-private-rt" : "${var.vpc_name}-private-${each.key}-rt"
  })
}

resource "aws_route" "private_nat" {
  for_each = local.nat_mode == "none" ? {} : aws_route_table.private

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = local.nat_mode == "one_per_az" ? aws_nat_gateway.nat[each.key].id : aws_nat_gateway.nat[var.azs[0]].id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public_subnet

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private_subnet

  subnet_id      = each.value.id
  route_table_id = local.nat_mode == "one_per_az" ? aws_route_table.private[each.key].id : aws_route_table.private["shared"].id
}

resource "aws_eip" "nat" {
  for_each = toset(local.nat_gateway_azs)
  domain   = "vpc"

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-nat-eip-${each.key}"
  })
}

resource "aws_nat_gateway" "nat" {
  for_each = toset(local.nat_gateway_azs)

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public_subnet[each.key].id

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-nat-${each.key}"
  })

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  name              = "/aws/vpc/${var.vpc_name}/flow-logs"
  retention_in_days = var.flow_log_retention_in_days

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-flow-logs"
  })
}

data "aws_iam_policy_document" "flow_logs_assume_role" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "flow_logs" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
    ]
    resources = ["${aws_cloudwatch_log_group.vpc_flow_logs[0].arn}:*"]
  }
}

resource "aws_iam_role" "flow_logs" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  name               = "${var.vpc_name}-flow-logs-role"
  assume_role_policy = data.aws_iam_policy_document.flow_logs_assume_role[0].json

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-flow-logs-role"
  })
}

resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  name   = "${var.vpc_name}-flow-logs-policy"
  role   = aws_iam_role.flow_logs[0].id
  policy = data.aws_iam_policy_document.flow_logs[0].json
}

resource "aws_flow_log" "vpc" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  iam_role_arn         = aws_iam_role.flow_logs[0].arn
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs[0].arn
  traffic_type         = var.flow_log_traffic_type
  vpc_id               = aws_vpc.main.id
  log_destination_type = "cloud-watch-logs"

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-flow-log"
  })
}

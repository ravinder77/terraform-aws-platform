output "vpc_id" {
  description = "VPC ID."
  value       = aws_vpc.main.id
}

output "vpc_arn" {
  description = "VPC ARN."
  value       = aws_vpc.main.arn
}

output "vpc_cidr_block" {
  description = "VPC CIDR block."
  value       = aws_vpc.main.cidr_block
}

output "public_subnets" {
  description = "Public subnet IDs."
  value       = [for az in var.azs : aws_subnet.public_subnet[az].id]
}

output "private_subnets" {
  description = "Private subnet IDs."
  value       = [for az in var.azs : aws_subnet.private_subnet[az].id]
}

output "nat_gateway_id" {
  description = "NAT gateway IDs."
  value       = [for az in local.nat_gateway_azs : aws_nat_gateway.nat[az].id]
}

output "public_route_table_id" {
  description = "Public route table ID."
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "Private route table IDs."
  value       = local.effective_nat_gateway_mode == "one_per_az" ? [for az in var.azs : aws_route_table.private[az].id] : [aws_route_table.private["shared"].id]
}

output "internet_gateway_id" {
  description = "Internet gateway ID."
  value       = try(aws_internet_gateway.igw[0].id, null)
}

output "flow_log_id" {
  description = "VPC flow log ID when enabled."
  value       = try(aws_flow_log.vpc[0].id, null)
}

output "aws_account_id" {
  description = "AWS account ID."
  value       = data.aws_caller_identity.current.account_id
}

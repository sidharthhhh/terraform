output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC."
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway."
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway (null if disabled)."
  value       = var.enable_nat_gateway ? aws_nat_gateway.main[0].id : null
}

output "availability_zones" {
  description = "Availability Zones the subnets are spread across."
  value       = local.azs
}

output "caller_identity" {
  description = "The AWS identity (current user/role) running Terraform."
  value       = data.aws_caller_identity.current.arn
}

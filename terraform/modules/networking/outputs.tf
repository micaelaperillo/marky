output "vpc_id" {
  description = "ID of the main VPC."
  value       = aws_vpc.main.id
}

output "backend_subnet_ids" {
  description = "List of backend subnet IDs across availability zones."
  value = [
    aws_subnet.this["backend-az1"].id,
    aws_subnet.this["backend-az2"].id,
  ]
}

output "backend_route_table_ids" {
  description = "List of backend route table IDs for VPC endpoint associations."
  value = [
    aws_route_table.backend_az1.id,
    aws_route_table.backend_az2.id,
  ]
}

output "lambda_sg_id" {
  description = "Security group ID for VPC-attached Lambda functions."
  value       = aws_security_group.lambda.id
}

output "rds_sg_id" {
  description = "Security group ID for RDS instance and RDS Proxy."
  value       = aws_security_group.rds.id
}

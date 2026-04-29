output "vpc_id" {
  value = aws_vpc.main.id
}

output "backend_subnet_ids" {
  value = [
    aws_subnet.this["backend-az1"].id,
    aws_subnet.this["backend-az2"].id,
  ]
}

output "nat_subnet_ids" {
  value = [
    aws_subnet.this["nat-az1"].id,
    aws_subnet.this["nat-az2"].id,
  ]
}

output "backend_route_table_ids" {
  value = [
    aws_route_table.backend_az1.id,
    aws_route_table.backend_az2.id,
  ]
}

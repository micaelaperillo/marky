output "backend_sg_id" {
  value = aws_security_group.backend.id
}

output "lambda_sg_id" {
  value = aws_security_group.lambda.id
}

output "nat_sg_id" {
  value = aws_security_group.nat.id
}

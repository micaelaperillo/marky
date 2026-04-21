output "frontend_sg_id" {
  value = aws_security_group.frontend.id
}

output "backend_sg_id" {
  value = aws_security_group.backend.id
}

output "nat_sg_id" {
  value = aws_security_group.nat.id
}

output "alb_sg_id" {
  value = aws_security_group.alb.id
}

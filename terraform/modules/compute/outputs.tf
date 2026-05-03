output "backend_asg_name" {
  value = aws_autoscaling_group.backend.name
}

output "backend_alb_dns" {
  value = aws_lb.backend.dns_name
}

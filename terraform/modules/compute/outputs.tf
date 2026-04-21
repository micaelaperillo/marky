output "alb_dns_name" {
  value = aws_lb.frontend.dns_name
}

output "frontend_asg_name" {
  value = aws_autoscaling_group.frontend.name
}

output "backend_asg_name" {
  value = aws_autoscaling_group.backend.name
}

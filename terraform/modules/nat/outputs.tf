output "instance_id" {
  value = aws_instance.fck_nat.id
}

output "private_ip" {
  value = aws_instance.fck_nat.private_ip
}

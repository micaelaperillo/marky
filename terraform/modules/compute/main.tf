# --- AMI Lookup (Amazon Linux 2023, ARM) ---

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-arm64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# ============================================================
# Key Pairs (conditional)
# ============================================================

resource "tls_private_key" "frontend" {
  count     = var.create_key_pairs ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "frontend" {
  count      = var.create_key_pairs ? 1 : 0
  key_name   = "${var.project}-frontend-ec2-kp"
  public_key = tls_private_key.frontend[0].public_key_openssh
}

resource "local_sensitive_file" "frontend_key" {
  count           = var.create_key_pairs ? 1 : 0
  content         = tls_private_key.frontend[0].private_key_pem
  filename        = "${path.root}/${var.project}-frontend-ec2-kp.pem"
  file_permission = "0400"
}

resource "tls_private_key" "backend" {
  count     = var.create_key_pairs ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "backend" {
  count      = var.create_key_pairs ? 1 : 0
  key_name   = "${var.project}-backend-ec2-kp"
  public_key = tls_private_key.backend[0].public_key_openssh
}

resource "local_sensitive_file" "backend_key" {
  count           = var.create_key_pairs ? 1 : 0
  content         = tls_private_key.backend[0].private_key_pem
  filename        = "${path.root}/${var.project}-backend-ec2-kp.pem"
  file_permission = "0400"
}

# ============================================================
# Launch Templates
# ============================================================

resource "aws_launch_template" "frontend" {
  name          = "${var.project}-frontend-ec2-launch-template"
  description   = "Marky frontend template."
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t4g.small"
  key_name      = var.create_key_pairs ? aws_key_pair.frontend[0].key_name : "${var.project}-frontend-ec2-kp"

  iam_instance_profile {
    name = var.iam_instance_profile_name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [var.frontend_sg_id]
  }

  private_dns_name_options {
    hostname_type                        = "ip-name"
    enable_resource_name_dns_a_record    = true
    enable_resource_name_dns_aaaa_record = false
  }

  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh.tftpl", {
    server_type = "frontend"
    repo_url    = var.repo_url
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project}-frontend"
    }
  }

  tags = { Name = "${var.project}-frontend-ec2-launch-template" }
}

resource "aws_launch_template" "backend" {
  name          = "${var.project}-backend-ec2-launch-template"
  description   = "Marky backend template."
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t4g.small"
  key_name      = var.create_key_pairs ? aws_key_pair.backend[0].key_name : "${var.project}-backend-ec2-kp"

  vpc_security_group_ids = [var.backend_sg_id]

  iam_instance_profile {
    name = var.iam_instance_profile_name
  }

  private_dns_name_options {
    hostname_type                        = "ip-name"
    enable_resource_name_dns_a_record    = true
    enable_resource_name_dns_aaaa_record = false
  }

  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh.tftpl", {
    server_type = "backend"
    repo_url    = var.repo_url
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project}-backend"
    }
  }

  tags = { Name = "${var.project}-backend-ec2-launch-template" }
}

# ============================================================
# ALB + Target Group + Listener (frontend only)
# ============================================================

resource "aws_lb" "frontend" {
  name               = "${var.project}-frontend-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.frontend_subnet_ids

  tags = { Name = "${var.project}-frontend-alb" }
}

resource "aws_lb_target_group" "frontend" {
  name     = "${var.project}-frontend-alb-${var.suffix}"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
    path                = "/"
    port                = "9090"
    protocol            = "HTTP"
  }

  tags = { Name = "${var.project}-frontend-alb-${var.suffix}" }
}

resource "aws_lb_listener" "frontend_http" {
  load_balancer_arn = aws_lb.frontend.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

# ============================================================
# Auto Scaling Groups
# ============================================================

resource "aws_autoscaling_group" "frontend" {
  name                      = "${var.project}-frontend-ec2-auto-scaling-group"
  desired_capacity          = 1
  min_size                  = 1
  max_size                  = 6
  vpc_zone_identifier       = var.frontend_subnet_ids
  target_group_arns         = [aws_lb_target_group.frontend.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.frontend.id
    version = aws_launch_template.frontend.latest_version
  }

  instance_maintenance_policy {
    min_healthy_percentage = 90
    max_healthy_percentage = 100
  }

  tag {
    key                 = "Name"
    value               = "${var.project}-frontend"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_group" "backend" {
  name                      = "${var.project}-backend-ec2-auto-scaling-group"
  desired_capacity          = 1
  min_size                  = 1
  max_size                  = 1
  vpc_zone_identifier       = var.backend_subnet_ids
  health_check_type         = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.backend.id
    version = aws_launch_template.backend.latest_version
  }

  instance_maintenance_policy {
    min_healthy_percentage = 90
    max_healthy_percentage = 100
  }

  tag {
    key                 = "Name"
    value               = "${var.project}-backend"
    propagate_at_launch = true
  }
}

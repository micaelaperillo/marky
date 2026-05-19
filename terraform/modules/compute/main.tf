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
# Key Pair (conditional)
# ============================================================

resource "tls_private_key" "backend" {
  count     = var.create_key_pair ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "backend" {
  count      = var.create_key_pair ? 1 : 0
  key_name   = "${var.project}-backend-ec2-kp"
  public_key = tls_private_key.backend[0].public_key_openssh
}

resource "local_sensitive_file" "backend_key" {
  count           = var.create_key_pair ? 1 : 0
  content         = tls_private_key.backend[0].private_key_pem
  filename        = "${path.root}/${var.project}-backend-ec2-kp.pem"
  file_permission = "0600"
}

# ============================================================
# Launch Template
# ============================================================

resource "aws_launch_template" "backend" {
  name          = "${var.project}-backend-ec2-launch-template"
  description   = "Marky backend cron template."
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t4g.small"
  key_name      = var.create_key_pair ? aws_key_pair.backend[0].key_name : "${var.project}-backend-ec2-kp"

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
# Auto Scaling Group
# ============================================================

resource "aws_autoscaling_group" "backend" {
  name                      = "${var.project}-backend-ec2-auto-scaling-group"
  desired_capacity          = 1
  min_size                  = 1
  max_size                  = 1
  vpc_zone_identifier       = [var.backend_subnet_ids[0]]
  health_check_type         = "EC2"
  health_check_grace_period = 300
  target_group_arns         = [aws_lb_target_group.backend.arn]

  launch_template {
    id      = aws_launch_template.backend.id
    version = aws_launch_template.backend.latest_version
  }

  tag {
    key                 = "Name"
    value               = "${var.project}-backend"
    propagate_at_launch = true
  }
}

# ============================================================
# Internal ALB (for Lambda → Backend communication)
# ============================================================

resource "aws_lb" "backend" {
  name               = "${var.project}-backend-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.backend_sg_id]
  subnets            = var.backend_subnet_ids

  tags = { Name = "${var.project}-backend-alb" }
}

resource "aws_lb_target_group" "backend" {
  name     = "${var.project}-backend-tg"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/health"
    port                = "8000"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
  }

  tags = { Name = "${var.project}-backend-tg" }
}

resource "aws_lb_listener" "backend" {
  load_balancer_arn = aws_lb.backend.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}

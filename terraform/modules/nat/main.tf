# --- fck-nat AMI Lookup ---

data "aws_ami" "fck_nat" {
  most_recent = true
  owners      = ["568608671756"] # Official fck-nat publisher

  filter {
    name   = "name"
    values = ["fck-nat-al2023-*-arm64-ebs"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# --- fck-nat Instance ---
# No user data needed — the AMI runs iptables masquerade on boot via systemd.

resource "aws_instance" "fck_nat" {
  ami                         = data.aws_ami.fck_nat.id
  instance_type               = "t4g.nano"
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  source_dest_check           = false # REQUIRED — AWS drops NATted packets otherwise
  associate_public_ip_address = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    delete_on_termination = true
  }

  tags = { Name = "${var.project}-fck-nat" }
}

# --- Backend Routes → fck-nat ---
# Route via ENI (not instance ID) — survives instance stop/start without breaking routes.

resource "aws_route" "backend_to_nat" {
  count = length(var.backend_route_table_ids)

  route_table_id         = var.backend_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_instance.fck_nat.primary_network_interface_id
}

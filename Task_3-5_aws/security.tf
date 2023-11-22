# ===========SSH key-pair data sources===========
data "aws_key_pair" "wordpress_kp" {
  filter {
    name   = "tag:Task"
    values = ["task3"]
  }
}

data "aws_key_pair" "docker_kp" {
  filter {
    name   = "tag:Task"
    values = ["task4"]
  }
}

data "aws_key_pair" "nagios_kp" {
  filter {
    name   = "tag:Task"
    values = ["task5"]
  }
}

# ===========Security group for instances===========
resource "aws_security_group" "ec2_sg" {
  name        = "Monitoring EC2 Security Group"
  description = "Allow 22, 80, 5666 and icmp"

  dynamic "ingress" {
    for_each = ["22", "80", "5666"]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_key_pair" "ec2_kp" {
  filter {
    name   = "tag:Purpose"
    values = ["onboarding"]
  }
}

resource "aws_security_group" "ec2_grafana_sg" {
  name = "Grafana EC2 Security Group"

  dynamic "ingress" {
    for_each = [22, 3000]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

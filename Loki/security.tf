# ===========SSH key-pair data source===========
data "aws_key_pair" "ec2_kp" {
  filter {
    name   = "tag:Purpose"
    values = ["onboarding"]
  }
}

# ===========Security groups for monitoring===========
resource "aws_security_group" "ec2_target_sg" {
  name = "Monitoring Target EC2 Security Group"

  dynamic "ingress" {
    for_each = var.docker_sg_port_list
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

resource "aws_security_group" "ec2_loki_sg" {
  name = "Grafana Loki EC2 Security Group"

  dynamic "ingress" {
    for_each = var.loki_sg_port_list
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

# ===========IAM role for ECR pulling===========
resource "aws_iam_role" "ecr_role" {
  name = var.docker_role_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "docker_policy_attachment" {
  role       = aws_iam_role.ecr_role.name
  policy_arn = var.docker_policy_arn
}

resource "aws_iam_instance_profile" "docker_profile" {
  name = var.docker_profile_name
  role = aws_iam_role.ecr_role.name
}

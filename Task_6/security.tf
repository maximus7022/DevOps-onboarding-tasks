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

data "aws_key_pair" "prom_kp" {
  filter {
    name   = "tag:Task"
    values = ["task6"]
  }
}

# ===========Security group for monitoring===========
resource "aws_security_group" "ec2_sg" {
  count = 3
  name  = "${var.ec2_names[count.index]} EC2 Security Group"

  dynamic "ingress" {
    for_each = var.sg_port_lists[count.index]
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

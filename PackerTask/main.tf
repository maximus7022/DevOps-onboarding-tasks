# ===========Receiving packer provisioned AMIs data===========
data "aws_ami" "docker_ami" {
  filter {
    name   = "name"
    values = ["docker-ami"]
  }
}

data "aws_ami" "wordpress_ami" {
  filter {
    name   = "name"
    values = ["wordpress-ami"]
  }
}

data "aws_ami" "prometheus_ami" {
  filter {
    name   = "name"
    values = ["prometheus-ami"]
  }
}

# ===========EC2 instances creation===========
resource "aws_instance" "ec2_docker" {
  ami                    = data.aws_ami.docker_ami.id
  instance_type          = var.ec2_type
  vpc_security_group_ids = [aws_security_group.ec2_target_sg.id]
  key_name               = data.aws_key_pair.ec2_kp.key_name
  tags = {
    Name = var.target_ec2_names[0]
  }
}

resource "aws_instance" "ec2_wordpress" {
  ami                    = data.aws_ami.wordpress_ami.id
  instance_type          = var.ec2_type
  vpc_security_group_ids = [aws_security_group.ec2_target_sg.id]
  key_name               = data.aws_key_pair.ec2_kp.key_name
  tags = {
    Name = var.target_ec2_names[1]
  }
}

resource "aws_instance" "ec2_prometheus" {
  ami                    = data.aws_ami.prometheus_ami.id
  instance_type          = var.ec2_type
  vpc_security_group_ids = [aws_security_group.ec2_prom_sg.id]
  key_name               = data.aws_key_pair.ec2_kp.key_name
  iam_instance_profile   = aws_iam_instance_profile.instance_profile.name
  tags = {
    Name = var.prom_ec2_name
  }
}

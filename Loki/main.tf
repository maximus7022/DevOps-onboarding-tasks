# ===========EC2 instances creation===========
resource "aws_instance" "ec2_docker" {
  ami                    = var.ec2_ami
  instance_type          = var.ec2_type
  vpc_security_group_ids = [aws_security_group.ec2_target_sg.id]
  key_name               = data.aws_key_pair.ec2_kp.key_name
  iam_instance_profile   = aws_iam_instance_profile.docker_profile.name
  tags = {
    Name = var.docker_ec2_name
  }
}

resource "aws_instance" "ec2_loki" {
  ami                    = var.ec2_ami
  instance_type          = var.ec2_type
  vpc_security_group_ids = [aws_security_group.ec2_loki_sg.id]
  key_name               = data.aws_key_pair.ec2_kp.key_name
  tags = {
    Name = var.loki_ec2_name
  }
}

# ===========SSM parameter creation to use in promtail config===========
resource "aws_ssm_parameter" "loki_client_address" {
  name        = var.loki_ssm_name
  description = "Grafana Loki machine address"
  type        = "SecureString"
  value       = aws_instance.ec2_loki.public_ip
}

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

resource "aws_instance" "ec2_prometheus" {
  ami                    = var.ec2_ami
  instance_type          = var.ec2_type
  vpc_security_group_ids = [aws_security_group.ec2_prom_sg.id]
  key_name               = data.aws_key_pair.ec2_kp.key_name
  iam_instance_profile   = aws_iam_instance_profile.prom_profile.name
  tags = {
    Name = var.prom_ec2_name
  }
}

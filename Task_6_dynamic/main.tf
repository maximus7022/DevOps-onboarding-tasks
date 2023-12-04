# ===========EC2 instances creation===========
resource "aws_instance" "ec2_targets" {
  count                  = 2
  ami                    = var.ec2_ami
  instance_type          = var.ec2_type
  vpc_security_group_ids = [aws_security_group.ec2_target_sg.id]
  key_name               = data.aws_key_pair.ec2_kp.key_name
  tags = {
    Name = var.target_ec2_names[count.index]
  }
}

resource "aws_instance" "ec2_prometheus" {
  ami                    = var.ec2_ami
  instance_type          = var.ec2_type
  vpc_security_group_ids = [aws_security_group.ec2_prom_sg.id]
  key_name               = data.aws_key_pair.ec2_kp.key_name
  iam_instance_profile   = aws_iam_instance_profile.instance_profile.name
  tags = {
    Name = var.prom_ec2_name
  }
}

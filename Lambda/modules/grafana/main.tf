resource "aws_instance" "ec2_grafana" {
  ami                    = var.instance_ami
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.ec2_grafana_sg.id]
  key_name               = data.aws_key_pair.ec2_kp.key_name
  iam_instance_profile   = aws_iam_instance_profile.grafana_profile.name
  tags = {
    Name = var.instance_name_tag
  }
}

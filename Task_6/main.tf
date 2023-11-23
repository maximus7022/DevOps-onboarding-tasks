# ===========EC2 instances creation===========
resource "aws_instance" "ec2" {
  count                  = 3
  ami                    = var.ec2_ami
  instance_type          = var.ec2_type
  vpc_security_group_ids = [aws_security_group.ec2_sg[count.index].id]
  key_name               = local.key_pairs[count.index]
  tags = {
    Name = var.ec2_names[count.index]
  }
}

# ===========Setting EC2 public IPs and key paths into ansible inventory===========
resource "null_resource" "inventory_update" {
  count = 3
  provisioner "local-exec" {
    command = "echo '[${var.ec2_names[count.index]}]\n${aws_instance.ec2[count.index].public_ip} ansible_ssh_private_key_file=${var.key_paths[count.index]}' >> ansible/inventory.txt"
  }
  depends_on = [aws_instance.ec2]
}

# ===========Setting docker and wordpress EC2 IPs as ansible vars===========
resource "null_resource" "hosts_to_monitor_update" {
  count = 2
  provisioner "local-exec" {
    command = "echo '${var.ec2_names[count.index]}_host_ip: ${aws_instance.ec2[count.index].public_ip}' >> ansible/prometheus/roles/prom-install/vars/main.yml"
  }
  depends_on = [aws_instance.ec2]
}

source "amazon-ebs" "wordpress" {
  ami_name = "wordpress-ami"
  source_ami = "ami-07ec4220c92589b40"
  instance_type = "t3.micro"
  region = "eu-north-1"
  ssh_username = "ubuntu"
}

build {
  name = "wordpress"
  sources = [
    "source.amazon-ebs.wordpress"
  ]

  provisioner "ansible" {
    playbook_file = "../ansible/wordpress/playbook.yml"
    ansible_env_vars = ["ANSIBLE_HOST_KEY_CHECKING=False"]
    extra_arguments = [ "--scp-extra-args", "'-O'" ]        # openssh compatibility (error fix)
    user = "ubuntu"
  }
}
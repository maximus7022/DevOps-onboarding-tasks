source "amazon-ebs" "docker" {
  ami_name = "docker-ami"
  source_ami = "ami-07ec4220c92589b40"
  instance_type = "t3.micro"
  region = "eu-north-1"
  ssh_username = "ubuntu"
}

build {
  name = "docker"
  sources = [
    "source.amazon-ebs.docker"
  ]

  provisioner "ansible" {
    playbook_file = "../ansible/docker/playbook.yml"
    ansible_env_vars = ["ANSIBLE_HOST_KEY_CHECKING=False"]
    extra_arguments = [ "--scp-extra-args", "'-O'" ]        # openssh compatibility (error fix)
    user = "ubuntu"
  }
}
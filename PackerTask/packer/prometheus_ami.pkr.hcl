source "amazon-ebs" "prometheus" {
  ami_name = "prometheus-ami"
  source_ami = "ami-07ec4220c92589b40"
  instance_type = "t3.micro"
  region = "eu-north-1"
  ssh_username = "ubuntu"
}

build {
  name = "prometheus"
  sources = [
    "source.amazon-ebs.prometheus"
  ]

  provisioner "ansible" {
    playbook_file = "../ansible/prometheus/playbook.yml"
    ansible_env_vars = ["ANSIBLE_HOST_KEY_CHECKING=False"]
    extra_arguments = [ "--scp-extra-args", "'-O'" ]        # openssh compatibility (error fix)
    user = "ubuntu"
  }
}
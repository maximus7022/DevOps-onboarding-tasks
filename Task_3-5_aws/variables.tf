# ===========key-pair data local (to be able to use count)===========
locals {
  key_pairs = [
    data.aws_key_pair.wordpress_kp.key_name,
    data.aws_key_pair.docker_kp.key_name,
    data.aws_key_pair.nagios_kp.key_name
  ]
}

# ===========Ubuntu AMI===========
variable "ec2_ami" {
  default = "ami-07ec4220c92589b40"
}

variable "ec2_type" {
  default = "t3.micro"
}

# ===========Paths to SSH key-pairs===========
variable "key_paths" {
  default = [
    "keys/wordpress-key.pem",
    "keys/docker-key.pem",
    "keys/nagios-key.pem"
  ]
}

# ===========Names for instances===========
variable "ec2_names" {
  default = [
    "wordpress",
    "docker",
    "nagios"
  ]
}

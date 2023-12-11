# ===========Ubuntu AMI===========
variable "ec2_ami" {
  default = "ami-07ec4220c92589b40"
}

variable "ec2_type" {
  default = "t3.micro"
}

# ===========Names for instances===========
variable "docker_ec2_name" {
  default = "target-docker"
}

variable "prom_ec2_name" {
  default = "prometheus"
}

# ===========Allowed port lists===========
variable "docker_sg_port_list" {
  default = [22, 80, 9100]
}

variable "prom_sg_port_list" {
  default = [22, 9090, 9093, 3000]
}

# ===========IAM vars===========
variable "prom_role_name" {
  default = "PrometheusEC2sdConfigRole"
}

variable "docker_role_name" {
  default = "DockerECRAccessRole"
}

variable "prom_policy_arn" {
  default = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

variable "docker_policy_arn" {
  default = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

variable "prom_profile_name" {
  default = "prometheus_profile"
}

variable "docker_profile_name" {
  default = "docker_profile"
}

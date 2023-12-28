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

variable "loki_ec2_name" {
  default = "grafana-loki"
}

# ===========Allowed port lists===========
variable "docker_sg_port_list" {
  default = [22, 80]
}

variable "loki_sg_port_list" {
  default = [22, 3000, 3100]
}

# ===========IAM vars===========
variable "docker_role_name" {
  default = "DockerECRAccessRole"
}

variable "docker_policy_arn" {
  default = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

variable "docker_profile_name" {
  default = "docker_profile"
}

# ===========SSM var===========
variable "loki_ssm_name" {
  default = "LokiClientAddress"
}

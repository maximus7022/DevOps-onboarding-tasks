# ===========Ubuntu AMI===========
variable "ec2_ami" {
  default = "ami-07ec4220c92589b40"
}

variable "ec2_type" {
  default = "t3.micro"
}

# ===========Names for instances===========
variable "target_ec2_names" {
  default = [
    "target-wordpress",
    "target-docker"
  ]
}

variable "prom_ec2_name" {
  default = "prometheus"
}

# ===========Allowed port lists===========
variable "target_sg_port_list" {
  default = [22, 80, 9100]
}

variable "prom_sg_port_list" {
  default = [22, 9090, 9093, 3000]
}

# ===========IAM vars===========
variable "iam_role_name" {
  default = "PrometheusEC2sdConfigRole"
}

variable "policy_arn" {
  default = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

variable "profile_name" {
  default = "prometheus_profile"
}

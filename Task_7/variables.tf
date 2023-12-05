variable "namespace" {
  default = "monitoring"
}

variable "grafana_port" {
  default = 3000
}

variable "prometheus_port" {
  default = 9090
}

variable "target_ec2_tags" {
  default = ["target-docker", "target-wordpress"]
}

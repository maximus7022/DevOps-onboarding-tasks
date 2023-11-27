# ==========AWS TARGET EC2 DATA SOURCES==========

data "aws_instance" "targets" {
  count = 2
  filter {
    name   = "tag:Name"
    values = [var.target_ec2_tags[count.index]]
  }
}

# ==========CREATING NAMESPACE FOR PROMETHEUS==========

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = var.namespace
  }
}

# ==========DEPLOYING PROMETHEUS TO CLUSTER==========

resource "helm_release" "prometheus_release" {
  name   = "prometheus-release"
  chart  = "./prometheus-chart"
  values = ["${file("./prometheus-chart/values.yaml")}"]

  set {
    name  = "prometheus.port"
    value = var.prometheus_port
  }

  set {
    name  = "namespace"
    value = var.namespace
  }

  set {
    name  = "target1.public_ip"
    value = data.aws_instance.targets[0].public_ip
  }

  set {
    name  = "target2.public_ip"
    value = data.aws_instance.targets[1].public_ip
  }

  depends_on = [kubernetes_namespace.monitoring]
}

# ==========DEPLOYING GRAFANA TO CLUSTER==========

resource "helm_release" "grafana_release" {
  name   = "grafana-release"
  chart  = "./grafana-chart"
  values = ["${file("./grafana-chart/values.yaml")}"]

  set {
    name  = "grafana.port"
    value = var.grafana_port
  }

  set {
    name  = "namespace"
    value = var.namespace
  }

  depends_on = [helm_release.prometheus_release]
}

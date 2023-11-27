
---
# Deploying Prometheus + Grafana to Minikube with Terraform and Helm
## Description
This documentation outlines the process of **`Prometheus`** and **`Grafana`** deployment to local k8s cluster **`Minikube`**, as well as its configuration for monitoring external targets.
In the end, we will have **`Prometheus`** data collector with Grafana dashboard, configured to monitor **`Docker`** and **`WordPress`** hosts with **`node_exporter`**.

## Requirements
- **`Terraform + Helm`** installed
- **`Minikube`** and **`Docker as VM driver`** installed
- **`Account on AWS`** with free tier (if you don't want to pay some $)
- **`AWS CLI`** installed

## Environment preparation
First, you need to start your local Minikube cluster by running:
```bash
minikube start --vm-driver=docker
```

To be able to provision AWS infrastructure with Terraform you'll need:
- to create corresponding IAM user with administrative rights in AWS Management Console
- to run `aws configure` command with use of created IAM credentials

The monitoring targets are two AWS instances, the process of creating which is described in the [`documentation for the previous task`](https://github.com/maximus7022/DevOps-onboarding-tasks/blob/master/Task_6/README.md).

Thus, these two machines with **`docker`** and **`wordpress`** must be pre-configured and running at the time of the next steps.

## Helm
**`Prometheus`** and **`Grafana`** are being deployed with corresponding **`helm charts`**.
For that, 2 separate charts been created.
### `prometheus-chart`
This chart is responsible for **`Prometheus`** deployment and configuration.
- [**`values.yaml`**](./prometheus-chart/values.yaml) consists of a bunch of Helm variables that are being used in chart templates
- [**`deployment.yaml`**](./prometheus-chart/templates/deployment.yaml) file includes k8s deployment definition for Prometheus
- [**`service.yaml`**](./prometheus-chart/templates/service.yaml) file includes Prometheus service definition for UI dashboard exposure
- [**`clusterRole.yaml`**](./prometheus-chart/templates/clusterRole.yaml) file includes cluster role definition, that provides Prometheus with needed permissions
- [**`config-map.yaml`**](./prometheus-chart/templates/config-map.yaml) contains main Prometheus configuration with such target specification:
```yml
      - job_name: "docker"
        static_configs:
          - targets: ["{{ .Values.target1.public_ip }}:9100"]
      - job_name: "wordpress"
        static_configs:
          - targets: ["{{ .Values.target2.public_ip }}:9100"]
```

### `grafana-chart`
This chart is responsible for **`Grafana Dashboard`** deployment.
- [**`values.yaml`**](./grafana-chart/values.yaml) file consists of a bunch of Helm variables that are being used in chart templates
- [**`deployment.yaml`**](./grafana-chart/templates/deployment.yaml) file includes k8s deployment definition for Grafana
- [**`service.yaml`**](./grafana-chart/templates/service.yaml) file includes Grafana service definition for UI dashboard exposure
- [**`datasource.yaml`**](./grafana-chart/templates/datasource.yaml) contains Prometheus datasource config for Grafana:
```yml
      apiVersion: v1
      kind: ConfigMap
      metadata:
        name: "{{ .Values.configMap.name }}"
        namespace: "{{ .Values.namespace }}"
      data:
        prometheus.yaml: |-
          {
              "apiVersion": 1,
              "datasources": [
                  {
                    "access":"proxy",
                    "editable": true,
                    "name": "prometheus",
                    "orgId": 1,
                    "type": "prometheus",
                    "url": "http://prometheus-service.monitoring.svc:8080",
                    "version": 1
                  }
              ]
          }
```

## Terraform code
For actual deployment of described services we need following **`Terraform`** configuration.
### `providers.tf` defines required providers (**aws, helm and kubernetes**):
```hcl
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.17.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "minikube"
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "minikube"
  }
}
```

### `main.tf` describes receiving target AWS instances from data sources and helm releases:
```hcl
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
```

### `vaiables.tf`
```hcl
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
  default = ["docker", "wordpress"]
}
```

## Deployment
To deploy **`Prometheus and Grafana`**, configured to minitor external EC2 instances, just run `terraform init`
and `terraform apply` to confirm changes.

## Result
After successfull deployments you'll have:
- **`Prometheus`** deployed to Minikube and configured to scrape external target metrics from **`node_exporter`**
- **`Grafana dashboard`** that will visualize your metrics

If you will want `to save Minikube state` to work later, you need to run:
```bash
minikube stop
```

In case you want `to destroy all`, run:
```bash
terraform destroy
```
```bash 
minikube delete
```
---
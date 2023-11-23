
---
# Deploying Prometheus, Docker and WordPress to AWS with Terraform and Ansible
## Description
This documentation outlines the process of **`Prometheus`**, **`Docker`** and **`WordPress`** deployment to **`Amazon Web Services`**, as well as configuration of these hosts for proper monitoring and metric collection. 
In the end, we will have **`Prometheus`** data collector with Grafana dashboard, configured to monitor **`Docker`** and **`WordPress`** hosts with **`node_exporter`**.
  
## Requirements
- **`Ansible`** + **`Terraform`** installed
- **`Account on AWS`** with free tier (if you don't want to pay some $)
- **`AWS CLI`** installed

## Environment preparation
To be able to provision AWS infrastructure with Terraform you'll need:
- to create corresponding IAM user with administrative rights in AWS Management Console
- to run `aws configure` command with use of created IAM credentials

Also, you'll need to create key-pairs manually to ensure secure SSH access to resources.
Your keys (`key-name.pem`) will be automatically downloaded on your PC after creation. 

***You need to place them in the project directory under `keys` folder***.

## Terraform code
Terraform configuration consists of some files with different content and purpose.
### `providers.tf` defines base terraform configuration (*aws provider, region, versions*):
```hcl
terraform {
  required_version = ">= 1.2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
}

provider "aws" {
  region = "eu-north-1"
}
```

### `main.tf` describes main AWS resouces:
```hcl
# ===========EC2 instances creation===========
resource "aws_instance" "ec2" {
  count                  = 3
  ami                    = var.ec2_ami
  instance_type          = var.ec2_type
  vpc_security_group_ids = [aws_security_group.ec2_sg[count.index].id]
  key_name               = local.key_pairs[count.index]
  tags = {
    Name = var.ec2_names[count.index]
  }
}

# ===========Setting EC2 public IPs and key paths into ansible inventory===========
resource "null_resource" "inventory_update" {
  count = 3
  provisioner "local-exec" {
    command = "echo '[${var.ec2_names[count.index]}]\n${aws_instance.ec2[count.index].public_ip} ansible_ssh_private_key_file=${var.key_paths[count.index]}' >> ansible/inventory.txt"
  }
  depends_on = [aws_instance.ec2]
}

# ===========Setting docker and wordpress EC2 IPs as ansible vars===========
resource "null_resource" "hosts_to_monitor_update" {
  count = 2
  provisioner "local-exec" {
    command = "echo '${var.ec2_names[count.index]}_host_ip: ${aws_instance.ec2[count.index].public_ip}' >> ansible/prometheus/roles/prom-install/vars/main.yml"
  }
  depends_on = [aws_instance.ec2]
}
```

### `security.tf` defines resources related to security:
```hcl
# ===========SSH key-pair data sources===========
data "aws_key_pair" "wordpress_kp" {
  filter {
    name   = "tag:Task"
    values = ["task3"]
  }
}

data "aws_key_pair" "docker_kp" {
  filter {
    name   = "tag:Task"
    values = ["task4"]
  }
}

data "aws_key_pair" "prom_kp" {
  filter {
    name   = "tag:Task"
    values = ["task6"]
  }
}

# ===========Security groups for monitoring===========
resource "aws_security_group" "ec2_sg" {
  count = 3
  name  = "${var.ec2_names[count.index]} EC2 Security Group"

  dynamic "ingress" {
    for_each = var.sg_port_lists[count.index]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

Here, you can see some key-pair data sources where filtering is being implemented through tags.

***These tags were set during the key-pair creation process.***
### `vaiables.tf`
```hcl
# ===========key-pair data local (to be able to use count)===========
locals {
  key_pairs = [
    data.aws_key_pair.wordpress_kp.key_name,
    data.aws_key_pair.docker_kp.key_name,
    data.aws_key_pair.prom_kp.key_name
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
    "keys/prometheus-key.pem"
  ]
}

# ===========Names for instances===========
variable "ec2_names" {
  default = [
    "wordpress",
    "docker",
    "prometheus"
  ]
}

# ===========Allowed port lists===========
variable "sg_port_lists" {
  default = [
    [22, 80, 9100],
    [22, 80, 9100],
    [22, 9090, 3000]
  ]
}
```

## Infrastructure creation
To create all needed infrastructure, run `terraform init` to install providers and dependencies.

Then, run `terraform apply` and confirm changes.

## Ansible
After all needed infrastructure is up and running, we can start our services deployment.

For that, 3 different ansible playbooks been created.
- [**`docker playbook`**](./ansible/docker) to deploy docker container with apache server on the corresponding EC2 instance:
```yml
    ---
    - hosts: docker                     # host, defined in inventory.txt
      remote_user: ubuntu               # remote user to login with
      become: yes                       # become root
      roles:
        - roles/docker-install          # role, that installs docker on the machine
        - roles/apache-container        # role, that creates and runs docker container with apache
        - roles/node-exporter-install   # role, that installs and configures node_exporter
```
- [**`wordpress playbook`**](./ansible/wordpress) to deploy wordpress service on the corresponding machine:
```yml
    ---
    - hosts: wordpress                  # host, defined in inventory.txt
      remote_user: ubuntu               # remote user to login with
      become: yes                       # become root
      roles:
        - roles/ansiblewordpress        # role, that installs and configures wordpress
        - roles/node-exporter-install   # role, that installs and configures node_exporter
```
- [**`prometheus playbook`**](./ansible/prometheus) to deploy and configure Nagios Core monitoring server on the last EC2 instance:
```yml
    ---
    - hosts: prometheus                   # host from inventory
      remote_user: ubuntu                 # target machine username
      become: yes                         # sudo
      roles:
        - roles/prom-install              # role, that installs prometheus
        - roles/node-exporter-install     # role, that installs node_exporter
        - roles/grafana-install           # role, that installs grafana

    # node_exporter public dashboard --> 1860
```

Besides actual services installation, these playbooks are bundled with monitoring and observability configuration.

In the [**`ansible`**](./ansible) directory you can also find the [**`inventory.txt`**](./ansible/inventory.txt) file, which contains host public IPs and paths to SSH key-pair files (***This file is managed by terraform configuration***).

## Service deployment
To deploy described services and apply configuration we need to run our playbooks:
```bash
ansible-playbook ./ansible/docker/playbook.yml -i ./ansible/inventory.txt
```
```bash
ansible-playbook ./ansible/wordpress/playbook.yml -i ./ansible/inventory.txt
```
```bash
ansible-playbook ./ansible/prometheus/playbook.yml -i ./ansible/inventory.txt
```

## Result
After successfull deployments you'll have:
- Ubuntu instance with **`Docker`** and running Apache2 container on board, configured to be a target of monitoring with **`node_exporter`**
- Ubuntu instance with **`WordPress`**, configured to be a target of monitoring with **`node_exporter`** as well
- **`Prometheus server`** with **`Grafana dashboard`**, configured to monitor resources and services of Docker and Wordpress EC2 instances
---

---
# Provisioning preconfigured AWS AMIs with Hashicorp Packer
## Description
This documentation outlines the process of creating preconfigured AWS machine images with use of **`Packer`** and **`Ansible`**.

**`Packer`** is a tool for building identical machine images for multiple platforms from a single source configuration.

**`Packer`** is lightweight, runs on every major operating system, and is highly performant, creating machine images for multiple platforms in parallel. **`Packer`** supports various platforms through external plugin integrations, the full list of which can be found at https://developer.hashicorp.com/packer/integrations.

## Requirements
- **`Packer + Ansible`** installed
- **`Terraform`** installed
- **`Account on AWS`** with free tier (if you don't want to pay some $)
- **`AWS CLI`** installed

## Environment preparation
To be able to provision AWS infrastructure with Terraform and AMIs with Packer you'll need:
- to create corresponding IAM user with administrative rights in AWS Management Console
- to run `aws configure` command with use of created IAM credentials

## Ansible
In this example we use **`Ansible`** to automatically configure machines for further images creation with **`Packer`**.

Thus, 3 different machines are being provisioned. Each of them has its own Ansible playbook with different configurations:
- First machine must contain Docker Engine and run container with apache2 server.
- Second machine must contain configured and running Wordpress.
- Last machine must monitor previous ones with Prometheus and Grafana under the hood.

PLaybooks are located under the [**`ansible`**](./ansible) directory and have such structure:
#### `docker` `playbook.yml`:
```yml
  ---
  - hosts: default                          # host is being set automatically by Packer
    become: yes                             # become root
    roles:
      - roles/docker-install                # role, that installs docker on the machine
      - roles/apache-container              # role, that creates and runs docker container with apache
      - roles/node-exporter-install         # role, that installs and configures node_exporter
```

#### `wordpress` `playbook.yml`:
```yml
  ---
  - hosts: default                          # host is being set automatically by Packer
    become: yes                             # become root
    roles:
      - roles/ansiblewordpress              # role, that installs and configures wordpress
      - roles/node-exporter-install         # role, that installs and configures node_exporter
```

#### `prometheus` `playbook.yml`:
```yml
  ---
  - hosts: default                      # host is being set automatically by Packer
    become: yes                         # sudo
    roles:
      - roles/prom-install              # role, that installs prometheus
      - roles/node-exporter-install     # role, that installs node_exporter
      - roles/grafana-install           # role, that installs grafana

  # node_exporter public dashboard --> 1860
```

## Packer config
Files, located under [**`packer`**](./packer) folder, contain required configurations for automatic AMI creation.

**`plugins.pkr.hcl`** contains required plugins (`aws` and `ansible`):
```hcl
  packer {
    required_plugins {
      amazon = {
        version = " >= 1.0.0 "
        source = "github.com/hashicorp/amazon"
      }
      ansible = {
        source  = "github.com/hashicorp/ansible"
        version = "~> 1"
      }
    }
  }
```

Next files are pretty similar, each of them consists of AMI configuration for our future EC2 machines.

**`docker.pkr.hcl`**:
```hcl
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
```

**`wordpress.pkr.hcl`**:
```hcl
  source "amazon-ebs" "wordpress" {
    ami_name = "wordpress-ami"
    source_ami = "ami-07ec4220c92589b40"
    instance_type = "t3.micro"
    region = "eu-north-1"
    ssh_username = "ubuntu"
  }

  build {
    name = "wordpress"
    sources = [
      "source.amazon-ebs.wordpress"
    ]

    provisioner "ansible" {
      playbook_file = "../ansible/wordpress/playbook.yml"
      ansible_env_vars = ["ANSIBLE_HOST_KEY_CHECKING=False"]
      extra_arguments = [ "--scp-extra-args", "'-O'" ]        # openssh compatibility (error fix)
      user = "ubuntu"
    }
  }
```

**`prometheus.pkr.hcl`**:
```hcl
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
```

Last three files consist from two blocks - `source` and `build`.
- `source` block configures general ami and source instance information
- `build` block is responsible for ami configuration process with different provisioners (Ansible in our case) 

## Images creation
To apply all described configuration you'll need to install all necessary plugins by running in the project folder:
```bash
  packer init packer
```
After that build each AMI by running those commands:
```bash
  packer build packer/docker_ami.pkr.hcl
```
```bash
  packer build packer/wordpress_ami.pkr.hcl
```
```bash
  packer build packer/prometheus_ami.pkr.hcl
```

After that you'll have **3 preconfigured AMIs on AWS**, which you can use for EC2 instances creation.

## Terraform code
In this example Terraform is being used to create EC2 instances from previously provisioned AMIs.
### `providers.tf` defines required provider:
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

### `main.tf` describes receiving our AMIs with data blocks and instances creation:
```hcl
# ===========Receiving packer provisioned AMIs data===========
data "aws_ami" "docker_ami" {
  filter {
    name   = "name"
    values = ["docker-ami"]
  }
}

data "aws_ami" "wordpress_ami" {
  filter {
    name   = "name"
    values = ["wordpress-ami"]
  }
}

data "aws_ami" "prometheus_ami" {
  filter {
    name   = "name"
    values = ["prometheus-ami"]
  }
}

# ===========EC2 instances creation===========
resource "aws_instance" "ec2_docker" {
  ami                    = data.aws_ami.docker_ami.id
  instance_type          = var.ec2_type
  vpc_security_group_ids = [aws_security_group.ec2_target_sg.id]
  key_name               = data.aws_key_pair.ec2_kp.key_name
  tags = {
    Name = var.target_ec2_names[0]
  }
}

resource "aws_instance" "ec2_wordpress" {
  ami                    = data.aws_ami.wordpress_ami.id
  instance_type          = var.ec2_type
  vpc_security_group_ids = [aws_security_group.ec2_target_sg.id]
  key_name               = data.aws_key_pair.ec2_kp.key_name
  tags = {
    Name = var.target_ec2_names[1]
  }
}

resource "aws_instance" "ec2_prometheus" {
  ami                    = data.aws_ami.prometheus_ami.id
  instance_type          = var.ec2_type
  vpc_security_group_ids = [aws_security_group.ec2_prom_sg.id]
  key_name               = data.aws_key_pair.ec2_kp.key_name
  iam_instance_profile   = aws_iam_instance_profile.instance_profile.name
  tags = {
    Name = var.prom_ec2_name
  }
}
```

### `vaiables.tf`
```hcl
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
  default = [22, 9090, 3000]
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
```

### `security.tf`
```hcl
# ===========SSH key-pair data source===========
data "aws_key_pair" "ec2_kp" {
  filter {
    name   = "tag:Purpose"
    values = ["onboarding"]
  }
}

# ===========Security groups for monitoring===========
resource "aws_security_group" "ec2_target_sg" {
  name = "Monitoring Target EC2 Security Group"

  dynamic "ingress" {
    for_each = var.target_sg_port_list
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

resource "aws_security_group" "ec2_prom_sg" {
  name = "Prometheus EC2 Security Group"

  dynamic "ingress" {
    for_each = var.prom_sg_port_list
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

# ===========IAM role for ec2_sd_config===========
resource "aws_iam_role" "iam_role" {
  name = var.iam_role_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "policy_attachment" {
  role       = aws_iam_role.iam_role.name
  policy_arn = var.policy_arn
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = var.profile_name
  role = aws_iam_role.iam_role.name
}
```

## Instances creation
To create EC2 instances from preconfigured AMIs, just run `terraform init`
and `terraform apply` to confirm changes.

---
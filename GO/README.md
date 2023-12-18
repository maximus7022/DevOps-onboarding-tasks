
---
# Monitoring Golang http server with Prometheus
## Description
This documentation outlines the process of simple http server creation with Golang and configuring `HTTP Requests Count metric` exposure to Prometheus.

`The Golang server` is intended to run in a Docker container on a dedicated AWS EC2 instance.

`The Prometheus server` will reside on another EC2 instance.

## Requirements
- `Account on AWS` with free tier (if you don't want to pay some $)
- `AWS CLI` [installed](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- `golang` [installed](https://go.dev/doc/install)
- `Terraform` [installed](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- `Docker` [installed](https://docs.docker.com/engine/install/)
- `Ansible` [installed](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)

## Project structure
The project implementation consists of such files:
```bash
GO
├── ansible
│   ├── ansible.cfg
│   ├── aws_ec2.yml
│   ├── docker
│   │   ├── playbook.yml
│   │   └── roles
│   │       ├── docker-install
│   │       │   └── tasks
│   │       │       └── main.yml
│   │       └── go-app-container
│   │           ├── tasks
│   │           │   └── main.yml
│   │           └── vars
│   │               └── main.yml
│   └── prometheus
│       ├── playbook.yml
│       └── roles
│           ├── alert-manager-install
│           │   ├── tasks
│           │   │   └── main.yml
│           │   ├── templates
│           │   │   ├── alert-config.j2
│           │   │   ├── alert-service.j2
│           │   │   └── alert.j2
│           │   └── vars
│           │       └── main.yml
│           ├── grafana-install
│           │   ├── tasks
│           │   │   └── main.yml
│           │   └── templates
│           │       └── data-source.j2
│           ├── node-exporter-install
│           │   ├── tasks
│           │   │   └── main.yml
│           │   └── templates
│           │       └── node-exp-service.j2
│           └── prom-install
│               ├── tasks
│               │   └── main.yml
│               └── templates
│                   ├── prom-config.j2
│                   └── prom-service.j2
├── server
│   ├── Dockerfile
│   ├── go.mod
│   ├── go.sum
│   ├── main.go
│   └── web
│       ├── css
│       │   └── style.css
│       ├── images
│       │   ├── bg.jpg
│       │   └── blackhole.png
│       ├── index.html
│       ├── js
│       │   └── script.js
│       └── video
│           └── bg.mp4
├── keys
│   └── ec2-key.pem
├── main.tf
├── providers.tf
├── security.tf
└── variables.tf
```
- [**`server`**](./server) folder contains actual `go application`, `static website files` (to serve) and `Dockerfile` (to build an image and transfer it to EC2 instance with Docker under the hood). Dockerfile is as follows:
```Dockerfile
  # build stage
  FROM golang:1.21.5-alpine AS builder

  WORKDIR /app

  COPY go.mod go.sum ./
  COPY main.go ./

  RUN go build -o /go-app

  # run stage
  FROM alpine:latest

  COPY --from=builder /go-app /go-app
  COPY web ./web/

  EXPOSE 8080
  CMD [ "/go-app" ]
```
- [**`ansible`**](./ansible) folder consists of two Ansible playbooks (one for `Docker instance with golang app container` and another one for `Prometheus monitoring server`).
- **`keys`** folder is not included to version control. It contains a single `SSH key`, that is used by Ansible to connect to EC2 instances.
- **`root folder`** contains `terraform configuration files` for infrastructure provisioning.

## Some preparations:
After you cloned this project into your local env, you'll need [to create private ECR repository](https://docs.aws.amazon.com/AmazonECR/latest/userguide/repository-create.html) for the go application image.

After that you'll need to build application docker image and push it to the registry.

To do so, you need to login to the registry. For that your aws cli IAM user must have permission to place images in ECR (`AmazonEC2ContainerRegistryFullAccess` policy). After you ensured it, run:
```bash
  aws ecr get-login-password --region <AWS_REGION> | docker login --username AWS --password-stdin <ECR_URI>
```

```bash
  docker build -t <ECR_URI> ./server
```

```bash
  docker push <ECR_URI>
```

Now your image resides in the secure remote location, from where you can pull it when you need.

Image pulling is defined as part of ansible playbook:
```yml
---
- name: Amazon ECR Login
  shell: aws ecr get-login-password --region eu-north-1 | docker login --username AWS --password-stdin {{ ecr_repo }}

- name: Run GO container
  community.docker.docker_container:
    name: go-app
    image: "{{ ecr_repo }}/go-app:latest"
    pull: true
    state: started
    ports:
      - "80:8080"
```

To provide your Ansible server with all needed AWS permissions you'll need:
- to create corresponding IAM user with **`AmazonEC2ReadOnly`** + **`SecretsManagerReadWrite`** + **`AmazonEC2ContainerRegistryPowerUser`** policies in AWS Management Console
- to create corresponding profile with `aws configure` command with use of created IAM credentials:
```bash
  aws configure set --profile ansible aws_access_key_id <your_key_id>
```
```bash
  aws configure set --profile ansible aws_secret_access_key <your_secret_key>
```
```bash
  aws configure set --profile ansible region <your_aws_region>
```

To provide Prometheus EC2 instance with rights to dynamically observe other instances you'll need to create corresponding IAM role with **`AmazonEC2ReadOnlyAccess`** policy (manually or with terraform):
```hcl
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

And attach new IAM profile to the instance:
```hcl
resource "aws_instance" "ec2_prometheus" {
  ami                    = var.ec2_ami
  instance_type          = var.ec2_type
  vpc_security_group_ids = [aws_security_group.ec2_prom_sg.id]
  key_name               = data.aws_key_pair.ec2_kp.key_name
  iam_instance_profile   = aws_iam_instance_profile.instance_profile.name
  tags = {
    Name = var.prom_ec2_name
  }
}
```
Same for Docker instance (**`AmazonEC2ContainerRegistryReadOnly`**) to make it able to pull ECR image.

## Applying the configuration
To apply all configuration you need to provicion EC2 instances with terraform. Run:
```bash
  terraform init
```
```bash
  terraform apply
```

After that, move to the ansible folder and run both playbooks:
```bash
  ansible-playbook ./docker/playbook.yml
```
```bash
  ansible-playbook ./prometheus/playbook.yml
```

## Result
Now we have:
- simple `HTTP server with Golang backend` running in a docker container and exposing `Website Access Count metric` to Prometheus
- `Prometheus server` that scrapes our HTTP server metrics
---
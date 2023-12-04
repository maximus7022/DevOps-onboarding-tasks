
---
# Ansible dynamic inventory and Prometheus ec2_sd_config configuration
## Description
This documentation outlines the process of [`previous task`](https://github.com/maximus7022/DevOps-onboarding-tasks/tree/master/Task_6) modification to ensure Ansible dynamic inventory and Prometheus dynamic targets config.

## Environment preparation
To be able to use aws_ec2 Ansible plugin you'll need:
- to create corresponding IAM user with **`AmazonEC2FullAccess`** policy in AWS Management Console
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
## New files
**`ansible.cfg`** been added to specify main ansible environment settings in one place:
```
  [defaults]
  host_key_checking = false
  inventory = aws_ec2.yml
  private_key_file = ../keys/ec2-key.pem

  [inventory]
  enable_plugins = aws_ec2
```

**`aws_ec2.yml`** - dynamic inventory itself, exists thanks to aws_ec2 Ansible plugin, it allows to autodetect instances by tags:
```yml
  ---
  plugin: aws_ec2
  aws_profile: ansible    # specifying aws config profile
  filters:
    tag:Name:             # filtering targets by tags
      - target-wordpress
      - target-docker
      - prometheus
    instance-state-name : running
  keyed_groups:
    - key: tags
      prefix: tag
```
## Key changes
Now there is no static inventory, all Ansible playbooks are using dynamic one. Hosts field of each playbook now contains alias of an EC2 tag:

**`prometheus`**:
```yml
  - hosts: tag_Name_prometheus             # host from dynamic inventory
```
**`docker`**:
```yml
  - hosts: tag_Name_target_docker          # host, defined in dynamic inventory
```
**`wordpress`**:
```yml
  - hosts: tag_Name_target_wordpress       # host, defined in dynamic inventory
```

Prometheus main config template has been modified by adding **`ec2_sd_configs`** to enable dynamic monitoring target detection. Here is a new job for **`docker`** and **`wordpress`** targets:
```yml
  - job_name: "targets"
    ec2_sd_configs:
      - region: eu-north-1
        port: 9100
    relabel_configs:
      - source_labels: [__meta_ec2_tag_Name]
        regex: target-.*
        action: keep
        target_label: instance
```
 

## Result
As a result, after all mentioned modifications we got rid of all hardcoded values and ensured dynamic IP mapping, that provides more flexible workflow.

---
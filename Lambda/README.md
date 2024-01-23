
---
# Performing Amazon EC2 health-checks with a Lambda function provisioned by Terraform

## Overview
`The goal` of this project is to collect and to visualize information about **Amazon EC2 instances** on the **Grafana Dashboard**.

`A Lambda function (Python)` has been developed to perform status checks on EC2 instances, which collects all the necessary information and saves it in **JSON format** to an **S3 bucket**. Also, this function supports **logging in Cloudwatch** and creates a **custom metric**.

`All AWS resources` being created with use of **Terraform**.

Separate `EC2 instance with Grafana server` been provisioned with **Ansible**.

To deliver `JSON data from the S3 bucket to Grafana`, it was decided to develop a simple **bash script** that will run in the background and **download data directly** from the bucket after **receiving a notification from the SQS queue** about a new object in the bucket.

## Prerequisites
To reproduce this project in your own environment you'll need:
- `AWS free tier account`
- `Terraform` to provision AWS infrastructure
- `Ansible` to deploy and configure Grafana on EC2

To be able to provision AWS infrastructure with Terraform you'll need:
- to create corresponding IAM user with administrative rights in AWS Management Console
- to run `aws configure` command with use of created IAM credentials

## Steps to reproduce

### The Python funtion itself
First of all we need to develop the code that we want to run as Lambda function. As an example, we have [`such code`](./source/lambda_function.py):
```python
import os
import json
import boto3
import logging

# aws clients
ec2_client = boto3.client('ec2')
s3_client = boto3.client('s3')
cloudwatch_client = boto3.client('cloudwatch')

# logger init
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    # EC2 information gathering
    logger.info("Starting to collect information about EC2 instances...")
    reservations = ec2_client.describe_instances()['Reservations']
    instances_data = {"instances": []}
    running_count = 0
    for reservation in reservations:
      for index, instance in enumerate(reservation['Instances']):
        instance_info = {
          "name": instance['Tags'][0]['Value'],
          "id": instance['InstanceId'],
          "type": instance['InstanceType'],
          "state": instance['State']['Name'],
          "launch_time": instance['LaunchTime'].strftime("%Y-%m-%d %H:%M:%S")
        }
        if instance['State']['Name'] == 'running':
          running_count += 1
          status_check_response = ec2_client.describe_instance_status(InstanceIds=[instance['InstanceId']])
          if 'InstanceStatuses' in status_check_response and len(status_check_response['InstanceStatuses']) > 0:
            instance_info.update({
              "instance_status_check": status_check_response['InstanceStatuses'][0]['InstanceStatus']['Details'][0]['Status'],
              "system_status_check": status_check_response['InstanceStatuses'][0]['SystemStatus']['Details'][0]['Status']
            })
        else:
          instance_info.update({
              "instance_status_check": "not running",
              "system_status_check": "not running"
            })
        instances_data["instances"].append(instance_info)
        logger.info(f"Collected info about instance with ID: {instance['InstanceId']}")
    logger.info("Finished EC2 instances collection.")
    
    # putting cloudwatch custom metric (running instances)
    logger.info(f"Exposing Cloudwatch custom metric...")
    cloudwatch_client.put_metric_data(
      Namespace='LambdaHealthCheckNamespace',
      MetricData=[
        {
          'MetricName': 'running_instances',
          'Value': running_count,
          'Unit': 'Count'
        },
      ]
    )
    logger.info("Cloudwatch custom metric exposed successfully.")

    # pushing gathered info to S3 bucket
    logger.info("Sending collected info to S3 bucket...")
    json_output = json.dumps(instances_data, indent=4, default=str)
    bucket_name = os.environ["BUCKET"]
    file_name = 'instance_data.json'
    s3_client.put_object(Body=json_output, Bucket=bucket_name, Key=file_name)
    logger.info(f"JSON data sent to S3 bucket: {bucket_name}/{file_name}")
    return instances_data
```
After execution, this code `collects information about all EC2's` in the region, converts the collected information `to JSON` and sends it to the `S3 bucket`.

### Terraform configuration
The following Terraform module structure been created for infrastructure provisioning:
- [`s3 module`](./modules/s3/): creates **S3 bucket** with versioning, **SQS queue** and **bucket notification**.
- [`lambda module`](./modules/lambda/): provisions **Lambda function**, configures all necessary **IAM permissions** and **automatic execution triggering**.
- [`grafana module`](./modules/grafana/): creates **Grafana EC2 instance**, security group + IAM permissions.

To apply above config you need to navigate to the [`root project directory`](./) and run such commands:
```bash
  terraform init
```
```bash
  terraform apply
```

### Ansible
To provision Grafana with all necessary configurations we need a corresponding playbook. [`Here`](./ansible/) it is:
```yml
  ---
  - hosts: tag_Name_grafana               # host from dynamic inventory
    remote_user: ubuntu                   # target machine username
    become: yes                           # sudo
    roles:
      - roles/grafana-install             # role, that installs grafana
      - roles/sqs-listener                # role, that launches script
```
It consists of two roles, one for Grafana server installation, datasource and dashboard pre-configuration, second one for bash script execution. 

To run this playbook you need to navigate to the [`ansible`](./ansible/) directory after applying terraform config and simply run:
```bash
  ansible-playbook grafana/playbook.yml
```

### Receiving data from S3 bucket
To deliver data to Grafana EC2 we have such daemon [`script`](./ansible/grafana/roles/sqs-listener/templates/sqs-listener.j2):
```bash
  #!/bin/bash

  function handle_sqs_notification() {
    FILE_KEY=$(jq -r '.Messages[].Body | fromjson | .Records[].s3.object.key' <<< $1)
    if [ ! $? -eq 0 ]; then
      return 1
    fi
    sudo aws s3 cp s3://{{ s3_bucket_name }}/$FILE_KEY /var/www/html/$FILE_KEY
  }

  while true; do
    sqs_message=$(aws sqs receive-message --queue-url {{ sqs_queue_url }} --region {{ region }} --wait-time-seconds 20)
    receipt_handle=$(jq -r '.Messages[].ReceiptHandle' <<< $sqs_message)

    if [[ $sqs_message ]]; then
      handle_sqs_notification "$sqs_message"
      if [ $? -eq 0 ]; then
        sudo aws sqs delete-message --receipt-handle $receipt_handle --queue-url {{ sqs_queue_url }} --region {{ region }}
      fi
    fi
  done
```
It waits for a message about new object in S3 bucket from SQS queue and downloads data from bucket after receiving one. 

Path for data downloads is set to ***/var/www/html*** because we need to serve our data on the local apache server in order to ensure access to it for Grafana ([**JSON API plugin**](https://grafana.com/grafana/plugins/marcusolsson-json-datasource/)). 

## Result
As a result, after applying all configs we have: 
- `Lambda function`, that performs EC2 health-checks and sends data to S3 bucket.
- `SQS queue`, that receive messages about new objects from S3 bucket.
- `EC2 instance with Grafana Server`.
- `bash background script`, that downloads data from S3 after receiving a message from SQS.
- `Grafana dashboard` with visualized data.
---
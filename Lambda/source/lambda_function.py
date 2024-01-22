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